import 'package:flutter/material.dart';
import 'package:ingv_app/ui/file_history/view_models/file_history_view_model.dart';
import 'package:ingv_app/data/models/file_version.dart';

class DocumentComparisonScreen extends StatefulWidget {
  const DocumentComparisonScreen({Key? key}) : super(key: key);

  @override
  State<DocumentComparisonScreen> createState() =>
      _DocumentComparisonScreenState();
}

class _DocumentComparisonScreenState extends State<DocumentComparisonScreen> {
  final DocumentMergeViewModel _viewModel = DocumentMergeViewModel();

  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel.generateFileHistory();
    _viewModel.addListener(_onViewModelStateChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelStateChanged);
    _viewModel.dispose();
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    super.dispose();
  }

  void _onViewModelStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Comparing Document Versions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 22,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_viewModel.leftVersion != null)
                      Expanded(
                        child: _buildVersionColumn(
                          currentSelectedVersion: _viewModel.leftVersion!,
                          isLeft: true,
                          scrollController: _leftScrollController,
                        ),
                      ),
                    const VerticalDivider(width: 4, color: Colors.grey),
                    if (_viewModel.rightVersion != null)
                      Expanded(
                        child: _buildVersionColumn(
                          currentSelectedVersion: _viewModel.rightVersion!,
                          isLeft: false,
                          scrollController: _rightScrollController,
                        ),
                      ),
                  ],
                ),
              ),
              _buildSaveToolbar(),
            ],
          ),
          if (_viewModel.isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVersionColumn({
    required FileVersion currentSelectedVersion,
    required bool isLeft,
    required ScrollController scrollController,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Info Card Layout Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header components: version and select all button
                SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isLeft
                          ? DropdownButtonHideUnderline(
                              child: DropdownButton<FileVersion>(
                                value: currentSelectedVersion,
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.blue,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                                onChanged: (FileVersion? newSelection) {
                                  if (newSelection != null) {
                                    _viewModel.updateSelectedVersion(
                                      targetVersion: newSelection,
                                      isLeftColumn: isLeft,
                                    );
                                  }
                                },
                                items: _viewModel.documentHistory
                                    .map<DropdownMenuItem<FileVersion>>((
                                      FileVersion value,
                                    ) {
                                      return DropdownMenuItem<FileVersion>(
                                        value: value,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            value.versionName,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currentSelectedVersion.versionName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                      ElevatedButton(
                        onPressed: () => _viewModel.selectAllForVersion(isLeft),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                        ),
                        child: const Text(
                          'Accept All',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentSelectedVersion.metaInfo,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 25, 25, 25),
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  currentSelectedVersion.subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            height: 20,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: currentSelectedVersion.blocks.length,
              itemBuilder: (context, index) {
                final block = currentSelectedVersion.blocks[index];
                return _buildSectionCard(block, isLeft);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(TextBlock block, bool isLeft) {
    Color cardBg = block.isSelected ? Colors.green.shade50 : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(
          color: block.isSelected
              ? Colors.green.shade400
              : Colors.grey.shade400,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    block.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _viewModel.updateBlockSelection(
                        block.id,
                        isLeft,
                        true,
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: block.isSelected
                            ? Colors.green
                            : Colors.white,
                        side: BorderSide(
                          color: block.isSelected
                              ? Colors.green
                              : Colors.grey.shade400,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        'Accept',
                        style: TextStyle(
                          color: block.isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () => _viewModel.updateBlockSelection(
                        block.id,
                        isLeft,
                        false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !block.isSelected
                            ? Colors.grey[200]
                            : Colors.blue[600],
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        'Reject',
                        style: TextStyle(
                          color: !block.isSelected
                              ? Colors.black54
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              block.content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(top: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: _viewModel.isSaving
                ? null // Disable the button while saving
                : () async {
                    // Call the ViewModel method to compile and commit strings
                    bool success = await _viewModel.compileAndSaveChanges();
                    if (success && mounted) {
                      // Show a confirmation banner
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Changes compiled and saved successfully!',
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text(
              'Save Changes',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
