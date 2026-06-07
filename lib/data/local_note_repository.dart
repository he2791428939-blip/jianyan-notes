import 'package:drift/drift.dart' show Value;
import '../models/note_model.dart';
import 'database.dart';
import 'note_repository.dart';

class LocalNoteRepository implements NoteRepository {
  final AppDatabase _db;

  LocalNoteRepository(this._db);

  NoteModel _toModel(Note row) {
    return NoteModel(
      id: row.id, title: row.title, content: row.content,
      imagePath: row.imagePath, folder: row.folder,
      pinned: row.pinned, deleted: row.deleted, deletedAt: row.deletedAt,
      colorIndex: row.colorIndex, createdAt: row.createdAt, updatedAt: row.updatedAt,
    );
  }

  NotesCompanion _toCompanion(NoteModel note) {
    return NotesCompanion(
      id: Value(note.id), title: Value(note.title), content: Value(note.content),
      imagePath: Value(note.imagePath), folder: Value(note.folder),
      pinned: Value(note.pinned), deleted: Value(note.deleted), deletedAt: Value(note.deletedAt),
      colorIndex: Value(note.colorIndex), createdAt: Value(note.createdAt), updatedAt: Value(note.updatedAt),
    );
  }

  @override Stream<List<NoteModel>> watchAllNotes() => _db.noteDao.watchAllNotes().map((r) => r.map(_toModel).toList());
  @override Stream<List<NoteModel>> watchNotesByFolder(String f) => _db.noteDao.watchNotesByFolder(f).map((r) => r.map(_toModel).toList());
  @override Stream<List<NoteModel>> watchTrash() => _db.noteDao.watchTrash().map((r) => r.map(_toModel).toList());
  @override Future<List<String>> getFolders() => _db.noteDao.getFolders();
  @override Stream<NoteModel?> watchNote(String id) => _db.noteDao.watchNote(id).map((r) => r == null ? null : _toModel(r));
  @override Future<NoteModel?> getNote(String id) async { final r = await _db.noteDao.getNote(id); return r == null ? null : _toModel(r); }

  @override
  Future<NoteModel> createNote({String title = '', String content = '', String? imagePath, String folder = '', int colorIndex = 0}) async {
    final note = NoteModel.create(title: title, content: content, imagePath: imagePath, folder: folder, colorIndex: colorIndex);
    await _db.noteDao.insertNote(_toCompanion(note));
    return note;
  }

  @override Future<bool> updateNote(NoteModel note) async { final u = note.copyWith(updatedAt: DateTime.now()); return _db.noteDao.updateNote(u.id, _toCompanion(u)); }
  @override Future<bool> togglePin(String id, bool v) => _db.noteDao.togglePin(id, v);
  @override Future<bool> softDelete(String id) => _db.noteDao.softDelete(id);
  @override Future<bool> restore(String id) => _db.noteDao.restore(id);
  @override Future<bool> deleteForever(String id) => _db.noteDao.deleteForever(id);
}
