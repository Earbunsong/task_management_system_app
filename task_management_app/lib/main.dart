import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:task_management_app/core/routes.dart';
import 'package:task_management_app/core/theme/app_theme.dart';
import 'package:task_management_app/models/task.dart';
import 'package:task_management_app/screens/add_edit_task_screen.dart';
import 'package:task_management_app/screens/dashboard_screen.dart';
import 'package:task_management_app/screens/forgot_password_screen.dart';
import 'package:task_management_app/screens/login_screen.dart';
import 'package:task_management_app/screens/notifications_screen.dart';
import 'package:task_management_app/screens/payment_screen.dart';
import 'package:task_management_app/screens/profile_screen.dart';
import 'package:task_management_app/screens/register_screen.dart';
import 'package:task_management_app/screens/reset_password_screen.dart';
import 'package:task_management_app/screens/splash_screen.dart';
import 'package:task_management_app/screens/task_detail_screen.dart';
import 'package:task_management_app/screens/verify_email_screen.dart';
import 'package:task_management_app/screens/admin_users_screen.dart';
import 'package:task_management_app/services/fcm_service.dart';
import 'package:uni_links/uni_links.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  /// Initialize deep link handling
  Future<void> _initDeepLinks() async {
    // For WEB: Parse URL from browser
    if (kIsWeb) {
      _handleWebUrl();
      return;
    }

    // For MOBILE: Handle deep links (taskmanager://)
    try {
      final initialLink = await getInitialUri();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Failed to get initial deep link: $e');
    }

    // Handle deep links while app is running
    _deepLinkSubscription = uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  /// Handle web URL parameters
  void _handleWebUrl() {
    try {
      final currentUrl = html.window.location.href;
      final uri = Uri.parse(currentUrl);

      debugPrint('Web URL: $currentUrl');

      // Check if URL contains verify-email route
      if (uri.path.contains('verify-email')) {
        final uid = uri.queryParameters['uid'];
        final token = uri.queryParameters['token'];

        if (uid != null && token != null) {
          debugPrint('Found verify-email parameters in URL: uid=$uid, token=$token');

          // Navigate after a short delay to ensure app is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            _navigatorKey.currentState?.pushReplacementNamed(
              AppRoutes.verifyEmail,
              arguments: {
                'uidb64': uid,
                'token': token,
              },
            );
          });
        }
      }
      // Check if URL contains reset-password route
      else if (uri.path.contains('reset-password')) {
        final uid = uri.queryParameters['uid'];
        final token = uri.queryParameters['token'];

        if (uid != null && token != null) {
          debugPrint('Found reset parameters in URL: uid=$uid, token=$token');

          // Navigate after a short delay to ensure app is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            _navigatorKey.currentState?.pushReplacementNamed(
              AppRoutes.resetPassword,
              arguments: {
                'uidb64': uid,
                'token': token,
              },
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to parse web URL: $e');
    }
  }

  /// Handle deep link navigation
  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');

    // Check if it's a password reset link
    // Expected format: taskmanager://taskmanager.com/reset-password?uid=XXX&token=YYY
    if (uri.path == '/reset-password' || uri.pathSegments.contains('reset-password')) {
      final uid = uri.queryParameters['uid'];
      final token = uri.queryParameters['token'];

      if (uid != null && token != null) {
        // Navigate to reset password screen with parameters
        _navigatorKey.currentState?.pushNamed(
          AppRoutes.resetPassword,
          arguments: {
            'uidb64': uid,
            'token': token,
          },
        );
      } else {
        debugPrint('Missing uid or token in deep link');
      }
    }
    // Check if it's an email verification link
    // Expected format: taskmanager://taskmanager.com/verify-email?uid=XXX&token=YYY
    else if (uri.path == '/verify-email' || uri.pathSegments.contains('verify-email')) {
      final uid = uri.queryParameters['uid'];
      final token = uri.queryParameters['token'];

      if (uid != null && token != null) {
        // Navigate to verify email screen with parameters
        _navigatorKey.currentState?.pushNamed(
          AppRoutes.verifyEmail,
          arguments: {
            'uidb64': uid,
            'token': token,
          },
        );
      } else {
        debugPrint('Missing uid or token in verify email deep link');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
          case AppRoutes.forgotPassword:
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen(),
            );
          case AppRoutes.resetPassword:
            // Optional: accept uidb64 and token as arguments
            final args = settings.arguments as Map<String, String>?;
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                uidb64: args?['uidb64'],
                token: args?['token'],
              ),
            );
          case AppRoutes.verifyEmail:
            // Optional: accept uidb64 and token as arguments
            final args = settings.arguments as Map<String, String>?;
            return MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(
                uidb64: args?['uidb64'],
                token: args?['token'],
              ),
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
          case AppRoutes.adminUsers:
            return MaterialPageRoute(
              builder: (_) => const AdminUsersScreen(),
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
