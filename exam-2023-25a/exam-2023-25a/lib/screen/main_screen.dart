import 'dart:convert';

import 'package:exam_25a/screen/price_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/entity.dart';
import '../model/local_database_repository.dart';
import '../websocket.dart';
import 'add_screen.dart';
import 'update_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  MainScreenState();

  late String currentlySelectedCategory = "";

  var isDeleteLoading = false;

  void showAreYouSureDialog(BuildContext context, int index,
      LocalDatabaseRepository storage, Entity entityToBeDeleted) {
    // set up the button
    Widget yesButton = ElevatedButton(
        child: const Text("Yes"),
        onPressed: () async {
          setState(() {
            isDeleteLoading = true;
          });

          var result = await storage.deleteActivity(entityToBeDeleted.id);

          setState(() {
            isDeleteLoading = false;
          });

          if (result.left is String && result.left != "ok") {
            final snackBar = SnackBar(
              content: Text(result.left as String),
            );

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            Navigator.of(context, rootNavigator: true).pop('dialog');
            return;
          }

          else {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            showAlertDialog(context, "Delete is not possible while offline!");
          }
        }
    );

    Widget cancelButton = ElevatedButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Error"),
      content: const Text('Are you sure you want to remove this entity?'),
      actions: [
        cancelButton,
        yesButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void showAlertDialog(BuildContext context, String message) {
    // set up the button
    Widget okButton = ElevatedButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Error"),
      content: Text(message),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }


  showAlertDialogForNotification(BuildContext context, Entity item) {
    // set up the button
    Widget okButton = ElevatedButton(
      child: const Text("Ok"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Notification"),
      actions: [okButton],
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Id: ${item.id}"),
        const SizedBox(
          height: 10.0,
        ),
        Text("Name: ${item.name}"),
        const SizedBox(
          height: 10.0,
        ),
        Text("Description: ${item.description}"),
        const SizedBox(
          height: 10.0,
        ),
        Text("Category: ${item.category}"),
        const SizedBox(
          height: 10.0,
        ),
        Text("Image: ${item.image}"),
        const SizedBox(
          height: 10.0,
        ),
        Text("Units: ${item.units}"),
        const SizedBox(
          height: 10.0,
        ),
        Text("Price: ${item.price}"),
        const SizedBox(
          height: 10.0,
        )
      ]),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalDatabaseRepository>(context);

    if (storage.connected.value == ConnectionStatus.CONNECTED) {
      storage.checkConnectivity().then((value) => {
            if (value == ConnectionStatus.CONNECTED)
              {
                if (!WebSocketInterface.isListened)
                  {
                    WebSocketInterface.listen().listen((event) {
                      if (!WebSocketInterface.isListened) {
                        setState(() {
                          WebSocketInterface.isListened = true;
                          Entity recipe = Entity.fromJson(json.decode(event));
                          print("Notification");
                          showAlertDialogForNotification(context, recipe);
                        });
                      }
                    })
                  }
              }
          });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Activities"),
      ),
      body: FutureBuilder(
          future: storage.futureCategories,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionStatus.CONNECTING) {
              const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (storage.connected.value != ConnectionStatus.CONNECTED) {
              if (storage.connected.value == ConnectionStatus.CONNECTING) {
                const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Column(
                children: <Widget>[
                  const Expanded(
                    child: Text("You are offline!"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_graph_outlined),
                    onPressed: () {
                      print("Retrying connection!");
                      storage.getCategories();
                    },
                  ),
                  PopupMenuButton(
                      // add icon, by default "3 dot" icon
                      // icon: Icon(Icons.book)
                      itemBuilder: (context) {
                    return [
                      const PopupMenuItem<int>(
                        value: 0,
                        child: Text("Price Section"),
                      ),
                    ];
                  }, onSelected: (value) {
                    if (storage.connected.value == ConnectionStatus.CONNECTED) {
                      if (value == 0) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const PriceScreenWidget(); //TODO PRICE SCREEN
                        }));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You are offline!')),
                      );
                    }
                  }),
                  const SizedBox(height: 10),
                  Expanded(
                      child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: storage.categories.length,
                          itemBuilder: (BuildContext context, int index) {
                            var item = storage.categories[index];
                            return InkWell(
                                child: Card(
                                    color: Colors.white70,
                                    child: ListTile(
                                      title: Column(children: [
                                        Text(storage.categories[index])
                                      ]),
                                      onTap: () {
                                        print("should change");
                                        currentlySelectedCategory = item;
                                        storage.getItems(item);
                                      },
                                    )));
                          })),
                  Expanded(
                      child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: storage.items.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                                color: Colors.white70,
                                child: ListTile(
                                  title: Column(children: [
                                    Text("Name: ${storage.items[index].name}"),
                                    Text("Description: ${storage.items[index].description}"),
                                    Text(
                                        "Image: ${storage.items[index].image}"),
                                    Text("Category: ${storage.items[index].category}"),
                                    Text("Units: ${storage.items[index].units}"),
                                    Text("Price: ${storage.items[index].price}")
                                  ]),
                                  trailing: SizedBox(
                                    width: 70,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                            child: ElevatedButton(
                                                child: SizedBox(
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                      2,
                                                  child: Column(
                                                    mainAxisSize:
                                                    MainAxisSize.min,
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                    children: const [
                                                      Text("X"),
                                                    ],
                                                  ),
                                                ),
                                                onPressed: () {
                                                  showAreYouSureDialog(context,
                                                      index,
                                                      storage,
                                                      storage.items[index]);
                                                }
                                            ))
                                      ],
                                    ),
                                  ),
                                ));
                          }))
                ],
              );
            }
            return Column(
              children: [
                PopupMenuButton(
                    // add icon, by default "3 dot" icon
                    // icon: Icon(Icons.book)
                    itemBuilder: (context) {
                  return [
                    const PopupMenuItem<int>(
                      value: 0,
                      child: Text("Intensity"),
                    )
                  ];
                }, onSelected: (value) {
                  if (storage.connected.value == ConnectionStatus.CONNECTED) {
                    if (value == 0) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const PriceScreenWidget(); //TODO PRICE SECTION
                      }));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You are offline!')),
                    );
                  }
                }),
                const SizedBox(height: 10),
                Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: storage.categories.length,
                        itemBuilder: (BuildContext context, int index) {
                          var item = storage.categories[index];
                          return InkWell(
                              child: Card(
                                  color: Colors.white70,
                                  child: ListTile(
                                    title: Column(children: [
                                      Text(storage.categories[index])
                                    ]),
                                    onTap: () {
                                      print("should change");
                                      currentlySelectedCategory = item;
                                      storage.getItems(item);
                                    },
                                  )));
                        })),
                Expanded(
                    child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: storage.items.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                              color: Colors.white70,
                              child: ListTile(
                                title: Column(children: [
                                  Text("Name: ${storage.items[index].name}"),
                                  Text("Description: ${storage.items[index].description}"),
                                  Text("Image: ${storage.items[index].image}"),
                                  Text("Category: ${storage.items[index].category}"),
                                  Text("Units: ${storage.items[index].units}"),
                                  Text("Price: ${storage.items[index].price}")
                                ]),
                                trailing: SizedBox(
                                  width: 70,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: !isDeleteLoading
                                            ? ElevatedButton(
                                                child: SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      2,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: const [
                                                      Text("X"),
                                                    ],
                                                  ),
                                                ),
                                                onPressed: () {
                                                    showAreYouSureDialog(context,
                                                        index,
                                                        storage,
                                                        storage.items[index]);
                                                }
                                              )
                                            : const Center(
                                                child:
                                                    CircularProgressIndicator()),
                                      )
                                    ],
                                  ),
                                ),
                              ));
                        }))
              ],
            );
          }),
      floatingActionButton: FloatingActionButton(
        heroTag: "add",
        onPressed: () => {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateScreen()),
          )
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
