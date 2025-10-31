class ApiConfig {
  // Override at runtime with: --dart-define=API_BASE_URL=https://your-host/api/v1/
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.taskmanager.com/api/v1/',
  );
}
