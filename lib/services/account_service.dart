import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account_model.dart';

/// Firestore access for account status (/accounts/{uid}) and the app
/// configuration (/config/app). Who may do what is enforced by
/// firestore.rules; the admin methods only work for admins.
class AccountService {
  AccountService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _accounts =>
      _firestore.collection('accounts');

  DocumentReference<Map<String, dynamic>> get _config =>
      _firestore.collection('config').doc('app');

  // Metadata changes included: a document missing from the local cache only
  // proves anything once the server has confirmed it
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAccount(String uid) =>
      _accounts.doc(uid).snapshots(includeMetadataChanges: true);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConfig() =>
      _config.snapshots(includeMetadataChanges: true);

  /// Registers a newly signed-in user. The rules accept 'approved' only
  /// from admins, or while the admin has switched approval off.
  Future<void> register(User user, {required bool approved}) {
    return _accounts.doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoUrl': user.photoURL,
      'status': approved ? 'approved' : 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ---- Admin ----

  Future<void> setStatus(String uid, AccountStatus status, {String? reason}) {
    return _accounts.doc(uid).update({
      'status': status.name,
      'statusChangedAt': FieldValue.serverTimestamp(),
      'blockedReason': status == AccountStatus.blocked
          ? (reason ?? '')
          : FieldValue.delete(),
    });
  }

  Future<void> approveAll(Iterable<String> uids) async {
    final ids = uids.toList();
    for (var i = 0; i < ids.length; i += 450) {
      final batch = _firestore.batch();
      for (final uid in ids.skip(i).take(450)) {
        batch.update(_accounts.doc(uid), {
          'status': AccountStatus.approved.name,
          'statusChangedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  /// [enabled] null removes the override, so the app-wide setting applies
  Future<void> setUserFeature(String uid, AppFeature feature, bool? enabled) {
    return _accounts.doc(uid).update({
      'features.${feature.name}': enabled ?? FieldValue.delete(),
    });
  }

  Future<void> updateConfig(Map<String, Object?> values) =>
      _config.set(values, SetOptions(merge: true));

  /// Set once the (status, createdAt) index turns out to be missing, so the
  /// rest of the session pages with the fallback query
  static bool _orderedListUnavailable = false;

  /// One page of accounts with [status], newest first. Uses the composite
  /// index on (status, createdAt) from firestore.indexes.json; until that
  /// index exists, pages come in document ID order, each sorted newest first.
  Future<({List<AppAccount> accounts, DocumentSnapshot? cursor})> listAccounts(
    AccountStatus status, {
    DocumentSnapshot? after,
    int limit = 25,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _listQuery(status, after, limit).get();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition' || _orderedListUnavailable) rethrow;
      print('⚠️ [ADMIN] Missing Firestore index on accounts '
          '(status, createdAt), listing without it: $e');
      _orderedListUnavailable = true;
      snapshot = await _listQuery(status, after, limit).get();
    }

    final accounts = [
      for (final doc in snapshot.docs) AppAccount.fromMap(doc.id, doc.data()),
    ];
    if (_orderedListUnavailable) {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      accounts.sort((a, b) =>
          (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
    }
    return (
      accounts: accounts,
      cursor: snapshot.docs.length < limit ? null : snapshot.docs.last,
    );
  }

  Query<Map<String, dynamic>> _listQuery(
    AccountStatus status,
    DocumentSnapshot? after,
    int limit,
  ) {
    Query<Map<String, dynamic>> query =
        _accounts.where('status', isEqualTo: status.name);
    if (!_orderedListUnavailable) {
      query = query.orderBy('createdAt', descending: true);
    }
    query = query.limit(limit);
    if (after != null) query = query.startAfterDocument(after);
    return query;
  }

  /// Counted on the server: about one read per 1,000 matching accounts
  Future<int> count(AccountStatus status) async {
    final snapshot =
        await _accounts.where('status', isEqualTo: status.name).count().get();
    return snapshot.count ?? 0;
  }

  Future<AppAccount?> findByEmail(String email) async {
    final snapshot = await _accounts
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return AppAccount.fromMap(doc.id, doc.data());
  }
}
