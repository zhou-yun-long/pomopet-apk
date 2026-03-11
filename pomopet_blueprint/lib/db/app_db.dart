import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_db.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get petId => text().withDefault(const Constant('lobster'))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get coin => integer().withDefault(const Constant(0))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  IntColumn get bestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get targetMinutes => integer().withDefault(const Constant(30))();
  BoolColumn get required => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active/paused
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class CompletionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Tasks, #id)();
  TextColumn get date => text()(); // YYYY-MM-DD
  IntColumn get minutes => integer()();

  TextColumn get source => text()(); // timer/proof/manual
  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  TextColumn get attachmentPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Inventory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get itemId => text()();
  IntColumn get count => integer().withDefault(const Constant(1))();
  BoolColumn get equipped => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TimerSessions extends Table {
  TextColumn get id => text()(); // uuid
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get taskId => integer().nullable().references(Tasks, #id)();

  TextColumn get presetId => text().withDefault(const Constant('classic_25_5'))();

  TextColumn get phase => text().withDefault(const Constant('focus'))(); // focus/short_break/long_break
  TextColumn get status => text().withDefault(const Constant('running'))(); // running/paused/finished/canceled

  IntColumn get plannedMinutes => integer()();
  IntColumn get elapsedSeconds => integer().withDefault(const Constant(0))();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endAt => dateTime()();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  IntColumn get breakIndex => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Users, Tasks, CompletionLogs, Inventory, TimerSessions])
class AppDb extends _$AppDb {
  AppDb() : super(_open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future migrations.
        },
      );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    return driftDatabase(name: 'pomopet.sqlite');
  });
}
