import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:task_management_app/core/routes.dart';
import 'package:task_management_app/core/theme/app_theme.dart';
import 'package:task_management_app/models/task.dart';
import 'package:task_management_app/screens/add_edit_task_screen.dart';
import 'package:task_management_app/screens/dashboard_screen.dart';
import 'package:task_management_app/screens/login_screen.dart';
import 'package:task_management_app/screens/notifications_screen.dart';
import 'package:task_management_app/screens/payment_screen.dart';
import 'package:task_management_app/screens/profile_screen.dart';
import 'package:task_management_app/screens/register_screen.dart';
import 'package:task_management_app/screens/splash_screen.dart';
import 'package:task_management_app/screens/task_detail_screen.dart';
import 'package:task_management_app/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (requires google-services.json in android/app)
  try {
    await Firebase.initializeApp();
    await FcmService().init();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue without Firebase if it fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        // Handle routes with arguments
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          case AppRoutes.login:
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case AppRoutes.register:
            return MaterialPageRoute(
              builder: (_) => const RegisterScreen(),
            );
          case AppRoutes.dashboard:
            return MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            );
          case AppRoutes.taskDetail:
            final task = settings.arguments as Task;
            return MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: task),
            );
          case AppRoutes.addTask:
            return MaterialPageRoute(
              builder: (_) => const AddEditTaskScreen(),
            );
          case AppRoutes.editTask:
            final task = settings.arguments as Task;
            return MaterialPageRoute(
              builder: (_) => AddEditTaskScreen(task: task),
            );
          case AppRoutes.payment:
            return MaterialPageRoute(
              builder: (_) => const PaymentScreen(),
            );
          case AppRoutes.notifications:
            return MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            );
          case AppRoutes.profile:
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('Route not found: ${settings.name}'),
                ),
              ),
            );
        }
      },
    );
  }
}
