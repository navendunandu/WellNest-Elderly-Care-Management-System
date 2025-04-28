import 'package:caretaker_wellnest/components/notification_service.dart';
import 'package:caretaker_wellnest/screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://xigidxtugemqjqxxupbq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhpZ2lkeHR1Z2VtcWpxeHh1cGJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkxODc0NTksImV4cCI6MjA1NDc2MzQ1OX0._nRKz4mIaREHLmv5mihabn9kwI180MBZIxwHbqkklQ8',
  );
  await RoutineNotificationService.init();
  runApp(MainApp());
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

// Get a reference your Supabase client
final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LoginPage());
  }
}
