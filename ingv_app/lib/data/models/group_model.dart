import 'package:flutter/foundation.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final List<String> members;

GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.members,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      members: List<String>.from(json['members'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'members': members,
    };
  }
}
