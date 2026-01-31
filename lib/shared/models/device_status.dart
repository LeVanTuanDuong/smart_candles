import 'package:flutter/material.dart';

enum TemperatureStatus {
  safe('An toàn', Colors.green, 'LED xanh'),
  warning('Cảnh báo', Colors.orange, 'LED vàng'),
  danger('Nguy hiểm', Colors.red, 'LED đỏ');

  final String label;
  final Color color;
  final String ledStatus;

  const TemperatureStatus(this.label, this.color, this.ledStatus);
}

class DeviceStatus {
  final double temperature;
  final TemperatureStatus status;
  final bool isLightOn;
  final String lightMode; // 'warm', 'amber', 'blue'
  final double lightBrightness; // 0.0 - 1.0
  final bool isMusicPlaying;
  final String? currentMusic;
  final double musicVolume; // 0.0 - 1.0
  final bool isBluetoothConnected;

  DeviceStatus({
    this.temperature = 25.0,
    TemperatureStatus? status,
    this.isLightOn = false,
    this.lightMode = 'warm',
    this.lightBrightness = 0.5,
    this.isMusicPlaying = false,
    this.currentMusic,
    this.musicVolume = 0.5,
    this.isBluetoothConnected = false,
  }) : status = status ??
            (temperature < 40
                ? TemperatureStatus.safe
                : temperature < 50
                    ? TemperatureStatus.warning
                    : TemperatureStatus.danger);

  DeviceStatus copyWith({
    double? temperature,
    bool? isLightOn,
    String? lightMode,
    double? lightBrightness,
    bool? isMusicPlaying,
    String? currentMusic,
    double? musicVolume,
    bool? isBluetoothConnected,
  }) {
    return DeviceStatus(
      temperature: temperature ?? this.temperature,
      isLightOn: isLightOn ?? this.isLightOn,
      lightMode: lightMode ?? this.lightMode,
      lightBrightness: lightBrightness ?? this.lightBrightness,
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      currentMusic: currentMusic ?? this.currentMusic,
      musicVolume: musicVolume ?? this.musicVolume,
      isBluetoothConnected: isBluetoothConnected ?? this.isBluetoothConnected,
    );
  }
}
