class Entity {
  int id; // = const Uuid().v4();
  String date;
  String type;
  int duration;
  int distance;
  int calories;
  int rate;

  Entity(
      {required this.id,
        required this.date,
        required this.type,
        required this.duration,
        required this.distance,
        required this.calories,
        required this.rate});

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
        id: json['id'],
        date: json['date'],
        type: json["type"],
        duration: json["duration"],
        calories: json["calories"],
        rate: json["rate"],
        distance: json["distance"]);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'duration': duration,
      'distance': distance,
      'calories': calories,
      'rate': rate,
    };
  }
}

class EntityDTO {
  String date;
  String type;
  int duration;
  int distance;
  int calories;
  int  rate;

  EntityDTO(
      {required this.date,
        required this.type,
        required this.duration,
        required this.distance,
        required this.calories,
        required this.rate});

  factory EntityDTO.fromJson(Map<String, dynamic> json) {
    return EntityDTO(
        date: json['date'],
        type: json["type"],
        duration: json["duration"],
        calories: json["calories"],
        distance: json["distance"],
        rate: json["rate"]);
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'type': type,
      'duration': duration,
      'calories': calories,
      'rate': rate,
      'distance': distance,
    };
  }
}

class EntityDTOWithID {
  int id; // = const Uuid().v4();
  String date;
  String type;
  int duration;
  int distance;
  int calories;
  int rate;

  EntityDTOWithID(
      {required this.id,
        required this.date,
        required this.type,
        required this.duration,
        required this.distance,
        required this.calories,
        required this.rate});


  factory EntityDTOWithID.fromJson(Map<String, dynamic> json) {
    return EntityDTOWithID(
        id: json['id'],
        date: json['date'],
        type: json["type"],
        duration: json["duration"],
        calories: json["calories"],
        rate: json["rate"],
        distance: json["distance"]);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'type': type,
      'duration': duration,
      'distance': distance,
      'calories': calories,
      'rate': rate,
    };
  }
}

