import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../models/expense_model.dart';
import '../models/deposit_model.dart';
import 'auth_service.dart';
import 'hive_service.dart';
import 'firestore_service.dart';
import 'deposit_firestore_service.dart';
import 'background_sync_service.dart';
import 'collection_sync.dart';

class SyncQueueService with WidgetsBindingObserver {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final DepositFirestoreService _depositFirestoreService =
      DepositFirestoreService();

  Timer? _flushTimer;
  bool _started = false;
  bool _isFlushing = false;
  bool _flushRequested = false;

  // Short delay so quick successive edits of the same document collapse
  // into a single write
  static const Duration _flushDelay = Duration(seconds: 2);
  Duration _retryDelay = _minRetryDelay;
  static const Duration _minRetryDelay = Duration(seconds: 10);
  static const Duration _maxRetryDelay = Duration(minutes: 5);

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    // Ops left over from a previous run (or queued before a sign-out) are
    // flushed as soon as a user is signed in
    _authService.authStateChanges.listen((user) {
      if (user != null) scheduleImmediateFlush();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hand pending ops to Firestore before the app can be killed
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      flushPendingOps();
    }
  }

  void scheduleImmediateFlush() {
    _scheduleFlush(Duration.zero);
  }

  void _scheduleFlush(Duration delay) {
    _flushTimer?.cancel();
    _flushTimer = Timer(delay, flushPendingOps);
  }

  Future<void> enqueueExpenseUpsert(Expense expense,
      {bool isNew = false}) async {
    await _enqueueOp(
      entity: 'expense',
      action: 'upsert',
      docId: expense.id,
      payload: expense.toJson(),
      isNew: isNew,
    );
  }

  Future<void> enqueueExpenseDelete(String id) async {
    await _enqueueOp(
      entity: 'expense',
      action: 'delete',
      docId: id,
      payload: {'id': id},
    );
  }

  // App settings (monthly budget) travel with the expenses as one control
  // doc, so other devices get them through the same listener
  Future<void> enqueueSettingsUpsert(Map<String, dynamic> settings) async {
    await _enqueueOp(
      entity: 'expense',
      action: 'upsert',
      docId: CollectionSync.settingsDocId,
      payload: settings,
    );
  }

  Future<void> enqueueDepositProfileUpsert(DepositProfile profile,
      {bool isNew = false}) async {
    await _enqueueOp(
      entity: 'deposit_profile',
      action: 'upsert',
      docId: profile.id,
      payload: profile.toJson(),
      isNew: isNew,
    );
  }

  Future<void> enqueueDepositProfileDelete(String id) async {
    await _enqueueOp(
      entity: 'deposit_profile',
      action: 'delete',
      docId: id,
      payload: {'id': id},
    );
  }

  Future<void> enqueueDepositTransactionUpsert(DepositTransaction transaction,
      {bool isNew = false}) async {
    await _enqueueOp(
      entity: 'deposit_transaction',
      action: 'upsert',
      docId: transaction.id,
      payload: transaction.toJson(),
      isNew: isNew,
    );
  }

  Future<void> enqueueDepositTransactionDelete(String id) async {
    await _enqueueOp(
      entity: 'deposit_transaction',
      action: 'delete',
      docId: id,
      payload: {'id': id},
    );
  }

  Future<void> _enqueueOp({
    required String entity,
    required String action,
    required String docId,
    required Map<String, dynamic> payload,
    bool isNew = false,
  }) async {
    final userId = _authService.getUserId();
    if (userId == null) return;

    // Only the latest op per document is kept, so it costs one write
    final existing = HiveService.getAllPendingSyncOps();
    final keysToRemove = <dynamic>[];
    var pendingCreate = false;
    existing.forEach((key, value) {
      if (value is Map) {
        final vUserId = value['userId'];
        final vEntity = value['entity'];
        final vDocId = value['docId'];
        if (vUserId == userId && vEntity == entity && vDocId == docId) {
          keysToRemove.add(key);
          if (value['isNew'] == true) pendingCreate = true;
        }
      }
    });
    for (final key in keysToRemove) {
      await HiveService.deletePendingSyncOp(key.toString());
    }

    // Created and deleted before it ever reached Firestore: nothing to write
    if (action == 'delete' && pendingCreate) return;

    final opId = '${DateTime.now().millisecondsSinceEpoch}-$docId-$action';
    final op = {
      'opId': opId,
      'userId': userId,
      'entity': entity,
      'action': action,
      'docId': docId,
      'payload': payload,
      'isNew': isNew || pendingCreate,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await HiveService.addPendingSyncOp(opId, op);
    _scheduleFlush(_flushDelay);
  }

  // Doc ids of the current user's ops that have not been handed to Firestore yet
  Set<String> pendingDocIds(List<String> entities) {
    final userId = _authService.getUserId();
    final ids = <String>{};
    HiveService.getAllPendingSyncOps().forEach((key, value) {
      if (value is Map &&
          value['userId'] == userId &&
          entities.contains(value['entity'])) {
        ids.add(value['docId'].toString());
      }
    });
    return ids;
  }

  // Drop the current user's queued ops for an entity (e.g. before wiping it)
  Future<void> discardPendingOps(String entity) async {
    final userId = _authService.getUserId();
    final keys = <String>[];
    HiveService.getAllPendingSyncOps().forEach((key, value) {
      if (value is Map &&
          value['userId'] == userId &&
          value['entity'] == entity) {
        keys.add(key.toString());
      }
    });
    for (final key in keys) {
      await HiveService.deletePendingSyncOp(key);
    }
  }

  Future<bool> flushPendingOps() async {
    if (_isFlushing) {
      _flushRequested = true;
      return false;
    }
    _isFlushing = true;
    _flushTimer?.cancel();
    try {
      final userId = _authService.getUserId();
      if (userId == null) return false;

      final opsForUser = <String, Map<String, dynamic>>{};
      HiveService.getAllPendingSyncOps().forEach((key, value) {
        if (value is Map && value['userId'] == userId) {
          opsForUser[key.toString()] = Map<String, dynamic>.from(value);
        }
      });
      if (opsForUser.isEmpty) return false;

      const batchSize = 450;
      final firestore = FirebaseFirestore.instance;
      final keys = opsForUser.keys.toList();
      final deviceId = HiveService.getDeviceId();

      for (var i = 0; i < keys.length; i += batchSize) {
        final end = (i + batchSize < keys.length) ? i + batchSize : keys.length;
        final chunk = keys.sublist(i, end);
        final batch = firestore.batch();

        for (final key in chunk) {
          final op = opsForUser[key]!;
          final entity = op['entity'] as String?;
          final action = op['action'] as String?;
          final docId = op['docId'] as String?;
          final payload = op['payload'] as Map?;
          final payloadData = payload == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(payload);

          if (entity == null || action == null || docId == null) {
            continue;
          }

          DocumentReference? ref;
          if (entity == 'expense') {
            ref = _firestoreService.getUserExpensesCollection().doc(docId);
          } else if (entity == 'deposit_profile') {
            ref = _depositFirestoreService
                .getUserDepositProfilesCollection()
                .doc(docId);
          } else if (entity == 'deposit_transaction') {
            ref = _depositFirestoreService
                .getUserDepositTransactionsCollection()
                .doc(docId);
          }
          if (ref == null) continue;

          // updatedAt + deviceId let other devices fetch only what changed
          // (see CollectionSync). A delete is written as a tombstone: the
          // same single write, but other devices' listeners can see it.
          if (action == 'delete') {
            batch.set(ref, {
              'id': docId,
              'deleted': true,
              'updatedAt': FieldValue.serverTimestamp(),
              'deviceId': deviceId,
            });
          } else {
            batch.set(ref, {
              ...payloadData,
              'updatedAt': FieldValue.serverTimestamp(),
              'deviceId': deviceId,
            });
          }
        }

        // With offline persistence Firestore stores the batch on disk right
        // away and keeps retrying it (across app restarts) until the server
        // accepts it. Keeping the queue entry until the server ack would let
        // the same write be sent a second time from here, so the entry is
        // dropped as soon as the batch is handed over.
        unawaited(batch.commit().then(
          (_) => print('✅ [SYNC_QUEUE] ${chunk.length} ops saved to server'),
          onError: (e) => print('❌ [SYNC_QUEUE] Server rejected batch: $e'),
        ));
        for (final key in chunk) {
          await HiveService.deletePendingSyncOp(key);
        }
      }

      _retryDelay = _minRetryDelay;

      // Lets Workmanager push Firestore's persisted writes if the app is
      // closed before the device is back online
      unawaited(BackgroundSyncService()
          .scheduleOneOffSync()
          .catchError((e) => print('⚠️ [SYNC_QUEUE] Schedule failed: $e')));
      return true;
    } catch (e) {
      print('❌ [SYNC_QUEUE] Flush failed: $e');
      _scheduleFlush(_retryDelay);
      _retryDelay = _nextDelay(_retryDelay);
      return false;
    } finally {
      _isFlushing = false;
      if (_flushRequested) {
        _flushRequested = false;
        scheduleImmediateFlush();
      }
    }
  }

  Duration _nextDelay(Duration current) {
    final nextSeconds = (current.inSeconds * 2).clamp(
      _minRetryDelay.inSeconds,
      _maxRetryDelay.inSeconds,
    );
    return Duration(seconds: nextSeconds);
  }
}
