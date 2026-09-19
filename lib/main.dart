import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';

import 'package:firebase_core/firebase_core.dart';

import 'services/fcm_notification_service.dart';
import 'Services/background_sync_service.dart';

import 'interfaces/interface_selection.dart';

import 'features/elderly/services/reminder_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FcmNotificationService.instance.initialize();

  await Workmanager().initialize(callbackDispatcher);

  await ReminderNotificationService.instance.initialize();

  await Workmanager().registerPeriodicTask(
    'alera-periodic-health-upload',
    aleraBackgroundSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  runApp(const AleraApp());
}

class AleraApp extends StatelessWidget {
  const AleraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InterfaceSelection(),
    );
  }
}
