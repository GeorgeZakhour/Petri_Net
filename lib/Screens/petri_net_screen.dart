//petri_net_screen.dart

// ignore_for_file: unused_field, unused_local_variable, unused_element, unused_import, avoid_print, use_build_context_synchronously, constant_identifier_names, depend_on_referenced_packages, unnecessary_cast, unnecessary_null_comparison
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphview/GraphView.dart';
import 'package:petrinets_test/grid_pattern_bg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';


import '../colors.dart';
import '../petri_net.dart';
import 'homepage.dart';


const int MAX_DEPTH = 3;
Map<String, int> initialMarking = {};
List<String> savedPetriNetList = [];

enum NodeType { place, transition }

class PetriNetElement {
  final String id;
  final NodeType type;
  int tokens;

  void addToken() {
    tokens++;
  }

  PetriNetElement({required this.id, required this.type, this.tokens = 0});
}

class MyPlaceNode extends Node {
  final String id; // Add id property

  MyPlaceNode(this.id) : super.Id(id);
}

class MyTransitionNode extends Node {
  final String id; // Add id property

  MyTransitionNode(this.id) : super.Id(id);
}

class PetriNetWidgetController {
  void Function() addPlace = () {};
  void Function() addTransition = () {};
  void Function() addArc = () {};
  bool draggingElement = false;
  Key? selectedStartElementKey;

}

class PetriNetScreen extends StatefulWidget {
  final String petriNetName;

  const PetriNetScreen({super.key, required this.petriNetName});

  @override
  State<StatefulWidget> createState() => PetriNetScreenState();
}

//MAIN CLASS
class PetriNetScreenState extends State<PetriNetScreen> {
  final PetriNetWidgetController controller = PetriNetWidgetController();
  final Graph graph = Graph();
  final Map<String, PetriNetElement> elements = {};
  bool darkMode = true;
  bool simulationMode = false;
  bool gameMode = false;
  bool gameStarted = false;
  bool loss = false;
  bool noMarkings = false;
  bool isPetriNetSaved = true;
  Node? _sourceNode;
  Node? _targetNode;

  PetriNetGraph petriNetGraph = PetriNetGraph(
      places: [], transitions: [], connections: []);

  void loadPetriNetData(List<dynamic> data) {
    var petriNetGraph = PetriNetGraph(
        places: [], transitions: [], connections: []);

    for (var item in data) {

      if (item is PetriNetPlace) {
        final id = item.id;
        print('This Item is Place : $id');
        final place = PetriNetPlace(id: item.id, position: item.position, tokens: item.tokens);
        petriNetGraph.places.add(place);
        final placeNode = MyPlaceNode(item.id);
        placeNode.position = item.position;
        placeNode.tokens = item.tokens;
        _loadPlace(item.id, item.tokens, item.position);
        int currentPlaceIndex = getAlphabeticalIndex(item.id);
        placeCounter = max(placeCounter, currentPlaceIndex);
      }

      else if (item is PetriNetTransition) {
        final id = item.id;
        print('This Item is Transition : $id');
        final transition = PetriNetTransition(
            id: item.id, position: item.position);
        petriNetGraph.transitions.add(transition);
        final transitionNode = MyTransitionNode(item.id);
        transitionNode.position = item.position;
        _loadTransition(item.id, item.position);
        int currentTransitionIndex = int.parse(item.id);
        transitionCounter = max(transitionCounter, currentTransitionIndex);
      }

      else if (item is PetriNetArc) {
        final source = item.sourceId;
        final target = item.targetId;
        print('This Item is Arc : From $source to $target');
        final arc = PetriNetArc(
            sourceId: item.sourceId, targetId: item.targetId);
        petriNetGraph.connections.add(arc);
        _loadArc(RegExp(r'^[A-Za-z]$').hasMatch(item.sourceId) ? MyPlaceNode(
            item.sourceId) : MyTransitionNode(item.sourceId),
            RegExp(r'^[A-Za-z]$').hasMatch(item.targetId) ? MyPlaceNode(
                item.targetId) : MyTransitionNode(item.targetId));
      }
    }
  }

  Future<void> loadPetriNetGraphFromSharedPrefs() async {

    final prefs = await SharedPreferences.getInstance();
    final petriNetJson = prefs.getString('petriNet_${widget.petriNetName}');
    if (petriNetJson != null) {
      final Map<String, dynamic> petriNetData = json.decode(petriNetJson);
      final List<PetriNetPlace> places = (petriNetData['places'] as List<dynamic>)
          .map((placeData) => PetriNetPlace.fromJson(placeData))
          .toList();
      loadPetriNetData(places);

      final List<PetriNetTransition> transitions =
          (petriNetData['transitions'] as List<dynamic>)
          .map((transitionData) => PetriNetTransition.fromJson(transitionData))
          .toList();
      loadPetriNetData(transitions);

      final List<PetriNetArc> connections =
      (petriNetData['connections'] as List<dynamic>)
          .map((arcData) => PetriNetArc.fromJson(arcData))
          .toList();
      loadPetriNetData(connections);

      petriNetGraph = PetriNetGraph(
        places: places,
        transitions: transitions,
        connections: connections,
      );

      // Refresh the graph
      setState(() {});
    }
  }


  @override
  void initState() {
    super.initState();
    loadPetriNetGraphFromSharedPrefs();
  }


  MarkingWithTransitions fixedRandomMarking = MarkingWithTransitions(
      {}, []); // Initialize with an empty marking and transition sequence


  @override
  Widget build(BuildContext context) {
    final canvasWidth = MediaQuery
        .of(context)
        .size
        .width;
    final canvasHeight = MediaQuery
        .of(context)
        .size
        .height;
    final nodeSize = elements.length * 7.5;
    final placeSize = canvasWidth * 0.11;
    final transitionWidth = canvasWidth * 0.2;

    initialMarking = findMarking(graph.nodes);
    TextEditingController nameController = TextEditingController();


    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Container(
                width: canvasWidth,
                decoration: BoxDecoration(
                  image: gameMode ? const DecorationImage(
                    image: AssetImage('assets/question-marks.png'),
                    fit: BoxFit
                        .cover,
                  ) : null,
                  gradient: RadialGradient(
                    colors: simulationMode ? (darkMode ? [
                      AppColors.darkBlue.withOpacity(0.8),
                      AppColors.darkBlue
                    ] : [
                      AppColors.backgroundColor2.withOpacity(0.8),
                      AppColors.backgroundColor2
                    ])
                        : gameMode ? (darkMode ? [
                      Colors.black12.withOpacity(0.7),
                      Colors.black12.withOpacity(0.8)
                    ] : [
                      AppColors.backgroundColor2.withOpacity(0.8),
                      AppColors.backgroundColor2
                    ])
                        : (darkMode ? [
                      AppColors.darkBlue.withOpacity(0.8),
                      AppColors.darkBlue
                    ] : [
                      AppColors.backgroundColor2.withOpacity(0.8),
                      AppColors.backgroundColor2
                    ]),
                    center: const Alignment(-0.4, -0.1),
                    focal: const Alignment(-0.9, -0.9),
                    focalRadius: 0.01,
                    radius: 0.7,
                  ),),
                child: GridPatternBackground(
                  color: simulationMode ? AppColors.blue : gameMode ? Colors
                      .transparent : AppColors.blue,
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        if (graph.nodes.isEmpty) {
                          return Container();
                        } else {
                          return InteractiveViewer(
                            constrained: false,
                            boundaryMargin: const EdgeInsets.all(100),
                            minScale: 0.01,
                            maxScale: 5.6,
                            child: GraphView(
                              graph: graph,
                              algorithm: FruchtermanReingoldAlgorithm(
                                repulsionRate: 0,
                                attractionRate: 1,
                                repulsionPercentage: 0.1,
                                attractionPercentage: 1,
                                edgeColor: AppColors.yellow,
                              ),
                              paint: Paint()
                                ..color = Colors.white
                                ..strokeWidth = 2.0
                                ..style = PaintingStyle.stroke,
                              builder: (Node? node) {
                                if (node == null) {
                                  return Container();
                                }
                                return simulationMode || gameMode
                                    ? GestureDetector(
                                  onTap: () => _onNodeTap(node),
                                  child: _buildNodeWidget(node, nodeSize),
                                )
                                    : Draggable(
                                  feedback: node is MyPlaceNode
                                      ?
                                  _feedbackPlace(
                                      max(placeSize - nodeSize * 0.9 - 20, 50))
                                      : (node is MyTransitionNode
                                      ? DottedBorder(
                                    dashPattern: const [5, 10],
                                    color: darkMode ? Colors.white : Colors
                                        .black,
                                    strokeWidth: 2,
                                    child: SizedBox(
                                      width: max(
                                          (transitionWidth - nodeSize) * 0.7,
                                          25),
                                      height: max(
                                          (transitionWidth - nodeSize) / 2 *
                                              0.7, 12),
                                    ),
                                  )
                                      : Container()),
                                  child: GestureDetector(
                                    onTap: () => _onNodeTap(node),
                                    child: _buildNodeWidget(node, nodeSize),
                                  ),
                                  onDraggableCanceled: (velocity, offset) {
                                    setState(() {
                                      if (node is MyPlaceNode ||
                                          node is MyTransitionNode) {
                                        final nodeId = node is MyPlaceNode
                                            ? (node as MyPlaceNode).id
                                            : (node as MyTransitionNode).id;
                                        petriNetGraph.updateNodePosition(
                                            nodeId, offset);
                                      }
                                      node.position = offset;
                                      isPetriNetSaved = false;
                                    }
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery
                  .of(context)
                  .size
                  .height / 20,
              left: simulationMode || gameMode ? 30 : 10,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          simulationMode || gameMode
                              ? const SizedBox()
                              : Container(

                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 20, bottom: 20),
                            margin: simulationMode || gameMode
                                ? const EdgeInsets.all(0)
                                : const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: darkMode
                                  ? Colors.blue.withOpacity(0.2)
                                  : const Color(0xFF0E2046).withOpacity(0.8),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3),
                            ),
                            child: Tooltip(
                              message: 'Back to Homepage',
                              child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      Navigator.pop(
                                          context); // Navigate back to the homepage
                                    });
                                  },
                                  child: Icon(Icons.arrow_back_outlined,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 40)),
                            ),
                          ),
                          Container(

                            padding: EdgeInsets.only(
                                left: simulationMode || gameMode ? 30 : 20,
                                right: simulationMode || gameMode ? 30 : 20,
                                top: simulationMode || gameMode ? 30 : 100,
                                bottom: simulationMode || gameMode ? 30 : 100),
                            decoration: BoxDecoration(
                              color: gameMode
                                  ? Colors.grey.withOpacity(0.5)
                                  : darkMode
                                  ? Colors.blue.withOpacity(0.2)
                                  : const Color(0xFF0E2046).withOpacity(0.8),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Tooltip(
                                  message: 'Simulate',
                                  child: GestureDetector(
                                      onTap: graph.edges.length > 1
                                          ? () {
                                        setState(() {
                                          simulationMode ? (
                                              simulationMode = !simulationMode)
                                              : gameMode
                                              ? (simulationMode = false,
                                          gameMode = false, userHints = 3,
                                          gameStarted = false)
                                              : simulationMode =
                                          !simulationMode;
                                        });
                                      } : null,
                                      child: Icon(
                                          simulationMode || gameMode ? Icons
                                              .arrow_back_outlined : graph.edges
                                              .length < 2 ? Icons
                                              .camera_outlined : Icons.camera,
                                          color: graph.edges.length < 2 ? Colors
                                              .white.withOpacity(0.3) : Colors
                                              .white, size: 40)),


                                ),
                                simulationMode || gameMode
                                    ? const SizedBox()
                                    : Column(
                                  children: [
                                    const SizedBox(height: 40),
                                    Container(width: 40,
                                        height: 2,
                                        color: Colors.white.withOpacity(0.3)),
                                    const SizedBox(height: 40),
                                    Tooltip(
                                      message: 'Add Place',
                                      child: GestureDetector(
                                          onTap: _addPlace,
                                          child: const Icon(
                                              Icons.circle_outlined,
                                              color: Colors.white, size: 40)),
                                    ),
                                    const SizedBox(height: 40),
                                    Tooltip(
                                      message: 'Add Transition',
                                      child: GestureDetector(
                                          onTap: _addTransition,
                                          child: const Icon(Icons
                                              .check_box_outline_blank_sharp,
                                              color: Colors.white, size: 40)),
                                    ),
                                    const SizedBox(height: 40),
                                    Tooltip(
                                      message: 'Add Arc',
                                      child: GestureDetector(
                                          onTap: _addArc,
                                          child: const Icon(
                                              Icons.arrow_right_alt_sharp,
                                              color: Colors.white, size: 40)),
                                    ),
                                    const SizedBox(height: 40),
                                    Tooltip(
                                      message: 'Add Tokens',
                                      child: GestureDetector(
                                          onTap: () =>
                                              _addTokenToSelectedElement(),
                                          child: const Icon(
                                              Icons.generating_tokens,
                                              color: Colors.white, size: 40)),
                                    ),
                                    const SizedBox(height: 40),
                                    Tooltip(
                                      message: 'Delete Tokens',
                                      child: GestureDetector(
                                          onTap: () =>
                                              _deleteTokenToSelectedElement(),
                                          child: const Icon(
                                              Icons.generating_tokens_outlined,
                                              color: Colors.white, size: 40)),
                                    ),
                                    const SizedBox(height: 40),
                                    Container(width: 40,
                                        height: 2,
                                        color: Colors.white.withOpacity(0.5)),
                                    const SizedBox(height: 40),
                                    Tooltip(
                                      message: 'Delete',
                                      child: GestureDetector(
                                          onTap: () => _deleteNode(),
                                          child: Icon(Icons.delete_forever,
                                              color: Colors.white.withOpacity(
                                                  0.8), size: 40)),
                                    ),
                                  ],
                                ),


                              ],
                            ),
                          ),

                          simulationMode || gameMode
                              ? const SizedBox()
                              : Container(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 20, bottom: 20),
                            margin: const EdgeInsets.only(top: 20),
                            decoration: BoxDecoration(
                              color: isPetriNetSaved ? Colors.blue.withOpacity(
                                  0.2) : darkMode
                                  ? Colors.blue.withOpacity(0.2)
                                  : const Color(0xFF0E2046).withOpacity(0.8),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 3),
                            ),
                            child: Tooltip(
                              message: isPetriNetSaved
                                  ? 'Petri net is already saved.'
                                  : 'Save',
                              child: GestureDetector(
                                onTap: () async {
                                  if (isPetriNetSaved) {
                                    print('Petri net is already saved.');
                                  } else {
                                    if (petriNetGraph.places.isEmpty &&
                                        petriNetGraph.transitions.isEmpty) {
                                      setState(() {
                                        isPetriNetSaved = true;
                                      });
                                      print(
                                          'Petri net is empty. You cannot save an empty Petri net.');
                                    }
                                    else {
                                      // Show a dialog to get the name from the user.
                                      String? petriNetName = await showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text(
                                                'Enter a name for the Petri net:'),
                                            content: TextField(
                                              controller: nameController,
                                              // Use the controller to get user input.
                                              onChanged: (value) {
                                                // You can use this onChanged callback to validate the name if needed.
                                              },
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(); // Close the dialog without saving.
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                      nameController
                                                          .text); // Return the name to be saved.
                                                },
                                                child: const Text('Save'),
                                              ),
                                            ],
                                          );
                                        },
                                      );


                                      if (petriNetName != null &&
                                          petriNetName.isNotEmpty) {
                                        // Convert your PetriNetGraph to a JSON-serializable format
                                        Map<String, dynamic> petriNetData = {
                                          'name': petriNetName,
                                          'places': petriNetGraph.places.map((
                                              place) => place.toJson())
                                              .toList(),
                                          'transitions': petriNetGraph
                                              .transitions.map((transition) =>
                                              transition.toJson()).toList(),
                                          'connections': petriNetGraph
                                              .connections.map((arc) =>
                                              arc.toJson()).toList(),
                                        };
                                        String petriNetJson = json.encode(
                                            petriNetData);

                                        final prefs = await SharedPreferences
                                            .getInstance();

                                        // Save the data to shared preferences with the name as the key
                                        await prefs.setString(
                                            'petriNet_$petriNetName',
                                            petriNetJson);

                                        // Add the name to the list of saved Petri net names
                                        savedPetriNetList.add(petriNetName);

                                        // Update the saved state
                                        setState(() {
                                          isPetriNetSaved = true;
                                        });

                                        // Optionally, you can print a confirmation message if needed.
                                        print(
                                            'Petri net data saved and added to the list.');
                                      }
                                    }
                                  }
                                },
                                child: Icon(Icons.save,
                                    color: isPetriNetSaved ? Colors.white
                                        .withOpacity(0.3) : Colors.white,
                                    size: 40),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(width: 30),
                      simulationMode || gameMode ? GestureDetector(
                        onTap: () {
                          setState(() {
                            simulationMode = true;
                            gameMode = false;
                            userHints = 3;
                            gameStarted = false;
                          }
                          );
                        },
                        child: Container(

                          padding: const EdgeInsets.all(25),
                          margin: const EdgeInsets.only(left: 30),
                          decoration: BoxDecoration(
                            color: simulationMode ? darkMode ? Colors.blue
                                .withOpacity(0.5) : const Color(0xFF0E2046)
                                .withOpacity(0.8) : darkMode ? Colors.grey
                                .withOpacity(0.2) : const Color(0xFF0E2046)
                                .withOpacity(0.8),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            border: Border.all(
                                color: simulationMode ? Colors.blue : Colors
                                    .white.withOpacity(0.3),
                                width: simulationMode ? 9 : 3),
                          ),
                          child: Tooltip(
                            message: 'Simulation Mode',
                            child: GestureDetector(
                                onTap: null,
                                child: Row(
                                  children: [
                                    Icon(simulationMode ? Icons.camera : Icons
                                        .camera_outlined,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 50),
                                    const SizedBox(width: 20),
                                    Text(
                                        "Simulation Mode",
                                        style: GoogleFonts.cairo(
                                          color: Colors.white.withOpacity(0.6),
                                          // Set the text color to white
                                          fontSize: 35,
                                          // fontWeight: FontWeight.bold
                                        )
                                    )
                                  ],
                                )),
                          ),
                        ),
                      ) : const SizedBox(),
                      const SizedBox(width: 40),
                      simulationMode || gameMode ? GestureDetector(onTap: () {
                        setState(() {
                          gameMode = true;
                          simulationMode = false;
                        }
                        );
                      }
                        , child: Container(

                          padding: const EdgeInsets.all(25),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: gameMode ? darkMode ? Colors.redAccent
                                .withOpacity(0.4) : const Color(0xFF0E2046)
                                .withOpacity(0.8) : darkMode ? Colors.grey
                                .withOpacity(0.2) : const Color(0xFF0E2046)
                                .withOpacity(0.8),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                            border: Border.all(
                                color: gameMode ? Colors.redAccent : Colors
                                    .white.withOpacity(0.3),
                                width: gameMode ? 9 : 3),
                          ),
                          child: Tooltip(
                            message: 'Game Mode',
                            child: GestureDetector(
                                onTap: null,
                                child: Row(
                                  children: [
                                    Icon(gameMode
                                        ? Icons.videogame_asset_rounded
                                        : Icons.videogame_asset_off_outlined,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 50),
                                    const SizedBox(width: 20),
                                    Text(
                                        "Game Mode",
                                        style: GoogleFonts.cairo(
                                          color: Colors.white.withOpacity(0.6),
                                          // Set the text color to white
                                          fontSize: 35,
                                          // fontWeight: FontWeight.bold
                                        )
                                    )
                                  ],
                                )),
                          ),
                        ),
                      ) : const SizedBox(),
                    ],
                  ),
                ),
              ),
            ),


            gameMode ? Positioned(

              bottom: MediaQuery
                  .of(context)
                  .size
                  .height / 50,
              right: 80,
              left: 80,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: 'Your current marking:  ',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      // Set the text color to white
                                      fontSize: 28,
                                      // fontWeight: FontWeight.bold
                                    )
                                ),
                                TextSpan(
                                    text: '$initialMarking      ',
                                    style: GoogleFonts.cairo(
                                        color: Colors.orange,
                                        // Set the text color to white
                                        fontSize: 30,
                                        fontWeight: FontWeight.normal
                                    )
                                ),
                              ],
                            ),
                            textAlign: TextAlign
                                .center, // Center-align the text within the RichText widget
                          ),
                          const SizedBox(width: 50),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            // Adjust the padding as needed
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                  50), // Adjust the radius for rounded corners
                            ),
                            child: Row(
                              // alignment: Alignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '  Hints Left:  ',
                                        style: GoogleFonts.cairo(
                                          color: Colors.black, // Text color
                                          fontSize: 28,
                                          // fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  // Adjust the size of the orange circle as needed
                                  height: 50,
                                  // Adjust the size of the orange circle as needed
                                  decoration: BoxDecoration(
                                    color: userHints > 0
                                        ? Colors.orange
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$userHints',
                                      style: GoogleFonts.cairo(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )


                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width - 20,
                        height: MediaQuery
                            .of(context)
                            .size
                            .height / 6,
                        padding: const EdgeInsets.only(
                            left: 10, right: 10, top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: darkMode
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFF0E2046).withOpacity(0.8),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          border: Border.all(
                            color: gameStarted ?
                            noMarkings ? Colors.yellow :  const MapEquality()
                                .equals(
                                initialMarking, fixedRandomMarking.marking) ?
                            Colors.green
                                : Colors.white.withOpacity(0.8) : Colors.grey,
                            width: gameStarted ?  const MapEquality().equals(
                                initialMarking, fixedRandomMarking.marking) ?
                            15 : 8 : 8,
                          ),
                        ),
                        child: Tooltip(
                          message: '',
                          child: gameStarted ?
                          Center(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                      text: noMarkings
                                          ? 'No Possible Markings\n'
                                          : loss
                                          ? 'You\'ve chosen the wrong path \n'
                                          : const MapEquality().equals(
                                          initialMarking,
                                          fixedRandomMarking.marking)
                                          ? 'Congratulations!\n'
                                          : 'Reach the Marking of\n',
                                      style: GoogleFonts.cairo(
                                          color: noMarkings
                                              ? Colors.white
                                              : loss
                                              ? Colors.redAccent
                                              :  const MapEquality().equals(
                                              initialMarking,
                                              fixedRandomMarking.marking)
                                              ? Colors.green
                                              : Colors.white,
                                          // Set the text color to white
                                          fontSize: 55,
                                          fontWeight: noMarkings ? FontWeight
                                              .w500 : loss
                                              ? FontWeight.w500
                                              :  const MapEquality().equals(
                                              initialMarking,
                                              fixedRandomMarking.marking)
                                              ? FontWeight.bold
                                              : FontWeight.normal
                                      )
                                  ),
                                  TextSpan(
                                      text: noMarkings
                                          ? 'Try again Later'
                                          : loss
                                          ? 'Solutions: ${(markingToSequences[fixedRandomMarking.marking.toString()] ?? [])
                                          .map((sequence) => '[ ${sequence.map((node) => 'T${node.id}').join(', ')} ]')
                                          .toSet()
                                          .join(' or ')}'
                                          :  const MapEquality().equals(
                                          initialMarking,
                                          fixedRandomMarking.marking)
                                          ? 'You have reached the marking    '
                                          : '$fixedRandomMarking',
                                      style: GoogleFonts.cairo(
                                          color: noMarkings
                                              ? Colors.grey
                                              : loss
                                              ? Colors.white
                                              :  const MapEquality().equals(
                                              initialMarking,
                                              fixedRandomMarking.marking)
                                              ? Colors.white
                                              : Colors.yellow,
                                          // Set the text color to white
                                          fontSize: noMarkings
                                              ? 35
                                              :  const MapEquality().equals(
                                              initialMarking,
                                              fixedRandomMarking.marking)
                                              ? 35
                                              : 40,
                                          fontWeight: loss
                                              ? FontWeight.normal
                                              :  const MapEquality().equals(
                                              initialMarking,
                                              fixedRandomMarking.marking)
                                              ? FontWeight.normal
                                              : FontWeight.bold
                                      )
                                  ),
                                  TextSpan(
                                      text:  const MapEquality().equals(
                                          initialMarking,
                                          fixedRandomMarking.marking)
                                          ? '$fixedRandomMarking'
                                          : '',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          // Set the text color to white
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold
                                      )
                                  ),
                                ],
                              ),
                              textAlign: TextAlign
                                  .center, // Center-align the text within the RichText widget
                            ),
                          )

                              : Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Reachability Game\n',
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          // Set the text color to white
                                          fontSize: 35,
                                          fontWeight: FontWeight.normal
                                      ))
                                  , Container(
                                    width: 150,
                                    // Set the width to your desired size
                                    height: 60,
                                    // Set the height to your desired size
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      // White border
                                      borderRadius: BorderRadius.circular(
                                          50), // Adjust the border radius
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          fixedRandomMarking=MarkingWithTransitions({}, []);
                                          gameStarted = true;
                                          noMarkings = false;
                                          loss = false;
                                          initialMarking =
                                              findMarking(graph.nodes);
                                          Map<String, int> tempInitial = Map
                                              .from(initialMarking);

                                          MarkingWithTransitions? getRandomElement(
                                              List<
                                                  MarkingWithTransitions> reachabilityList,
                                              Map<String, int> initialState) {
                                            if (reachabilityList.isEmpty) {
                                              return null; // Handle the case when the list is empty
                                            }

                                            final Random random = Random();
                                            MarkingWithTransitions? randomMarking;
                                            int consecutiveEqualMarkings = 0;
                                            const int maxConsecutiveEqualMarkings = 10;

                                            do {
                                              final int randomIndex = random
                                                  .nextInt(
                                                  reachabilityList.length);
                                              randomMarking =
                                              reachabilityList[randomIndex];

                                              if (mapEquals(
                                                  randomMarking.marking,
                                                  initialState)) {
                                                consecutiveEqualMarkings++;
                                                if (consecutiveEqualMarkings >=
                                                    maxConsecutiveEqualMarkings) {
                                                  noMarkings = true;
                                                  break;
                                                }
                                              } else {
                                                consecutiveEqualMarkings =
                                                0; // Reset the counter
                                              }
                                            } while (mapEquals(
                                                randomMarking.marking,
                                                initialState));

                                            return randomMarking;
                                          }


                                          List<
                                              MarkingWithTransitions> reachabilityList = [
                                            MarkingWithTransitions(
                                                findMarking(graph.nodes), [])
                                          ]; // Initialize with the initial state


                                          List<
                                              MarkingWithTransitions>reachabilityGraph = generateReachabilityGraph(
                                              tempInitial, reachabilityList, [],
                                              25);
                                          print(
                                              'reachabilityGraph: $reachabilityGraph');

                                          // final List<Map<String,int>> Temp = List.from(reachabilityGraph);

                                          // Check if there are no possible markings other than the initial state
                                          if (reachabilityGraph.length == 1 ) {
                                            noMarkings = true;
                                          } else {
                                            fixedRandomMarking = getRandomElement(reachabilityGraph, initialMarking)!;
                                          }
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white, backgroundColor: Colors.transparent,
                                        // Set the text color
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              20), // Adjust the button's border radius
                                        ),
                                      ),
                                      child: Text(
                                        'Start',
                                        style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            // Set the text color to white
                                            fontSize: 35,
                                            fontWeight: FontWeight.normal
                                        ),
                                      ),
                                    ),
                                  )

                                ]),
                          ),

                          // GestureDetector(
                          //     onTap:() {
                          //       setState(() {
                          //          gameStarted=true;});
                          //       }
                          //       ,child:Icon(Icons.question_mark_outlined,size: 80,color: Colors.yellow,)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ) : const SizedBox(),

            Positioned(
              bottom: MediaQuery
                  .of(context)
                  .size
                  .height / 50,
              right: 30,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(

                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: darkMode
                          ? Colors.blue.withOpacity(0.2)
                          : const Color(0xFF0E2046).withOpacity(0.8),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 3),
                    ),
                    child: Tooltip(
                      message: 'Switch Mode',
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              // Assuming you have a variable 'edges' that contains the list of edges in your Petri net
                              if (initialMarking.isEmpty) {
                                initialMarking = findMarking(graph.nodes);
                              }

                              // Now you can use the 'initialMarking' map as needed
                              print("Initial Marking: $initialMarking");
                              // darkMode = !darkMode;
                              List<MarkingWithTransitions> reachabilityList = [
                                MarkingWithTransitions(initialMarking, [])
                              ]; // Initialize with the initial state

                              final allPossibleMarkings = generateReachabilityGraph(
                                  initialMarking, reachabilityList, [], 25);
                              for (final possible in allPossibleMarkings) {
                                print("Possible Marking: [${possible
                                    .marking} , ${possible
                                    .transitionSequence}]"); // This will print a list of all possible markings
                              }


                            });
                          },
                          child: Icon(darkMode ? Icons.sunny : Icons.nightlight,
                              color: Colors.white.withOpacity(0.5), size: 30)),
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }


  Future<void> _savePetriNet(String petriNetName) async {
    final prefs = await SharedPreferences.getInstance();
    final petriNetJson = petriNetGraph.toJson();
    await prefs.setString(petriNetName, jsonEncode(petriNetJson));
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    String petriNetName = ''; // Initialize an empty string

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Petri Net'),
          content: TextField(
            decoration: const InputDecoration(
                labelText: 'Enter a name for the Petri Net'),
            onChanged: (value) {
              petriNetName = value; // Update the petriNetName as the user types
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (petriNetName.isNotEmpty) {
                  // Call the save function if the name is not empty
                  await _savePetriNet(petriNetName);
                  // SavedPetriNet newPetriNet = SavedPetriNet(
                  //   name: petriNetName,
                  // );
                  // widget.onSavePressed(newPetriNet);
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
            ),
          ],
        );
      },
    );
  }

// Add this function to your "Save" button onPressed handler
  void _onSaveButtonPressed(BuildContext context) {
    _showSaveDialog(context);
  }

  Future<PetriNetGraph?> _loadPetriNet(String petriNetName) async {
    final prefs = await SharedPreferences.getInstance();
    final petriNetJson = prefs.getString(petriNetName);

    if (petriNetJson != null) {
      final Map<String, dynamic> petriNetData = jsonDecode(petriNetJson);
      return PetriNetGraph.fromJson(petriNetData);
    }

    return null; // Return null if the Petri Net with the given name doesn't exist
  }

  Future<void> _loadAndDisplayPetriNet(String petriNetName) async {
    final loadedPetriNet = await _loadPetriNet(petriNetName);

    if (loadedPetriNet != null) {
      setState(() {
        petriNetGraph =
            loadedPetriNet; // Set the loaded Petri Net as the current Petri Net
      });
    } else {
      // Handle the case where the Petri Net doesn't exist
      // You can show an error message or take appropriate action.
    }
  }

  void _onNodeTap(Node node) {
    setState(() {
      if (_sourceNode == node) {
        _sourceNode = null; // Deselect the source node if it's re-tapped
      } else if (_targetNode == node) {
        _targetNode = null; // Deselect the target node if it's re-tapped
      } else if (_sourceNode == null) {
        _sourceNode = node;
      } else if (_targetNode == null) {
        // Check if both nodes are of type Place
        if (_sourceNode is MyPlaceNode && node is MyPlaceNode || _sourceNode is MyTransitionNode && node is MyTransitionNode) {
          // Do nothing or show a warning that two place nodes cannot be selected
        } else {
          _targetNode = node;
        }
      } else {
        _sourceNode = null;
        _targetNode = null;
      }
    });
  }



  void _resetSelection() {
    _sourceNode = null;
    _targetNode = null;
    setState(() {});
  }


  String getAlphabeticalId(int index) {
    final int startIndex = 'A'.codeUnitAt(0); // ASCII value of 'A'
    const int alphabetSize = 26; // Number of letters in the alphabet
    final int letterIndex = startIndex + (index % alphabetSize);
    final String letter = String.fromCharCode(letterIndex);
    final int repeatCount = (index ~/ alphabetSize) +
        1; // Number of times the alphabet has cycled

    return letter * repeatCount;
  }

  int getAlphabeticalIndex(String id) {
    if (id.isEmpty) return -1; // Return -1 for invalid IDs

    final int startIndex = 'A'.codeUnitAt(0); // ASCII value of 'A'
    const int alphabetSize = 26; // Number of letters in the alphabet

    final int letterIndex = id[0].codeUnitAt(0) - startIndex;
    final int repeatCount = id.length;

    return (repeatCount - 1) * alphabetSize + letterIndex;
  }


  int placeCounter = -1;
  int transitionCounter = 0;


  Offset lastPlacePosition = const Offset(100, 100);

  void _addPlace() {
    placeCounter++;  // Increment first
    final id = getAlphabeticalId(placeCounter);
    elements[id] = PetriNetElement(id: id, type: NodeType.place, tokens: 0);


    // Create the MyPlaceNode using the provided id and add it to the graph
    final placeNode = MyPlaceNode(id);

    double newX = lastPlacePosition.dx + 30;
    double newY = lastPlacePosition.dy + 40;

    placeNode.position = Offset(newX, newY);

    lastPlacePosition = placeNode.position;

    // Provide an empty string as the name for now
    final place = PetriNetPlace(id: id, position: lastPlacePosition);

    // Add the created place to the PetriNetGraph by modifying the places list
    final updatedPlaces = [...petriNetGraph.places, place];
    petriNetGraph = petriNetGraph.copyWith(places: updatedPlaces);


    graph.addNode(placeNode, lastPlacePosition, 0);

    // placeCounter++; // Increment the place counter

    setState(() {
      isPetriNetSaved = false;
    });
  }

  void _loadPlace(String placeId, int placeTokens, Offset placePosition) {
    final id = placeId;
    elements[id] =
        PetriNetElement(id: id, type: NodeType.place, tokens: placeTokens);

    print('Place $id has $placeTokens Tokens');

    print('Place $id has ${elements[id]?.tokens}');


    // Create the MyPlaceNode using the provided id and add it to the graph
    final placeNode = MyPlaceNode(id);


    placeNode.position = placePosition;

    lastPlacePosition = placeNode.position;

    // Provide an empty string as the name for now
    final place = PetriNetPlace(id: id, position: lastPlacePosition);

    // Add the created place to the PetriNetGraph by modifying the places list
    final updatedPlaces = [...petriNetGraph.places, place];
    petriNetGraph = petriNetGraph.copyWith(places: updatedPlaces);


    graph.addNode(
        placeNode, placePosition, placeTokens); // Increment the place counter

    setState(() {
      isPetriNetSaved = false;
    });
  }


  Offset lastTransitionPosition = const Offset(300, 300);

  void _addTransition() {
    transitionCounter++;  // Increment first
    final id = '$transitionCounter';
    elements[id] =
        PetriNetElement(id: id, type: NodeType.transition, tokens: 0);
    final transitionNode = MyTransitionNode(
        id); // Use 'id' instead of 'transition_${elements.length}'

    double newX = lastTransitionPosition.dx +
        30; // You can adjust the horizontal spacing as needed
    double newY = lastTransitionPosition.dy + 60;

    transitionNode.position = Offset(newX, newY);

    lastTransitionPosition = transitionNode.position;

    graph.addNode(transitionNode, lastTransitionPosition, 0);

    final transition = PetriNetTransition(
        id: id, position: lastTransitionPosition);

    final updatedTransitions = [...petriNetGraph.transitions, transition];
    petriNetGraph = petriNetGraph.copyWith(transitions: updatedTransitions);

    // transitionCounter++; // Increment the transition counter

    setState(() {
      isPetriNetSaved = false;
    });
  }

  void _loadTransition(String transitionId, Offset transitionPosition) {
    final id = transitionId;
    elements[id] =
        PetriNetElement(id: id, type: NodeType.transition, tokens: 0);
    final transitionNode = MyTransitionNode(
        id); // Use 'id' instead of 'transition_${elements.length}'

    double X = transitionPosition
        .dx; // You can adjust the horizontal spacing as needed
    double Y = transitionPosition.dy;

    print('Transition $transitionId : [X : $X , Y : $Y]');
    print('Transition $transitionId : $transitionPosition');


    transitionNode.position = Offset(X, Y);

    lastTransitionPosition = transitionNode.position;

    graph.addNode(transitionNode, transitionPosition, 0);
    print(
        'Transition $transitionNode is added with position $transitionPosition');

    final transition = PetriNetTransition(
        id: id, position: transitionNode.position);

    final updatedTransitions = [...petriNetGraph.transitions, transition];
    petriNetGraph = petriNetGraph.copyWith(transitions: updatedTransitions);

    setState(() {
      transitionNode.position = Offset(X, Y);
      isPetriNetSaved = false;
    });
  }


  void _addArc() {
    if (_sourceNode != null && _targetNode != null) {
      if (_sourceNode != _targetNode) {
        if ((_sourceNode is MyPlaceNode && _targetNode is MyTransitionNode) ||
            (_sourceNode is MyTransitionNode && _targetNode is MyPlaceNode)) {
          graph.addEdge(_sourceNode!, _targetNode!);

          final sourceId = (_sourceNode is MyPlaceNode)
              ? (_sourceNode as MyPlaceNode).id
              : (_sourceNode as MyTransitionNode).id;
          final targetId = (_targetNode is MyPlaceNode)
              ? (_targetNode as MyPlaceNode).id
              : (_targetNode as MyTransitionNode).id;
          final arc = PetriNetArc(sourceId: sourceId, targetId: targetId);

          final updatedConnections = [...petriNetGraph.connections, arc];
          petriNetGraph =
              petriNetGraph.copyWith(connections: updatedConnections);

          _sourceNode = null;
          _targetNode = null;

          setState(() {
            isPetriNetSaved = false;
          });
          return;
        }
      } else {
        print("Self-loop arcs are not allowed in a Petri net.");
      }
    }

    _sourceNode = null;
    _targetNode = null;

    setState(() {});
  }

  void _loadArc(Node? source, Node? target) {
    if (source != null && target != null) {
      if (source != target) {
        if ((source is MyPlaceNode && target is MyTransitionNode) ||
            (source is MyTransitionNode && target is MyPlaceNode)) {
          graph.addEdge(source, target);

          final sourceId = (source is MyPlaceNode)
              ? (source as MyPlaceNode).id
              : (source as MyTransitionNode).id;
          final targetId = (target is MyPlaceNode)
              ? (target as MyPlaceNode).id
              : (target as MyTransitionNode).id;
          final arc = PetriNetArc(sourceId: sourceId, targetId: targetId);

          final updatedConnections = [...petriNetGraph.connections, arc];
          petriNetGraph =
              petriNetGraph.copyWith(connections: updatedConnections);

          graph.addEdge(source, target);

          source = null;
          target = null;

          setState(() {
            isPetriNetSaved = false;
          });
          return;
        }
      } else {
        print("Self-loop arcs are not allowed in a Petri net.");
      }
    }

    source = null;
    target = null;

    setState(() {});
  }


  void _addTokenToSelectedElement() {
    if (_sourceNode != null && _sourceNode is MyPlaceNode) {
      final element = elements[(_sourceNode as MyPlaceNode).id];
      if (element != null) {
        _sourceNode?.tokens += 1;
        element.tokens += 1;
        elements[(_sourceNode as MyPlaceNode).id] = element;
      }
      print('${element?.tokens}');
      final tokens = element?.tokens ?? 0;

      setState(() {
        elements[(_sourceNode as MyPlaceNode).id]?.tokens = tokens;

        final placeId = (_sourceNode as MyPlaceNode).id;
        final updatedPlaces = petriNetGraph.places.map((place) {
          if (place.id == placeId) {
            return place.copyWith(tokens: tokens);
          }
          return place;
        }).toList();
        petriNetGraph = PetriNetGraph(
          places: updatedPlaces,
          transitions: petriNetGraph.transitions,
          connections: petriNetGraph.connections,
        );
        isPetriNetSaved = false;
      });
    }
  }


  void _deleteTokenToSelectedElement() {
    if (_sourceNode != null && _sourceNode is MyPlaceNode) {
      final element = elements[(_sourceNode as MyPlaceNode).id];
      if (element != null && element.tokens > 0) {
        _sourceNode?.tokens -= 1;
        element.tokens -= 1;
        elements[(_sourceNode as MyPlaceNode).id] = element;
      }
      print('${element?.tokens}');
      final tokens = element?.tokens ?? 0;

      setState(() {
        elements[(_sourceNode as MyPlaceNode).id]?.tokens = tokens;

        final placeId = (_sourceNode as MyPlaceNode).id;
        final updatedPlaces = petriNetGraph.places.map((place) {
          if (place.id == placeId) {
            return place.copyWith(tokens: tokens);
          }
          return place;
        }).toList();
        petriNetGraph = petriNetGraph.copyWith(places: updatedPlaces);

        isPetriNetSaved = false;
      });
    }
  }

  void _deleteNode() {
    if (_sourceNode != null) {
      // Remove the selected node from the graph
      graph.removeNode(_sourceNode);

      // Remove all arcs connected to the selected node
      final arcsToRemove = <Edge>[];
      for (final edge in graph.edges) {
        if (edge.source == _sourceNode || edge.destination == _sourceNode) {
          arcsToRemove.add(edge);
        }
      }
      for (final arc in arcsToRemove) {
        graph.removeEdge(arc);
      }

      // Remove the selected node's data from the elements map
      elements.remove(_sourceNode?.key);

      // Clear the selected node
      _sourceNode = null;

      // Call setState to rebuild the UI
      setState(() {
        isPetriNetSaved = false;
      });
    }
  }


  Widget _buildTokens(int count) {
    final List<Widget> tokens = [];
    const double tokenSize = 8;
    const double spacing = 4;

    for (int i = 0; i < count; i++) {
      tokens.add(Container(
        width: tokenSize,
        height: tokenSize,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Colors.black),
      ));
      if (i < count - 1) {
        tokens.add(const SizedBox(width: spacing));
      }
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: tokens);
  }

  Widget _buildNodeWidget(Node node, double nodeSize) {
    if (node is MyPlaceNode) {
      return GestureDetector(
        onPanStart: (details) {
          controller.draggingElement = true;
          controller.selectedStartElementKey = node.key;
        },
        onPanEnd: (details) {
          controller.draggingElement = false;
          controller.selectedStartElementKey = null;
        },
        child: _buildPlaceWidget(
            node, node == _sourceNode, node == _targetNode, nodeSize),
      );
    } else if (node is MyTransitionNode) {
      return GestureDetector(
        onPanStart: (details) {
          controller.draggingElement = true;
          controller.selectedStartElementKey = node.key;
        },
        onPanEnd: (details) {
          controller.draggingElement = false;
          controller.selectedStartElementKey = null;
        },
        child: _buildTransitionWidget(
            node, node == _sourceNode, node == _targetNode, nodeSize,
            fixedRandomMarking),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceWidget(MyPlaceNode node, bool isSource, bool isTarget,
      double nodeSize) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final placeSize = screenWidth * 0.11;
    final element = elements[node.id];
    final tokens = element?.tokens ??
        0; // Use 'tokens' to display the token count in the widget.
    final placeName = element?.id;

    return GestureDetector(
      onTap: () => simulationMode || gameMode ? null : _onNodeTap(node),
      child: Row(
        children: [
          Container(
            width: max(placeSize - nodeSize * 0.9 - 20, 50),
            height: max(placeSize - nodeSize * 0.9 - 20, 50),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0),
                  blurRadius: 8,
                  offset: const Offset(-5, -5),
                ),
                BoxShadow(
                  color: Colors.blue[300]!.withOpacity(0),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              gradient: RadialGradient(
                colors: isSource ? [AppColors.backgroundColor2, Colors.teal]
                    : (isTarget ? [AppColors.backgroundColor2, Colors.orange]
                    : [AppColors.backgroundColor2, AppColors.blue]),
                center: const Alignment(0.3, -0.3),
                focal: const Alignment(0, -0.3),
                focalRadius: 0.01,
                radius: 0.7,
              ),
            ),
            child: ClipOval(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors:
                    simulationMode
                        ? [Colors.white60, Colors.blueGrey]
                        : gameMode
                        ? [Colors.white, Colors.white60]
                        : isSource
                        ? [Colors.white60, Colors.teal.withOpacity(0.9)]
                        : isTarget
                        ? [Colors.white60, Colors.orange.withOpacity(0.9)]
                        : [Colors.white60, AppColors.blue],

                    center: const Alignment(0.3, -0.3),
                    focal: const Alignment(0, -0.3),
                    focalRadius: 0.005,
                    radius: 0.6,
                  ),
                ),
                child: Center(
                    child: tokens <= 3 // Check if tokens are 3 or less
                        ? _buildTokens(tokens) // Display tokens as real tokens
                        : Text('$tokens', style: TextStyle(
                        color: isSource ? Colors.black45 : (isTarget ? Colors
                            .black45 : AppColors.blue),
                        fontWeight: FontWeight.bold,
                        fontSize: max(screenWidth / 35 - nodeSize * 0.1, 8)))),
              ),
            ),
          ),
          const SizedBox(width: 25),
          Text(
              placeName!,
              style: GoogleFonts.cairo(
                color: isSource
                    ? Colors.white60
                    : (isTarget ? Colors.white60 : Colors.white38),
                // Set the text color to white
                fontSize: max(screenWidth / 35 - nodeSize * 0.1, 8),
              )

          ),
        ],
      ),
    );
  }

  Widget _feedbackPlace(double circleSize) {
    return DashedCircleBorder(
      circleSize: circleSize,
    );
  }

  Widget _buildTransitionWidget(MyTransitionNode node, bool isSource,
      bool isTarget, double nodeSize, MarkingWithTransitions targetMarking) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final transitionWidth = screenWidth * 0.11;
    final transitionHeight = screenHeight * 0.05;
    final element = elements[node.id];
    final transitionName = element?.id;


    List<Node> inputPlaces = _findInputPlaces(node, graph.edges);
    for (final input in inputPlaces) {
      // Call the function to find input places
      print('TEST IF FIRABLE : Input Places of ${node
          .id} is $input where its Tokens: ${input.tokens}');
    }

    bool connected = transitionConnected(node, graph.edges);

    bool isFireable = false; // Assume the transition is initially not firable
    print('TEST IF FIRABLE : ${node.id} is connected: $connected');

    if (inputPlaces.isEmpty && connected) {
      isFireable = true; // Token Generator
    } else if (inputPlaces.isNotEmpty && !connected) {
      isFireable = inputPlaces.every((input) => input.tokens > 0); // Token Remover
    } else {
      isFireable = connected && inputPlaces.every((input) => input.tokens > 0);
    }
    return
      simulationMode || gameMode
          ? Tooltip(
        message: isFireable
            ? '' // No message when it's firable
            : 'This transition is not firable under these conditions',
        waitDuration: Duration.zero, // Show on click
        child: GestureDetector(
          onTap: () => isFireable && !const MapEquality().equals(
              initialMarking,
              fixedRandomMarking.marking) && !loss
              ? gameMode
              ? gameStarted
              ? _fireGameTransition(node, targetMarking)
              : null
              : _fireTransition(node)
              : null,
          child: Row(
            children: [
              Container(
                width: max(transitionWidth - nodeSize * 0.3, 90),
                height: max((transitionWidth - nodeSize * 0.3) / 2, 50),
                decoration: BoxDecoration(
                  color: simulationMode ? (isFireable
                      ? Colors.lightBlueAccent
                      : Colors.blueGrey) : gameMode ? (isFireable ? Colors
                      .redAccent : Colors.grey) : (isFireable
                      ? Colors.redAccent
                      : Colors.grey),
                ),
              ),
              const SizedBox(width: 25),
              Text(
                  transitionName!, // Display the place name
                  style: GoogleFonts.cairo(
                    color: isSource
                        ? Colors.white60
                        : (isTarget ? Colors.white60 : Colors.white38),
                    // Set the text color to white
                    fontSize: max(screenWidth / 35 - nodeSize * 0.1, 8),
                  ))
            ],
          ),
        ),
      )
          :

      Row(
        children: [
          GestureDetector(
            onTap: () => _onNodeTap(node),
            child: Container(
              width: max(transitionWidth - nodeSize * 0.3, 90),
              height: max((transitionWidth - nodeSize * 0.3) / 2, 50),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0),
                    blurRadius: 8,
                    offset: const Offset(-3, -3),
                  ),
                  BoxShadow(
                    color: Colors.grey[300]!.withOpacity(0),
                    blurRadius: 8,
                    offset: const Offset(3, 3),
                  ),
                ],
                gradient: LinearGradient(
                  colors:
                  darkMode ?
                  isSource ? [Colors.teal.shade100, Colors.teal]
                      : (isTarget ? [Colors.orange.shade200, Colors.orange]
                      : [AppColors.backgroundColor2, Colors.white])
                      : isSource ? [Colors.teal.shade100, Colors.teal]
                      : (isTarget ? [Colors.orange.shade200, Colors.orange]
                      : [AppColors.blue, AppColors.darkBlue]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          const SizedBox(width: 25),
          Text(
            transitionName!, // Display the place name
            style: GoogleFonts.cairo(
              color: isSource
                  ? Colors.white60
                  : (isTarget ? Colors.white60 : Colors.white38),
              // Set the text color to white
              fontSize: max(screenWidth / 35 - nodeSize * 0.1, 8),
            ),)
        ],
      );
  }

  Widget _feedbackTransition(MyTransitionNode node, double nodeSize) {
    return DottedBorder(
      dashPattern: const [5, 10],
      color: darkMode ? Colors.white : Colors.black,
      strokeWidth: 2,
      child: Container(

      ),
    );
  }


  List<MyPlaceNode> _findInputPlaces(Node transitionNode, List<Edge> edges) {
    final List<MyPlaceNode> inputPlaces = [];

    // Iterate through the edges to find input places connected to the transition
    for (final edge in edges) {
      if (edge.destination == transitionNode) {
        // The destination of the edge is the transition, so the source is an input place
        inputPlaces.add(edge.source as MyPlaceNode);
      }
    }

    return inputPlaces;
  }

  List<MyPlaceNode> _findOutputPlaces(Node transitionNode, List<Edge> edges) {
    final List<MyPlaceNode> outputPlaces = [];

    // Iterate through the edges to find input places connected to the transition
    for (final edge in edges) {
      if (edge.source == transitionNode) {
        // The destination of the edge is the transition, so the source is an input place
        outputPlaces.add(edge.destination as MyPlaceNode);
      }
    }

    return outputPlaces;
  }

  bool transitionConnected(Node transitionNode, List<Edge> edges) {
    final List<Node> outputPlaces = [];

    // Iterate through the edges to find input places connected to the transition
    for (final edge in edges) {
      if (edge.source == transitionNode) {
        return true;
      }
    }
    return false;
  }

  void _fireTransition(MyTransitionNode node) {
    List<Node> inputPlaces = _findInputPlaces(node, graph.edges);
    List<Node> outputPlaces = _findOutputPlaces(node, graph.edges);

    // Update the score and possibly other UI elements
    setState(() {
      if (inputPlaces.isEmpty) {
        // Token Generator
        for (final output in outputPlaces) {
          final element = elements[(output as MyPlaceNode).id];
          element?.tokens += 1;
          output.tokens += 1;
        }
      } else if (outputPlaces.isEmpty) {
        // Token Remover
        for (final input in inputPlaces) {
          final element = elements[(input as MyPlaceNode).id];
          element?.tokens = max(0, element.tokens - 1);
          input.tokens = max(0, input.tokens - 1);
        }
      } else {
        // Reset tokens for input places
        for (final input in inputPlaces) {
          final element = elements[(input as MyPlaceNode).id];
          element?.tokens = 0;
          input.tokens = 0;
        }

        // Increment tokens for output places
        for (final output in outputPlaces) {
          final element = elements[(output as MyPlaceNode).id];
          element?.tokens += 1;
          output.tokens += 1;
        }
      }

    });
  }

  int userHints = 3; // Initialize userHints to 3 at the beginning of each game



  void _fireGameTransition(MyTransitionNode node, MarkingWithTransitions targetMarking) {
    setState(() {
      List<Node> inputPlaces = _findInputPlaces(node, graph.edges);
      List<Node> outputPlaces = _findOutputPlaces(node, graph.edges);
      bool validated = validateTransition(node, targetMarking);

      print('Selected Node: $node, Solution: ${targetMarking.transitionSequence}');
      print('TARGET MARKETING:$targetMarking');

      if (userHints > 0) {
        if (validated) {
          // Token Generator
          if (inputPlaces.isEmpty) {
            for (final output in outputPlaces) {
              final element = elements[(output as MyPlaceNode).id];
              element?.tokens += 1;
              output.tokens += 1;
            }
          }
          // Token Remover
          else if (outputPlaces.isEmpty) {
            for (final input in inputPlaces) {
              final element = elements[(input as MyPlaceNode).id];
              element?.tokens = max(0, element.tokens - 1);
              input.tokens = max(0, input.tokens - 1);
            }
          }
          // Normal Transition
          else {
            for (final input in inputPlaces) {
              final element = elements[(input as MyPlaceNode).id];
              element?.tokens = 0;
              input.tokens = 0;
            }
            for (final output in outputPlaces) {
              final element = elements[(output as MyPlaceNode).id];
              element?.tokens += 1;
              output.tokens += 1;
            }
          }
        } else {
          userHints -= 1;
          print('HINTS LEFT: $userHints');
          showIncorrectTransitionNotification();
        }
      } else {
        if (validated) {
          // Token Generator
          if (inputPlaces.isEmpty) {
            for (final output in outputPlaces) {
              final element = elements[(output as MyPlaceNode).id];
              element?.tokens += 1;
              output.tokens += 1;
            }
          }
          // Token Remover
          else if (outputPlaces.isEmpty) {
            for (final input in inputPlaces) {
              final element = elements[(input as MyPlaceNode).id];
              element?.tokens = max(0, element.tokens - 1);
              input.tokens = max(0, input.tokens - 1);
            }
          }
          // Normal Transition
          else {
            for (final input in inputPlaces) {
              final element = elements[(input as MyPlaceNode).id];
              element?.tokens = 0;
              input.tokens = 0;
            }
            for (final output in outputPlaces) {
              final element = elements[(output as MyPlaceNode).id];
              element?.tokens += 1;
              output.tokens += 1;
            }
          }
          // Similar code as above for handling Token Generator, Token Remover, and Normal Transition
        } else {
          loss = true;
        }
      }
    });
  }



  void _fakeFireTransition(MyTransitionNode node, Map<String, int> currentState) {
    List<MyPlaceNode> inputPlaces = _findInputPlaces(node, graph.edges);
    List<MyPlaceNode> outputPlaces = _findOutputPlaces(node, graph.edges);

    // Token Generator: No input places, so just add tokens to output places
    if (inputPlaces.isEmpty && outputPlaces.isNotEmpty) {
      for (final output in outputPlaces) {
        currentState[output.id] = (currentState[output.id] ?? 0) + 1;
      }
    }
    // Token Remover: No output places, so just remove tokens from input places
    else if (inputPlaces.isNotEmpty && outputPlaces.isEmpty) {
      for (final input in inputPlaces) {
        currentState[input.id] = max(0, currentState[input.id]! - 1);
      }
    }
    // Normal Transition: Reset tokens for input places and add tokens to output places
    else {
      for (final input in inputPlaces) {
        currentState[input.id] = 0;
      }
      for (final output in outputPlaces) {
        currentState[output.id] = (currentState[output.id] ?? 0) + 1;
      }
    }
  }





  bool canBeFired(MyTransitionNode node, Map<String, int> currentMarking) {
    List<MyPlaceNode> inputPlaces = _findInputPlaces(node, graph.edges);
    bool connected = transitionConnected(node, graph.edges);

    if (inputPlaces.isEmpty && connected) {
      return true; // Token Generator
    } else if (inputPlaces.isNotEmpty && !connected) {
      return inputPlaces.every((input) => currentMarking[input.id]! > 0); // Token Remover
    } else {
      return connected && inputPlaces.every((input) => currentMarking[input.id]! > 0);
    }
  }


  // Define a function to find the initial marking of the Petri net
  Map<String, int> findMarking(List<Node> nodes) {
    // Initialize an empty map to store the initial marking
    Map<String, int> marking = {};
    List<Node> tempNodes = List.from(nodes);

    // Loop through all the nodes (places) in the Petri net
    for (final node in tempNodes) {
      if (node is MyPlaceNode) {
        // Get the name (label) of the place
        final placeName = node.id;

        // Get the current token count of the place
        final tokens = node.tokens;

        // Assign the token count to the place's label (name) in the initial marking
        marking[placeName] = tokens;
      }
    }

    // Return the initial marking
    return marking;
  }


  bool stateReachability(Map<String, int> currentState) {
    List<MyTransitionNode> transitions = [];
    for (final node in graph.nodes) {
      if (node is MyTransitionNode) {
        transitions.add(node);
      }
    }

    for (final transition in transitions) {
      if (canBeFired(transition, currentState)) {
        return true;
      }
    }
    return false;
  }


// Declare the map outside the method to keep track of all sequences for each marking
  Map<String, List<List<MyTransitionNode>>> markingToSequences = {};

  List<MarkingWithTransitions> generateReachabilityGraph(
      Map<String, int> currentState,
      List<MarkingWithTransitions> reachabilityList,
      List<MyTransitionNode> transitionSequence,
      int maxGraphSize) {
    // Extract all transition nodes from the graph
    List<MyTransitionNode> transitions = [];
    for (final node in graph.nodes) {
      if (node is MyTransitionNode) {
        transitions.add(node);
      }
    }

    // Stop exploring if the graph size exceeds the maximum limit
    if (reachabilityList.length >= maxGraphSize) {
      return reachabilityList;
    }

    // Your stateReachability function (assuming it checks if the state is reachable)
    if (stateReachability(currentState)) {
      for (final transition in transitions) {
        // Your canBeFired function (assuming it checks if the transition can be fired)
        if (canBeFired(transition, currentState)) {
          // Create a copy of the current state and transition sequence
          Map<String, int> nextState = Map.from(currentState);
          List<MyTransitionNode> nextTransitionSequence = List.from(transitionSequence);

          // Apply the transition to get the next state
          _fakeFireTransition(transition, nextState);
          nextTransitionSequence.add(transition);

          // Add the new marking and transition sequence to the reachability list
          reachabilityList.add(MarkingWithTransitions(nextState, nextTransitionSequence));

          // Convert the marking to a string to use it as a key
          String markingString = nextState.toString();

          // Update the markingToSequences map
          if (markingToSequences.containsKey(markingString)) {
            markingToSequences[markingString]!.add(nextTransitionSequence);
          } else {
            markingToSequences[markingString] = [nextTransitionSequence];
          }

          // Recursively explore the next state
          generateReachabilityGraph(nextState, reachabilityList, nextTransitionSequence, maxGraphSize);
        }
      }
    }
    return reachabilityList;
  }



  int userScore = 0;


  bool validateTransition(MyTransitionNode selectedTransition, MarkingWithTransitions targetMarking) {
    String targetMarkingString = targetMarking.marking.toString();
    if (markingToSequences.containsKey(targetMarkingString)) {
      List<List<MyTransitionNode>> allSequences = markingToSequences[targetMarkingString]!;
      for (List<MyTransitionNode> sequence in allSequences) {
        if (sequence.contains(selectedTransition)) {
          return true;
        }
      }
    }
    return false;
  }



  void showIncorrectTransitionNotification() {
    print('Incorrect Transition! Try again.');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Incorrect Transition!'),
          content: const Text('Try again.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class DashedCircleBorder extends StatelessWidget {
  final double circleSize;

  const DashedCircleBorder({super.key,
    required this.circleSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(
        circleSize: circleSize,
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final double circleSize;

  _DashedCirclePainter({
    required this.circleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = circleSize / 2;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashSpace = 360.0 / 15;
    final Path path = Path();

    for (int i = 0; i < 15; i++) {
      final double startAngle = i * dashSpace;
      path.moveTo(
        center.dx + radius * cos(startAngle * pi / 180.0),
        center.dy + radius * sin(startAngle * pi / 180.0),
      );
      final double endAngle = (i + 0.5) * dashSpace;
      path.lineTo(
        center.dx + radius * cos(endAngle * pi / 180.0),
        center.dy + radius * sin(endAngle * pi / 180.0),
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class MarkingWithTransitions {
  Map<String, int> marking;
  List<MyTransitionNode> transitionSequence;

  MarkingWithTransitions(this.marking, this.transitionSequence);

  @override
  String toString() {
    print('Possible Marking : $marking , Transition Sequence: $transitionSequence');
    return '$marking'; // Display only the marking part
  }

}
