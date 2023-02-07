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

  var dateController = TextEditingController();
  var typeController = TextEditingController();
  var durationController = TextEditingController();
  var distanceController = TextEditingController();
  var caloriesController = TextEditingController();
  var rateController = TextEditingController();

  CreateScreenState();

  void showAlertDialog(BuildContext context, String message) {
    // set up the button
    Widget okButton = TextButton(
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
                            controller: dateController,
                            decoration: const InputDecoration(
                              labelText: "Date",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.person),
                        title: TextField(
                            controller: typeController,
                            decoration: const InputDecoration(
                              labelText: "Type",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.add_location_alt_outlined),
                        title: TextField(
                            controller: durationController,
                            decoration: const InputDecoration(
                              labelText: "Duration",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.dehaze_outlined),
                        title: TextField(
                            controller: distanceController,
                            decoration: const InputDecoration(
                              labelText: "Distance",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.line_weight),
                        title: TextField(
                            controller: caloriesController,
                            decoration: const InputDecoration(
                              labelText: "Calories",
                            ))),
                    ListTile(
                        leading: const Icon(Icons.line_weight),
                        title: TextField(
                            controller: rateController,
                            decoration: const InputDecoration(
                              labelText: "Rate",
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
                                final regex = RegExp(r'[1-9][0-9]{3}-(1|2|3|4|5|6|7|8|9|10|11|12)-(1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)');

                                var caloriesInt =
                                    int.tryParse(caloriesController.text);
                                var rateInt =
                                    int.tryParse(rateController.text);
                                var durationInt =
                                int.tryParse(durationController.text);
                                var distanceInt =
                                int.tryParse(distanceController.text);

                                if (caloriesInt == null || rateInt == null || durationInt == null || distanceInt == null || durationInt <= 0 || !regex.hasMatch(dateController.text)) {
                                  showAlertDialog(context,
                                      'The provided entity details are invalid!');
                                  setState(() {
                                    isAddLoading = false;
                                  });
                                  return;
                                }

                                var result =
                                    await Provider.of<LocalDatabaseRepository>(
                                            context,
                                            listen: false)
                                        .addActivity(EntityDTO(
                                            date: dateController.text,
                                            type:
                                                durationController.text,
                                            duration: durationInt,
                                            distance: distanceInt,
                                            calories: caloriesInt,
                                            rate: rateInt));

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
    if (dateController.text.isEmpty) {
      errorText += "Date can't be empty.\n";
    }
    if (durationController.text.isEmpty) {
      errorText += "Duration can't be empty.\n";
    }
    if (typeController.text.isEmpty) {
      errorText += "Type can't be empty.\n";
    }
    if (distanceController.text.isEmpty) {
      errorText += "Distance can't be empty.\n";
    }
    if (caloriesController.text.isEmpty) {
      errorText += "Calories can't be empty.\n";
    }
    if (rateController.text.isEmpty) {
      errorText += "Rate can't be empty.\n";
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
