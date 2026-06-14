import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/database.dart';
import '../data/local_note_repository.dart';
import '../data/note_repository.dart';
import '../models/note_model.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final noteRepositoryProvider = Provider<NoteRepository>((ref) => LocalNoteRepository(ref.watch(databaseProvider)));

final notesProvider = StreamProvider<List<NoteModel>>((ref) => ref.watch(noteRepositoryProvider).watchAllNotes());
final notesByFolderProvider = StreamProvider.family<List<NoteModel>, String>((ref, f) => ref.watch(noteRepositoryProvider).watchNotesByFolder(f));
final foldersProvider = FutureProvider<List<String>>((ref) => ref.watch(noteRepositoryProvider).getFolders());
final noteProvider = StreamProvider.family<NoteModel?, String>((ref, id) => ref.watch(noteRepositoryProvider).watchNote(id));
final trashProvider = StreamProvider<List<NoteModel>>((ref) => ref.watch(noteRepositoryProvider).watchTrash());

class NoteActionsNotifier extends Notifier<void> {
  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  @override
  void build() {}

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<String> create({String title = '', String content = '', String? imagePath, String folder = ''}) async {
    final colors = [0, 1, 2, 3, 4, 5];
    final n = await _repo.createNote(title: title, content: content, imagePath: imagePath, folder: folder, userId: _userId, colorIndex: (title.hashCode % colors.length).abs());
    ref.invalidate(foldersProvider);
    if (_userId != null) _pushToRemote(n);
    return n.id;
  }

  Future<void> update(NoteModel note) async {
    await _repo.updateNote(note);
    ref.invalidate(foldersProvider);
    if (_userId != null) _pushToRemote(note);
  }

  Future<void> togglePin(NoteModel n) async {
    await _repo.togglePin(n.id, !n.pinned);
  }

  Future<void> delete(NoteModel n) async {
    await _repo.softDelete(n.id);
    ref.invalidate(foldersProvider);
    if (_userId != null) _pushToRemote(n.copyWith(deleted: true, deletedAt: DateTime.now()));
  }

  Future<void> restore(String id) async {
    await _repo.restore(id);
    ref.invalidate(foldersProvider);
    if (_userId != null) {
      final n = await _repo.getNote(id);
      if (n != null) _pushToRemote(n);
    }
  }

  Future<void> deleteForever(NoteModel n) async {
    if (n.imagePath != null && n.imagePath!.isNotEmpty) {
      try { await File(n.imagePath!).delete(); } catch (_) {}
    }
    await _repo.deleteForever(n.id);
    if (_userId != null && Supabase.instance.client.auth.currentUser != null) {
      await Supabase.instance.client.from('notes').delete().eq('id', n.id);
    }
  }

  /// 登录后首次同步。
  Future<void> syncOnLogin(String userId) async {
    await _repo.migrateLocalNotes(userId);
    await _repo.pullRemoteNotes(userId);
    ref.invalidate(notesProvider);
    ref.invalidate(foldersProvider);
  }

  void _pushToRemote(NoteModel n) async {
    try {
      await Supabase.instance.client.from('notes').upsert({
        'id': n.id, 'title': n.title, 'content': n.content,
        'imagePath': n.imagePath, 'folder': n.folder, 'pinned': n.pinned,
        'deleted': n.deleted, 'deletedAt': n.deletedAt?.toIso8601String(),
        'userId': n.userId, 'colorIndex': n.colorIndex,
        'createdAt': n.createdAt.toIso8601String(), 'updatedAt': n.updatedAt.toIso8601String(),
      });
    } catch (_) {}
  }
}

final noteActionsProvider = NotifierProvider<NoteActionsNotifier, void>(() => NoteActionsNotifier());
