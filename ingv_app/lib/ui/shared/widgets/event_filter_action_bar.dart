import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';

class EventFilterActionBar extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showCategoryDropdown;
  final bool showDateFilter;
  final bool showSearch;
  final bool showExportPdf;
  final bool showExportZip;
  final bool showAddEvent;
  final bool isExporting;
  final ValueChanged<String>? onCategoryChanged;
  final Future<void> Function()? onDateRangePicked;
  final VoidCallback? onClearDateFilter;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportZip;
  final Future<void> Function()? onExportDateRangePdf;
  final Future<void> Function()? onExportDateRangeZip;
  final VoidCallback? onAddEvent;
  final bool embeddedInPage;
  final Duration? timelineScaleDuration;
  final List<EventModel> searchSuggestions;
  final ValueChanged<EventModel>? onSuggestionSelected;

  const EventFilterActionBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.searchQuery,
    required this.startDate,
    required this.endDate,
    this.showCategoryDropdown = true,
    this.showDateFilter = true,
    this.showSearch = true,
    this.showExportPdf = false,
    this.showExportZip = false,
    this.showAddEvent = false,
    this.isExporting = false,
    this.onCategoryChanged,
    this.onDateRangePicked,
    this.onClearDateFilter,
    this.onSearchChanged,
    this.onExportPdf,
    this.onExportZip,
    this.onExportDateRangePdf,
    this.onExportDateRangeZip,
    this.onAddEvent,
    this.embeddedInPage = false,
    this.timelineScaleDuration,
    this.searchSuggestions = const [],
    this.onSuggestionSelected,
  });

  @override
  State<EventFilterActionBar> createState() => _EventFilterActionBarState();
}

class _EventFilterActionBarState extends State<EventFilterActionBar> {
  late final TextEditingController _searchController;
  final LayerLink _searchLayerLink = LayerLink();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _suggestionsOverlay;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void didUpdateWidget(covariant EventFilterActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
    if (widget.searchSuggestions != oldWidget.searchSuggestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_searchFocusNode.hasFocus && widget.searchSuggestions.isNotEmpty) {
          _showSuggestionsOverlay();
        } else {
          _removeSuggestionsOverlay();
        }
      });
    }
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      _removeSuggestionsOverlay();
    } else if (widget.searchSuggestions.isNotEmpty) {
      _showSuggestionsOverlay();
    }
  }

  void _showSuggestionsOverlay() {
    if (widget.searchSuggestions.isEmpty) {
      _removeSuggestionsOverlay();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_suggestionsOverlay == null) {
        _suggestionsOverlay = OverlayEntry(
          builder: (context) => Positioned(
            width: 260,
            child: CompositedTransformFollower(
              link: _searchLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 44),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: widget.searchSuggestions.length,
                    itemBuilder: (context, index) {
                      final event = widget.searchSuggestions[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) {
                          _selectSuggestion(event);
                        },
                        child: ListTile(
                          dense: true,
                          title: Text(event.title),
                          subtitle: Text(event.category),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        Overlay.of(context).insert(_suggestionsOverlay!);
      } else {
        _suggestionsOverlay!.markNeedsBuild();
      }
    });
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  void _selectSuggestion(EventModel event) {
    setState(() {
      _searchController.text = event.title;
    });

    widget.onSearchChanged?.call(event.title);

    _removeSuggestionsOverlay();
    _searchFocusNode.unfocus();
    widget.onSuggestionSelected?.call(event);
  }

  @override
  void dispose() {
    _removeSuggestionsOverlay();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _dateLabel() {
    if (widget.startDate == null) {
      return 'Filter by Date';
    }
    final start = widget.startDate!.toLocal().toString().split(' ')[0];
    final end = widget.endDate?.toLocal().toString().split(' ')[0] ?? 'Any';
    return '$start - $end';
  }

  String _formatDurationLabel(Duration duration) {
    if (duration.inDays >= 7) {
      final weeks = duration.inDays ~/ 7;
      return '${weeks} week(s)';
    } else if (duration.inDays >= 1) {
      return '${duration.inDays} day(s)';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} hour(s)';
    } else {
      return '${duration.inMinutes} minute(s)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (widget.showCategoryDropdown)
          SizedBox(
            width: 180,
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.selectedCategory,
                  isExpanded: true,
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: widget.onCategoryChanged == null
                      ? null
                      : (value) {
                          if (value != null) {
                            widget.onCategoryChanged!(value);
                          }
                        },
                ),
              ),
            ),
          ),
        if (widget.showDateFilter)
          TextButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(_dateLabel()),
            onPressed: widget.onDateRangePicked == null
                ? null
                : () => widget.onDateRangePicked!(),
          ),
        if (widget.showDateFilter &&
            (widget.startDate != null || widget.endDate != null) &&
            widget.onClearDateFilter != null)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Date Filter',
            onPressed: widget.onClearDateFilter,
          ),

        if (widget.showExportPdf || widget.showExportZip)
          PopupMenuButton<String>(
            tooltip: 'Download export options',
            enabled: !widget.isExporting,
            onSelected: (value) {
              switch (value) {
                case 'visible_pdf':
                  widget.onExportPdf?.call();
                  break;
                case 'visible_zip':
                  widget.onExportZip?.call();
                  break;
                case 'range_pdf':
                  widget.onExportDateRangePdf?.call();
                  break;
                case 'range_zip':
                  widget.onExportDateRangeZip?.call();
                  break;
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];
              if (widget.showExportPdf && widget.onExportPdf != null) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'visible_pdf',
                    child: Text('Export as PDF'),
                  ),
                );
              }
              if (widget.showExportZip && widget.onExportZip != null) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'visible_zip',
                    child: Text('Export as ZIP'),
                  ),
                );
              }
              if (widget.onExportDateRangePdf != null) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'range_pdf',
                    child: Text('Export date range as PDF'),
                  ),
                );
              }
              if (widget.onExportDateRangeZip != null) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'range_zip',
                    child: Text('Export date range as ZIP'),
                  ),
                );
              }
              return items;
            },
            icon: widget.isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
          ),
        if (widget.showSearch)
          CompositedTransformTarget(
            link: _searchLayerLink,
            child: SizedBox(
              width: 220,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: widget.onSearchChanged, // unchanged
                decoration: InputDecoration(
                  hintText: 'Search (keywords, tags)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged?.call('');
                            _removeSuggestionsOverlay();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                ),
              ),
            ),
          ),
        if (widget.showAddEvent)
          TextButton.icon(
            onPressed: widget.onAddEvent,
            icon: const Icon(Icons.add),
            label: const Text('Add event'),
          ),
        if (widget.timelineScaleDuration != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Timeline scale: ${_formatDurationLabel(widget.timelineScaleDuration!)}',
            ),
          ),
      ],
    );

    if (widget.embeddedInPage) {
      return toolbar;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: toolbar,
    );
  }
}
