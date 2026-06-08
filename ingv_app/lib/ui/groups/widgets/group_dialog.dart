import 'package:flutter/material.dart';

class GroupDialog extends StatefulWidget {
  const GroupDialog({super.key, required this.mode});

  final String mode;

  @override
  State<GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<GroupDialog> {
  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final searchController = TextEditingController();

    // Mock data for the list view inside the dialog
    final List<String> mockUsers = [
      'Robert van Tilburg',
      'Julia van Tilburg',
      'Henkie van Tilburg',
    ];
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Add people to group:',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Name Input Row
                Row(
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'Name:',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Input field',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Media Input Row
                Row(
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'Media:',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // File picker logic goes here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Add file',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Input Bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 20,
                      ),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Total Users Text Indicator
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Showing ${mockUsers.length} users:',
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 12),

                // Users List
                Expanded(
                  child: ListView.builder(
                    itemCount: mockUsers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            // Circular Outline Profile Badge
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.grey.shade600,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 20),

                            // User Display Name
                            Expanded(
                              child: Text(
                                mockUsers[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),

                            // Add Button
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Dialog Actions (Footer Row)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          // Trigger your _viewModel here to finalize creation
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: widget.mode == 'create'
                          ? const Text('Create Group')
                          : const Text('Update Group'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
