
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/models/person_model.dart';
abstract class IGroupService {
  Future<List<GroupModel>> getGroups();
  Future<void> insertGroup(GroupModel group);
  Future<List<PersonModel>> getAllPersons();
  Future<void> updateGroup(GroupModel updatedGroup);
  Future<bool> deleteGroup(String groupId);
  dynamic getImageByGroupId(String groupId);
  Future<List<GroupModel>> getGroupsOfUser(String userId);
  void postImageToGroupId(String groupId, String imagePath);
}
