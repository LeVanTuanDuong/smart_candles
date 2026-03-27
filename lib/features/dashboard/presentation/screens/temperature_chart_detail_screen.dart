import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_candles/shared/models/device_status.dart';

/// Màn hình biểu đồ nhiệt độ & độ ẩm — mở từ [TemperatureCardHome].
///
/// [historySamples] / [humidityHistorySamples]: nếu có thì vẽ đúng dữ liệu thực từ thiết bị.
class TemperatureChartDetailScreen extends StatelessWidget {
  final DeviceStatus deviceStatus;
  final List<double>? historySamples;
  final List<double>? humidityHistorySamples;

  const TemperatureChartDetailScreen({
    super.key,
    required this.deviceStatus,
    this.historySamples,
    this.humidityHistorySamples,
  });

  static List<FlSpot> _buildSpotsTemperature(List<double>? samples) {
    if (samples == null || samples.isEmpty) return const [];
    return List.generate(
      samples.length,
      (i) => FlSpot(i.toDouble(), samples[i]),
    );
  }

  static List<FlSpot> _buildSpotsHumidity(List<double>? samples) {
    if (samples == null || samples.isEmpty) return const [];
    return List.generate(
      samples.length,
      (i) => FlSpot(i.toDouble(), samples[i].clamp(0.0, 100.0)),
    );
  }

  static Color _humidityColor(double h) {
    if (h < 35) return const Color(0xFFE65100);
    if (h > 75) return const Color(0xFF283593);
    return const Color(0xFF00838F);
  }

  static String _humidityLabel(double h) {
    if (h < 35) return 'Khô';
    if (h > 75) return 'Ẩm cao';
    return 'Dễ chịu';
  }

  @override
  Widget build(BuildContext context) {
    final tempSpots = _buildSpotsTemperature(historySamples);
    final humSpots = _buildSpotsHumidity(humidityHistorySamples);
    final hasTempHistory = tempSpots.isNotEmpty;
    final hasHumidityHistory = humSpots.isNotEmpty;
    final hasCurrentSensorData = deviceStatus.temperature > 0 && deviceStatus.humidity > 0;

    final tempYs = hasTempHistory ? tempSpots.map((s) => s.y).toList() : <double>[deviceStatus.temperature];
    final minTempY = (tempYs.reduce(math.min) - 2).floorToDouble();
    final maxTempY = (tempYs.reduce(math.max) + 2).ceilToDouble();
    final tempLineColor = deviceStatus.status.color;

    final humYs = hasHumidityHistory ? humSpots.map((s) => s.y).toList() : <double>[deviceStatus.humidity];
    final minHumY = math.max(0.0, humYs.reduce(math.min) - 5).floorToDouble();
    final maxHumY = math.min(100.0, humYs.reduce(math.max) + 5).ceilToDouble();
    final humLineColor = _humidityColor(deviceStatus.humidity);

    final timeFmt = DateFormat('HH:mm');
    final dataSourceNote = deviceStatus.isBluetoothConnected
        ? 'Nguồn: dữ liệu thực từ ESP32 qua BLE'
        : 'Bluetooth chưa kết nối';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FC),
      appBar: AppBar(
        title: const Text('Nhiệt độ & độ ẩm'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hiện tại',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nhiệt độ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  hasCurrentSensorData
                                      ? deviceStatus.temperature.toStringAsFixed(1)
                                      : '--',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: tempLineColor,
                                  ),
                                ),
                                Text(
                                  ' °C',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        tempLineColor.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        tempLineColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    deviceStatus.status.label,
                                    style: TextStyle(
                                      color: tempLineColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 56,
                        color: Colors.grey.withValues(alpha: 0.25),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Độ ẩm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    hasCurrentSensorData
                                        ? deviceStatus.humidity
                                            .clamp(0, 100)
                                            .toStringAsFixed(0)
                                        : '--',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: humLineColor,
                                    ),
                                  ),
                                  Text(
                                    ' %',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          humLineColor.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          humLineColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      hasCurrentSensorData
                                          ? _humidityLabel(deviceStatus.humidity)
                                          : 'Chưa có',
                                      style: TextStyle(
                                        color: humLineColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    dataSourceNote,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Lịch sử nhiệt độ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (hasTempHistory)
            SizedBox(
              height: 260,
              child: _TimeSeriesLineChart(
                spots: tempSpots,
                minY: minTempY,
                maxY: maxTempY,
                lineColor: tempLineColor,
                leftAxisSuffix: '°',
                tooltipSuffix: ' °C',
                timeFmt: timeFmt,
                horizontalInterval: (maxTempY - minTempY) > 8 ? 4 : 2,
              ),
            )
          else
            const _NoSensorDataCard(
              message: 'Chưa có dữ liệu nhiệt độ thực tế từ ESP32.',
            ),
          const SizedBox(height: 24),
          Text(
            'Lịch sử độ ẩm',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (hasHumidityHistory)
            SizedBox(
              height: 260,
              child: _TimeSeriesLineChart(
                spots: humSpots,
                minY: minHumY,
                maxY: maxHumY,
                lineColor: humLineColor,
                leftAxisSuffix: '%',
                tooltipSuffix: ' %',
                timeFmt: timeFmt,
                horizontalInterval: (maxHumY - minHumY) > 20 ? 10 : 5,
              ),
            )
          else
            const _NoSensorDataCard(
              message: 'Chưa có dữ liệu độ ẩm thực tế từ ESP32.',
            ),
        ],
      ),
    );
  }
}

class _NoSensorDataCard extends StatelessWidget {
  final String message;

  const _NoSensorDataCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 120,
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TimeSeriesLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;
  final Color lineColor;
  final String leftAxisSuffix;
  final String tooltipSuffix;
  final DateFormat timeFmt;
  final double horizontalInterval;

  const _TimeSeriesLineChart({
    required this.spots,
    required this.minY,
    required this.maxY,
    required this.lineColor,
    required this.leftAxisSuffix,
    required this.tooltipSuffix,
    required this.timeFmt,
    required this.horizontalInterval,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 16,
          right: 16,
          left: 8,
          bottom: 8,
        ),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (spots.length - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: horizontalInterval,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: horizontalInterval,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}$leftAxisSuffix',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: spots.length > 12 ? 4 : 3,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (i < 0 || i >= spots.length) {
                      return const SizedBox.shrink();
                    }
                    final now = DateTime.now();
                    final label = timeFmt.format(
                      now.subtract(Duration(hours: spots.length - 1 - i)),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                left: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((s) {
                    return LineTooltipItem(
                      '${s.y.toStringAsFixed(1)}$tooltipSuffix',
                      TextStyle(
                        color: lineColor,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: lineColor,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withValues(alpha: 0.35),
                      lineColor.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
