import 'package:flutter/material.dart';
import 'package:smart_candles/shared/models/device_status.dart';

class TemperatureHistoryEntry {
  final DateTime timestamp;
  final double temperature;
  final TemperatureStatus status;

  TemperatureHistoryEntry({
    required this.timestamp,
    required this.temperature,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'status': status.name,
    };
  }

  factory TemperatureHistoryEntry.fromMap(Map<String, dynamic> map) {
    return TemperatureHistoryEntry(
      timestamp: DateTime.parse(map['timestamp']),
      temperature: map['temperature'] as double,
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
