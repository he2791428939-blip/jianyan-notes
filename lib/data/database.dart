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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  Future<List<Note>> getAllNotes() =>
      (select(notes)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  Stream<List<Note>> watchAllNotes() =>
      (select(notes)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<Note?> getNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Note?> watchNote(String id) =>
      (select(notes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Note> insertNote(NotesCompanion entry) =>
      into(notes).insertReturning(entry);

  Future<bool> updateNote(String id, NotesCompanion data) =>
      (update(notes)..where((t) => t.id.equals(id)))
          .write(data)
          .then((c) => c > 0);

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
