import 'package:flutter/material.dart';
import '../models/device_status.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            deviceStatus.status.color.withOpacity(0.3),
            deviceStatus.status.color.withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                  color: deviceStatus.status.color.withOpacity(0.5),
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
                  '${deviceStatus.status.label} - ${deviceStatus.temperature.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      deviceStatus.isBluetoothConnected
                          ? 'Đã kết nối Bluetooth'
                          : 'Chưa kết nối',
                      style: TextStyle(
                        fontSize: 14,
                        color: deviceStatus.isBluetoothConnected
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!deviceStatus.isBluetoothConnected && onConnect != null)
                      TextButton.icon(
                        onPressed: onConnect,
                        icon: const Icon(Icons.bluetooth_searching, size: 16),
                        label: const Text('Kết nối'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
    );
  }
}
