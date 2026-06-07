import '../models/note_model.dart';

abstract class NoteRepository {
  Stream<List<NoteModel>> watchAllNotes();
  Stream<List<NoteModel>> watchNotesByFolder(String folder);
  Stream<List<NoteModel>> watchTrash();
  Future<List<String>> getFolders();
  Stream<NoteModel?> watchNote(String id);
  Future<NoteModel?> getNote(String id);
  Future<NoteModel> createNote({
    String title = '',
    String content = '',
    String? imagePath,
    String folder = '',
    int colorIndex = 0,
  });
  Future<bool> updateNote(NoteModel note);
  Future<bool> togglePin(String id, bool pinned);
  Future<bool> softDelete(String id);
  Future<bool> restore(String id);
  Future<bool> deleteForever(String id);
}
