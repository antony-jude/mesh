import 'dart:convert';

enum EmergencyCategory {
  medical,
  foodWater,
  evacuation,
  missingPerson,
  general,
}

class EmergencyPayload {
  final EmergencyCategory category;
  final String title;
  final String description;
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  EmergencyPayload({
    required this.category,
    required this.title,
    required this.description,
    this.hasLocation = false,
    this.latitude,
    this.longitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'title': title,
        'description': description,
        'hasLocation': hasLocation,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EmergencyPayload.fromJson(Map<String, dynamic> json) => EmergencyPayload(
        category: EmergencyCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => EmergencyCategory.general,
        ),
        title: json['title'] as String? ?? 'EMERGENCY ALERT',
        description: json['description'] as String? ?? '',
        hasLocation: json['hasLocation'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        timestamp: DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now(),
      );

  String serialize() => jsonEncode(toJson());

  static EmergencyPayload deserialize(String rawJson) {
    final map = jsonDecode(rawJson) as Map<String, dynamic>;
    return EmergencyPayload.fromJson(map);
  }
}
