// lib/view_models/group_screen_view_model.dart
import 'package:flutter/material.dart';
import '../../../data/models/group_model.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/models/person_model.dart';

class GroupScreenViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;

  List<GroupModel> groups = [];
  List<PersonModel> persons = [];
  bool isLoading = false;
  String? errorMessage;

  GroupScreenViewModel(this._groupRepository);

  Future<void> fetchGroups() async {
    _setLoading(true);
    errorMessage = null;
    
    try {
      groups = await _groupRepository.getGroups();
    } catch (e) {
      errorMessage = "Failed to load groups: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createNewGroup(String name) async {
    _setLoading(true);
    errorMessage = null;
    
    try {
      final newGroup = GroupModel(id: DateTime.now().toString(), name: name, members: [], description: '', image: '');
      await _groupRepository.insertGroup(newGroup);
      groups.add(newGroup);
      notifyListeners();
    } catch (e) {
      errorMessage = "Failed to create group: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> editGroup(String groupId, String newName) async {
    _setLoading(true);
    errorMessage = null;
    
    try {
      final groupIndex = groups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        final updatedGroup = GroupModel(
          id: groups[groupIndex].id,
          name: newName,
          members: groups[groupIndex].members,
          description: groups[groupIndex].description,
          image: groups[groupIndex].image,
        );
        await _groupRepository.updateGroup(updatedGroup);
        groups[groupIndex] = updatedGroup;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Failed to update group: $e";
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> getPersons() async {
    try {
      persons = await _groupRepository.getPersons();
      notifyListeners();
    } catch (e) {
      errorMessage = "Failed to load persons: $e";
      notifyListeners();
    }
  }

  Future<void> addorRemoveMember(String groupId, String personId) async {
    _setLoading(true);
    errorMessage = null;
    
    try {
      final groupIndex = groups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        final group = groups[groupIndex];
        if (!group.members.contains(personId)) {
          final updatedGroup = GroupModel(
            id: group.id,
            name: group.name,
            members: [...group.members, personId],
            description: group.description,
            image: group.image,
          );
          await _groupRepository.updateGroup(updatedGroup);
          groups[groupIndex] = updatedGroup;
          notifyListeners();
        } else {
          final updatedGroup = GroupModel(
            id: group.id,
            name: group.name,
            members: group.members.where((id) => id != personId).toList(),
            description: group.description,
            image: group.image,
          );
          await _groupRepository.updateGroup(updatedGroup);
          groups[groupIndex] = updatedGroup;
          notifyListeners();
        }
      }
    } catch (e) {
      errorMessage = "Failed to add member: $e";
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
}
      