import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ESP32ControlPage extends StatefulWidget {
  // Use Strings instead of BluetoothDevice to allow direct address connection
  final String deviceAddress;
  final String deviceName;

  const ESP32ControlPage({
    super.key,
    required this.deviceAddress,
    this.deviceName = "Thiết bị ESP32",
  });

  @override
  _ESP32ControlPageState createState() => _ESP32ControlPageState();
}

class _ESP32ControlPageState extends State<ESP32ControlPage> {
  BluetoothConnection? connection;
  bool isConnected = false;
  bool isConnecting = true; // Track connecting state

  // Dữ liệu từ ESP32
  double temperature = 0;
  double humidity = 0;
  bool isOverheat = false;

  // Trạng thái điều khiển
  double brightness = 0;
  bool lightStatus = false;
  bool musicStatus = false;

  @override
  void initState() {
    super.initState();
    _connectToESP32();
  }

  @override
  void dispose() {
    // Ensure we disconnect when leaving the page
    if (isConnected) {
      connection?.dispose();
    }
    super.dispose();
  }

  // Hàm kết nối tới ESP32_SmartHome
  void _connectToESP32() async {
    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        if (mounted) {
          setState(() {
            isConnecting = true;
            isConnected = false;
          });
        }

        print("Đang thử kết nối lần ${retryCount + 1}...");
        connection = await BluetoothConnection.toAddress(widget.deviceAddress);
        print('Đã kết nối với ESP32: ${widget.deviceAddress}');

        if (mounted) {
          setState(() {
            isConnected = true;
            isConnecting = false;
          });
        }

        // Lắng nghe dữ liệu gửi về từ ESP32
        connection!.input!.listen((Uint8List data) {
          String message = ascii.decode(data);
          _handleIncomingData(message);
        }).onDone(() {
          if (mounted) {
            setState(() {
              isConnected = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Mất kết nối với thiết bị")));
          }
        });

        // Connection successful, break the loop
        return;
      } catch (e) {
        print('Lỗi kết nối lần ${retryCount + 1}: $e');
        retryCount++;

        // Wait a bit before retrying
        await Future.delayed(const Duration(seconds: 1));

        if (retryCount >= maxRetries) {
          if (mounted) {
            setState(() {
              isConnecting = false;
              isConnected = false;
            });

            // Show detailed error dialog after all retries failed
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Kết nối thất bại"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                          "Đã thử kết nối 3 lần nhưng không thành công."),
                      const SizedBox(height: 16),
                      const Text("BẮT BUỘC KIỂM TRA LẠI:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 8),
                      const Text(
                          "1. Vào Cài đặt Bluetooth điện thoại -> QUÊN (Unpair) thiết bị cũ -> Ghép đôi (Pair) lại từ đầu."),
                      const SizedBox(height: 8),
                      const Text("2. Tắt/Bật lại Bluetooth trên điện thoại."),
                      const SizedBox(height: 8),
                      const Text("3. Reset cứng ESP32 (nhấn nút EN/RST)."),
                      const SizedBox(height: 8),
                      const Text(
                          "4. Code ESP32 SAI: Phải dùng thư viện 'BluetoothSerial', không dùng BLE."),
                      const SizedBox(height: 12),
                      Text("Lỗi cuối cùng: $e",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("Đã rõ"),
                  )
                ],
              ),
            );
          }
        }
      }
    }
  }

  // Buffer to store incoming data fragments
  String _buffer = "";

  // Xử lý dữ liệu nhận được
  void _handleIncomingData(String dataString) {
    _buffer += dataString; // Append new data to buffer

    // Check if buffer contains newline (end of message marker)
    if (_buffer.contains('\n')) {
      List<String> messages = _buffer.split('\n');

      // The last part might be incomplete, so keep it in the buffer
      // If the last character was \n, the last part is empty, which is fine
      // but usually split gives an empty string at the end if string ends with delimiter.
      // Let's handle it carefully.

      if (_buffer.endsWith('\n')) {
        _buffer = ""; // All complete
      } else {
        _buffer = messages.removeLast(); // Keep incomplete part
      }

      for (String message in messages) {
        if (message.trim().isEmpty) continue;

        try {
          // Parse JSON
          // Example expected format: {"temp": 25.0, "humi": 60.0, "alert": 0}
          final Map<String, dynamic> jsonData = jsonDecode(message.trim());

          if (mounted) {
            setState(() {
              temperature = jsonData['temp']?.toDouble() ?? temperature;
              humidity = jsonData['humi']?.toDouble() ?? humidity;
              // Map 'alert' or 'warn' to our isOverheat logic if needed
              // User snippet used 'alert' and 'warn'. Adapting to existing var.
              isOverheat = (jsonData['alert'] == 1) ||
                  (jsonData['warn'] != null && jsonData['warn'] > 0);

              if (isOverheat) _showOverheatDialog();
            });
          }
          print("Cập nhật cảm biến: $temperature°C");
        } catch (e) {
          // Fallback for non-JSON text
          if (message.contains("EMERGENCY")) {
            _showOverheatDialog();
          }
          print("Dữ liệu không phải JSON hoặc lỗi: $message");
        }
      }
    }
  }

  // Gửi lệnh xuống ESP32
  void _sendCommand(String command) async {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(ascii.encode(command + "\n"));
      await connection!.output.allSent;
      print("Sent: $command");
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Chưa kết nối")));
    }
  }

  void _showOverheatDialog() {
    if (!mounted) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
              title: const Text("CẢNH BÁO KHẨN CẤP"),
              content: const Text(
                  "Phát hiện quá nhiệt! Vui lòng kiểm tra thiết bị ngay lập tức."),
              backgroundColor: Colors.red.shade100,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Đã rõ"),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Điều khiển ${widget.deviceName}")),
      body: isConnecting
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text("Đang kết nối tới ${widget.deviceAddress}..."),
              ],
            ))
          : !isConnected
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bluetooth_disabled,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("Không có kết nối"),
                    ElevatedButton(
                        onPressed: _connectToESP32,
                        child: const Text("Thử lại"))
                  ],
                ))
              : Column(
                  children: [
                    // Hiển thị thông số cảm biến
                    Card(
                      color: isOverheat
                          ? Colors.red.shade100
                          : Colors.blue.shade50,
                      margin: const EdgeInsets.all(16),
                      child: ListTile(
                        leading: const Icon(Icons.thermostat),
                        title: Text(
                            "Nhiệt độ: ${temperature.toStringAsFixed(1)}°C"),
                        subtitle:
                            Text("Độ ẩm: ${humidity.toStringAsFixed(1)}%"),
                        trailing: isOverheat
                            ? const Icon(Icons.warning, color: Colors.red)
                            : const Icon(Icons.check_circle,
                                color: Colors.green),
                      ),
                    ),

                    if (isOverheat)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("CẢNH BÁO: QUÁ NHIỆT!",
                            style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold)),
                      ),

                    const Divider(),

                    // Điều khiển đèn (Bật/Tắt)
                    SwitchListTile(
                      title: const Text("Đèn chính"),
                      value: lightStatus,
                      onChanged: (val) {
                        setState(() => lightStatus = val);
                        _sendCommand(val ? "LIGHT_ON" : "LIGHT_OFF");
                      },
                    ),

                    // Thanh trượt chỉnh độ sáng
                    ListTile(
                      title: const Text("Độ sáng"),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.brightness_low),
                          Expanded(
                            child: Slider(
                              value: brightness,
                              min: 0,
                              max: 255,
                              divisions: 255,
                              label: brightness.round().toString(),
                              onChanged: (val) {
                                setState(() => brightness = val);
                              },
                              onChangeEnd: (val) {
                                _sendCommand("BRIGHT:${val.toInt()}");
                              },
                            ),
                          ),
                          const Icon(Icons.brightness_high),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Điều khiển nhạc
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon:
                              Icon(musicStatus ? Icons.stop : Icons.play_arrow),
                          label: Text(musicStatus ? "Dừng nhạc" : "Phát nhạc"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: musicStatus
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                          ),
                          onPressed: () {
                            setState(() => musicStatus = !musicStatus);
                            _sendCommand(
                                musicStatus ? "MUSIC_PLAY" : "MUSIC_STOP");
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
