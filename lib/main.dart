import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/app_config.dart';
import 'services/fcm_notification_service.dart';
import 'Services/background_sync_service.dart';
import 'interfaces/interface_selection.dart';
import 'features/elderly/services/reminder_notification_service.dart';
import 'features/startup/presentation/alera_startup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const AleraApp());
}

Future<void> _initializeAlera() async {
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
}

class AleraApp extends StatelessWidget {
  const AleraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _AleraStartupGate(),
    );
  }
}

class _AleraStartupGate extends StatefulWidget {
  const _AleraStartupGate();

  @override
  State<_AleraStartupGate> createState() => _AleraStartupGateState();
}

class _AleraStartupGateState extends State<_AleraStartupGate> {
  bool _ready = false;
  Object? _startupError;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      await Future.wait([
        _initializeAlera(),

        // Prevent an ugly split-second flash when startup is very fast.
        Future<void>.delayed(const Duration(milliseconds: 850)),
      ]);

      if (!mounted) return;

      setState(() {
        _ready = true;
      });
    } catch (error, stackTrace) {
      debugPrint('Alera startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _startupError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const InterfaceSelection();
    }

    if (_startupError != null) {
      return const _StartupErrorScreen();
    }

    return const AleraStartupScreen();
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F4FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 42,
                  color: Color(0xFF8B5DE7),
                ),
                SizedBox(height: 20),
                Text(
                  'Alera couldn\'t finish starting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF3D3459),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please close the app and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF71698D), fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
