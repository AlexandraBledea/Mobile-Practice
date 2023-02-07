import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/local_database_repository.dart';

class ProgressScreenWidget extends StatefulWidget {
  const ProgressScreenWidget({Key? key}) : super(key: key);

  @override
  State<ProgressScreenWidget> createState() => _ProgressScreenWidgetState();
}

class _ProgressScreenWidgetState extends State<ProgressScreenWidget> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalDatabaseRepository>(context);
    return Scaffold(
      body: FutureBuilder(
        future: storage.futureTop3Types,
        builder: (context, snapshot) {
          if (storage.connected.value == ConnectionStatus.DISCONNECTED) {
            Text("You are not connected!");
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return Column(
              children: [
                const SizedBox(height: 10),
                // Expanded(
                //     child: ListView.builder(
                //         padding: const EdgeInsets.all(8),
                //         itemCount: storage.top3TypesList.length,
                //         itemBuilder: (BuildContext context, int index) {
                //           return InkWell(
                //             child: Card(
                //                 color: Colors.white70,
                //                 child: ListTile(
                //                   title: Column(children: [
                //                     Text(storage.top3TypesList[index].year
                //                         .toString()),
                //                     Text(storage.yearitems[
                //                     storage.yearitemsList[index].year]
                //                         .toString()),
                //                   ]),
                //                   trailing: SizedBox(
                //                     width: 70,
                //                     child: Row(
                //                       mainAxisAlignment:
                //                       MainAxisAlignment.spaceBetween,
                //                       children: [],
                //                     ),
                //                   ),
                //                 )),
                //           );
                //         })),
                Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: storage.top3TypesList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return InkWell(
                            child: Card(
                                color: Colors.white70,
                                child: ListTile(
                                  title: Column(children: [
                                    Text(storage.top3TypesList[index].type
                                        .toString()),
                                    Text(storage.top3Types[storage.top3TypesList[index].type]
                                        .toString()),
                                  ]),
                                  trailing: SizedBox(
                                    width: 70,
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [],
                                    ),
                                  ),
                                )),
                          );
                        })),
              ],
            );
          }
        },
      ),
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Intensity Section"),
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            return [
              PopupMenuItem<int>(
                value: 0,
                child: Text("Main"),
              )
            ];
          }, onSelected: (value) {
            if (value == 0) {
              Navigator.pop(context);
            }
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
