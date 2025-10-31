import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:task_management_app/screens/login_screen.dart';
import 'package:task_management_app/screens/notifications_screen.dart';
import 'package:task_management_app/screens/payment_screen.dart';
import 'package:task_management_app/screens/register_screen.dart';
import 'package:task_management_app/screens/task_list_screen.dart';
import 'package:task_management_app/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (requires google-services.json in android/app)
  await Firebase.initializeApp();
  await FcmService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/tasks': (_) => const TaskListScreen(),
        '/payments': (_) => const PaymentScreen(),
        '/notifications': (_) => const NotificationsScreen(),
      },
    );
  }
}
