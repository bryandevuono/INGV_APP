import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/models/person_model.dart'; 
import 'group_service_interface.dart';

class GroupServiceSembast implements IGroupService {
  static final GroupServiceSembast _instance = GroupServiceSembast._internal();
  factory GroupServiceSembast() => _instance;
  GroupServiceSembast._internal();

  Database? _database;
  final List<GroupModel> groups = [];
  final List<PersonModel> persons = [];
  bool _initialized = false;

  final _groupsStore = stringMapStoreFactory.store('groups');
  final _personsStore = stringMapStoreFactory.store('persons');

  Future<Database> get _db async {
    if (_database != null) return _database!;
    
    final directory = await getApplicationDocumentsDirectory();
    await directory.create(recursive: true);
    final dbPath = join(directory.path, 'ingv_database.db');
    
    _database = await databaseFactoryIo.openDatabase(dbPath);
    return _database!;
  }

  Future<bool> isDatabaseEmpty() async {
    final db = await _db;
    final groupsCount = await _groupsStore.count(db);
    final personsCount = await _personsStore.count(db);
    return groupsCount == 0 && personsCount == 0;
  }

  Future<void> clearDatabase() async {
    final db = await _db;
    await _groupsStore.drop(db);
    await _personsStore.drop(db);

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
      final db = await _db;
      await _groupsStore.drop(db);
      groups.clear();
      return true;
    } catch (e) {
      return false; 
    }
  }

  Future<void> _initialize() async {
    try {
      final db = await _db;

      // 1. Handle Groups Initialization
      final groupsCount = await _groupsStore.count(db);
      if (groupsCount == 0) {
        final generatedGroups = _generateMockGroups();
        for (var group in generatedGroups) {
          await _groupsStore.record(group.id).put(db, group.toJson());
        }
      }

      final personsCount = await _personsStore.count(db);
      if (personsCount == 0) {
        final List<PersonModel> mockPersons = List.generate(10, (index) {
          return PersonModel(id: 'p_${index + 1}', name: 'Person ${index + 1}', image: '');
        });
        for (var person in mockPersons) {
          await _personsStore.record(person.id).put(db, person.toJson());
        }
      }

      final groupSnapshots = await _groupsStore.find(db);
      groups.clear();
      groups.addAll(
        groupSnapshots.map((snap) => GroupModel.fromJson(snap.value)).toList()
      );

      final personSnapshots = await _personsStore.find(db);
      persons.clear();
      persons.addAll(
        personSnapshots.map((snap) => PersonModel.fromJson(snap.value)).toList()
      );

    } catch (e) {
      groups.clear();
      groups.addAll(_generateMockGroups());
      initPersons();
    }
    _initialized = true;
  }

  @override
  Future<void> insertGroup(GroupModel group) async {
    if (!_initialized) await _initialize();
    
    final db = await _db;
    await _groupsStore.record(group.id).put(db, group.toJson());
    
    // Maintain local state consistency
    groups.add(group);
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

  void initPersons() {
    final List<PersonModel> mockPersons = List.generate(10, (index) {
      return PersonModel(id: 'p_${index + 1}', name: 'Person ${index + 1}', image: '');
    });
    persons.clear();
    persons.addAll(mockPersons);
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
    
    final db = await _db;
    await _groupsStore.record(updatedGroup.id).put(db, updatedGroup.toJson());
    
    final index = groups.indexWhere((g) => g.id == updatedGroup.id);
    if (index != -1) {
      groups[index] = updatedGroup;
    }
  }
}