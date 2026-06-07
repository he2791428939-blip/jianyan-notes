import '../models/note_model.dart';

/// 笔记仓库接口 — 定义 CRUD 操作契约。
abstract class NoteRepository {
  Stream<List<NoteModel>> watchAllNotes();
  Stream<NoteModel?> watchNote(String id);
  Future<NoteModel?> getNote(String id);
  Future<NoteModel> createNote({
    String title = '',
    String content = '',
    String? imagePath,
    int colorIndex = 0,
  });
  Future<bool> updateNote(NoteModel note);
  Future<bool> deleteNote(String id);
}
