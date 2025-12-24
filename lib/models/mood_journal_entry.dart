class MoodJournalEntry {
  final DateTime date;
  final String moodEmoji;
  final String? journalText;

  MoodJournalEntry({
    required this.date,
    required this.moodEmoji,
    this.journalText,
  });

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'moodEmoji': moodEmoji,
      'journalText': journalText,
    };
  }

  // Create from map
  factory MoodJournalEntry.fromMap(Map<String, dynamic> map) {
    return MoodJournalEntry(
      date: DateTime.parse(map['date']),
      moodEmoji: map['moodEmoji'] as String,
      journalText: map['journalText'] as String?,
    );
  }
}

