class EssentialOil {
  final String id;
  final String name;
  final String description;
  final String imageType; // 'lavender', 'orange', 'chamomile', 'peppermint', etc.
  final String? imagePath; // Path to custom image file
  final bool isInLibrary; // true if user added to library, false if AI suggested
  final DateTime? addedDate;

  EssentialOil({
    required this.id,
    required this.name,
    required this.description,
    required this.imageType,
    this.imagePath,
    this.isInLibrary = false,
    this.addedDate,
  });

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageType': imageType,
      'imagePath': imagePath,
      'isInLibrary': isInLibrary,
      'addedDate': addedDate?.toIso8601String(),
    };
  }

  // Create from map
  factory EssentialOil.fromMap(Map<String, dynamic> map) {
    return EssentialOil(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      imageType: map['imageType'] as String,
      imagePath: map['imagePath'] as String?,
      isInLibrary: map['isInLibrary'] as bool? ?? false,
      addedDate: map['addedDate'] != null
          ? DateTime.parse(map['addedDate'])
          : null,
    );
  }

  // Copy with method
  EssentialOil copyWith({
    String? id,
    String? name,
    String? description,
    String? imageType,
    String? imagePath,
    bool? isInLibrary,
    DateTime? addedDate,
  }) {
    return EssentialOil(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageType: imageType ?? this.imageType,
      imagePath: imagePath ?? this.imagePath,
      isInLibrary: isInLibrary ?? this.isInLibrary,
      addedDate: addedDate ?? this.addedDate,
    );
  }
}

