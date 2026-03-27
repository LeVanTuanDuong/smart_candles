/// Cấu hình bật/tắt đèn theo mặt trời mọc / lặn.
class SolarAutomationConfig {
  final bool enabled;
  final double latitude;
  final double longitude;

  /// Bật đèn quanh lúc hoàng hôn (có thể lệch bằng [sunsetOffsetMinutes]).
  final bool turnOnNearSunset;

  /// Tắt đèn quanh lúc bình minh (có thể lệch bằng [sunriseOffsetMinutes]).
  final bool turnOffNearSunrise;

  /// Phút lệch so với hoàng hôn (âm = sớm hơn, dương = muộn hơn).
  final int sunsetOffsetMinutes;

  /// Phút lệch so với bình minh.
  final int sunriseOffsetMinutes;

  const SolarAutomationConfig({
    this.enabled = false,
    this.latitude = 21.0285,
    this.longitude = 105.8542,
    this.turnOnNearSunset = true,
    this.turnOffNearSunrise = true,
    this.sunsetOffsetMinutes = 0,
    this.sunriseOffsetMinutes = 0,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'latitude': latitude,
        'longitude': longitude,
        'turnOnNearSunset': turnOnNearSunset,
        'turnOffNearSunrise': turnOffNearSunrise,
        'sunsetOffsetMinutes': sunsetOffsetMinutes,
        'sunriseOffsetMinutes': sunriseOffsetMinutes,
      };

  factory SolarAutomationConfig.fromJson(Map<String, dynamic> json) {
    return SolarAutomationConfig(
      enabled: json['enabled'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 21.0285,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 105.8542,
      turnOnNearSunset: json['turnOnNearSunset'] as bool? ?? true,
      turnOffNearSunrise: json['turnOffNearSunrise'] as bool? ?? true,
      sunsetOffsetMinutes: json['sunsetOffsetMinutes'] as int? ?? 0,
      sunriseOffsetMinutes: json['sunriseOffsetMinutes'] as int? ?? 0,
    );
  }

  SolarAutomationConfig copyWith({
    bool? enabled,
    double? latitude,
    double? longitude,
    bool? turnOnNearSunset,
    bool? turnOffNearSunrise,
    int? sunsetOffsetMinutes,
    int? sunriseOffsetMinutes,
  }) {
    return SolarAutomationConfig(
      enabled: enabled ?? this.enabled,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      turnOnNearSunset: turnOnNearSunset ?? this.turnOnNearSunset,
      turnOffNearSunrise: turnOffNearSunrise ?? this.turnOffNearSunrise,
      sunsetOffsetMinutes: sunsetOffsetMinutes ?? this.sunsetOffsetMinutes,
      sunriseOffsetMinutes: sunriseOffsetMinutes ?? this.sunriseOffsetMinutes,
    );
  }
}
