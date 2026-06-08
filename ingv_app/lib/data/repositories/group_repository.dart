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
}