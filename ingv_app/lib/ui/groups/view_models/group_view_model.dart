// lib/view_models/group_screen_view_model.dart
import 'package:flutter/material.dart';
import '../../../data/models/group_model.dart';
import '../../../data/repositories/group_repository.dart';

class GroupScreenViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;

  List<GroupModel> groups = [];
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

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}