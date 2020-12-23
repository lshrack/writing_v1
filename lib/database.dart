import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'project_list.dart';

// database table and column names
final String tableProjects = 'projects';
final String columnId = '_id';
final String columnName = 'word';
final String columnWords = 'words';
final String columnTargetWords = 'target_count';

//All of the basic database methods:
//read(db, id), readAll(db), save(entry, db), clearAll(db), deleteItem(id, db),
//editItem(db, entry), getId(db, entry), readAllAsProject(db)

class DatabaseMethods {
  static read(ProjectDatabaseHelper helper, int rowId) async {
    ProjectEntry entry = await helper.queryEntry(rowId);

    if (entry == null) {
    } else {
      return entry;
    }
  }

  static Future<List<ProjectEntry>> readAll(
      ProjectDatabaseHelper helper) async {
    List<ProjectEntry> entries = await helper.queryAllEntries();

    if (entries != null) {
      return entries;
    } else {}

    return [];
  }

  static Future<int> save(
      ProjectEntry entry, ProjectDatabaseHelper helper) async {
    int id = await helper.insert(entry);
    return id;
  }

  static clearAll(ProjectDatabaseHelper helper) async {
    helper.deleteAllEntries();
  }

  static deleteItem(int id, ProjectDatabaseHelper helper) async {
    await helper.deleteEntry(id);

    await readAll(helper);
  }

  static editItem(ProjectDatabaseHelper helper, ProjectEntry entry) async {
    await helper.update(entry);
    await readAll(helper);
  }

  static Future<int> getId(
      ProjectDatabaseHelper helper, ProjectEntry item) async {
    List<ProjectEntry> entries = await readAll(helper);
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].toMap()[columnName] == item.name &&
          entries[i].toMap()[columnWords] == item.words.toString()) {
        return entries[i].id;
      }
    }
    return 10000;
  }

  static Future<List<Project>> readAllAsProject(
      ProjectDatabaseHelper helper) async {
    List<ProjectEntry> entries = await readAll(helper);
    List<Project> projects = [];
    ProjectEntry curr;

    for (int i = 0; i < entries.length; i++) {
      curr = entries[i];
      projects.add(curr.toProject());
    }

    return projects;
  }
}

//******************************************************************************\\
//Project Class
//******************************************************************************\\

class ProjectEntry {
  int id;
  String name;
  String words;
  int target;

  ProjectEntry();
  ProjectEntry.withParams(this.id, this.name, this.words, this.target);

  //takes map and makes it into a ProjectEntry
  ProjectEntry.fromMap(Map<String, dynamic> map) {
    id = map[columnId];
    name = map[columnName];
    words = map[columnWords];
    target = map[columnTargetWords];
  }

  //makes map out of ProjectEntry
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnName: name,
      columnWords: words,
      columnTargetWords: target,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  //creates String for debug output
  @override
  String toString() {
    return '$id ' + name + ' WC $words, target $target';
  }

  Project toProject() {
    return Project(id: id, name: name, countsString: words, target: target);
  }
}

//************************************************************************************************\\
//HELPER FOR ITEM DATABASE
//************************************************************************************************\\

class ProjectDatabaseHelper {
  //Change name when restructuring db; changing version doesn't seem to work
  static final _databaseName = "ProjectDatabase.db";
  static final _databaseVersion = 1;

  ProjectDatabaseHelper._privateConstructor();
  static final ProjectDatabaseHelper instance =
      ProjectDatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database _database;
  Future<Database> get database async {
    if (_database != null) _database.close();
    _database = await _initDatabase();
    return _database;
  }

  // open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // Open the database
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    await db.execute('''
              CREATE TABLE $tableProjects (
                $columnId INTEGER PRIMARY KEY,
                $columnName TEXT NOT NULL,
                $columnWords STRING NOT NULL,
                $columnTargetWords INT NOT NULL
              )
              ''');
  }

  //Database helper methods:
  //insert(entry), queryEntry(id), queryAllEntries(), deleteAllEntries(),
  //deleteEntry(id), update(entry)
  Future<int> insert(ProjectEntry item) async {
    Database db = await database;
    int id = await db.insert(tableProjects, item.toMap());
    return id;
  }

  Future<ProjectEntry> queryEntry(int id) async {
    Database db = await database;
    List<Map> maps = await db.query(tableProjects,
        columns: [
          columnId,
          columnName,
          columnWords,
          columnTargetWords,
        ],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return ProjectEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ProjectEntry>> queryAllEntries() async {
    Database db = await database;
    List<Map> maps = await db.query(tableProjects);

    if (maps.length == 0) {
      return [];
    }

    List<ProjectEntry> items = [ProjectEntry.fromMap(maps.first)];

    for (int i = 1; i < maps.length; i++) {
      items.add(ProjectEntry.fromMap(maps[i]));
    }

    return items;
  }

  Future<void> deleteAllEntries() async {
    List<ProjectEntry> items = await queryAllEntries();

    if (items != null) {
      items.forEach((item) {
        deleteEntry(item.id);
      });
    }

    await queryAllEntries();
  }

  Future<void> deleteEntry(int id) async {
    final db = await database;
    await db.delete(tableProjects, where: "$columnId = ?", whereArgs: [id]);
  }

  Future<void> update(ProjectEntry entry) async {
    final db = await database;
    await db.update(tableProjects, entry.toMap(),
        where: "$columnId = ?", whereArgs: [entry.id]);
  }
}
