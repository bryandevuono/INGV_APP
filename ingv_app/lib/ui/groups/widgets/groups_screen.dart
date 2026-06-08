import 'package:flutter/material.dart';
import '../../../data/repositories/group_repository.dart';
import '../view_models/group_view_model.dart';
import 'package:ingv_app/data/services/group_service_json.dart';
import 'presentation_card.dart';
import 'group_dialog.dart';

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
    _viewModel = GroupScreenViewModel(GroupRepository(GroupServiceJson()));
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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Groups',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddGroupDialog(context),
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.blue,
                      size: 28,
                    ),
                    label: const Text(
                      'Add group',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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

                    return GridView.builder(
                      itemCount: _viewModel.groups.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemBuilder: (context, index) {
                        return GroupCard(group: _viewModel.groups[index]);
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
        return const GroupDialog(mode: 'create');
      },
    );
  }
}
