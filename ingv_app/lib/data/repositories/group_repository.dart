import 'package:flutter/cupertino.dart';

import '../models/group_model.dart';
import '../services/group_service_interface.dart';
import '../models/person_model.dart';
class GroupRepository {
  final IGroupService _groupService;

  GroupRepository(this._groupService);

  Future<List<GroupModel>> getGroups() {
    return _groupService.getGroups();
  }

  Future<void> insertGroup(GroupModel group) {
    return _groupService.insertGroup(group);
  }

  Future<List<PersonModel>> getPersons() async {
    return _groupService.getAllPersons();
  }

  Future<void> updateGroup(GroupModel group) {
    return _groupService.updateGroup(group);
  }

  Future<bool> deleteGroup(String groupId) {
    return _groupService.deleteGroup(groupId);
  }

  Future<List<GroupModel>> getGroupsOfUser(String userId) {
    return _groupService.getGroupsOfUser(userId);
  }

  dynamic getImagebyGroupId(String groupId) {
    return _groupService.getImageByGroupId(groupId);
  }

  void postImageToGroupId(String groupId, String imagePath) {
    _groupService.postImageToGroupId(groupId, imagePath);
  }
}