/// 笔记领域模型。
class NoteModel {
  final String id;
  final String title;
  final String content;
  final String? imagePath;
  final String folder;
  final bool pinned;
  final bool deleted;
  final DateTime? deletedAt;
  final String? userId;
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.folder,
    required this.pinned,
    required this.deleted,
    this.deletedAt,
    this.userId,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  NoteModel copyWith({
    String? id, String? title, String? content, String? imagePath,
    bool clearImage = false, String? folder, bool? pinned, bool? deleted,
    DateTime? deletedAt, bool clearDeletedAt = false, String? userId, bool clearUserId = false,
    int? colorIndex, DateTime? createdAt, DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id, title: title ?? this.title, content: content ?? this.content,
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      folder: folder ?? this.folder, pinned: pinned ?? this.pinned,
      deleted: deleted ?? this.deleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      userId: clearUserId ? null : (userId ?? this.userId),
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NoteModel.create({
    String title = '', String content = '', String? imagePath,
    String folder = '', bool pinned = false, String? userId, int colorIndex = 0,
  }) {
    final now = DateTime.now();
    return NoteModel(
      id: _genId(), title: title, content: content, imagePath: imagePath,
      folder: folder, pinned: pinned, deleted: false, userId: userId,
      colorIndex: colorIndex, createdAt: now, updatedAt: now,
    );
  }

  static String _genId() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    return '$ms${(ms % 100000).toString().padLeft(5, '0')}';
  }

  @override
  String toString() => 'NoteModel(id: $id, title: $title)';
  @override
  bool operator ==(Object other) => identical(this, other) || other is NoteModel && id == other.id;
  @override
  int get hashCode => id.hashCode;
}
