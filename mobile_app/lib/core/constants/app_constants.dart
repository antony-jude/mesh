class AppConstants {
  static const String appName = 'MeshLink';
  static const String appTagline = 'Communication without infrastructure';
  static const String appVersion = '1.0.0';

  // Routing defaults
  static const int defaultTtl = 10;
  static const int emergencyTtl = 20;
  static const int dedupeCacheMaxEntries = 500;
  static const Duration dedupeCacheTtl = Duration(minutes: 30);
  static const Duration messageSyncInterval = Duration(seconds: 4);
  static const Duration peerKeepAliveInterval = Duration(seconds: 5);

  // Storage Keys
  static const String keyNodeId = 'meshlink_node_id';
  static const String keyDisplayName = 'meshlink_display_name';
  static const String keyEmergencyMode = 'meshlink_emergency_mode';
  static const String keyDemoMode = 'meshlink_demo_mode';
}
