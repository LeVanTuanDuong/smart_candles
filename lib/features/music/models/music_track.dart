class MusicTrack {
  final String id;
  final String name;
  final String description;
  final String? imagePath;
  final String? audioPath;
  final String? audioUrl;
  final String category;
  final bool isUploaded;
  final DateTime? addedDate;

  MusicTrack({
    required this.id,
    required this.name,
    required this.description,
    this.imagePath,
    this.audioPath,
    this.audioUrl,
    required this.category,
    this.isUploaded = false,
    this.addedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'audioPath': audioPath,
      'audioUrl': audioUrl,
      'category': category,
      'isUploaded': isUploaded,
      'addedDate': addedDate?.toIso8601String(),
    };
  }

  factory MusicTrack.fromMap(Map<String, dynamic> map) {
    return MusicTrack(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      imagePath: map['imagePath'] as String?,
      audioPath: map['audioPath'] as String?,
      audioUrl: map['audioUrl'] as String?,
      category: map['category'] as String,
      isUploaded: map['isUploaded'] as bool? ?? false,
      addedDate: map['addedDate'] != null
          ? DateTime.parse(map['addedDate'])
          : null,
    );
  }

  MusicTrack copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    String? audioPath,
    String? audioUrl,
    String? category,
    bool? isUploaded,
    DateTime? addedDate,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      audioUrl: audioUrl ?? this.audioUrl,
      category: category ?? this.category,
      isUploaded: isUploaded ?? this.isUploaded,
      addedDate: addedDate ?? this.addedDate,
    );
  }
}
