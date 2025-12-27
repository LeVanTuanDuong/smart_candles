import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/temperature_history_entry.dart';
import '../services/temperature_history_service.dart';

class SafetyHistoryScreen extends StatefulWidget {
  const SafetyHistoryScreen({super.key});

  @override
  State<SafetyHistoryScreen> createState() => _SafetyHistoryScreenState();
}

class _SafetyHistoryScreenState extends State<SafetyHistoryScreen> {
  List<TemperatureHistoryEntry> _historyEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    // Clean up old entries before loading
    await TemperatureHistoryService.cleanupOldEntries();
    
    // Load entries (already filtered to last 24 hours)
    final entries = await TemperatureHistoryService.loadEntries();
    
    setState(() {
      _historyEntries = entries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Lịch sử An toàn',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Temperature Header Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nhiệt độ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lightbulb,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // History List
                Expanded(
                  child: _historyEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có lịch sử',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _historyEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _historyEntries[index];
                            return _buildHistoryCard(entry);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHistoryCard(TemperatureHistoryEntry entry) {
    final timeFormat = DateFormat('HH:mm');
    final timeString = timeFormat.format(entry.timestamp);
    final temperatureString = '${entry.temperature.toStringAsFixed(1)}°C';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time and temperature
          Text(
            '$timeString, $temperatureString',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          // Status tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: entry.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: entry.statusColor,
                width: 1.5,
              ),
            ),
            child: Text(
              entry.statusLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: entry.statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

