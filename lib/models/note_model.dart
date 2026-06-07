/// 笔记领域模型。
class NoteModel {
  final String id;
  final String title;
  final String content;
  final String? imagePath;
  final String folder;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.folder,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? imagePath,
    bool clearImage = false,
    String? folder,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      folder: folder ?? this.folder,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NoteModel.create({
    String title = '',
    String content = '',
    String? imagePath,
    String folder = '',
    int colorIndex = 0,
  }) {
    final now = DateTime.now();
    return NoteModel(
      id: _generateId(),
      title: title,
      content: content,
      imagePath: imagePath,
      folder: folder,
      colorIndex: colorIndex,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _generateId() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    final r = (ms % 100000).toString().padLeft(5, '0');
    return '$ms$r';
  }

  @override
  String toString() => 'NoteModel(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoteModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
