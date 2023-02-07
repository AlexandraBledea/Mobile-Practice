// import 'package:exam_25a/model/entity.dart';
// import 'package:exam_25a/model/local_database_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// class UpdateScreenState extends StatefulWidget {
//   final Entity _item;
//
//   const UpdateScreenState(this._item, {Key? key}) : super(key: key);
//
//   @override
//   State<UpdateScreenState> createState() => UpdateScreen();
// }
//
// class UpdateScreen extends State<UpdateScreenState> {
//   bool isLoading = false;
//
//   void showAlertDialog(BuildContext context, String message) {
//     // set up the button
//     Widget okButton = TextButton(
//       child: const Text("OK"),
//       onPressed: () {
//         Navigator.pop(context);
//       },
//     );
//
//     // set up the AlertDialog
//     AlertDialog alert = AlertDialog(
//       title: const Text("Error"),
//       content: Text(message),
//       actions: [
//         okButton,
//       ],
//     );
//
//     // show the dialog
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return alert;
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     var nameController = TextEditingController();
//     nameController.text = widget._item.date;
//
//     var descriptionController = TextEditingController();
//     descriptionController.text = widget._item.type;
//
//     var imageController = TextEditingController();
//     imageController.text = widget._item.duration;
//
//     var unitsController = TextEditingController();
//     unitsController.text = widget._item.calories.toString();
//
//     var priceController = TextEditingController();
//     priceController.text = widget._item.rate.toString();
//
//     return Scaffold(
//         appBar: AppBar(
//           centerTitle: true,
//           title: const Text('Increment price by 1 unit'),
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               ListTile(
//                   leading: const Icon(Icons.person),
//                   title: TextField(
//                       readOnly: true,
//                       controller: nameController,
//                       decoration: const InputDecoration(
//                         labelText: "Name",
//                       ))),
//               ListTile(
//                   leading: const Icon(Icons.add_location_alt_outlined),
//                   title: TextField(
//                       readOnly: true,
//                       controller: descriptionController,
//                       decoration: const InputDecoration(
//                         labelText: "Description",
//                       ))),
//               ListTile(
//                   leading: const Icon(Icons.dehaze_outlined),
//                   title: TextField(
//                       readOnly: true,
//                       controller: imageController,
//                       decoration: const InputDecoration(
//                         labelText: "Image",
//                       ))),
//               ListTile(
//                   leading: const Icon(Icons.line_weight),
//                   title: TextField(
//                       readOnly: true,
//                       controller: unitsController,
//                       decoration: const InputDecoration(
//                         labelText: "Units",
//                       ))),
//               ListTile(
//                   leading: const Icon(Icons.line_weight),
//                   title: TextField(
//                       readOnly: true,
//                       controller: priceController,
//                       decoration: const InputDecoration(
//                         labelText: "Price",
//                       ))),
//               Center(
//                 child: !isLoading ? ElevatedButton(
//                   child: SizedBox(
//                     width: MediaQuery.of(context).size.width / 2,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: const [
//                         Text("Increment price by 1 unit"),
//                       ],
//                     ),
//                   ),
//                   onPressed: () async {
//                     setState(() {
//                       isLoading = true;
//                     });
//
//                     var result = await Provider.of<LocalDatabaseRepository>(context, listen: false).updateActivity(
//                         widget._item.rate + 1,
//                         widget._item.id
//                     );
//
//                     setState(() {
//                       isLoading = false;
//                     });
//
//                     if (result.left is String && result.left != "ok") {
//                       final snackBar = SnackBar(
//                         content: Text(result.left as String),
//                       );
//
//                       ScaffoldMessenger.of(context).showSnackBar(snackBar);
//                       Navigator.pop(context);
//                       return;
//                     }
//
//                     if (result.right is ConnectionStatus &&
//                         result.right ==
//                             ConnectionStatus.DISCONNECTED) {
//                       const snackBar = SnackBar(
//                         content: Text(
//                             "Add is not possible while offline!"),
//                       );
//
//                       ScaffoldMessenger.of(context)
//                           .showSnackBar(snackBar);
//                       Navigator.pop(context);
//                     }
//                   },
//                 ) : const Center(child:CircularProgressIndicator()),
//               ),
//             ],
//           ),
//         )
//     );
//   }
// }
