import 'package:flutter/material.dart';
import '../../../data/models/group_model.dart';
import '../view_models/group_view_model.dart';
import 'group_dialog.dart';

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final String groupId;
  final GroupScreenViewModel viewModel;
  const GroupCard({
    super.key,
    required this.group,
    required this.groupId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context)  {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top image placeholder
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.grey[300],
                  child: viewModel.getGroupImage(groupId) ?? const Icon(Icons.group, size: 48, color: Colors.white),
                ),
              ),

              // Bottom content area
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment
                        .center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              group.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Members: ${group.members.join(', ')}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Edit button right next to the text
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              // Fixed: Added groupId parameter passing here
                              return GroupDialog(
                                mode: 'update',
                                groupId: groupId,
                                viewModel: viewModel,
                              );
                            },
                          );
                        },
                        child: const Text('Edit'),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: const Text(
                                'Are you sure you want to delete this group?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    viewModel.deleteGroup(groupId);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
