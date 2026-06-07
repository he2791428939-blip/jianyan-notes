import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../data/local_note_repository.dart';
import '../data/note_repository.dart';
import '../models/note_model.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return LocalNoteRepository(ref.watch(databaseProvider));
});

/// 全部笔记。
final notesProvider = StreamProvider<List<NoteModel>>((ref) {
  return ref.watch(noteRepositoryProvider).watchAllNotes();
});

/// 按分类过滤的笔记。
final notesByFolderProvider =
    StreamProvider.family<List<NoteModel>, String>((ref, folder) {
  return ref.watch(noteRepositoryProvider).watchNotesByFolder(folder);
});

/// 分类列表（一次性加载）。
final foldersProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(noteRepositoryProvider).getFolders();
});

/// 当前选中的分类（首页底栏切换用）。
final selectedFolderProvider = StateProvider<String>((ref) => '');

/// 单条笔记。
final noteProvider = StreamProvider.family<NoteModel?, String>((ref, id) {
  return ref.watch(noteRepositoryProvider).watchNote(id);
});

/// CRUD 操作。
class NoteActionsNotifier extends Notifier<void> {
  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  @override
  void build() {}

  Future<String> create({
    String title = '',
    String content = '',
    String? imagePath,
    String folder = '',
  }) async {
    final colors = [0, 1, 2, 3, 4, 5];
    final colorIndex = (title.hashCode % colors.length).abs();
    final note = await _repo.createNote(
      title: title,
      content: content,
      imagePath: imagePath,
      folder: folder,
      colorIndex: colorIndex,
    );
    ref.invalidate(foldersProvider);
    return note.id;
  }

  Future<void> update(NoteModel note) async {
    await _repo.updateNote(note);
    ref.invalidate(foldersProvider);
  }

  Future<void> delete(NoteModel note) async {
    // 清理关联图片
    if (note.imagePath != null && note.imagePath!.isNotEmpty) {
      try { await File(note.imagePath!).delete(); } catch (_) {}
    }
    await _repo.deleteNote(note.id);
    ref.invalidate(foldersProvider);
  }
}

final noteActionsProvider = NotifierProvider<NoteActionsNotifier, void>(() {
  return NoteActionsNotifier();
});
