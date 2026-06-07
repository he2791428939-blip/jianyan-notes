import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../data/local_note_repository.dart';
import '../data/note_repository.dart';
import '../models/note_model.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final noteRepositoryProvider = Provider<NoteRepository>((ref) => LocalNoteRepository(ref.watch(databaseProvider)));

final notesProvider = StreamProvider<List<NoteModel>>((ref) => ref.watch(noteRepositoryProvider).watchAllNotes());
final notesByFolderProvider = StreamProvider.family<List<NoteModel>, String>((ref, f) => ref.watch(noteRepositoryProvider).watchNotesByFolder(f));
final foldersProvider = FutureProvider<List<String>>((ref) => ref.watch(noteRepositoryProvider).getFolders());
final selectedFolderProvider = StateProvider<String>((ref) => '');
final noteProvider = StreamProvider.family<NoteModel?, String>((ref, id) => ref.watch(noteRepositoryProvider).watchNote(id));
final trashProvider = StreamProvider<List<NoteModel>>((ref) => ref.watch(noteRepositoryProvider).watchTrash());

class NoteActionsNotifier extends Notifier<void> {
  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  @override
  void build() {}

  Future<String> create({String title = '', String content = '', String? imagePath, String folder = ''}) async {
    final colors = [0, 1, 2, 3, 4, 5];
    final colorIndex = (title.hashCode % colors.length).abs();
    final note = await _repo.createNote(title: title, content: content, imagePath: imagePath, folder: folder, colorIndex: colorIndex);
    ref.invalidate(foldersProvider);
    return note.id;
  }

  Future<void> update(NoteModel note) async {
    await _repo.updateNote(note);
    ref.invalidate(foldersProvider);
  }

  Future<void> togglePin(NoteModel note) async => await _repo.togglePin(note.id, !note.pinned);

  /// 软删除 — 移入回收站。
  Future<void> delete(NoteModel note) async {
    await _repo.softDelete(note.id);
    ref.invalidate(foldersProvider);
  }

  /// 从回收站恢复。
  Future<void> restore(String id) async {
    await _repo.restore(id);
    ref.invalidate(foldersProvider);
  }

  /// 彻底删除（含图片文件）。
  Future<void> deleteForever(NoteModel note) async {
    if (note.imagePath != null && note.imagePath!.isNotEmpty) {
      try { await File(note.imagePath!).delete(); } catch (_) {}
    }
    await _repo.deleteForever(note.id);
  }
}

final noteActionsProvider = NotifierProvider<NoteActionsNotifier, void>(() => NoteActionsNotifier());
