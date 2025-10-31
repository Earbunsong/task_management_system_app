class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String taskDetail = '/task-detail';
  static const String editTask = '/edit-task';
  static const String addTask = '/add-task';

  // Other features
  static const String payment = '/payment';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  // Admin
  static const String admin = '/admin';

  // List of routes that don't require authentication
  static const List<String> publicRoutes = [
    splash,
    login,
    register,
    forgotPassword,
  ];

  // List of routes that require authentication
  static const List<String> protectedRoutes = [
    dashboard,
    taskDetail,
    editTask,
    addTask,
    payment,
    notifications,
    profile,
    editProfile,
  ];

  // Admin only routes
  static const List<String> adminRoutes = [
    admin,
  ];
}
