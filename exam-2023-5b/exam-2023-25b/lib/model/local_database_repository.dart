import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';

import '../utils/pair.dart';
import 'entity.dart';

enum ConnectionStatus { CONNECTED, CONNECTING, DISCONNECTED }

class LocalDatabaseRepository extends ChangeNotifier {
  String updateEndpoint = "price";
  String entryEndpoint = "entry";
  String entriesEndpoint = "entries";
  String datesEndpoint = "dates";
  String allEndpoint = "all";

  List<Entity> entries = [];
  List<String> dates = [];

  List<Entity> top3TypesList = [];
  HashMap<String, int> top3Types = HashMap<String, int>();
  late Future<HashMap<String, int>> futureTop3Types;

  List<Entity> weeksList = [];
  HashMap<String, int> weeks = HashMap<String, int>();

  late Future<List<String>> futureDates;
  Map<String, List<Entity>> datesEntries = Map<String, List<Entity>>();


  static final String urlServer = "http://10.0.2.2:2305";

  ValueNotifier<ConnectionStatus> connected =
  ValueNotifier(ConnectionStatus.DISCONNECTED);

  static final ValueNotifier<bool> notifier = ValueNotifier(false);
  static final log = Logger('ActivityService');

  StreamController<ConnectivityResult> connectivityController =
  StreamController<ConnectivityResult>(sync: true);

  LocalDatabaseRepository() {
    futureTop3Types = get3TopTypes();
    futureDates = getDates();
    notifyListeners();
    for (String genre in dates) {
      datesEntries[genre] = [];
    }
  }

  // var tempResult = Map.fromEntries(top3Types.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)));
  //
  // top3Types.clear();
  //
  // for(int i = 0; i < 3; i++){
  //   top3Types[tempResult.keys.toList()[i]] = tempResult.values.toList()[i];
  // }
  //
  // // Map<String, int> finalResult = Map.fromEntries(distances.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)));
  //
  // print(top3Types);

  Future<HashMap<String, int>> getCaloriesForWeeks() async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      var url = Uri.parse("$urlServer/$allEndpoint");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        weeksList = jsonDecode(response.body)
            .map<Entity>((t) => Entity.fromJson(t))
            .toList() as List<Entity>;
      } else {}

      for(Entity item in weeksList){

      }

      HashSet<String> types = HashSet();

      for(Entity item in top3TypesList){
        types.add(item.type);
      }

      for(String type in types){
        top3Types[type] = 0;
      }

      for(Entity item in top3TypesList){
        int temp = top3Types[item.type]!;
        temp +=  item.distance;
        top3Types[item.type] = temp;
      }
      print(top3Types);

      top3TypesList.sort((a, b) {
        int dataComparison = top3Types[b.type]!.compareTo(top3Types[a.type]!);
        return dataComparison;
      });

      List<Entity> deepCopyList = List<Entity>.from(top3TypesList);
      for (int i = 0; i < deepCopyList.length - 1; ++i) {
        if (deepCopyList[i].type == deepCopyList[i + 1].type) {
          top3TypesList.remove(deepCopyList[i + 1]);
        }
      }

      top3TypesList = top3TypesList.take(3).toList();

      log.info("GET $urlServer/$allEndpoint");
      return top3Types;

    } else {
      connected.value = ConnectionStatus.DISCONNECTED;
      return HashMap();
    }
  }

  Future<HashMap<String, int>> get3TopTypes() async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      var url = Uri.parse("$urlServer/$allEndpoint");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        top3TypesList = jsonDecode(response.body)
            .map<Entity>((t) => Entity.fromJson(t))
            .toList() as List<Entity>;
      } else {}

      HashSet<String> types = HashSet();

      for(Entity item in top3TypesList){
        types.add(item.type);
      }

      for(String type in types){
        top3Types[type] = 0;
      }

      for(Entity item in top3TypesList){
        int temp = top3Types[item.type]!;
        temp +=  item.distance;
        top3Types[item.type] = temp;
      }
      print(top3Types);

      top3TypesList.sort((a, b) {
        int dataComparison = top3Types[b.type]!.compareTo(top3Types[a.type]!);
        return dataComparison;
      });

      List<Entity> deepCopyList = List<Entity>.from(top3TypesList);
      for (int i = 0; i < deepCopyList.length - 1; ++i) {
        if (deepCopyList[i].type == deepCopyList[i + 1].type) {
          top3TypesList.remove(deepCopyList[i + 1]);
        }
      }

      top3TypesList = top3TypesList.take(3).toList();

      log.info("GET $urlServer/$allEndpoint");
      return top3Types;

    } else {
      connected.value = ConnectionStatus.DISCONNECTED;
      return HashMap();
    }
  }

  Future<List<String>> getDates() async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      try {
        connected.value = ConnectionStatus.CONNECTING;
        var url = Uri.parse("$urlServer/$datesEndpoint");

        final response = await http.get(url);

        if (response.statusCode == 200) {
          connected.value = ConnectionStatus.CONNECTED;
          dates = jsonDecode(response.body)
              .map<String>((t) => t.toString())
              .toList() as List<String>;

          log.info("GET $urlServer/$datesEndpoint");
        } else {}

        notifyListeners();

        await DatabaseHelper.instance.clearCategoriesTable();

        for (String item in dates) {
          await DatabaseHelper.instance.add(item);
          datesEntries[item] = [];
        }

        return dates;
      } catch (e) {
        return []; //TODO SERVER ERRORS CATCH
      }
    } else {
      log.info("Using existent dates offline");
      connected.value = ConnectionStatus.DISCONNECTED;
      dates = await DatabaseHelper.instance.getAll();

      for (String date in dates) {
        var items =
        await DatabaseHelper.instance.getAllEntriesByDate(date);
        datesEntries[date] = items;
      }

      return dates;
    }
  }

  Future<ConnectionStatus> checkConnectivity() async {
    final ConnectivityResult result = await Connectivity().checkConnectivity();

    if (result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile) {
      connected.value = ConnectionStatus.CONNECTED;
    } else {
      connected.value = ConnectionStatus.DISCONNECTED;
    }

    log.info("connected: ${connected.value}");
    return connected.value;
  }

  Future<List<Entity>> getEntries(String category) async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      try {
        connected.value = ConnectionStatus.CONNECTING;

        var url = Uri.parse("$urlServer/$entriesEndpoint/$category");
        final response = await http.get(url);
        var items_2 = [];
        if (response.statusCode == 200) {
          items_2 = jsonDecode(response.body)
              .map<Entity>((t) => Entity.fromJson(t))
              .toList() as List<Entity>;
        } else {}

        log.info("GET $urlServer/$entriesEndpoint/$category");

        await DatabaseHelper.instance.clearItemsForCategory(category);
        entries.clear();

        for (Entity item in items_2) {
          var res = await DatabaseHelper.instance.addItems(EntityDTOWithID(
            id: item.id,
              date: item.date,
              type: item.type,
              duration: item.duration,
              distance: item.distance,
              calories: item.calories,
              rate: item.rate));
          print(res?.id);
          entries.add(res!);
        }

        datesEntries[category] = entries;

        connected.value = ConnectionStatus.CONNECTED;
        notifyListeners();
        return entries;
      } catch(e){
        return []; //TODO SERVER ERRORS CATCH
      }
    } else {
      log.info("Using existing entries offline");
      connected.value = ConnectionStatus.DISCONNECTED;
      entries = await DatabaseHelper.instance.getAllEntriesByDate(category);
      notifyListeners();
      return entries;
    }
  }

  Future<Pair> addActivity(EntityDTO item) async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      try {
        connected.value = ConnectionStatus.CONNECTING;

        var url = Uri.parse("$urlServer/$entryEndpoint");
        var response = await http.post(url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(item.toMap()));

        if (response.statusCode != 200) {
          return Pair(response.body, ConnectionStatus.CONNECTED);
        }

        var res = await DatabaseHelper.instance.addItemsWithoutID(item);
        if (res != null) {
          add(item.date);
          addItem(res);
        }

        connected.value = ConnectionStatus.CONNECTED;

        log.info("POST $urlServer/$entryEndpoint");

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        notifyListeners();
        return Pair(response.body, ConnectionStatus.CONNECTED);

      }
      catch(e){
        return Pair(e.toString(), ConnectionStatus.DISCONNECTED);
      }
    } else {
      notifyListeners();
      connected.value = ConnectionStatus.DISCONNECTED;
      return Pair("ok", ConnectionStatus.DISCONNECTED);
    }
  }

  Future<Pair> deleteActivity(int id) async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      try {
        connected.value = ConnectionStatus.CONNECTING;

        var url = Uri.parse("$urlServer/$entryEndpoint/$id");
        var response = await http.delete(url, headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        });

        if (response.statusCode != 200) {
          return Pair(response.body, ConnectionStatus.CONNECTED);
        }

        connected.value = ConnectionStatus.CONNECTED;
        log.info("DELETE $urlServer/$entryEndpoint/$id");

        delete(id);
        await DatabaseHelper.instance.removeItems(id);

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        // notifyListeners();
        return Pair(response.body, ConnectionStatus.CONNECTED);
      }
      catch(e){
        return Pair(e.toString(), ConnectionStatus.DISCONNECTED);
      }
    } else {
      connected.value = ConnectionStatus.DISCONNECTED;
      return Pair("ok", ConnectionStatus.DISCONNECTED);
    }
  }

  Future<Pair> updateActivity(num price, int id) async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      try {
        connected.value = ConnectionStatus.CONNECTING;
        var url = Uri.parse("$urlServer/$updateEndpoint");
        Map<String, dynamic> data = Map();
        data["id"] = id;
        data["price"] = price;

        var response = await http.post(url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(data));

        if (response.statusCode != 200) {
          return Pair(response.body, ConnectionStatus.CONNECTED);
        }

        connected.value = ConnectionStatus.CONNECTED;

        log.info("POST $urlServer/$updateEndpoint");

        bool found = false;
        for(Entity item in entries){
          if(item.id == id){
              found = true;
          }
        }
        if(found){
          var item = findById(id);
          var res = await DatabaseHelper.instance
              .updateItems(item);
          update(res!);
        }
        else {
          print("Item is not in database!!!!!");
        }

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        notifyListeners();
        return Pair(response.body, ConnectionStatus.CONNECTED);
      }
      catch(e){
        return Pair(e.toString(), ConnectionStatus.DISCONNECTED);
      }
    } else {
      connected.value = ConnectionStatus.DISCONNECTED;
      return Pair("ok", ConnectionStatus.DISCONNECTED);
    }
  }

  Future<void> add(String entity) async {
    await DatabaseHelper.instance.add(entity);
    bool found = false;
    for (String category in dates) {
      if (category == entity) {
        found = true;
      }
    }
    if (found == false) {
      dates.add(entity);
    }
    // notifyListeners();
  }

  Entity findById(int id) {
    return entries.firstWhere((element) => element.id == id);
  }

  void update(Entity res) {

    int index = entries.indexWhere((element) => element.id == res.id);
    entries[index] = res;
    // notifyListeners();
  }

  void addItem(Entity entity) {
    entries.add(entity);
    var category = entity.distance;
    datesEntries[category]?.add(entity);
    // notifyListeners();
  }

  void delete(int activity_id) {
    var item = findById(activity_id);
    var category = item.distance;

    entries.removeWhere((element) => element.id == activity_id);
    datesEntries[category]
        ?.removeWhere((element) => element.id == activity_id);
    // notifyListeners();
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static const tableNameDates = 'dates';
  static const tableNameEntries = 'entries';
  static const tableNameAllEntries = 'allEntries';

  static final log = Logger('ActivityService');

  static Database? _database;

  Future<Database?> get database async => _database ??= await _initDatabase();

  void print(String error) async {
    final file = File('error_log.txt');
    //await file.writeAsString(error);
    // print(error);
  }

  Future<Database?> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // await deleteDatabase(documentsDirectory.path);
    try {
      String path = join(documentsDirectory.path, 'exam25b.db');
      return await openDatabase(path, version: 1, onCreate: _onCreate);
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future _onCreate(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE allEntries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date VARCHAR(30),
        type VARCHAR(30),
        duration int,
        distance int,
        calories int,
        rate int
      )
        ''');

      await db.execute('''
      CREATE TABLE dates(
        date VARCHAR(30) PRIMARY KEY
        )
        ''');
      await db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date VARCHAR(30),
        type VARCHAR(30),
        duration int,
        distance int,
        calories int,
        rate int
      )
        ''');

      log.info("Tables Created!");
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Entity?> addAll(EntityDTOWithID entity) async {
    Database? db = await instance.database;
    int? id = await db?.insert(tableNameAllEntries, entity.toMap());
    if (id != null) {
      log.info("Entry added to database");
      return Entity(
          id: id,
          date: entity.date,
          type: entity.type,
          distance: entity.distance,
          duration: entity.duration,
          calories: entity.calories,
          rate: entity.rate);
    }
    return null;
  }

  Future<HashMap<String, int>> getDistanceForType() async {
    Database? db = await instance.database;
    var entries = await db!.rawQuery("SELECT type, COUNT(distance) FROM allEntries GROUP BY type");

    HashMap<String, int> result = HashMap();
    try{
      for(int i = 0; i < entries.length; i++){
        result[entries[i].keys.first] = int.parse(entries[i].values.first.toString());
      }
    }
    catch(e){
      print(e.toString());
    }
    log.info("Distance for every type - database");
    return result;
  }

  Future<List<String>> getAll() async {
    Database? db = await instance.database;
    var entities = await db!.query(tableNameDates);

    List<String> entityList = [];
    try {
      for (int i = 0; i < entities.length; i++) {
        entityList.add(fromJson(entities[i]));
      }
    } catch (e) {
      print(e.toString());
    }
    log.info("Dates loaded from database");
    return entityList;
  }

  Future<void> clearItemsForCategory(String date) async {
    Database? db = await instance.database;
    await db?.delete(
      tableNameEntries,
      where: "date = ?",
      whereArgs: [date],
    );
    log.info("Items with date = $date -> deleted from database");
  }

  Future<void> clearCategoriesTable() async {
    Database? db = await instance.database;
    db?.delete(tableNameDates);

    log.info("Items for date table -> deleted from database");
  }

  Future<void> clearAllTable() async{
    Database? db = await instance.database;
    db?.delete(tableNameAllEntries);

    log.info("Items for all table -> deleted from database");
  }

  Future<void> clearTables() async {
    Database? db = await instance.database;
    db?.delete(tableNameDates);
    db?.delete(tableNameEntries);
    log.info("Tables deleted from database");
  }

  String fromJson(Map<String, dynamic> json) {
    return json["date"];
  }

  Future<Entity?> getById(int id) async {
    Database? db = await instance.database;

    var possibleEntities =
    await db?.query(tableNameDates, where: 'id = ?', whereArgs: [id]);

    Entity? foundEntity = null;
    try {
      for (int i = 0; i < possibleEntities!.length; i++) {
        foundEntity = Entity.fromJson(possibleEntities[i]);
        break;
      }
    } catch (e) {
      print(e.toString());
    }
    log.info("Date with $id loaded from database");

    return foundEntity;
  }

  Map<String, dynamic> toMap(String date) {
    return {'date': date};
  }

  Future<String?> add(String entity) async {
    Database? db = await instance.database;
    try {
      int? id = await db?.insert(tableNameDates, toMap(entity));
      if (id != null) {
        log.info("Date added to database");
        return entity;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Entity?> update(Entity entity) async {
    Database? db = await instance.database;
    db?.update(tableNameDates, entity.toMap(),
        where: 'id = ?', whereArgs: [entity.id]);

    try {
      Entity? updatedActivities = await getById(entity.id);
      log.info("Date updated -> database");
      return updatedActivities!;
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future remove(int id) async {
    Database? db = await instance.database;
    try {
      await db?.delete(tableNameDates, where: 'id = ?', whereArgs: [id]);
      log.info("Date with $id removed from database");
    } catch (e) {
      print(e.toString());
    }
  }

  Future<List<Entity>> getAllItems() async {
    Database? db = await instance.database;
    var entities = await db!.query(tableNameEntries);

    List<Entity> entityList = [];
    try {
      for (int i = 0; i < entities.length; i++) {
        entityList.add(Entity.fromJson(entities[i]));
      }
    } catch (e) {
      print(e.toString());
    }
    log.info("Entries loaded from database");

    return entityList;
  }

  Future<List<Entity>> getAllEntriesByDate(String genre) async {
    Database? db = await instance.database;
    var entities = await db!
        .query(tableNameEntries, where: 'date = ?', whereArgs: [genre]);

    List<Entity> entityList = [];
    try {
      for (int i = 0; i < entities.length; i++) {
        entityList.add(Entity.fromJson(entities[i]));
      }
      log.info("Entries for date = $genre -> loaded from database");
    } catch (e) {
      print(e.toString());
    }
    return entityList;
  }

  Future<Entity?> getByIdItems(int id) async {
    Database? db = await instance.database;

    var possibleEntities =
    await db?.query(tableNameEntries, where: 'id = ?', whereArgs: [id]);

    Entity? foundEntity = null;
    try {
      for (int i = 0; i < possibleEntities!.length; i++) {
        foundEntity = Entity.fromJson(possibleEntities[i]);
        break;
      }
    } catch (e) {
      print(e.toString());
    }
    log.info("Entry with id $id -> loaded from database");
    return foundEntity;
  }

  Future<String?> getItemByCategory(String category) async {
    Database? db = await instance.database;

    var possibleEntities = await db?.query(tableNameDates,
        where: 'date = ?', whereArgs: [category]);

    String? foundEntity = null;
    try {
      for (int i = 0; i < possibleEntities!.length; i++) {
        foundEntity = fromJson(possibleEntities[i]);
        break;
      }
    } catch (e) {
      print(e.toString());
    }
    log.info("Date $category -> loaded from database");
    return foundEntity;
  }

  Future<Entity?> addItems(EntityDTOWithID entity) async {
    Database? db = await instance.database;
    int? id = await db?.insert(tableNameEntries, entity.toMap());
    if (id != null) {
      log.info("Entry added to database");
      return Entity(
          id: entity.id,
          date: entity.date,
          type: entity.type,
          duration: entity.duration,
          distance: entity.distance,
          calories: entity.calories,
          rate: entity.rate);
    }
    return null;
  }

  Future<Entity?> addItemsWithoutID(EntityDTO entity) async {
    Database? db = await instance.database;
    int? id = await db?.insert(tableNameEntries, entity.toMap());
    if (id != null) {
      log.info("Entry added to database");
      return Entity(
          id: id,
          date: entity.date,
          type: entity.type,
          distance: entity.distance,
          duration: entity.duration,
          calories: entity.calories,
          rate: entity.rate);
    }
    return null;
  }

  Future<Entity?> updateItems(Entity entity) async {
    Database? db = await instance.database;
    db?.update(tableNameEntries, {'price': entity.rate},
        where: 'id = ?', whereArgs: [entity.id]);

    try {
      Entity? updatedActivities = await getByIdItems(entity.id);
      log.info("Entry updated to database");
      return updatedActivities!;
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future removeItems(int id) async {
    Database? db = await instance.database;
    try {
      await db?.delete(tableNameEntries, where: 'id = ?', whereArgs: [id]);
      log.info("Entry removed from database");
    } catch (e) {
      print(e.toString());
    }
  }
}
