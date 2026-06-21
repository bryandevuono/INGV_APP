import 'package:flutter/material.dart';
import '../../../data/repositories/group_repository.dart';
import '../view_models/group_view_model.dart';
import 'package:ingv_app/data/services/group_service_sembast.dart';
import 'group_dialog.dart';
import 'presentation_card.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late final GroupScreenViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GroupScreenViewModel(GroupRepository(GroupServiceSembast()));
    _viewModel.fetchGroups();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            16.0,
          ), // Reduced slightly from 24 for better mobile screen usage
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Groups',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddGroupDialog(context),
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.blue,
                      size: 24,
                    ),
                    label: const Text(
                      'Add group',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, child) {
                    if (_viewModel.isLoading && _viewModel.groups.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_viewModel.errorMessage != null) {
                      return Center(child: Text(_viewModel.errorMessage!));
                    }

                    if (_viewModel.groups.isEmpty) {
                      return const Center(
                        child: Text('No groups found. Create one!'),
                      );
                    }

                    // LayoutBuilder checks the screen width dynamically
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate appropriate column count based on available screen width
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 700) {
                          crossAxisCount = 4; // Tablets / Web
                        } else if (constraints.maxWidth > 380) {
                          crossAxisCount = 3; // Mid-to-Large mobile phones
                        }

                        return GridView.builder(
                          itemCount: _viewModel.groups.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            // Adjusting the aspect ratio depending on columns for clear visibility
                            childAspectRatio: crossAxisCount == 1 ? 1.2 : 1.05,
                          ),
                          itemBuilder: (context, index) {
                            return GroupCard(
                              group: _viewModel.groups[index],
                              groupId: _viewModel.groups[index].id,
                              viewModel: _viewModel,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return GroupDialog(mode: 'create', groupId: "", viewModel: _viewModel);
      },
    );
  }
}
