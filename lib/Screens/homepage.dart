import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:petrinets_test/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'petri_net_screen.dart';
import '../petri_net.dart';

void main() {
  runApp( MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body:  SplashScreen(),
    ),
  ));
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading by delaying for a few seconds
    Timer(Duration(seconds: 5), () {
      // Navigate to your main screen
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => Homepage(), // Replace with your main screen
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
              SizedBox(height: 20),
              CircularProgressIndicator(), // Loading indicator
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
  List<SavedPetriNet> savedPetriNets = [];

  @override
  void initState() {
    super.initState();
    loadSavedPetriNets();
  }

  Future<void> loadSavedPetriNets() async {

    savedPetriNets;
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));
    savedPetriNets.add(SavedPetriNet(name: 'Dummy Petri Net'));





  }

  @override
  Widget build(BuildContext context) {
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/Petrinets-Logo-dark.png', width: 250, height: 150),
                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => PetriNetScreen(onSavePressed: onSaveButtonPressed)));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                              ),
                              child: Icon(Icons.add_circle_outline, size: 180, color: AppColors.backgroundColor.withOpacity(0.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    // height: savedPetriNets.length<8 ? MediaQuery.of(context).size.height * 0.65 : MediaQuery.of(context).size.height,
                      // double.infinity
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor2.withOpacity(0.6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(0, 40, 0, 30),
                            child: Text(
                              "Saved Petri Nets",
                              style: TextStyle(
                                fontSize: 28,
                                fontFamily: "verdana",
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue,
                              ),
                            ),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 1.5,
                            child: Divider(
                              color: AppColors.blue.withOpacity(0.5),
                              thickness: 2,
                              indent: 20,
                              endIndent: 20,
                            ),
                          ),
                          for (var i = 0; i < (savedPetriNets.length / 2).ceil(); i++)
                            Row(
                              children: [
                                Expanded(child: _buildSavedPetriNetBox(context, savedPetriNets[i * 2])),
                                if (i * 2 + 1 < savedPetriNets.length)
                                  Expanded(child: _buildSavedPetriNetBox(context, savedPetriNets[i * 2 + 1])),
                                if (i * 2 + 1 >= savedPetriNets.length && savedPetriNets.length.isOdd)
                                  Expanded(child: SizedBox()),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPetriNetBox(BuildContext context, SavedPetriNet savedPetriNet) {
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
          SizedBox(height: 10),
          Text(savedPetriNet.name, style: const TextStyle(fontSize: 20)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // IconButton(
              //   onPressed: () {
              //     // Navigate to edit petri net
              //   },
              //   icon: const Icon(Icons.edit),
              //   color: AppColors.darkBlue,
              // ),
              IconButton(
                onPressed: () {
                  // Simulate the petri net
                  _simulatePetriNet(savedPetriNet);
                },
                icon: const Icon(Icons.play_arrow,size: 35,),
                color: AppColors.darkBlue,
              ),
              IconButton(
                onPressed: () {
                  // Delete the petri net
                  _deletePetriNet(savedPetriNet);
                },
                icon: const Icon(Icons.delete),
                color: AppColors.darkBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }


  // Widget _buildSavedPetriNetBox(BuildContext context, SavedPetriNet savedPetriNet) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: AppColors.backgroundColor2.withOpacity(0.4),
  //       borderRadius: const BorderRadius.all(Radius.circular(25)),
  //       border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.blue.withOpacity(0.1),
  //           spreadRadius: 1,
  //           blurRadius: 4,
  //           offset: Offset(5, 7),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         const SizedBox(height: 10),
  //         Text(savedPetriNet.name, style: const TextStyle(fontSize: 20)),
  //         const SizedBox(height: 20),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: [
  //             IconButton(
  //               onPressed: () {
  //                 // Navigate to edit petri net
  //               },
  //               icon: const Icon(Icons.edit),
  //               color: AppColors.darkBlue,
  //             ),
  //             IconButton(
  //               onPressed: () {
  //                 // Simulate the petri net
  //                 _simulatePetriNet(savedPetriNet);
  //               },
  //               icon: const Icon(Icons.play_arrow),
  //               color: AppColors.darkBlue,
  //             ),
  //             IconButton(
  //               onPressed: () {
  //                 // Delete the petri net
  //                 _deletePetriNet(savedPetriNet);
  //               },
  //               icon: const Icon(Icons.delete),
  //               color: AppColors.darkBlue,
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void addSavedPetriNet(SavedPetriNet newPetriNet) {
    setState(() {
      savedPetriNets.add(newPetriNet);
    });
  }

// After a user has saved a Petri net, call this function to add it to the list.
  void onSaveButtonPressed(SavedPetriNet newPetriNet) {
    // Save the Petri net to your storage or database as needed.
    // Then add it to the list.
    addSavedPetriNet(newPetriNet);
  }




  void _simulatePetriNet(SavedPetriNet savedPetriNet) {
    // Implement logic to simulate the Petri net here
  }

  void _deletePetriNet(SavedPetriNet savedPetriNet) {
    // Implement logic to delete the Petri net here
  }
}


//try to extend petriNetGraph class
class SavedPetriNet {
  final String name;

  SavedPetriNet({
    required this.name,
  });

  factory SavedPetriNet.fromJson(Map<String, dynamic> json) {
    return SavedPetriNet(
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}
