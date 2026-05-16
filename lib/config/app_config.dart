class AppConfig {
  AppConfig._();

  /// OneSignal App ID.
  
  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '729c13e9-37c8-4881-b376-2e8441e04a35',
  );
}