import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/deposit_model.dart';
import 'auth_service.dart';
import 'hive_service.dart';
import 'firestore_service.dart';
import 'deposit_firestore_service.dart';

class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final DepositFirestoreService _depositFirestoreService =
      DepositFirestoreService();

  Timer? _retryTimer;
  bool _isFlushing = false;
  Duration _currentDelay = const Duration(seconds: 10);
  static const Duration _minDelay = Duration(seconds: 10);
  static const Duration _maxDelay = Duration(minutes: 5);

  void start() {
    _scheduleRetry(immediate: true);
  }

  void scheduleImmediateFlush() {
    _scheduleRetry(immediate: true);
  }

  Future<void> enqueueExpenseUpsert(Expense expense) async {
    await _enqueueOp(
      entity: 'expense',
      action: 'upsert',
      docId: expense.id,
      payload: expense.toJson(),
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

  Future<void> enqueueDepositProfileUpsert(DepositProfile profile) async {
    await _enqueueOp(
      entity: 'deposit_profile',
      action: 'upsert',
      docId: profile.id,
      payload: profile.toJson(),
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

  Future<void> enqueueDepositTransactionUpsert(
      DepositTransaction transaction) async {
    await _enqueueOp(
      entity: 'deposit_transaction',
      action: 'upsert',
      docId: transaction.id,
      payload: transaction.toJson(),
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
  }) async {
    final userId = _authService.getUserId();
    if (userId == null) return;

    final existing = HiveService.getAllPendingSyncOps();
    final keysToRemove = <dynamic>[];
    existing.forEach((key, value) {
      if (value is Map) {
        final vUserId = value['userId'];
        final vEntity = value['entity'];
        final vDocId = value['docId'];
        if (vUserId == userId && vEntity == entity && vDocId == docId) {
          keysToRemove.add(key);
        }
      }
    });
    for (final key in keysToRemove) {
      await HiveService.deletePendingSyncOp(key.toString());
    }

    final opId =
        '${DateTime.now().millisecondsSinceEpoch}-${docId}-${action}';
    final op = {
      'opId': opId,
      'userId': userId,
      'entity': entity,
      'action': action,
      'docId': docId,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await HiveService.addPendingSyncOp(opId, op);
    scheduleImmediateFlush();
  }

  Future<bool> flushPendingOps() async {
    if (_isFlushing) return false;
    _isFlushing = true;
    try {
      final userId = _authService.getUserId();
      if (userId == null) {
        _isFlushing = false;
        return false;
      }

      final allOps = HiveService.getAllPendingSyncOps();
      if (allOps.isEmpty) {
        _isFlushing = false;
        return false;
      }

      final opsForUser = <Map<String, dynamic>>[];
      allOps.forEach((key, value) {
        if (value is Map) {
          final vUserId = value['userId'];
          if (vUserId == userId) {
            opsForUser.add(Map<String, dynamic>.from(value));
          }
        }
      });

      if (opsForUser.isEmpty) {
        _isFlushing = false;
        return false;
      }

      const batchSize = 450;
      final firestore = FirebaseFirestore.instance;
      int processed = 0;
      final opsToRemove = <String>[];

      for (var i = 0; i < opsForUser.length; i += batchSize) {
        final batch = firestore.batch();
        final end =
            (i + batchSize < opsForUser.length) ? i + batchSize : opsForUser.length;

        for (var j = i; j < end; j++) {
          final op = opsForUser[j];
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

          if (entity == 'expense') {
            final ref =
                _firestoreService.getUserExpensesCollection().doc(docId);
            if (action == 'delete') {
              batch.delete(ref);
            } else {
              batch.set(ref, payloadData);
            }
          } else if (entity == 'deposit_profile') {
            final ref =
                _depositFirestoreService.getUserDepositProfilesCollection().doc(docId);
            if (action == 'delete') {
              batch.delete(ref);
            } else {
              batch.set(ref, payloadData);
            }
          } else if (entity == 'deposit_transaction') {
            final ref = _depositFirestoreService
                .getUserDepositTransactionsCollection()
                .doc(docId);
            if (action == 'delete') {
              batch.delete(ref);
            } else {
              batch.set(ref, payloadData);
            }
          }

          final opId = op['opId']?.toString();
          if (opId != null) {
            opsToRemove.add(opId);
          }
          processed += 1;
        }

        await batch.commit();
      }

      for (final opId in opsToRemove) {
        await HiveService.deletePendingSyncOp(opId);
      }

      if (processed > 0) {
        _currentDelay = _minDelay;
      }

      _isFlushing = false;
      return processed > 0;
    } catch (e) {
      _isFlushing = false;
      return false;
    }
  }

  void _scheduleRetry({bool immediate = false}) {
    _retryTimer?.cancel();
    final delay = immediate ? Duration.zero : _currentDelay;
    _retryTimer = Timer(delay, () async {
      final success = await flushPendingOps();
      if (!success) {
        _currentDelay = _nextDelay(_currentDelay);
      } else {
        _currentDelay = _minDelay;
      }
      _scheduleRetry(immediate: false);
    });
  }

  Duration _nextDelay(Duration current) {
    final nextSeconds = (current.inSeconds * 2).clamp(
      _minDelay.inSeconds,
      _maxDelay.inSeconds,
    );
    return Duration(seconds: nextSeconds);
  }
}
