import '../models/note_model.dart';

abstract class NoteRepository {
  Stream<List<NoteModel>> watchAllNotes();
  Stream<List<NoteModel>> watchNotesByFolder(String folder);
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
  Future<bool> deleteNote(String id);
}
