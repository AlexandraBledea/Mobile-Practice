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
  List<Entity> items = [];
  List<String> categories = [];

  late Future<List<Entity>> futureDiscountedItems = getDiscountedItems();
  List<Entity> discountedItems = [];
  HashMap<String, bool> categoryJustAdded = HashMap<String, bool>();

  late Future<List<String>> futureCategories;
  HashMap<String, List<Entity>> categoryItems = HashMap<String, List<Entity>>();

  static final String urlServer = "http://10.0.2.2:2325";

  ValueNotifier<ConnectionStatus> connected =
      ValueNotifier(ConnectionStatus.DISCONNECTED);

  static final ValueNotifier<bool> notifier = ValueNotifier(false);
  static final log = Logger('ActivityService');

  StreamController<ConnectivityResult> connectivityController =
      StreamController<ConnectivityResult>(sync: true);

  LocalDatabaseRepository() {

    futureDiscountedItems = getDiscountedItems();
    futureCategories = getCategories();
    notifyListeners();
    for (String genre in categories) {
      categoryItems[genre] = [];
    }
  }

  Future<List<Entity>> getDiscountedItems() async{
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      var url = Uri.parse(urlServer + "/discounted");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        discountedItems = jsonDecode(response.body)
            .map<Entity>((t) => Entity.fromJson(t))
            .toList() as List<Entity>;
      } else {}

      discountedItems.sort((e1, e2) =>
      (e1.price > e2.price || (e1.price == e2.price && e1.units > e2.units)) ? 1 : 0
      );

      discountedItems = discountedItems.take(10).toList();
      return discountedItems;
    } else {
      connected.value = ConnectionStatus.DISCONNECTED;
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      connected.value = ConnectionStatus.CONNECTING;
      var url = Uri.parse(urlServer + "/categories");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        connected.value = ConnectionStatus.CONNECTED;
        categories = jsonDecode(response.body)
            .map<String>((t) => t.toString())
            .toList() as List<String>;

        log.info("GET " + urlServer + "/categories");
      } else {}

      notifyListeners();

      DatabaseHelper.instance.clearCategoriesTable();

      for (String item in categories) {
          await DatabaseHelper.instance.add(item);
          categoryItems[item] = [];
      }

      return categories;
    } else {
      log.info("Using existent genres offline");
      connected.value = ConnectionStatus.DISCONNECTED;
      categories = await DatabaseHelper.instance.getAll();

      for (String category in categories) {
        var items = await DatabaseHelper.instance.getAllItemsByCategory(category);
        categoryItems[category] = items;
      }

      return categories;
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

    log.info("connected: " + connected.value.toString());
    return connected.value;
  }

  Future<List<Entity>> getItems(String category) async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      connected.value = ConnectionStatus.CONNECTING;

      var url = Uri.parse(urlServer + "/items/" + category);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        items = jsonDecode(response.body)
            .map<Entity>((t) => Entity.fromJson(t))
            .toList() as List<Entity>;
      } else {}

      log.info("GET " + urlServer + "/items/" + category);

      categoryItems[category] = items;

      DatabaseHelper.instance.clearItemsForCategory(category);

      for (Entity item in items) {
        await DatabaseHelper.instance.addItems(EntityDTO(
            name: item.name,
            description: item.description,
            category: item.category,
            units: item.units,
            price: item.price,
            image: item.image));
      }

      connected.value = ConnectionStatus.CONNECTED;
      notifyListeners();
      return items;
    }
    else
    {
      connected.value = ConnectionStatus.DISCONNECTED;
      items = await DatabaseHelper.instance.getAllItemsByCategory(category);
      notifyListeners();
      return items;
    }
  }

  Future<Pair> addActivity(EntityDTO item) async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      connected.value = ConnectionStatus.CONNECTING;

      var url = Uri.parse(urlServer + "/item");
      var response = await http.post(url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(item.toMap()));

      if (response.statusCode != 200) {
        return Pair(response.body, ConnectionStatus.CONNECTED);
      }

      var res = await DatabaseHelper.instance.addItems(item);
      if (res != null) {
        add(item.category);
        addItem(res);
      }

      connected.value = ConnectionStatus.CONNECTED;

      log.info("POST " + urlServer + "/item");

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      notifyListeners();
      return Pair(response.body, ConnectionStatus.CONNECTED);
    } else {
      notifyListeners();
      connected.value = ConnectionStatus.DISCONNECTED;
      return Pair("ok", ConnectionStatus.DISCONNECTED);
    }
  }

  Future<Pair> deleteActivity(int id) async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      connected.value = ConnectionStatus.CONNECTING;

      var url = Uri.parse(urlServer + "/item/" + id.toString());
      var response = await http.delete(url, headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      });

      if (response.statusCode != 200) {
        return Pair(response.body, ConnectionStatus.CONNECTED);
      }

      connected.value = ConnectionStatus.CONNECTED;
      log.info("DELETE " + urlServer + "/item/" + id.toString());


      delete(id);
      await DatabaseHelper.instance.removeItems(id);


      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      notifyListeners();
      return Pair(response.body, ConnectionStatus.CONNECTED);
    } else {
      connected.value = ConnectionStatus.DISCONNECTED;
      return Pair("ok", ConnectionStatus.DISCONNECTED);
    }
  }

  Future<Pair> updateActivity(num price, int id) async {
    await checkConnectivity();
    if (connected.value == ConnectionStatus.CONNECTED) {
      connected.value = ConnectionStatus.CONNECTING;
      var url = Uri.parse("$urlServer/price");
      Map<String, dynamic> data = Map();
      data["id"] = id;
      data["price"] = price;

      var response = await http.post(url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: json.encode(data));

      if(response.statusCode != 200){
        return Pair(response.body, ConnectionStatus.CONNECTED);
      }

      connected.value = ConnectionStatus.CONNECTED;

      log.info("POST $urlServer/price");

      update(id);


      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return Pair(response.body, ConnectionStatus.CONNECTED);

    } else {
      connected.value = ConnectionStatus.DISCONNECTED;
      return Pair("ok", ConnectionStatus.DISCONNECTED);
    }
  }

  Future<void> add(String entity) async {
    await DatabaseHelper.instance.add(entity);
    bool found = false;
    for(String category in categories){
      if(category == entity){
        found = true;
      }
    }
    if(found == false) {
      categories.add(entity);
    }
    notifyListeners();
  }

  Entity findById(int id) {
    return items.firstWhere((element) => element.id == id);
  }

  Future<void> update(int id) async {
    Entity activity = findById(id);
    var updatedActivity = null;
    await DatabaseHelper.instance
        .update(activity)
        .then((value) => updatedActivity = value);

    int index = items.indexWhere((element) => element.id == activity.id);
    items[index] = updatedActivity!;
    notifyListeners();
  }

  void addItem(Entity entity){
    items.add(entity);
    var category = entity.category;
    categoryItems[category]?.add(entity);
    // notifyListeners();
  }

  void delete(int activity_id) {
    var item = findById(activity_id);
    var category = item.category;

    items.removeWhere((element) => element.id == activity_id);
    categoryItems[category]?.removeWhere((element) => element.id == activity_id);
    // notifyListeners();
  }



}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static const tableNameCategories = 'categories';
  static const tableNameItems = 'items';

  static Database? _database;

  Future<Database?> get database async => _database ??= await _initDatabase();

  void print(String error) async {
    final file = File('error_log.txt');
    //await file.writeAsString(error);
    print(error);
  }

  Future<Database?> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // await deleteDatabase(documentsDirectory.path);
    try {
      String path = join(documentsDirectory.path, 'items1.db');
      return await openDatabase(path, version: 1, onCreate: _onCreate);
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future _onCreate(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE categories(
        category VARCHAR(30) PRIMARY KEY
        )
        ''');
      await db.execute('''
      CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(30),
        description VARCHAR(30),
        category VARCHAR(30),
        image VARCHAR(30),
        units int,
        price real
      )
        ''');

    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> clearItemsForCategory(String category) async{
    Database? db = await instance.database;
      await db?.delete(
      tableNameItems,
      where: "category = ?",
      whereArgs: [category],);
  }

  Future<void> clearCategoriesTable() async{
    Database? db = await instance.database;
    db?.delete(tableNameCategories);
  }

  Future<void> clearTables() async {
    Database? db = await instance.database;
    db?.delete(tableNameCategories);
    db?.delete(tableNameItems);
  }

  String fromJson(Map<String, dynamic> json) {
    return json["category"];
  }

  Future<List<String>> getAll() async {
    Database? db = await instance.database;
    var entities = await db!.query(tableNameCategories);

    List<String> entityList = [];
    try {
      for (int i = 0; i < entities.length; i++) {
        entityList.add(fromJson(entities[i]));
      }
    } catch (e) {
      print(e.toString());
    }
    return entityList;
  }

  Future<Entity?> getById(int id) async {
    Database? db = await instance.database;

    var possibleEntities =
        await db?.query(tableNameCategories, where: 'id = ?', whereArgs: [id]);

    Entity? foundEntity = null;
    try {
      for (int i = 0; i < possibleEntities!.length; i++) {
        foundEntity = Entity.fromJson(possibleEntities[i]);
        break;
      }
    } catch (e) {
      print(e.toString());
    }
    return foundEntity;
  }

  Map<String, dynamic> toMap(String category) {
    return {'category': category};
  }

  Future<String?> add(String entity) async {
    Database? db = await instance.database;
    try {
      int? id = await db?.insert(tableNameCategories, toMap(entity));
      if (id != null) {
        return entity!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Entity?> update(Entity entity) async {
    Database? db = await instance.database;
    db?.update(tableNameCategories, entity.toMap(),
        where: 'id = ?', whereArgs: [entity.id]);

    try {
      Entity? updatedActivities = await getById(entity.id);
      return updatedActivities!;
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future remove(int id) async {
    Database? db = await instance.database;
    try {
      await db?.delete(tableNameCategories, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<List<Entity>> getAllItems() async {
    Database? db = await instance.database;
    var entities = await db!.query(tableNameItems);

    List<Entity> entityList = [];
    try {
      for (int i = 0; i < entities.length; i++) {
        entityList.add(Entity.fromJson(entities[i]));
      }
    } catch (e) {
      print(e.toString());
    }
    return entityList;
  }

  Future<List<Entity>> getAllItemsByCategory(String genre) async {
    Database? db = await instance.database;
    var entities = await db!
        .query(tableNameItems, where: 'category = ?', whereArgs: [genre]);

    List<Entity> entityList = [];
    try {
      for (int i = 0; i < entities.length; i++) {
        entityList.add(Entity.fromJson(entities[i]));
      }
    } catch (e) {
      print(e.toString());
    }
    return entityList;
  }

  Future<Entity?> getByIdItems(int id) async {
    Database? db = await instance.database;

    var possibleEntities =
        await db?.query(tableNameItems, where: 'id = ?', whereArgs: [id]);

    Entity? foundEntity = null;
    try {
      for (int i = 0; i < possibleEntities!.length; i++) {
        foundEntity = Entity.fromJson(possibleEntities[i]);
        break;
      }
    } catch (e) {
      print(e.toString());
    }
    return foundEntity;
  }

  Future<String?> getItemByCategory(String category) async {
    Database? db = await instance.database;

    var possibleEntities = await db?.query(tableNameCategories,
        where: 'category = ?', whereArgs: [category]);

    String? foundEntity = null;
    try {
      for (int i = 0; i < possibleEntities!.length; i++) {
        foundEntity = fromJson(possibleEntities[i]);
        break;
      }
    } catch (e) {
      print(e.toString());
    }
    return foundEntity;
  }

  Future<Entity?> addItems(EntityDTO entity) async {
    Database? db = await instance.database;
    int? id = await db?.insert(tableNameItems, entity.toMap());
    if (id != null) {
      return Entity(
          id: id,
          name: entity.name,
          description: entity.description,
          category: entity.category,
          image: entity.image,
          units: entity.units,
          price: entity.price)!;
    }
    return null;
  }

  Future<Entity?> updateItems(Entity entity) async {
    Database? db = await instance.database;
    db?.update(tableNameItems, entity.toMap(),
        where: 'id = ?', whereArgs: [entity.id]);

    try {
      Entity? updatedActivities = await getById(entity.id);
      return updatedActivities!;
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  Future removeItems(int id) async {
    Database? db = await instance.database;
    try {
      await db?.delete(tableNameItems, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print(e.toString());
    }
  }
}
