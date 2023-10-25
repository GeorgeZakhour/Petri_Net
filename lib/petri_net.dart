


import 'dart:ui';


Map<String, dynamic> offsetToJson(Offset offset) {
  return {
    'dx': offset.dx,
    'dy': offset.dy,
  };
}


class PetriNetGraph {
  List<PetriNetPlace> places;
  List<PetriNetTransition> transitions;
  List<PetriNetArc> connections;

  PetriNetGraph({
    required this.places,
    required this.transitions,
    required this.connections,
  });

  PetriNetGraph copyWith({
    List<PetriNetPlace>? places,
    List<PetriNetTransition>? transitions,
    List<PetriNetArc>? connections,
  }) {
    return PetriNetGraph(
      places: places ?? this.places,
      transitions: transitions ?? this.transitions,
      connections: connections ?? this.connections,
    );
  }

  void updateNodePosition(String nodeId, Offset newPosition) {
    final updatedPlaces = places.map((place) {
      if (place.id == nodeId) {
        return place.copyWith(position: newPosition);
      }
      return place;
    }).toList();

    final updatedTransitions = transitions.map((transition) {
      if (transition.id == nodeId) {
        return transition.copyWith(position: newPosition);
      }
      return transition;
    }).toList();

    places = updatedPlaces;
    transitions = updatedTransitions;
  }


  void addPlace(PetriNetPlace place) {
    if (!places.contains(place)) {
      places.add(place);
    }
  }

  void addTransition(PetriNetTransition transition) {
    if (!transitions.contains(transition)) {
      transitions.add(transition);
    }
  }

  void addArc(PetriNetArc arc) {
    if (!connections.contains(arc)) {
      connections.add(arc);
    }
  }

  void removePlace(PetriNetPlace place) {
    places.remove(place);
    // Also remove connected arcs
    connections.removeWhere((arc) => arc.sourceId == place.id || arc.targetId == place.id);
  }

  void removeTransition(PetriNetTransition transition) {
    transitions.remove(transition);
    // Also remove connected arcs
    connections.removeWhere((arc) => arc.sourceId == transition.id || arc.targetId == transition.id);
  }

  void removeArc(PetriNetArc arc) {
    connections.remove(arc);
  }

  List<PetriNetPlace> getPlaces() => places;

  List<PetriNetTransition> getTransitions() => transitions;

  List<PetriNetArc> getArcs() => connections;

  PetriNetPlace getPlaceById(String id) {
    return places.firstWhere((place) => place.id == id);
  }

  PetriNetTransition getTransitionById(String id) {
    return transitions.firstWhere((transition) => transition.id == id);
  }

  PetriNetArc getArcBySourceAndTarget(String sourceId, String targetId) {
    return connections.firstWhere((arc) => arc.sourceId == sourceId && arc.targetId == targetId);
  }

  // Convert the Petri net graph to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'places': places.map((place) {
        final json = place.toJson();
        json['position'] = place.position;
        return json;
      }).toList(),
      'transitions': transitions.map((transition) {
        final json = transition.toJson();
        json['position'] = transition.position;
        return json;
      }).toList(),
      'connections': connections.map((connection) {
        // Since 'position' is no longer part of PetriNetArc, you can omit it here
        return connection.toJson();
      }).toList(),
    };
  }



  // Create the Petri net graph from a JSON representation
  // Create the Petri net graph from a JSON representation
  factory PetriNetGraph.fromJson(Map<String, dynamic> json) {
    return PetriNetGraph(
      places: (json['places'] as List<dynamic>).map((placeJson) {
        final place = PetriNetPlace.fromJson(placeJson);
        place.position = placeJson['position'];
        return place;
      }).toList(),
      transitions: (json['transitions'] as List<dynamic>).map((transitionJson) {
        final transition = PetriNetTransition.fromJson(transitionJson);
        transition.position = transitionJson['position'];
        return transition;
      }).toList(),
      connections: (json['connections'] as List<dynamic>).map((connectionJson) {
        // Since 'position' is no longer part of PetriNetArc, you can omit it here
        return PetriNetArc.fromJson(connectionJson);
      }).toList(),
    );
  }


}

class PetriNetPlace {
  String id;
  int tokens;
  Offset position; // Add this line

  PetriNetPlace({
    required this.id,
    this.tokens = 0,
    required this.position, // Add this line
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tokens': tokens,
      'position': offsetToJson(position), // Include the 'position' property
      // Serialize other properties here
    };
  }

  factory PetriNetPlace.fromJson(Map<String, dynamic> json) {
    return PetriNetPlace(
      id: json['id'],
      tokens: json['tokens'],
      position: Offset(json['position']['dx'], json['position']['dy']), // Deserialize the 'position' property as Offset
      // Deserialize other properties here
    );
  }


  PetriNetPlace copyWith({
    String? id,
    String? name,
    int? tokens,
    Offset? position, // Use the correct data type here
  }) {
    return PetriNetPlace(
      id: id ?? this.id,
      tokens: tokens ?? this.tokens,
      position: position ?? this.position, // Set 'position' or use the existing value
    );
  }
}


class PetriNetTransition {
  String id;
  Offset position; // Add this line

  PetriNetTransition({
    required this.id,
    required this.position, // Add this line
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': offsetToJson(position), // Include the 'position' property
      // Serialize other properties here
    };
  }

  factory PetriNetTransition.fromJson(Map<String, dynamic> json) {
    return PetriNetTransition(
      id: json['id'],
      position: Offset(json['position']['dx'], json['position']['dy']), // Deserialize the 'position' property as Offset
      // Deserialize other properties here
    );
  }

  PetriNetTransition copyWith({
    String? id,
    String? name,
    Offset? position, // Use the correct data type here
  }) {
    return PetriNetTransition(
      id: id ?? this.id,
      position: position ?? this.position, // Set 'position' or use the existing value
    );
  }
}


class PetriNetArc {
  String sourceId;
  String targetId;

  PetriNetArc({
    required this.sourceId,
    required this.targetId,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      // Serialize other properties here
    };
  }

  factory PetriNetArc.fromJson(Map<String, dynamic> json) {
    return PetriNetArc(
      sourceId: json['sourceId'],
      targetId: json['targetId'],
      // Deserialize other properties here
    );
  }

  PetriNetArc copyWith({
    String? sourceId,
    String? targetId,
  }) {
    return PetriNetArc(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
    );
  }
}


