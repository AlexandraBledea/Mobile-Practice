import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/entity.dart';
import '../model/local_database_repository.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  State<CreateScreen> createState() => CreateScreenState();
}

class CreateScreenState extends State<CreateScreen> {
  bool isAddLoading = false;

  var nameController = TextEditingController();
  var categoryController = TextEditingController();
  var descriptionController = TextEditingController();
  var imageController = TextEditingController();
  var unitsController = TextEditingController();
  var priceController = TextEditingController();

  CreateScreenState();

  void showAlertDialog(BuildContext context, String message) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Scaffold(
            appBar: AppBar(),
            body: SingleChildScrollView(
              child: Form(
                child: Column(
                  children: [
                    ListTile(
                        leading: const Icon(Icons.person),
                        title: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: "Name",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.person),
                        title: TextField(
                            controller: categoryController,
                            decoration: const InputDecoration(
                              labelText: "Category",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.add_location_alt_outlined),
                        title: TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: "Description",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.dehaze_outlined),
                        title: TextField(
                            controller: imageController,
                            decoration: const InputDecoration(
                              labelText: "Image",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.line_weight),
                        title: TextField(
                            controller: unitsController,
                            decoration: const InputDecoration(
                              labelText: "Units",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.line_weight),
                        title: TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: "Price",
                            ))),
                    Center(
                      child: !isAddLoading
                          ? ElevatedButton(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 2,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text("Add item"),
                                  ],
                                ),
                              ),
                              onPressed: () async {
                                setState(() {
                                  isAddLoading = true;
                                });

                                String validationErrors = getValidationErrors();
                                if (validationErrors.isNotEmpty) {
                                  _showAlertInvalidFieldsDialog(
                                      "Error", validationErrors);
                                  setState(() {
                                    isAddLoading = false;
                                  });
                                  return;
                                }

                                var unitsInt =
                                    int.tryParse(unitsController.text);
                                var priceNum =
                                    num.tryParse(priceController.text);

                                if (unitsInt == null || priceNum == null) {
                                  showAlertDialog(context,
                                      'The provided entity details are invalid!');
                                  return;
                                }

                                var result =
                                    await Provider.of<LocalDatabaseRepository>(
                                            context,
                                            listen: false)
                                        .addActivity(EntityDTO(
                                            name: nameController.text,
                                            description:
                                                descriptionController.text,
                                            image: imageController.text,
                                            category: categoryController.text,
                                            units: unitsInt,
                                            price: priceNum));

                                setState(() {
                                  isAddLoading = false;
                                });

                                if (result.left is String &&
                                    result.left != "ok") {
                                  final snackBar = SnackBar(
                                    content: Text(result.left as String),
                                  );

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                  Navigator.pop(context);
                                  return;
                                }

                                if (result.right is ConnectionStatus &&
                                    result.right ==
                                        ConnectionStatus.DISCONNECTED) {
                                  const snackBar = SnackBar(
                                    content: Text(
                                        "Add is not possible while offline!"),
                                  );

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                  Navigator.pop(context);
                                }
                              },
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                ),
              ),
              // );}
            )));
  }

  String getValidationErrors() {
    // validations
    String errorText = '';
    if (nameController.text.isEmpty) {
      errorText += "Name can't be empty.\n";
    }
    if (descriptionController.text.isEmpty) {
      errorText += "Description can't be empty.\n";
    }
    if (categoryController.text.isEmpty) {
      errorText += "Category can't be empty.\n";
    }
    if (imageController.text.isEmpty) {
      errorText += "Image can't be empty.\n";
    }
    if (unitsController.text.isEmpty) {
      errorText += "Units can't be empty.\n";
    }
    if (priceController.text.isEmpty) {
      errorText += "Price can't be empty.\n";
    }
    return errorText;
  }

  void _showAlertInvalidFieldsDialog(String title, String message) {
    AlertDialog alertDialog = AlertDialog(
      title: Text(title, style: const TextStyle(color: Colors.black)),
      content: Text(message, style: const TextStyle(color: Colors.black)),
    );
    showDialog(context: context, builder: (_) => alertDialog);
  }
}
