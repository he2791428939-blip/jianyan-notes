import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get imagePath => text().nullable()();
  TextColumn get folder => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Notes], daos: [NoteDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => await m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(notes, notes.folder);
          if (from < 3) await m.addColumn(notes, notes.pinned);
          if (from < 4) {
            await m.addColumn(notes, notes.deleted);
            await m.addColumn(notes, notes.deletedAt);
          }
        },
      );
}

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  /// 活跃笔记（未删除）。
  Stream<List<Note>> watchAllNotes() => (select(notes)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.pinned), (t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Stream<List<Note>> watchNotesByFolder(String folder) => (select(notes)
        ..where((t) => t.folder.equals(folder) & t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.pinned), (t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Future<List<String>> getFolders() async {
    final query = selectOnly(notes, distinct: true)
      ..addColumns([notes.folder])
      ..where(notes.folder.isNotValue('') & notes.deleted.equals(false));
    final rows = await query.get();
    final folders = <String>[];
    for (final r in rows) {
      final f = r.read(notes.folder);
      if (f != null && f.isNotEmpty) folders.add(f);
    }
    folders.sort();
    return folders;
  }

  /// 回收站。
  Stream<List<Note>> watchTrash() => (select(notes)
        ..where((t) => t.deleted.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
      .watch();

  Future<int> trashCount() =>
      (selectOnly(notes)..addColumns([notes.id])..where(notes.deleted.equals(true)))
          .map((r) => r.read(notes.id))
          .get()
          .then((l) => l.length);

  Future<Note?> getNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Note?> watchNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Note> insertNote(NotesCompanion entry) => into(notes).insertReturning(entry);

  Future<bool> updateNote(String id, NotesCompanion data) =>
      (update(notes)..where((t) => t.id.equals(id))).write(data).then((c) => c > 0);

  Future<bool> togglePin(String id, bool v) =>
      (update(notes)..where((t) => t.id.equals(id)))
          .write(NotesCompanion(pinned: Value(v)))
          .then((c) => c > 0);

  /// 软删除。
  Future<bool> softDelete(String id) =>
      (update(notes)..where((t) => t.id.equals(id)))
          .write(NotesCompanion(deleted: const Value(true), deletedAt: Value(DateTime.now())))
          .then((c) => c > 0);

  /// 恢复。
  Future<bool> restore(String id) =>
      (update(notes)..where((t) => t.id.equals(id)))
          .write(const NotesCompanion(deleted: Value(false), deletedAt: Value(null)))
          .then((c) => c > 0);

  /// 物理删除。
  Future<bool> deleteForever(String id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go().then((c) => c > 0);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'jianyan_notes.sqlite');
    return NativeDatabase(File(dbPath));
  });
}
