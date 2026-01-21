import 'dart:convert';
import 'package:http/http.dart' as http;

class EspApiService {
  String _baseUrl = ''; // e.g., http://192.168.1.45

  void setBaseUrl(String ip) {
    if (!ip.startsWith('http')) {
      _baseUrl = 'http://$ip';
    } else {
      _baseUrl = ip;
    }
  }

  bool get hasIp => _baseUrl.isNotEmpty;

  /// Generic POST request
  Future<bool> _post(String path, Map<String, dynamic> body) async {
    if (!hasIp) return false;
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Generic GET request
  Future<dynamic> _get(String path) async {
    if (!hasIp) return null;
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- Control Methods (Mirroring BluetoothService) ---

  Future<bool> setLightOn(bool on) async {
    return await _post('/light', {'state': on ? 1 : 0});
  }

  Future<bool> setLightColor(int r, int g, int b) async {
    return await _post('/light/color', {'r': r, 'g': g, 'b': b});
  }

  Future<bool> setLightBrightness(double brightness) async {
    int val = (brightness * 255).round();
    return await _post('/light/brightness', {'value': val});
  }

  Future<bool> setMusicControl(String command) async {
    int cmdVal = 0;
    if (command == 'play') cmdVal = 1;
    if (command == 'pause') cmdVal = 2;
    if (command == 'stop') cmdVal = 0; // or 3 strictly? using 0 for stop as per BLE
    return await _post('/music', {'command': cmdVal});
  }

  /// Get current status (Temperature, etc)
  Future<Map<String, dynamic>?> getStatus() async {
    final data = await _get('/status');
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }
}
