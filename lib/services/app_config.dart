class AppConfig {
  // Base URL can be overridden at build/run time with:
  //   flutter run --dart-define=API_BASE_URL=http://<host>:8080
  // Default is 10.0.2.2 which resolves to the host machine from the Android emulator.
  // For a physical device, pass your dev machine's LAN IP via --dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String apiUrl = '$baseUrl/api';
}
