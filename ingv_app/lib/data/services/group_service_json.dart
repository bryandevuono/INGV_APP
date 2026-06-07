import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'group_service_interface.dart';

class GroupServiceJson implements IGroupService {
  static final GroupServiceJson _instance = GroupServiceJson._internal();
  factory GroupServiceJson() => _instance;
  GroupServiceJson._internal();

  static const String _assetPath = 'assets/data/groups.json';
  final List<GroupModel> groups = [];
  bool _initialized = false;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/groups.json');
  }

  @override
  Future<List<GroupModel>> getGroups() async {
    if (!_initialized) {
      await _initialize();
    }
    return List.from(groups);
  }

  Future<void> _initialize() async {
    try {
      final file = await _localFile;
      String jsonString;

      if (await file.exists()) {
        jsonString = await file.readAsString();
      } else {
        jsonString = await rootBundle.loadString(_assetPath);
        await file.writeAsString(jsonString);
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      
      final loadedGroups = jsonList
          .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
          .toList();
          
      groups.clear();
      groups.addAll(loadedGroups);
    } catch (e) {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      final loadedGroups = jsonList
          .map((g) => GroupModel.fromJson(g as Map<String, dynamic>))
          .toList();
          
      groups.clear();
      groups.addAll(loadedGroups);
    }
    _initialized = true;
  }

  @override
  Future<void> insertGroup(GroupModel group) async {
    if (!_initialized) await _initialize();
    groups.add(group);
    await _writeGroupsToJson();
  }

  Future<void> _writeGroupsToJson() async {
    final file = await _localFile;
    // Using your exact .toJson method here
    final List<Map<String, dynamic>> jsonList = groups
        .map((g) => g.toJson()) 
        .toList();
    final String jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

  
}