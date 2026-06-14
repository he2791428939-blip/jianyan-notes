import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';
import 'database.dart';
import 'note_repository.dart';

class LocalNoteRepository implements NoteRepository {
  final AppDatabase _db;
  LocalNoteRepository(this._db);

  NoteModel _toModel(Note row) => NoteModel(
    id: row.id, title: row.title, content: row.content,
    imagePath: row.imagePath, folder: row.folder, pinned: row.pinned,
    deleted: row.deleted, deletedAt: row.deletedAt, userId: row.userId,
    colorIndex: row.colorIndex, createdAt: row.createdAt, updatedAt: row.updatedAt,
  );

  NotesCompanion _toCompanion(NoteModel n) => NotesCompanion(
    id: Value(n.id), title: Value(n.title), content: Value(n.content),
    imagePath: Value(n.imagePath), folder: Value(n.folder), pinned: Value(n.pinned),
    deleted: Value(n.deleted), deletedAt: Value(n.deletedAt), userId: Value(n.userId),
    colorIndex: Value(n.colorIndex), createdAt: Value(n.createdAt), updatedAt: Value(n.updatedAt),
  );

  @override Stream<List<NoteModel>> watchAllNotes() => _db.noteDao.watchAllNotes().map((r) => r.map(_toModel).toList());
  @override Stream<List<NoteModel>> watchNotesByFolder(String f) => _db.noteDao.watchNotesByFolder(f).map((r) => r.map(_toModel).toList());
  @override Stream<List<NoteModel>> watchTrash() => _db.noteDao.watchTrash().map((r) => r.map(_toModel).toList());
  @override Future<List<String>> getFolders() => _db.noteDao.getFolders();
  @override Stream<NoteModel?> watchNote(String id) => _db.noteDao.watchNote(id).map((r) => r == null ? null : _toModel(r));
  @override Future<NoteModel?> getNote(String id) async { final r = await _db.noteDao.getNote(id); return r == null ? null : _toModel(r); }

  @override
  Future<NoteModel> createNote({String title = '', String content = '', String? imagePath, String folder = '', String? userId, int colorIndex = 0}) async {
    final n = NoteModel.create(title: title, content: content, imagePath: imagePath, folder: folder, userId: userId, colorIndex: colorIndex);
    await _db.noteDao.insertNote(_toCompanion(n));
    return n;
  }

  @override Future<bool> updateNote(NoteModel n) => _db.noteDao.updateNote(n.id, _toCompanion(n.copyWith(updatedAt: DateTime.now())));
  @override Future<bool> togglePin(String id, bool v) => _db.noteDao.togglePin(id, v);
  @override Future<bool> softDelete(String id) => _db.noteDao.softDelete(id);
  @override Future<bool> restore(String id) => _db.noteDao.restore(id);
  @override Future<bool> deleteForever(String id) => _db.noteDao.deleteForever(id);

  /// 初次登录时，把本地 userId=null 的笔记绑定到新账号。
  @override
  Future<void> migrateLocalNotes(String userId) async {
    final local = (await _db.noteDao.getAllNotes()).where((r) => r.userId == null).toList();
    for (final r in local) {
      await _db.noteDao.updateNote(r.id, NotesCompanion(userId: Value(userId)));
    }
  }

  /// 从 Supabase 拉取云端笔记写入本地（去重）。
  @override
  Future<void> pullRemoteNotes(String userId) async {
    final supabase = Supabase.instance.client;
    final remoteRaw = await supabase.from('notes').select().eq('userId', userId);
    final remoteList = (remoteRaw as List<dynamic>).cast<Map<String, dynamic>>();
    final localIds = (await _db.noteDao.getAllNotes()).map((r) => r.id).toSet();

    for (final j in remoteList) {
      final n = NoteModel(
        id: j['id'], title: j['title'] ?? '', content: j['content'] ?? '',
        imagePath: j['imagePath'], folder: j['folder'] ?? '',
        pinned: j['pinned'] == true, deleted: j['deleted'] == true, deletedAt: j['deletedAt'] != null ? DateTime.tryParse(j['deletedAt']) : null,
        userId: j['userId'], colorIndex: j['colorIndex'] ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
      );
      if (localIds.contains(n.id)) {
        await _db.noteDao.updateNote(n.id, _toCompanion(n));
      } else {
        await _db.noteDao.insertNote(_toCompanion(n));
      }
    }
  }
}
