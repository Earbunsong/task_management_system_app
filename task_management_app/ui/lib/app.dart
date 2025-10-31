import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routes.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/tasks/presentation/screens/dashboard_screen.dart';
import 'features/tasks/presentation/screens/task_detail_screen.dart';
import 'features/payments/presentation/screens/payment_screen.dart';
import 'features/notifications/presentation/screens/notification_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management System',
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (_) => const SplashScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.register: (_) => const RegisterScreen(),
        Routes.dashboard: (_) => const DashboardScreen(),
        Routes.taskDetail: (_) => const TaskDetailScreen(),
        Routes.payment: (_) => const PaymentScreen(),
        Routes.notifications: (_) => const NotificationScreen(),
        Routes.profile: (_) => const ProfileScreen(),
        Routes.admin: (_) => const AdminDashboard(),
      },
    );
  }
}
