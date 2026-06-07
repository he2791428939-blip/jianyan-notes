import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../data/local_note_repository.dart';
import '../data/note_repository.dart';
import '../models/note_model.dart';

/// 数据库单例。
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Repository 注入 — 未来换 Supabase 只需改这里。
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return LocalNoteRepository(db);
});

/// 笔记列表（响应式流）。
final notesProvider = StreamProvider<List<NoteModel>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchAllNotes();
});

/// 单条笔记（按 ID）。
final noteProvider =
    StreamProvider.family<NoteModel?, String>((ref, id) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchNote(id);
});

/// CRUD 操作 Notifier。
class NoteActionsNotifier extends Notifier<void> {
  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  @override
  void build() {}

  Future<String> create({
    String title = '',
    String content = '',
    String? imagePath,
  }) async {
    final colors = [0, 1, 2, 3, 4, 5];
    final colorIndex = (title.hashCode % colors.length).abs();
    final note = await _repo.createNote(
      title: title,
      content: content,
      imagePath: imagePath,
      colorIndex: colorIndex,
    );
    return note.id;
  }

  Future<void> update(NoteModel note) async {
    await _repo.updateNote(note);
  }

  Future<void> delete(String id) async {
    await _repo.deleteNote(id);
  }
}

final noteActionsProvider =
    NotifierProvider<NoteActionsNotifier, void>(() {
  return NoteActionsNotifier();
});
