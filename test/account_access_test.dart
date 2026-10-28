import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/models/account_model.dart';

AppAccount accountWith(AccountStatus status,
        {Map<AppFeature, bool> features = const {}}) =>
    AppAccount(
        uid: 'u1', email: 'u1@example.com', status: status, features: features);

void main() {
  group('resolveAccess', () {
    AccessState resolve({
      bool signedIn = true,
      bool isAdmin = false,
      bool loaded = true,
      AppConfig config = const AppConfig(),
      AppAccount? account,
    }) =>
        resolveAccess(
          signedIn: signedIn,
          isAdmin: isAdmin,
          loaded: loaded,
          config: config,
          account: account,
        );

    test('signed out wins over everything', () {
      expect(resolve(signedIn: false, isAdmin: true), AccessState.signedOut);
    });

    test('admins get in at once, even before loading and during maintenance',
        () {
      expect(resolve(isAdmin: true, loaded: false), AccessState.approved);
      expect(
        resolve(isAdmin: true, config: const AppConfig(maintenance: true)),
        AccessState.approved,
      );
    });

    test('waits until the account and config are known', () {
      expect(resolve(loaded: false), AccessState.loading);
    });

    test('maintenance comes before the account status', () {
      expect(
        resolve(
          config: const AppConfig(maintenance: true),
          account: accountWith(AccountStatus.approved),
        ),
        AccessState.maintenance,
      );
    });

    test('follows the account status', () {
      expect(resolve(account: accountWith(AccountStatus.approved)),
          AccessState.approved);
      expect(resolve(account: accountWith(AccountStatus.blocked)),
          AccessState.blocked);
      expect(resolve(account: accountWith(AccountStatus.pending)),
          AccessState.pending);
    });

    test('no account yet means pending (registration is under way)', () {
      expect(resolve(), AccessState.pending);
    });
  });

  group('resolveFeature', () {
    test('features are on unless switched off', () {
      expect(resolveFeature(AppFeature.savings, const AppConfig(), null), true);
    });

    test('the app-wide switch applies to everyone', () {
      const config = AppConfig(features: {AppFeature.statement: false});
      expect(resolveFeature(AppFeature.statement, config, null), false);
      expect(
        resolveFeature(
            AppFeature.statement, config, accountWith(AccountStatus.approved)),
        false,
      );
    });

    test('a per-user override wins in both directions', () {
      const off = AppConfig(features: {AppFeature.cloudSync: false});
      final userOn = accountWith(AccountStatus.approved,
          features: {AppFeature.cloudSync: true});
      expect(resolveFeature(AppFeature.cloudSync, off, userOn), true);

      final userOff = accountWith(AccountStatus.approved,
          features: {AppFeature.savings: false});
      expect(
          resolveFeature(AppFeature.savings, const AppConfig(), userOff), false);
    });
  });

  group('parsing', () {
    test('AppConfig defaults when the document is missing or partial', () {
      final empty = AppConfig.fromMap(null);
      expect(empty.maintenance, false);
      expect(empty.requireApproval, true);
      expect(empty.isEnabled(AppFeature.savings), true);

      final config = AppConfig.fromMap({
        'maintenance': true,
        'maintenanceMessage': 'Back at 9',
        'requireApproval': false,
        'features': {'savings': false, 'unknown': true, 'statement': 'yes'},
      });
      expect(config.maintenance, true);
      expect(config.maintenanceMessage, 'Back at 9');
      expect(config.requireApproval, false);
      expect(config.features, {AppFeature.savings: false});
    });

    test('AppAccount reads Firestore data and tolerates bad values', () {
      final account = AppAccount.fromMap('u1', {
        'email': 'u1@example.com',
        'displayName': 'User One',
        'status': 'blocked',
        'blockedReason': 'spam',
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
        'features': {'cloudSync': false},
      });
      expect(account.status, AccountStatus.blocked);
      expect(account.blockedReason, 'spam');
      expect(account.createdAt, DateTime(2026, 10, 1));
      expect(account.features, {AppFeature.cloudSync: false});

      expect(AppAccount.fromMap('u2', {'status': 'nonsense'}).status,
          AccountStatus.pending);
    });

    test('unblocking clears the block reason', () {
      final blocked =
          accountWith(AccountStatus.approved).copyWith(
              status: AccountStatus.blocked, blockedReason: 'spam');
      expect(blocked.blockedReason, 'spam');
      expect(blocked.copyWith(status: AccountStatus.approved).blockedReason,
          isNull);
    });
  });
}
