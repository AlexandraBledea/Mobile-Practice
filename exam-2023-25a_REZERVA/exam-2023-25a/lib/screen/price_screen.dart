import 'dart:convert';

import 'package:exam_25a/screen/update_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/entity.dart';
import '../model/local_database_repository.dart';

class PriceScreenWidget extends StatefulWidget {
  const PriceScreenWidget({Key? key}) : super(key: key);

  @override
  State<PriceScreenWidget> createState() => _PriceScreenWidgetState();
}

class _PriceScreenWidgetState extends State<PriceScreenWidget> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isUpdateLoading = false;

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalDatabaseRepository>(context);
    var items = storage.getDiscountedItems();

    return Scaffold(
      body: FutureBuilder(
        future: items,
        builder: (context, snapshot) {
          if (storage.connected.value == ConnectionStatus.DISCONNECTED) {
            const Text("You are not connected!");
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            var entities = snapshot.data;
            return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: entities?.length,
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                      child: Card(
                          color: Colors.white70,
                          child: ListTile(
                            title: Column(children: [
                              Text("Name: ${entities![index].name}"),
                              Text(
                                  "Description: ${entities[index]
                                      .description}"),
                              Text("Image: ${entities[index].image}"),
                              Text("Units: ${entities[index].units}"),
                              Text("Price: ${entities[index].price}")
                            ]),
                            trailing: SizedBox(
                              width: 70,
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: !isUpdateLoading ? ElevatedButton(
                                          child: SizedBox(
                                            width: MediaQuery
                                                .of(context)
                                                .size
                                                .width /
                                                2,
                                            child: Column(
                                              mainAxisSize:
                                              MainAxisSize.min,
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: const [
                                                Text("Update"),
                                              ],
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                      builder: (context) {
                                                        return UpdateScreenState(
                                                            storage
                                                                .discountedItems[index]);
                                                      }
                                                  ));
                                            });
                                          }
                                      ) : const Center(
                                          child: CircularProgressIndicator())
                                  )
                                ],
                              ),
                            ),
                          )));
                });
          }}),
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Intensity Section"),
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            return [
              const PopupMenuItem<int>(
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
