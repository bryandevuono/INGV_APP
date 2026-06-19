import 'package:flutter/foundation.dart';

class PersonModel {
  final String id;
  final String name;
  final String image;

  PersonModel({required this.id, required this.name, required this.image});

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'image': image};
  }
}
