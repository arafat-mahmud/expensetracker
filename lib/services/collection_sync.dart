import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'auth_service.dart';
import 'hive_service.dart';
import 'sync_queue_service.dart';

/// Changes received from Firestore for one collection, ready to apply
/// locally. Ids with a local write still waiting in the sync queue are left
/// out: that write is newer and will overwrite the remote version.
class RemoteChanges {
  /// "Delete All" was run on another device
  bool wiped = false;

  /// Live documents by id, including control docs such as `_settings`
  final Map<String, Map<String, dynamic>> upserts = {};

  final Set<String> deletedIds = {};
}

/// Parses remote docs, skipping (and logging) any that are malformed so one
/// bad document cannot block the rest of the sync
Map<String, T> parseRemoteDocs<T>(Map<String, Map<String, dynamic>> docs,
    T Function(Map<String, dynamic>) fromJson) {
  final parsed = <String, T>{};
  docs.forEach((id, data) {
    try {
      parsed[id] = fromJson(data);
    } catch (e) {
      print('⚠️ [SYNC] Skipping malformed document $id: $e');
    }
  });
  return parsed;
}

/// Keeps one Firestore collection in step with local storage on every device
/// signed in to the same account, at the lowest read cost Firestore allows:
/// - The whole collection is read from the server once per device. Signing
///   in again on the same device loads it from Firestore's local cache, which
///   is free.
/// - A listener then receives only documents changed on *other* devices since
///   the last sync. Each remote change costs one read, this device's own
///   writes cost none, and nothing is read while the app is in the background.
///
/// Every write carries `updatedAt` (server time) and `deviceId` (added by
/// SyncQueueService). Deletes are written as `deleted: true` tombstones so
/// the listeners on other devices see them.
class CollectionSync with WidgetsBindingObserver {
  CollectionSync({
    required this.scope,
    required this.entity,
    required this.collection,
    required this.isLocalEmpty,
    required this.apply,
  }) {
    WidgetsBinding.instance.addObserver(this);
  }

  static const String settingsDocId = '_settings';
  static const String wipeDocId = '_wipe';

  // Firestore re-attaches a listener with a resume token and bills only what
  // changed meanwhile, but the token expires after 30 minutes
  static const Duration _resumeTokenLifetime = Duration(minutes: 30);

  /// Key for the stored sync state, e.g. 'expenses'
  final String scope;

  /// SyncQueueService entity name, e.g. 'expense'
  final String entity;
  final CollectionReference Function() collection;
  final bool Function() isLocalEmpty;
  final Future<void> Function(RemoteChanges changes) apply;

  final AuthService _authService = AuthService();
  String? _userId;
  bool _active = false;
  Future<bool>? _starting;
  // Bumped by stop(), so work started for an earlier session is dropped
  int _generation = 0;
  StreamSubscription<QuerySnapshot>? _subscription;
  int? _listenFrom;
  DateTime? _pausedAt;
  Future<void> _applyQueue = Future.value();
  bool _deviceFilterUnavailable = false;

  /// Loads the collection if local storage needs it, then listens for changes
  /// from other devices. Safe to call repeatedly (e.g. pull-to-refresh): while
  /// the listener is running it costs nothing.
  /// Returns true when data was loaded into an empty local store.
  Future<bool> start() {
    final userId = _authService.getUserId();
    if (userId == null) return Future.value(false);
    if (_userId == userId) {
      if (_starting != null) return _starting!;
      if (_active) {
        if (_subscription == null) _listen();
        return Future.value(false);
      }
    } else {
      stop();
    }

    _userId = userId;
    late final Future<bool> starting;
    starting = _start(userId, _generation).whenComplete(() {
      if (identical(_starting, starting)) _starting = null;
    });
    return _starting = starting;
  }

  bool _isCurrent(String userId, int generation) =>
      generation == _generation && _authService.getUserId() == userId;

  Future<bool> _start(String userId, int generation) async {
    var loaded = false;
    try {
      final lastSyncAt = HiveService.getLastSyncAt(userId, scope);
      final localWasEmpty = isLocalEmpty();

      if (lastSyncAt == null) {
        // First sync on this device: the only full read from the server
        final snapshot = await collection()
            .get(const GetOptions(source: Source.server));
        if (!_isCurrent(userId, generation)) return false;
        await _apply(snapshot.docs, initialLoad: true);
        await HiveService.setLastSyncAt(
            userId, scope, _newestUpdate(snapshot.docs) ?? 0);
        loaded = localWasEmpty;
        print('☁️ [SYNC:$scope] First sync: ${snapshot.docs.length} docs');
      } else if (localWasEmpty) {
        // Signed in again on this device: Firestore's local cache already
        // holds every document up to lastSyncAt, and cache reads are free
        final snapshot =
            await collection().get(const GetOptions(source: Source.cache));
        if (!_isCurrent(userId, generation)) return false;
        await _apply(snapshot.docs, initialLoad: true);
        loaded = true;
        print('📦 [SYNC:$scope] Loaded ${snapshot.docs.length} docs from cache');
      }
    } catch (e) {
      // Offline on first launch, for example. Retried by the next start()
      // (app resume, pull-to-refresh, sign-in).
      print('❌ [SYNC:$scope] Initial load failed: $e');
      return false;
    }

    if (!_isCurrent(userId, generation)) return false;
    _active = true;
    _listen();
    return loaded;
  }

  void stop() {
    _generation++;
    _starting = null;
    _subscription?.cancel();
    _subscription = null;
    _active = false;
    _userId = null;
    _listenFrom = null;
    _pausedAt = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_userId == null) return;

    if (state == AppLifecycleState.paused) {
      // Nothing is read in the background; Firestore keeps the resume token
      _pausedAt = DateTime.now();
      _subscription?.cancel();
      _subscription = null;
    } else if (state == AppLifecycleState.resumed) {
      if (!_active) {
        start(); // the initial load or the listener failed earlier
        return;
      }
      if (_subscription != null) return;

      final pausedAt = _pausedAt;
      if (pausedAt != null &&
          DateTime.now().difference(pausedAt) >= _resumeTokenLifetime) {
        // With the token expired, re-attaching the same query is billed as a
        // new query over everything it ever matched. Starting from the latest
        // sync point reads only what is actually new.
        _listenFrom = null;
      }
      _listen();
    }
  }

  void _listen() {
    final userId = _userId;
    if (userId == null) return;
    _subscription?.cancel();
    _subscription = null;
    // Attached on resume instead, so nothing is read in the background
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }

    final from = _listenFrom ??= HiveService.getLastSyncAt(userId, scope) ?? 0;
    final generation = _generation;
    _subscription = _changesSince(from).snapshots().listen(
      (snapshot) => _applyQueue =
          _applyQueue.then((_) => _onSnapshot(snapshot, generation)),
      onError: _onListenError,
    );
  }

  Query _changesSince(int fromMicros) {
    Query query = collection().where('updatedAt',
        isGreaterThan: Timestamp.fromMicrosecondsSinceEpoch(fromMicros));
    if (!_deviceFilterUnavailable) {
      // Leaves this device's own writes out on the server, so they cost no
      // reads. Needs a composite index on (deviceId, updatedAt).
      query = query.where('deviceId', isNotEqualTo: HiveService.getDeviceId());
    }
    return query;
  }

  bool _isMissingIndex(Object error) =>
      error is FirebaseException &&
      error.code == 'failed-precondition' &&
      !_deviceFilterUnavailable;

  void _onListenError(Object error) {
    _subscription = null;
    if (_isMissingIndex(error)) {
      // Until the index exists, listen without the device filter (each of
      // this device's own writes then costs one read)
      print('⚠️ [SYNC:$scope] Missing Firestore index. Create it with the '
          'link in this message: $error');
      _deviceFilterUnavailable = true;
      _listen();
      return;
    }
    print('❌ [SYNC:$scope] Listener failed: $error');
    _active = false; // restarted by the next start() or app resume
  }

  Future<void> _onSnapshot(QuerySnapshot snapshot, int generation) async {
    final userId = _userId;
    if (userId == null || !_isCurrent(userId, generation)) return;

    try {
      final docs = [
        for (final change in snapshot.docChanges)
          // "removed" only means a doc stopped matching the query (e.g. this
          // device edited it); real deletions arrive as tombstones. Docs with
          // pending writes are this device's own unconfirmed changes.
          if (change.type != DocumentChangeType.removed &&
              !change.doc.metadata.hasPendingWrites)
            change.doc,
      ];
      if (docs.isNotEmpty) await _apply(docs, initialLoad: false);

      // Only a server snapshot is complete, so only it may move the sync point
      if (!snapshot.metadata.isFromCache) {
        final newest = _newestUpdate(snapshot.docs);
        if (newest != null &&
            newest > (HiveService.getLastSyncAt(userId, scope) ?? 0)) {
          await HiveService.setLastSyncAt(userId, scope, newest);
        }
      }
    } catch (e) {
      print('❌ [SYNC:$scope] Failed to apply remote changes: $e');
    }
  }

  Future<void> _apply(List<DocumentSnapshot> docs,
      {required bool initialLoad}) async {
    final userId = _userId!;
    final pending = SyncQueueService().pendingDocIds([entity]);
    final changes = RemoteChanges();

    // The wipe goes first, so documents written after it in the same
    // snapshot survive it
    for (final doc in docs) {
      if (doc.id != wipeDocId) continue;
      final data = doc.data() as Map<String, dynamic>?;
      // This device's own wipe has already been applied locally
      if (data?['deviceId'] == HiveService.getDeviceId()) continue;
      final wipedAt = _updatedAt(data);
      if (wipedAt != null &&
          wipedAt > (HiveService.getWipedAt(userId, scope) ?? -1)) {
        await HiveService.setWipedAt(userId, scope, wipedAt);
        // An initial load reflects the server after the wipe already
        changes.wiped = !initialLoad;
      }
    }

    final wipedAt = HiveService.getWipedAt(userId, scope);
    final deviceId = HiveService.getDeviceId();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || doc.id == wipeDocId || pending.contains(doc.id)) {
        continue;
      }
      // Only reaches the listener when the device filter is unavailable;
      // local storage already has this device's own changes
      if (!initialLoad && data['deviceId'] == deviceId) continue;

      // Older than a wipe: only possible for stale copies in the local cache
      final updatedAt = _updatedAt(data);
      final staleAfterWipe =
          wipedAt != null && (updatedAt == null || updatedAt <= wipedAt);

      if (data['deleted'] == true || staleAfterWipe) {
        changes.deletedIds.add(doc.id);
      } else {
        changes.upserts[doc.id] = data;
      }
    }

    if (changes.wiped ||
        changes.upserts.isNotEmpty ||
        changes.deletedIds.isNotEmpty) {
      await apply(changes);
    }
  }

  /// Every document id in the collection, read as cheaply as possible. After
  /// the first sync, Firestore's local cache holds every id (free to read),
  /// and only changes made on other devices since then come from the server.
  Future<Set<String>> allDocIds() async {
    final userId = _authService.getUserId();
    final lastSyncAt =
        userId == null ? null : HiveService.getLastSyncAt(userId, scope);
    if (lastSyncAt == null) {
      final snapshot =
          await collection().get(const GetOptions(source: Source.server));
      return snapshot.docs.map((d) => d.id).toSet();
    }

    final cached =
        await collection().get(const GetOptions(source: Source.cache));
    final ids = cached.docs.map((d) => d.id).toSet();
    try {
      ids.addAll(await _remoteIdsSince(lastSyncAt));
    } catch (e) {
      // Offline: the cached ids are everything this device knows about
      print('⚠️ [SYNC:$scope] Could not check for remote changes: $e');
    }
    return ids;
  }

  Future<Iterable<String>> _remoteIdsSince(int fromMicros) async {
    try {
      final snapshot = await _changesSince(fromMicros)
          .get(const GetOptions(source: Source.server));
      return snapshot.docs.map((d) => d.id);
    } catch (e) {
      if (!_isMissingIndex(e)) rethrow;
      _deviceFilterUnavailable = true;
      return _remoteIdsSince(fromMicros);
    }
  }

  static int? _updatedAt(Map<String, dynamic>? data) =>
      (data?['updatedAt'] as Timestamp?)?.microsecondsSinceEpoch;

  static int? _newestUpdate(List<DocumentSnapshot> docs) {
    int? newest;
    for (final doc in docs) {
      final updatedAt = _updatedAt(doc.data() as Map<String, dynamic>?);
      if (updatedAt != null && (newest == null || updatedAt > newest)) {
        newest = updatedAt;
      }
    }
    return newest;
  }
}
