import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/journal_storage_service.dart';
import '../models/mood_journal_entry.dart';
import '../services/temperature_history_service.dart';
import '../models/temperature_history_entry.dart';
import '../models/device_status.dart';
import 'mood_journal_screen.dart';
import 'safety_history_screen.dart';

class UsageHistoryScreen extends StatefulWidget {
  const UsageHistoryScreen({super.key});

  @override
  State<UsageHistoryScreen> createState() => _UsageHistoryScreenState();
}

class _UsageHistoryScreenState extends State<UsageHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MoodJournalEntry> _journalEntries = [];
  List<TemperatureHistoryEntry> _temperatureEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load journal entries
      final journalMap = await JournalStorageService.loadEntries();
      _journalEntries = journalMap.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first

      // Load temperature entries
      _temperatureEntries = await TemperatureHistoryService.loadEntries();
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lịch sử sử dụng'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Nhật ký tâm trạng'),
            Tab(text: 'Lịch sử nhiệt độ'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJournalTab(),
                _buildTemperatureTab(),
              ],
            ),
    );
  }

  Widget _buildJournalTab() {
    if (_journalEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có nhật ký nào',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy bắt đầu ghi lại tâm trạng của bạn',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MoodJournalScreen(),
                  ),
                ).then((_) => _loadHistory());
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm nhật ký mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _journalEntries.length,
        itemBuilder: (context, index) {
          final entry = _journalEntries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple[100],
                radius: 30,
                child: Text(
                  entry.moodEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              title: Text(
                DateFormat('dd/MM/yyyy').format(entry.date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: entry.journalText != null &&
                      entry.journalText!.isNotEmpty
                  ? Text(
                      entry.journalText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const Text('Không có ghi chú'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MoodJournalScreen(),
                  ),
                ).then((_) => _loadHistory());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemperatureTab() {
    if (_temperatureEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.thermostat_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có dữ liệu nhiệt độ',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Kết nối với nến thông minh để xem lịch sử nhiệt độ',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SafetyHistoryScreen(),
                  ),
                ).then((_) => _loadHistory());
              },
              icon: const Icon(Icons.history),
              label: const Text('Xem chi tiết'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _temperatureEntries.length,
        itemBuilder: (context, index) {
          final entry = _temperatureEntries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(entry.status).withOpacity(0.2),
                child: Icon(
                  _getStatusIcon(entry.status),
                  color: _getStatusColor(entry.status),
                ),
              ),
              title: Text(
                '${entry.temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(entry.status),
                    style: TextStyle(
                      color: _getStatusColor(entry.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(entry.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SafetyHistoryScreen(),
                  ),
                ).then((_) => _loadHistory());
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(TemperatureStatus status) {
    return status.color;
  }

  IconData _getStatusIcon(TemperatureStatus status) {
    switch (status) {
      case TemperatureStatus.safe:
        return Icons.check_circle;
      case TemperatureStatus.warning:
        return Icons.warning;
      case TemperatureStatus.danger:
        return Icons.dangerous;
    }
  }

  String _getStatusText(TemperatureStatus status) {
    return status.label;
  }
}

