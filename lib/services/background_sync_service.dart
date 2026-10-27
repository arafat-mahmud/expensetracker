import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'app_check_service.dart';

const String _oneOffSyncTask = 'sync_queue_one_off';
const String _periodicSyncTask = 'sync_queue_periodic';

@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    // Without it, enforced App Check would reject these background writes
    await activateAppCheck();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Every write is handed to Firestore's offline queue, which lives on
    // disk. Starting Firestore here replays that queue, so no write is sent
    // twice, and Hive (not safe across isolates) is never opened here.
    try {
      await FirebaseFirestore.instance
          .waitForPendingWrites()
          .timeout(const Duration(minutes: 2));
      return true;
    } catch (e) {
      return false;
    }
  });
}

class BackgroundSyncService {
  static final BackgroundSyncService _instance =
      BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  Future<void> initialize() async {
    Workmanager().initialize(
      backgroundSyncCallbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      _periodicSyncTask,
      _periodicSyncTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    await scheduleOneOffSync();
  }

  Future<void> scheduleOneOffSync() async {
    await Workmanager().registerOneOffTask(
      _oneOffSyncTask,
      _oneOffSyncTask,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
