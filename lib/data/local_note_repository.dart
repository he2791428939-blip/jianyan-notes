import 'package:drift/drift.dart' show Value;
import '../models/note_model.dart';
import 'database.dart';
import 'note_repository.dart';

class LocalNoteRepository implements NoteRepository {
  final AppDatabase _db;

  LocalNoteRepository(this._db);

  NoteModel _toModel(Note row) {
    return NoteModel(
      id: row.id,
      title: row.title,
      content: row.content,
      imagePath: row.imagePath,
      folder: row.folder,
      colorIndex: row.colorIndex,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  NotesCompanion _toCompanion(NoteModel note) {
    return NotesCompanion(
      id: Value(note.id),
      title: Value(note.title),
      content: Value(note.content),
      imagePath: Value(note.imagePath),
      folder: Value(note.folder),
      colorIndex: Value(note.colorIndex),
      createdAt: Value(note.createdAt),
      updatedAt: Value(note.updatedAt),
    );
  }

  @override
  Stream<List<NoteModel>> watchAllNotes() {
    return _db.noteDao.watchAllNotes().map((r) => r.map(_toModel).toList());
  }

  @override
  Stream<List<NoteModel>> watchNotesByFolder(String folder) {
    return _db.noteDao
        .watchNotesByFolder(folder)
        .map((r) => r.map(_toModel).toList());
  }

  @override
  Future<List<String>> getFolders() => _db.noteDao.getFolders();

  @override
  Stream<NoteModel?> watchNote(String id) {
    return _db.noteDao.watchNote(id).map((r) => r == null ? null : _toModel(r));
  }

  @override
  Future<NoteModel?> getNote(String id) async {
    final row = await _db.noteDao.getNote(id);
    return row == null ? null : _toModel(row);
  }

  @override
  Future<NoteModel> createNote({
    String title = '',
    String content = '',
    String? imagePath,
    String folder = '',
    int colorIndex = 0,
  }) async {
    final note = NoteModel.create(
      title: title,
      content: content,
      imagePath: imagePath,
      folder: folder,
      colorIndex: colorIndex,
    );
    await _db.noteDao.insertNote(_toCompanion(note));
    return note;
  }

  @override
  Future<bool> updateNote(NoteModel note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    return _db.noteDao.updateNote(updated.id, _toCompanion(updated));
  }

  @override
  Future<bool> deleteNote(String id) async {
    return _db.noteDao.deleteNote(id);
  }
}
