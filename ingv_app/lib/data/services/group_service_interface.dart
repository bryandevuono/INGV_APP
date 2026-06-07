import 'package:ingv_app/data/models/group_model.dart';

abstract class IGroupService {
  Future<List<GroupModel>> getGroups();
   Future<void> insertGroup(GroupModel group);
}
