import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'model/entity.dart';
import 'model/local_database_repository.dart';
import 'screen/main_screen.dart';
import 'websocket.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    Logger.root.level = Level.ALL; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Workout app';

    return CupertinoApp(
        home: MultiProvider(providers: [
          ChangeNotifierProvider.value(
            value: LocalDatabaseRepository(),
          ),
        ], child: const MaterialApp(title: appTitle, home: MainScreen())));
  }
}
