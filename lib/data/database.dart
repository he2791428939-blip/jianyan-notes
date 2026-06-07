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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => await m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(notes, notes.folder);
          if (from < 3) await m.addColumn(notes, notes.pinned);
        },
      );
}

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  Stream<List<Note>> watchAllNotes() =>
      (select(notes)..orderBy([(t) => OrderingTerm.desc(t.pinned), (t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Stream<List<Note>> watchNotesByFolder(String folder) =>
      (select(notes)
            ..where((t) => t.folder.equals(folder))
            ..orderBy([(t) => OrderingTerm.desc(t.pinned), (t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<List<String>> getFolders() async {
    final query = selectOnly(notes, distinct: true)
      ..addColumns([notes.folder])
      ..where(notes.folder.isNotValue(''));
    final rows = await query.get();
    final folders = <String>[];
    for (final r in rows) {
      final f = r.read(notes.folder);
      if (f != null && f.isNotEmpty) folders.add(f);
    }
    folders.sort();
    return folders;
  }

  Future<Note?> getNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Note?> watchNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Note> insertNote(NotesCompanion entry) => into(notes).insertReturning(entry);

  Future<bool> updateNote(String id, NotesCompanion data) =>
      (update(notes)..where((t) => t.id.equals(id))).write(data).then((c) => c > 0);

  Future<bool> togglePin(String id, bool newValue) =>
      (update(notes)..where((t) => t.id.equals(id))).write(NotesCompanion(pinned: Value(newValue))).then((c) => c > 0);

  Future<bool> deleteNote(String id) =>
      (delete(notes)..where((t) => t.id.equals(id))).go().then((c) => c > 0);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'jianyan_notes.sqlite');
    return NativeDatabase(File(dbPath));
  });
}
