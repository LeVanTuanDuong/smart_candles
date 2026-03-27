/// Lịch cố định theo giờ + lặp theo thứ (Mon=1 … Sun=7).
class WeeklyTimeSchedule {
  final bool enabled;

  /// Giờ bật đèn (vd 18:00).
  final int onHour;
  final int onMinute;

  /// Giờ tắt đèn (vd 06:00 — thường là sáng hôm sau).
  final int offHour;
  final int offMinute;

  /// Thứ được chọn: 1=Thứ Hai … 7=Chủ nhật.
  final Set<int> weekdays;

  const WeeklyTimeSchedule({
    this.enabled = true,
    this.onHour = 18,
    this.onMinute = 0,
    this.offHour = 6,
    this.offMinute = 0,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'onHour': onHour,
        'onMinute': onMinute,
        'offHour': offHour,
        'offMinute': offMinute,
        'weekdays': weekdays.toList()..sort(),
      };

  factory WeeklyTimeSchedule.fromJson(Map<String, dynamic> json) {
    final list = json['weekdays'] as List<dynamic>? ?? [1, 2, 3, 4, 5, 6, 7];
    return WeeklyTimeSchedule(
      enabled: json['enabled'] as bool? ?? true,
      onHour: json['onHour'] as int? ?? 18,
      onMinute: json['onMinute'] as int? ?? 0,
      offHour: json['offHour'] as int? ?? 6,
      offMinute: json['offMinute'] as int? ?? 0,
      weekdays: list.map((e) => e as int).toSet(),
    );
  }

  WeeklyTimeSchedule copyWith({
    bool? enabled,
    int? onHour,
    int? onMinute,
    int? offHour,
    int? offMinute,
    Set<int>? weekdays,
  }) {
    return WeeklyTimeSchedule(
      enabled: enabled ?? this.enabled,
      onHour: onHour ?? this.onHour,
      onMinute: onMinute ?? this.onMinute,
      offHour: offHour ?? this.offHour,
      offMinute: offMinute ?? this.offMinute,
      weekdays: weekdays ?? this.weekdays,
    );
  }
}
