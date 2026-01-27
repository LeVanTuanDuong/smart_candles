import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../services/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  _DiscoveryPageState createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;
  List<BluetoothDiscoveryResult> results =
      List<BluetoothDiscoveryResult>.empty(growable: true);
  bool isDiscovering = false;

  // Default address provided by user
  static const String defaultEsp32Address = "00:70:07:E7:13:4E";

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndStart();
  }

  Future<void> _checkPermissionsAndStart() async {
    // Request permissions for Android 12+
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      _startDiscovery();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Cần cấp quyền Bluetooth để quét thiết bị")),
        );
      }
    }
  }

  void _restartDiscovery() {
    setState(() {
      results.clear();
      isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    try {
      _streamSubscription =
          FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        if (!mounted) return;
        // Filter out devices with empty names (ghost devices)
        if (r.device.name == null || r.device.name!.isEmpty) return;

        setState(() {
          final existingIndex = results.indexWhere(
              (element) => element.device.address == r.device.address);
          if (existingIndex >= 0) {
            results[existingIndex] = r;
          } else {
            results.add(r);
          }
        });
      }, onError: (e) {
        debugPrint('Discovery error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi quét thiết bị: $e')),
          );
          setState(() => isDiscovering = false);
        }
      });

      _streamSubscription!.onDone(() {
        if (mounted) {
          setState(() {
            isDiscovering = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Failed to start discovery: $e');
      if (mounted) {
        setState(() => isDiscovering = false);
        // Don't show error immediately on init to avoid spamming if just opening page
      }
    }
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _connectToDevice(
      BuildContext context, String address, String name) async {
    // Stop scanning first
    _streamSubscription?.cancel();
    _streamSubscription = null;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // Attempt connection via global service
    final bluetoothService = BluetoothService();
    bool success = await bluetoothService.connect(address);

    // Hide loading
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Pop loading dialog
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã kết nối với $name")),
        );
        // Return to Home Screen (Pop DiscoveryPage)
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Kết nối thất bại"),
            content: const Text(
                "Vui lòng đảm bảo thiết bị đã được Ghép đôi (Pair) trong Cài đặt Bluetooth và thử lại."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Đóng"))
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét thiết bị ESP32'),
        actions: [
          isDiscovering
              ? FittedBox(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.replay),
                  onPressed: _restartDiscovery,
                )
        ],
      ),
      body: Column(
        children: [
          // Fast Connect Section
          // Container(
          //   color: Colors.blue.shade50,
          //   padding: const EdgeInsets.all(16.0),
          //   child: Row(
          //     children: [
          //       const Icon(Icons.bolt, color: Colors.amber, size: 32),
          //       const SizedBox(width: 16),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             const Text(
          //               "Kết nối nhanh",
          //               style: TextStyle(
          //                   fontSize: 16, fontWeight: FontWeight.bold),
          //             ),
          //             Text("ESP32 mặc định ($defaultEsp32Address)"),
          //           ],
          //         ),
          //       ),
          //       ElevatedButton(
          //         onPressed: () => _connectToDevice(
          //           context,
          //           defaultEsp32Address,
          //           "ESP32 Mặc định",
          //         ),
          //         child: const Text("Kết nối"),
          //       ),
          //     ],
          //   ),
          // ),
          const Divider(height: 1),
          // Discovery List
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (BuildContext context, index) {
                BluetoothDiscoveryResult result = results[index];
                final device = result.device;
                final address = device.address;
                return ListTile(
                  title: Text(device.name ?? "Thiết bị không tên"),
                  subtitle: Text(address),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (result.rssi != 0)
                        Container(
                          margin: const EdgeInsets.all(8.0),
                          child: Text("${result.rssi}dBm",
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      ElevatedButton(
                        child: const Text('Kết nối'),
                        onPressed: () => _connectToDevice(
                          context,
                          address,
                          device.name ?? "Thiết bị",
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
