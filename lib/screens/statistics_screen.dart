import 'package:flutter/material.dart';
import '../services/journal_storage_service.dart';
import '../models/mood_journal_entry.dart';
import '../services/temperature_history_service.dart';
import '../models/temperature_history_entry.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<MoodJournalEntry> _journalEntries = [];
  List<TemperatureHistoryEntry> _temperatureEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final journalMap = await JournalStorageService.loadEntries();
      _journalEntries = journalMap.values.toList();

      _temperatureEntries = await TemperatureHistoryService.loadEntries();
    } catch (e) {
      // Removed print statement: 'Error loading statistics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, int> _getMoodStats() {
    final Map<String, int> stats = {};
    for (final entry in _journalEntries) {
      stats[entry.moodEmoji] = (stats[entry.moodEmoji] ?? 0) + 1;
    }
    return stats;
  }

  double _getAverageTemperature() {
    if (_temperatureEntries.isEmpty) return 0.0;
    final sum = _temperatureEntries
        .map((e) => e.temperature)
        .reduce((a, b) => a + b);
    return sum / _temperatureEntries.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thống kê'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final moodStats = _getMoodStats();
    final averageTemp = _getAverageTemperature();
    final totalJournalEntries = _journalEntries.length;
    final totalTempReadings = _temperatureEntries.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thống kê'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Nhật ký',
                      totalJournalEntries.toString(),
                      Icons.book_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Đọc nhiệt độ',
                      totalTempReadings.toString(),
                      Icons.thermostat_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Nhiệt độ trung bình',
                '${averageTemp.toStringAsFixed(1)}°C',
                Icons.trending_up_outlined,
                Colors.green,
                fullWidth: true,
              ),
              const SizedBox(height: 24),
              // Mood Statistics
              if (moodStats.isNotEmpty) ...[
                const Text(
                  'Thống kê tâm trạng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: moodStats.entries.map((entry) {
                        final percentage = (entry.value / totalJournalEntries * 100)
                            .toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$percentage%',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    LinearProgressIndicator(
                                      value: entry.value / totalJournalEntries,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.purple[600]!,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.value} lần',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Temperature Statistics
              if (_temperatureEntries.isNotEmpty) ...[
                const Text(
                  'Thống kê nhiệt độ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTempStatRow(
                          'Nhiệt độ cao nhất',
                          _temperatureEntries
                              .map((e) => e.temperature)
                              .reduce((a, b) => a > b ? a : b),
                        ),
                        const Divider(),
                        _buildTempStatRow(
                          'Nhiệt độ thấp nhất',
                          _temperatureEntries
                              .map((e) => e.temperature)
                              .reduce((a, b) => a < b ? a : b),
                        ),
                        const Divider(),
                        _buildTempStatRow(
                          'Nhiệt độ trung bình',
                          averageTemp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                if (!fullWidth) const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempStatRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}°C',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange[600],
            ),
          ),
        ],
      ),
    );
  }
}

