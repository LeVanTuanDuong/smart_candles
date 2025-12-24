import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_journal_entry.dart';
import '../services/journal_storage_service.dart';

class MoodJournalScreen extends StatefulWidget {
  const MoodJournalScreen({super.key});

  @override
  State<MoodJournalScreen> createState() => _MoodJournalScreenState();
}

class _MoodJournalScreenState extends State<MoodJournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  DateTime _currentMonth = DateTime.now();
  Map<DateTime, MoodJournalEntry> _journalEntries = {};
  String? _selectedMoodEmoji;

  // Mood emojis mapping
  final Map<String, String> _moodEmojis = {
    'happy': '😊',
    'neutral': '😐',
    'annoyed': '😤',
    'sad': '😢',
    'angry': '😠',
  };

  @override
  void initState() {
    super.initState();
    _loadJournalEntries(); // Load entries asynchronously
  }

  @override
  void dispose() {
    _journalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadJournalEntries() async {
    // Load existing entries from database
    final entries = await JournalStorageService.loadEntries();
    setState(() {
      _journalEntries = entries;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedMoodEmoji = _journalEntries[date]?.moodEmoji;
      _journalController.text = _journalEntries[date]?.journalText ?? '';
    });
  }

  void _selectMood(String moodKey) {
    setState(() {
      _selectedMoodEmoji = _moodEmojis[moodKey];
    });
  }

  Future<void> _saveEntry() async {
    // Close keyboard
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
    
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    
    if (_selectedMoodEmoji != null) {
      final entry = MoodJournalEntry(
        date: dateOnly,
        moodEmoji: _selectedMoodEmoji!,
        journalText: _journalController.text.trim().isEmpty 
            ? null 
            : _journalController.text.trim(),
      );
      
      // Save to database
      await JournalStorageService.saveEntry(entry);
      
      // Update local state
      setState(() {
        _journalEntries[dateOnly] = entry;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu nhật ký thành công!'),
          duration: Duration(seconds: 2),
        ),
      );
      
      _journalController.clear();
      _selectedMoodEmoji = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn tâm trạng của bạn'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    int firstWeekday = firstDay.weekday;
    
    List<DateTime> days = [];
    
    // Add empty days at the start if needed
    for (int i = 1; i < firstWeekday; i++) {
      days.add(DateTime(0)); // Placeholder
    }
    
    // Add all days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final monthYear = DateFormat('MMMM yyyy').format(_currentMonth);
    
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nhật ký Tâm trạng',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendar Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.lightBlue[50],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousMonth,
                      ),
                      const Text(
                        'Lịch ngày',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    monthYear,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Days of week
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DayLabel('T2'),
                      _DayLabel('T3'),
                      _DayLabel('T4'),
                      _DayLabel('T5'),
                      _DayLabel('T6'),
                      _DayLabel('T7'),
                      _DayLabel('CN'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: days.length,
                    itemBuilder: (context, index) {
                      final date = days[index];
                      if (date.year == 0) {
                        return const SizedBox.shrink();
                      }
                      
                      final entry = _journalEntries[date];
                      final isToday = date.year == DateTime.now().year &&
                          date.month == DateTime.now().month &&
                          date.day == DateTime.now().day;
                      
                      return GestureDetector(
                        onTap: () => _selectDate(date),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday ? Colors.blue[100] : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: Colors.blue, width: 2)
                                : null,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Show date number only if no entry
                              if (entry == null)
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                    color: Colors.black87,
                                  ),
                                ),
                              // Show emoji on top, covering the number
                              if (entry != null)
                                Text(
                                  entry.moodEmoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Journal Input Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chọn tâm trạng:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MoodButton('happy', '😊', _selectedMoodEmoji == '😊', _selectMood),
                      _MoodButton('neutral', '😐', _selectedMoodEmoji == '😐', _selectMood),
                      _MoodButton('annoyed', '😤', _selectedMoodEmoji == '😤', _selectMood),
                      _MoodButton('sad', '😢', _selectedMoodEmoji == '😢', _selectMood),
                      _MoodButton('angry', '😠', _selectedMoodEmoji == '😠', _selectMood),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _journalController,
                    focusNode: _focusNode,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Hôm nay tôi...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
            
            // Save Button
            Container(
              margin: const EdgeInsets.all(16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  final String label;
  
  const _DayLabel(this.label);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final String moodKey;
  final String emoji;
  final bool isSelected;
  final Function(String) onTap;
  
  const _MoodButton(this.moodKey, this.emoji, this.isSelected, this.onTap);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(moodKey),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[200] : Colors.grey[200],
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

