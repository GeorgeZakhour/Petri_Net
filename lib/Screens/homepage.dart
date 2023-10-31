// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, await_only_futures

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:petrinets_test/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'petri_net_screen.dart';

void main() {
  runApp( const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body:  SplashScreen(),
    ),
  ));
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading by delaying for a few seconds
    Timer(const Duration(seconds: 5), () {
      // Navigate to your main screen
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const Homepage(), // Replace with your main screen
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkBlue.withOpacity(0.7), AppColors.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make the Scaffold's background transparent
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Your logo image
              Image.asset('assets/Petrinets-Logo2.png', width: 600, height: 600),
              const SizedBox(height: 20),
              const CircularProgressIndicator(), // Loading indicator
            ],
          ),
        ),
      ),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // List<SavedPetriNet> savedPetriNets = [];
  List<String> savedPetriNetNames = [];


  @override
  void initState() {
    super.initState();
    // loadSavedPetriNets();
    loadSavedPetriNetNames();
  }

  void loadSavedPetriNetNames() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming you have saved the names with a common prefix "petriNet_"
    Set<String> keys = prefs.getKeys().where((key) => key.startsWith('petriNet_')).toSet();
    setState(() {
      savedPetriNetNames = keys.map((key) => key.replaceAll('petriNet_', '')).toList();
      savedPetriNetNames = savedPetriNetNames.reversed.toList();

    });
  }

  // Future<void> loadSavedPetriNets() async {
  //
  //   savedPetriNets;
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //   savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
  //
  //
  //
  //
  //
  // }

  @override
  Widget build(BuildContext context) {
    loadSavedPetriNetNames();
    TextEditingController nameController = TextEditingController();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            Container(
              color: AppColors.blue2,
            ),
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.35,
                  floating: true,
                  elevation: 0,
                  pinned: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [AppColors.backgroundColor.withOpacity(0.8), AppColors.blue2],
                          center: const Alignment(-0.4, -0.7),
                          focal: const Alignment(-0.9, -2.2),
                          focalRadius: 0.01,
                          radius: 0.9,
                        ),
                      ),
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(flex:2, child: Container(margin:const EdgeInsets.only(top: 25),child: Image.asset('assets/Petrinets-Logo-dark.png', width: 250, height: 150))),
                          Expanded(flex: 5,
                            child: InkWell(
                              onTap: () {
                                // Navigator.push(context, MaterialPageRoute(builder: (context) => PetriNetScreen(onSavePressed: onSaveButtonPressed)));
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const PetriNetScreen(petriNetName: '')));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                ),
                                child: Icon(Icons.add_circle_outline, size: 210, color: AppColors.backgroundColor.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: savedPetriNetNames.length<7 ? MediaQuery.of(context).size.height * 0.65 : MediaQuery.of(context).size.height,
                      // double.infinity
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor2.withOpacity(0.6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: savedPetriNetNames.isNotEmpty ?Column(
                        children: [
                          Padding(
                            padding:  const EdgeInsets.fromLTRB(0, 40, 0, 30),
                            child: Text(
                                "Saved Petri Nets",
                                style: GoogleFonts.cairo(
                                  color: AppColors.darkBlue, // Set the text color to white
                                  fontSize: 37,
                                  fontWeight: FontWeight.w500
                                )
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: Divider(
                              color: AppColors.blue.withOpacity(0.5),
                              thickness: 2,
                              indent: 20,
                              endIndent: 20,
                            ),
                          ),
                          for (var i = 0; i < (savedPetriNetNames.length / 2).ceil(); i++)
                            Row(
                              children: [
                                Expanded(child: _buildSavedPetriNetBox(context, nameController,savedPetriNetNames[i * 2])),
                                if (i * 2 + 1 < savedPetriNetNames.length)
                                  Expanded(child: _buildSavedPetriNetBox(context, nameController, savedPetriNetNames[i * 2 + 1])),
                                if (i * 2 + 1 >= savedPetriNetNames.length && savedPetriNetNames.length.isOdd)
                                   const Expanded(child: SizedBox()),
                              ],
                            ),
                        ],
                      ) : Column(
                        children: [
                           Padding(
                            padding:  const EdgeInsets.fromLTRB(0, 40, 0, 30),
                            child: Text(
                              "Saved Petri Nets",
                                style: GoogleFonts.cairo(
                                  color: AppColors.darkBlue, // Set the text color to white
                                  fontSize: 42,
                                  // fontWeight: FontWeight.bold
                                )
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: Divider(
                              color: AppColors.blue.withOpacity(0.5),
                              thickness: 2,
                              indent: 20,
                              endIndent: 20,
                            ),
                          ),
                          SizedBox(height:MediaQuery.of(context).size.height*0.55,child: Center(child: Text(
                              "No saved Petri Nets",
                              style: GoogleFonts.cairo(
                                color: AppColors.darkBlue.withOpacity(0.4), // Set the text color to white
                                fontSize: 35,
                                // fontWeight: FontWeight.bold
                              )
                          )))
                        ],
                      ),
                    ) ,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPetriNetBox(BuildContext context, TextEditingController controller, String name) {
    String newName = ''; // Declare newName variable here

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor2.withOpacity(0.4),
        borderRadius: const BorderRadius.all(Radius.circular(25)),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(5, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(name, style: GoogleFonts.cairo(
            color: AppColors.darkBlue,
            fontSize: 32,
          )),
          SizedBox(
            width: MediaQuery.of(context).size.width / 3.5,
            child: Divider(
              color: AppColors.blue.withOpacity(0.5),
              thickness: 2,
              indent: 20,
              endIndent: 20,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () async {
                      String? newName = await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Enter a new name for the Petri net:'),
                            content: TextField(
                              controller: controller,
                              onChanged: (value) {},
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(controller.text);
                                },
                                child: const Text('Rename'),
                              ),
                            ],
                          );
                        },
                      );

                      if (newName != null && newName.isNotEmpty) {
                        // Check if the new name is different from the current name
                        if (newName != name) {
                          // Update the savedPetriNetList to reflect the new name
                          int index = savedPetriNetList.indexOf(name);
                          if (index != -1) {
                            savedPetriNetList[index] = newName;
                          }

                          // Rename the Petri net data in SharedPreferences with the new name
                          final prefs = await SharedPreferences.getInstance();
                          String? petriNetJson = await prefs.getString('petriNet_$name');
                          if (petriNetJson != null) {
                            // Modify the name in the data to the new name
                            Map<String, dynamic> petriNetData = json.decode(petriNetJson);
                            petriNetData['name'] = newName;

                            // Convert the modified data back to JSON
                            String updatedPetriNetJson = json.encode(petriNetData);

                            // Save the updated data with the new name in SharedPreferences
                            await prefs.setString('petriNet_$newName', updatedPetriNetJson);

                            // Remove the old saved Petri net data from SharedPreferences
                            await prefs.remove('petriNet_$name');
                          }

                          // Optionally, you can print a confirmation message if needed.
                          if (kDebugMode) {
                            print('Petri net data renamed from $name to $newName.');
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.drive_file_rename_outline_outlined, size: 40),
                    color: AppColors.darkBlue,
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.darkBlue,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Load the Petri net with the new name
                        loadPetriNetByName(newName.isNotEmpty ? newName : name);
                      },
                      // Replace the Icon with an Image widget
                      icon: const Icon(Icons.camera,size: 50,),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () {
                      // Delete the petri net
                      deletePetriNetByName(newName.isNotEmpty ? newName : name);
                    },
                    icon: const Icon(Icons.delete_forever_outlined, size: 40),
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }






  // Function to load a Petri net by its name.
  void loadPetriNetByName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    String? petriNetJson = await prefs.getString('petriNet_$name');

    if (petriNetJson != null) {
      // Parse and use the retrieved Petri net data.
      if (kDebugMode) {
        print('Loaded Petri Net [$name] is: $petriNetJson');
      }
      // You can then navigate to a screen to display the Petri net, passing the data.
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PetriNetScreen(petriNetName: name),
      ));
    }
  }



  // Function to delete a Petri net by its name.
  void deletePetriNetByName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('petriNet_$name');
    // Reload the list of saved Petri net names to reflect the deletion.
    loadSavedPetriNetNames();
    if (kDebugMode) {
      print('Deleted Petri Net [$name].');
    }
  }




// //try to extend petriNetGraph class
// class SavedPetriNet {
//   final String name;
//
//   SavedPetriNet({
//     required this.name,
//   });
//
//   factory SavedPetriNet.fromJson(Map<String, dynamic> json) {
//     return SavedPetriNet(
//       name: json['name'],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'name': name,
//     };
//   }
}
