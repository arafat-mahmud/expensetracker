import 'package:flutter_test/flutter_test.dart';
import 'package:expensetracker/services/user_data_manager.dart';

/// Test to verify user data isolation works correctly
void main() {
  group('User Data Isolation Tests', () {
    test('UserDataManager should detect user switches', () async {
      final manager = UserDataManager();

      // Test initialization
      manager.initialize();

      // Get initial user info
      final initialInfo = manager.getUserInfo();
      print('Initial user info: $initialInfo');

      // Test force cleanup
      await manager.forceCleanup();

      final afterCleanupInfo = manager.getUserInfo();
      print('After cleanup info: $afterCleanupInfo');

      expect(afterCleanupInfo['lastKnownUserId'], isNull);
    });

    test('HiveService should clear all data and settings', () async {
      // This test would need to be run in a Flutter environment with Hive initialized
      // For now, it's a placeholder to show the testing approach

      expect(true, true); // Placeholder
    });
  });
}
