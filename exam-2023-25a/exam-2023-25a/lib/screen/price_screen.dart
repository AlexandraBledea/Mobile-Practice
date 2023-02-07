
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

  Widget _buildListView() {
    final futureDiscountedItems = Provider.of<LocalDatabaseRepository>(context, listen: true).getDiscountedItems();

    return Scaffold( body:
    FutureBuilder(
        future: futureDiscountedItems,
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionStatus.DISCONNECTED) {
            const Text("You are not connected!");
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var entities = snapshot.data;
          entities?.left = entities.left ?? [];

          if (entities?.left.length == 0) {
            return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.blue.shade300,
                  ),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: const Text("Offline")
            );
          }

          return ListView.builder(
              itemCount: entities?.left.length,
              itemBuilder: (context, index) {
                var entity = entities?.left[index];

                if (entities?.left != [] && entity == null) {
                  return const Card();
                }
                else if (entity == null && index == 0) {
                  return const Card(
                      child: Text("Offline")
                  );
                }
                else if (entity == null) {
                  return const Card();
                }

                var card = Card(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.blue.shade300,
                    ),
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                      title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              entity.name,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 19.0,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              entity.description,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 19.0,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              entity.image,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 19.0,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              entity.category,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 19.0,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              entity.units.toString(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 19.0,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              entity.price.toString(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 19.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ]
                      ),

                      onTap: () => {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (context) {
                              return UpdateScreenState(entity);
                            }
                        ))
                      }
                  ),
                );

                if (entities?.right == false && index == 0) {
                  return Card(
                    child: Column(
                        children: [
                          const Text("Offline"),
                          card
                        ]
                    ),
                  );
                }

                return card;

              }

          );
        }
    ),
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
  Widget build(BuildContext context) {
    final storage = Provider.of<LocalDatabaseRepository>(context);
    // final infoMessage = storage.getInfoMessage();

    // if (infoMessage != '') {
    //   return AlertDialog(
    //     title: const Text('Alert'),
    //     content: SingleChildScrollView(
    //       child: ListBody(
    //         children: <Widget>[
    //           Text(infoMessage)
    //         ],
    //       ),
    //     ),
    //     actions: [
    //       TextButton(
    //         child: const Text("OK"),
    //         onPressed: () {
    //           // storage.setInfoMessage('');
    //         },
    //       )
    //     ],
    //   );
    // }

    return _buildListView();
  }
// return Scaffold(
//   body: FutureBuilder(
//     future: storage.futureDiscountedItems,
//     builder: (context, snapshot) {
//       if (storage.connected.value == ConnectionStatus.DISCONNECTED) {
//         const Text("You are not connected!");
//         return const Center(
//           child: CircularProgressIndicator(),
//         );
//       } else {
//         return Column(
//           children: [
//             const SizedBox(height: 10),
//             Expanded(
//                 child: ListView.builder(
//                     padding: const EdgeInsets.all(8),
//                     itemCount: storage.discountedItems.length,
//                     itemBuilder: (BuildContext context, int index) {
//                       return InkWell(
//                       child: Card(
//                           color: Colors.white70,
//                           child: ListTile(
//                             title: Column(children: [
//                               Text("Name: ${storage.discountedItems[index].name}"),
//                               Text(
//                                   "Description: ${storage.discountedItems[index].description}"),
//                               Text("Image: ${storage.discountedItems[index].image}"),
//                               Text("Units: ${storage.discountedItems[index].units}"),
//                               Text("Price: ${storage.discountedItems[index].price}")
//                             ]),
//                             trailing: SizedBox(
//                               width: 70,
//                               child: Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Expanded(
//                                       child: !isUpdateLoading ?ElevatedButton(
//                                           child: SizedBox(
//                                             width: MediaQuery.of(context)
//                                                     .size
//                                                     .width /
//                                                 2,
//                                             child: Column(
//                                               mainAxisSize:
//                                                   MainAxisSize.min,
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               children: const [
//                                                 Text("Update"),
//                                               ],
//                                             ),
//                                           ),
//                                           onPressed: () {
//                                             setState(() {
//                                               Navigator.of(context).push(MaterialPageRoute<void>(
//                                                   builder: (context) {
//
//                                                     return UpdateScreenState(storage.discountedItems[index]);
//
//                                                   }
//                                               ));
//                                             });
//                                           }
//                                           ): const Center(child: CircularProgressIndicator())
//                                   )
//                                 ],
//                               ),
//                             ),
//                           )));
//                     }))
//           ],
//         );
//       }
//     },
//   ),

}

