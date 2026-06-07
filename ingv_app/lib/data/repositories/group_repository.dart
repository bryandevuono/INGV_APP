import '../models/group_model.dart';
import '../services/group_service_interface.dart';
class GroupRepository {
  final IGroupService _groupService;

  GroupRepository(this._groupService);

  Future<List<GroupModel>> getGroups() {
    return _groupService.getGroups();
  }

  Future<void> insertGroup(GroupModel group) {
    return _groupService.insertGroup(group);
  }
}