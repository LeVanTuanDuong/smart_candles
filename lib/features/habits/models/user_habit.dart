/// Một “thói quen” — giờ cố định trong ngày để gợi ý bật/tắt đèn.
class UserHabit {
  final String id;
  final String title;

  /// Tên icon Material (vd: wb_sunny, bedtime, self_improvement).
  final String iconName;
  final int hour;
  final int minute;
  final bool turnLightOn;
  final double brightness;

  const UserHabit({
    required this.id,
    required this.title,
    this.iconName = 'wb_sunny',
    required this.hour,
    required this.minute,
    required this.turnLightOn,
    this.brightness = 0.6,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iconName': iconName,
        'hour': hour,
        'minute': minute,
        'turnLightOn': turnLightOn,
        'brightness': brightness,
      };

  factory UserHabit.fromJson(Map<String, dynamic> json) {
    return UserHabit(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'wb_sunny',
      hour: json['hour'] as int? ?? 7,
      minute: json['minute'] as int? ?? 0,
      turnLightOn: json['turnLightOn'] as bool? ?? true,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.6,
    );
  }
}
