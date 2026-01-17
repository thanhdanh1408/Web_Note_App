/// Enum for note color tags
enum NoteColorTag {
  none,
  red,
  orange,
  yellow,
  green,
  blue,
  purple,
  pink,
}

/// Extension to get color values for each tag
extension NoteColorTagExtension on NoteColorTag {
  /// Get display name in Vietnamese
  String get displayName {
    switch (this) {
      case NoteColorTag.none:
        return 'Tất cả';
      case NoteColorTag.red:
        return 'Đỏ';
      case NoteColorTag.orange:
        return 'Cam';
      case NoteColorTag.yellow:
        return 'Vàng';
      case NoteColorTag.green:
        return 'Xanh lá';
      case NoteColorTag.blue:
        return 'Xanh dương';
      case NoteColorTag.purple:
        return 'Tím';
      case NoteColorTag.pink:
        return 'Hồng';
    }
  }
  
  /// Get database value (lowercase enum name)
  String get dbValue {
    return toString().split('.').last;
  }

  int get colorValue {
    switch (this) {
      case NoteColorTag.none:
        return 0xFF9E9E9E; // Grey
      case NoteColorTag.red:
        return 0xFFEF5350;
      case NoteColorTag.orange:
        return 0xFFFF7043;
      case NoteColorTag.yellow:
        return 0xFFFFCA28;
      case NoteColorTag.green:
        return 0xFF66BB6A;
      case NoteColorTag.blue:
        return 0xFF42A5F5;
      case NoteColorTag.purple:
        return 0xFFAB47BC;
      case NoteColorTag.pink:
        return 0xFFEC407A;
    }
  }

  int get lightColorValue {
    switch (this) {
      case NoteColorTag.none:
        return 0xFFFFFFFF; // White
      case NoteColorTag.red:
        return 0xFFFFEBEE;
      case NoteColorTag.orange:
        return 0xFFFBE9E7;
      case NoteColorTag.yellow:
        return 0xFFFFFDE7;
      case NoteColorTag.green:
        return 0xFFE8F5E9;
      case NoteColorTag.blue:
        return 0xFFE3F2FD;
      case NoteColorTag.purple:
        return 0xFFF3E5F5;
      case NoteColorTag.pink:
        return 0xFFFCE4EC;
    }
  }
}

/// Note model
class Note {
  final String id;
  final String userId;
  String title;
  String contentJson; // JSON string from flutter_quill
  String plainText; // Plain text for search
  NoteColorTag colorTag;
  bool isPinned;
  bool isPrivate; // Uses shared SAFE password
  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.userId,
    this.title = '',
    this.contentJson = '[]',
    this.plainText = '',
    this.colorTag = NoteColorTag.none,
    this.isPinned = false,
    this.isPrivate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new empty note
  factory Note.create({required String userId}) {
    final now = DateTime.now();
    return Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create Note from JSON map
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String? ?? '',
      contentJson: json['contentJson'] as String? ?? '[]',
      plainText: json['plainText'] as String? ?? '',
      colorTag: NoteColorTag.values.firstWhere(
        (e) => e.toString() == json['colorTag'],
        orElse: () => NoteColorTag.none,
      ),
      isPinned: json['isPinned'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Note to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'contentJson': contentJson,
      'plainText': plainText,
      'colorTag': colorTag.toString(),
      'isPinned': isPinned,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Copy with modifications
  Note copyWith({
    String? title,
    String? contentJson,
    String? plainText,
    NoteColorTag? colorTag,
    bool? isPinned,
    bool? isPrivate,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      userId: userId,
      title: title ?? this.title,
      contentJson: contentJson ?? this.contentJson,
      plainText: plainText ?? this.plainText,
      colorTag: colorTag ?? this.colorTag,
      isPinned: isPinned ?? this.isPinned,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get preview text (first 100 characters of plain text)
  String get preview {
    if (plainText.isEmpty) return 'Không có nội dung';
    return plainText.length > 100 
        ? '${plainText.substring(0, 100)}...' 
        : plainText;
  }
}
