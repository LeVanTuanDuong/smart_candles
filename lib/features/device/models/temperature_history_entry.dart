import 'package:flutter/material.dart';
import 'package:smart_candles/shared/models/device_status.dart';

class TemperatureHistoryEntry {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final TemperatureStatus status;

  TemperatureHistoryEntry({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'status': status.name,
    };
  }

  factory TemperatureHistoryEntry.fromMap(Map<String, dynamic> map) {
    final rawTemperature = map['temperature'];
    final rawHumidity = map['humidity'];
    return TemperatureHistoryEntry(
      timestamp: DateTime.parse(map['timestamp']),
      temperature: rawTemperature is num ? rawTemperature.toDouble() : 0.0,
      humidity: rawHumidity is num ? rawHumidity.toDouble() : 55.0,
      status: TemperatureStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TemperatureStatus.safe,
      ),
    );
  }

  String get statusLabel {
    switch (status) {
      case TemperatureStatus.safe:
        return 'Xanh';
      case TemperatureStatus.warning:
        return 'Vàng';
      case TemperatureStatus.danger:
        return 'Đỏ';
    }
  }

  Color get statusColor {
    return status.color;
  }
}
