import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'hive_service.dart';
import 'sync_queue_service.dart';

const String _oneOffSyncTask = 'sync_queue_one_off';
const String _periodicSyncTask = 'sync_queue_periodic';

@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await HiveService.init();

    final flushed = await SyncQueueService().flushPendingOps();
    return Future.value(flushed);
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
