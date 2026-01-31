class SmartwatchData {
  final int? heartRate; // bpm
  final double? bodyTemperature; // celsius
  final int? bloodPressureSystolic; // mmHg
  final int? bloodPressureDiastolic; // mmHg
  final bool isConnected;

  SmartwatchData({
    this.heartRate,
    this.bodyTemperature,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.isConnected = false,
  });
}
