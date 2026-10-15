class ApiConfig {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator/desktop
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );
  static String get wsUrl => '${baseUrl.replaceFirst('http', 'ws')}/ws';
}
