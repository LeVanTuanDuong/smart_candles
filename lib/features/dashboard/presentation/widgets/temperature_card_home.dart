import 'package:flutter/material.dart';
import 'package:smart_candles/features/device/services/temperature_history_service.dart';
import 'package:smart_candles/features/dashboard/presentation/screens/temperature_chart_detail_screen.dart';
import 'package:smart_candles/shared/models/device_status.dart';

class TemperatureCardHome extends StatelessWidget {
  final DeviceStatus deviceStatus;
  final VoidCallback? onConnect;

  const TemperatureCardHome({
    super.key,
    required this.deviceStatus,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final hasRealSensorData = deviceStatus.temperature > 0 && deviceStatus.humidity > 0;
    final tempText = hasRealSensorData
        ? '${deviceStatus.status.label} - ${deviceStatus.temperature.toStringAsFixed(1)}°C'
        : 'Chưa có dữ liệu cảm biến';
    final humidityText = hasRealSensorData
        ? 'Độ ẩm ${deviceStatus.humidity.clamp(0, 100).toStringAsFixed(0)}% · Chạm xem biểu đồ'
        : 'Kết nối BLE để nhận nhiệt độ/độ ẩm thực tế';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final entries = await TemperatureHistoryService.loadEntries();
            List<double>? tempSamples;
            List<double>? humiditySamples;

            if (entries.isNotEmpty) {
              // Build exactly 24 hourly points for the last 24 hours.
              final now = DateTime.now();
              final newestFirst = [...entries]
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
              final tempByHour = List<double?>.filled(24, null);
              final humidityByHour = List<double?>.filled(24, null);

              for (final entry in newestFirst) {
                final diffHours = now.difference(entry.timestamp).inHours;
                if (diffHours < 0 || diffHours > 23) continue;
                final idx = 23 - diffHours; // 0: 23h ago, 23: current hour
                tempByHour[idx] ??= entry.temperature;
                humidityByHour[idx] ??= entry.humidity;
              }

              final hasAnyData = tempByHour.any((v) => v != null);
              if (hasAnyData) {
                final fallbackTemp =
                    tempByHour.firstWhere((v) => v != null, orElse: () => 0.0) ??
                        0.0;
                final fallbackHumidity = humidityByHour.firstWhere(
                      (v) => v != null,
                      orElse: () => deviceStatus.humidity > 0
                          ? deviceStatus.humidity
                          : 50.0,
                    ) ??
                    50.0;

                var lastTemp = fallbackTemp;
                var lastHumidity = fallbackHumidity;
                tempSamples = tempByHour.map((v) {
                  if (v != null) lastTemp = v;
                  return lastTemp;
                }).toList(growable: false);
                humiditySamples = humidityByHour.map((v) {
                  if (v != null) lastHumidity = v;
                  return lastHumidity;
                }).toList(growable: false);
              }
            }

            if (!context.mounted) return;

            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => TemperatureChartDetailScreen(
                  deviceStatus: deviceStatus,
                  historySamples: tempSamples,
                  humidityHistorySamples: humiditySamples,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  deviceStatus.status.color.withValues(alpha: 0.3),
                  deviceStatus.status.color.withValues(alpha: 0.1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: deviceStatus.status.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              deviceStatus.status.color.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.thermostat,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tempText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          humidityText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              deviceStatus.isBluetoothConnected
                                  ? 'Đã kết nối Bluetooth'
                                  : 'Bluetooth chưa kết nối',
                              style: TextStyle(
                                fontSize: 14,
                                color: deviceStatus.isBluetoothConnected
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!deviceStatus.isBluetoothConnected &&
                                onConnect != null)
                              TextButton.icon(
                                onPressed: onConnect,
                                icon: const Icon(Icons.bluetooth_searching,
                                    size: 16),
                                label: const Text('Kết nối'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  backgroundColor: Colors.blue[50],
                                  foregroundColor: Colors.blue[700],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
