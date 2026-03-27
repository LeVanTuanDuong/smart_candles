import 'package:flutter/material.dart';
import 'package:smart_candles/shared/services/bluetooth_service.dart';

class BluetoothDeviceDialog extends StatefulWidget {
  const BluetoothDeviceDialog({super.key});

  @override
  State<BluetoothDeviceDialog> createState() => _BluetoothDeviceDialogState();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const BluetoothDeviceDialog(),
    );
  }
}

class _BluetoothDeviceDialogState extends State<BluetoothDeviceDialog> {
  final BluetoothService _bluetoothService = BluetoothService();
  bool _isScanning = false;
  bool _dialogClosed = false;

  @override
  void initState() {
    super.initState();
    _startScan();
    _bluetoothService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _bluetoothService.removeListener(_onServiceUpdate);
    _bluetoothService.stopScan();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {
        _isScanning = _bluetoothService.isScanning;
      });
      if (_bluetoothService.isConnected && !_dialogClosed) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          _dialogClosed = true;
          navigator.pop(true);
        }
      }
    }
  }

  Future<void> _startScan() async {
    try {
      await _bluetoothService.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tìm thiết bị nến'),
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _bluetoothService.scanResults.isEmpty
            ? Center(
                child: Text(
                  _isScanning
                      ? 'Đang tìm kiếm...'
                      : 'Không tìm thấy thiết bị nào',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _bluetoothService.scanResults
                    .where((r) => r.device.platformName.isNotEmpty)
                    .length,
                itemBuilder: (context, index) {
                  final results = _bluetoothService.scanResults
                      .where((r) => r.device.platformName.isNotEmpty)
                      .toList();
                  final result = results[index];
                  final device = result.device;
                  final name = device.platformName;
                  final isCandle = name.contains(deviceNamePattern);

                  return ListTile(
                    leading: Icon(
                      Icons.bluetooth,
                      color: isCandle ? Colors.blue : Colors.grey,
                    ),
                    title: Text(name),
                    subtitle: Text(device.remoteId.toString()),
                    trailing: isCandle
                        ? const Chip(
                            label: Text(
                              'Nến',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            backgroundColor: Colors.blueAccent,
                          )
                        : null,
                    onTap: () {
                      _bluetoothService.stopScan();
                      _bluetoothService.connectToDevice(device);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đang kết nối tới $name...')),
                      );
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
