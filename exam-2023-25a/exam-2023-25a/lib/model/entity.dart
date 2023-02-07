class Entity {
  int id; // = const Uuid().v4();
  String name;
  String description;
  String image;
  String category;
  int units;
  num price;

  Entity(
      {required this.id,
        required this.name,
        required this.description,
        required this.image,
        required this.category,
        required this.units,
        required this.price});

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
        id: json['id'],
        name: json['name'],
        description: json["description"],
        image: json["image"],
        units: json["units"],
        price: json["price"],
        category: json["category"]);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'category': category,
      'units': units,
      'price': price,
    };
  }
}

class EntityDTO {
  String name;
  String description;
  String image;
  String category;
  int units;
  num  price;

  EntityDTO(
      {required this.name,
        required this.description,
        required this.image,
        required this.category,
        required this.units,
        required this.price});

  factory EntityDTO.fromJson(Map<String, dynamic> json) {
    return EntityDTO(
        name: json['name'],
        description: json["description"],
        image: json["image"],
        units: json["units"],
        category: json["category"],
        price: json["price"]);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'units': units,
      'price': price,
      'category': category,
    };
  }
}

class EntityDTOWithID {
  int id;
  String name;
  String description;
  String image;
  String category;
  int units;
  num  price;

  EntityDTOWithID(
      {required this.id,
        required this.name,
        required this.description,
        required this.image,
        required this.category,
        required this.units,
        required this.price});

  factory EntityDTOWithID.fromJson(Map<String, dynamic> json) {
    return EntityDTOWithID(
        id: json['id'],
        name: json['name'],
        description: json["description"],
        image: json["image"],
        units: json["units"],
        price: json["price"],
        category: json["category"]);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'units': units,
      'price': price,
      'category': category,
    };
  }
}

