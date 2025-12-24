import 'package:flutter/material.dart';
import '../models/device_status.dart';

class TemperatureHistoryEntry {
  final DateTime timestamp;
  final double temperature;
  final TemperatureStatus status;

  TemperatureHistoryEntry({
    required this.timestamp,
    required this.temperature,
    required this.status,
  });

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'status': status.name, // 'safe', 'warning', 'danger'
    };
  }

  // Create from map
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

  // Get status label in Vietnamese
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

  // Get status color
  Color get statusColor {
    return status.color;
  }
}

