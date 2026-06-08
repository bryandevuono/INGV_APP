import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/models/person_model.dart'; 
import 'group_service_interface.dart';

class GroupServiceJson implements IGroupService {
  static final GroupServiceJson _instance = GroupServiceJson._internal();
  factory GroupServiceJson() => _instance;
  GroupServiceJson._internal();

  final List<GroupModel> groups = [];
  final List<PersonModel> persons = [];
  bool _initialized = false;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/groups.json');
  }

  Future<File> get _personsFile async {
    final path = await _localPath;
    return File('$path/persons.json');
  }

  Future<bool> isDatabaseEmpty() async {
    final groupsFile = await _localFile;
    final personsFile = await _personsFile;
    
    // It's empty if either file doesn't exist yet
    if (!await groupsFile.exists() || !await personsFile.exists()) {
      return true;
    }
    
    final groupsContent = await groupsFile.readAsString();
    final personsContent = await personsFile.readAsString();
    
    final List<dynamic> groupsList = json.decode(groupsContent);
    final List<dynamic> personsList = json.decode(personsContent);
    
    return groupsList.isEmpty && personsList.isEmpty;
  }


  Future<void> clearDatabase() async {
    final groupsFile = await _localFile;
    final personsFile = await _personsFile;

    // 1. Delete physical files from disk
    if (await groupsFile.exists()) await groupsFile.delete();
    if (await personsFile.exists()) await personsFile.delete();

    groups.clear();
    persons.clear();
    
    _initialized = false;
  }

  @override
  Future<List<GroupModel>> getGroups() async {
    if (!_initialized) {
      await _initialize();
    }
    return List.from(groups);
  }

  Future<bool> deleteGroupsFile() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false; 
    } catch (e) {
      return false; 
    }
  }

  Future<void> _initialize() async {
    try {
      final groupsFile = await _localFile;
      final pFile = await _personsFile;
      
      String groupsJsonString;
      String personsJsonString;

      // Handle Groups setup
      if (await groupsFile.exists()) {
        groupsJsonString = await groupsFile.readAsString();
      } else {
        final generatedGroups = _generateMockGroups();
        final List<Map<String, dynamic>> jsonList = generatedGroups.map((g) => g.toJson()).toList();
        groupsJsonString = json.encode(jsonList);
        await groupsFile.writeAsString(groupsJsonString);
      }

      // Handle Persons setup (Ensures sync with your groups initialization)
      if (await pFile.exists()) {
        personsJsonString = await pFile.readAsString();
      } else {
        // Generate the 10 static persons 
        final List<PersonModel> mockPersons = List.generate(10, (index) {
          return PersonModel(id: 'p_${index + 1}', name: 'Person ${index + 1}', image: '');
        });
        final List<Map<String, dynamic>> jsonList = mockPersons.map((p) => p.toJson()).toList();
        personsJsonString = json.encode(jsonList);
        await pFile.writeAsString(personsJsonString);
      }

      final List<dynamic> parsedGroups = json.decode(groupsJsonString);
      final List<dynamic> parsedPersons = json.decode(personsJsonString);
      
      groups.clear();
      groups.addAll(parsedGroups.map((g) => GroupModel.fromJson(g as Map<String, dynamic>)).toList());

      persons.clear();
      persons.addAll(parsedPersons.map((p) => PersonModel.fromJson(p as Map<String, dynamic>)).toList());

    } catch (e) {
      groups.clear();
      groups.addAll(_generateMockGroups());
      await initPersons();
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
    final List<Map<String, dynamic>> jsonList = groups.map((g) => g.toJson()).toList();
    final String jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

  List<GroupModel> _generateMockGroups() {
    final List<PersonModel> mockPersons = List.generate(10, (index) {
      return PersonModel(id: 'p_${index + 1}', name: 'Person ${index + 1}', image: '');
    });

    return [
      GroupModel(
        id: 'group_1',
        name: 'Tech Enthusiasts',
        description: 'A group for people loving flutter and tech.',
        image: '',
        members: [mockPersons[0].id, mockPersons[1].id, mockPersons[2].id, mockPersons[3].id],
      ),
      GroupModel(
        id: 'group_2',
        name: 'Design Pioneers',
        description: 'Focusing on UI/UX trends and clean visuals.',
        image: '',
        members: [mockPersons[4].id, mockPersons[5].id, mockPersons[6].id],
      ),
      GroupModel(
        id: 'group_3',
        name: 'Project Managers',
        description: 'Agile sprints, coordination, and delivery.',
        image: '',
        members: [mockPersons[7].id, mockPersons[8].id, mockPersons[9].id, mockPersons[0].id],
      ),
    ];
  }

  Future<void> initPersons() {
    final List<PersonModel> mockPersons = List.generate(10, (index) {
      return PersonModel(id: 'p_${index + 1}', name: 'Person ${index + 1}', image: '');
    });
    persons.clear();
    persons.addAll(mockPersons);
    return Future.value();
  }
  
  @override
  Future<List<PersonModel>> getAllPersons() async {
    if (!_initialized) {
      await _initialize();
    }
    return List.from(persons);
  }

  Future<List<PersonModel>> getPersonsFromGroup(int groupIndex) async {
    if (!_initialized) {
      await _initialize();
    }
    if (groupIndex < 0 || groupIndex >= groups.length) {
      return [];
    }
    final group = groups[groupIndex];
    return persons.where((p) => group.members.contains(p.id)).toList();
  }

  @override
  Future<void> updateGroup(GroupModel updatedGroup) async {
    if (!_initialized) await _initialize();
    final index = groups.indexWhere((g) => g.id == updatedGroup.id);
    if (index != -1) {
      groups[index] = updatedGroup;
      await _writeGroupsToJson();
    }
  }
}