// event_filter_action_bar.dart
import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';

class EventFilterActionBar extends StatefulWidget {
  static const List<Duration> defaultTimeScales = [
    Duration(days: 7),
    Duration(days: 1),
    Duration(hours: 12),
    Duration(hours: 1),
  ];

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
  final bool showExportJson;
  final bool showExportCsv;
  final bool showAddEvent;
  final bool isExporting;
  final ValueChanged<String>? onCategoryChanged;
  final Future<void> Function()? onDateRangePicked;
  final VoidCallback? onClearDateFilter;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onExportPdf;
  final VoidCallback? onExportZip;
  final VoidCallback? onExportJson;
  final VoidCallback? onExportCsv;
  final Future<void> Function()? onExportDateRangePdf;
  final Future<void> Function()? onExportDateRangeZip;
  final Future<void> Function()? onExportDateRangeJson;
  final Future<void> Function()? onExportDateRangeCsv;
  final VoidCallback? onAddEvent;
  final bool embeddedInPage;
  final Duration? timelineScaleDuration;
  final List<Duration> availableTimeScales;
  final ValueChanged<Duration>? onTimeScaleChanged;
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
    this.showExportJson = false,
    this.showExportCsv = false,
    this.showAddEvent = false,
    this.isExporting = false,
    this.onCategoryChanged,
    this.onDateRangePicked,
    this.onClearDateFilter,
    this.onSearchChanged,
    this.onExportPdf,
    this.onExportZip,
    this.onExportJson,
    this.onExportCsv,
    this.onExportDateRangePdf,
    this.onExportDateRangeZip,
    this.onExportDateRangeJson,
    this.onExportDateRangeCsv,
    this.onAddEvent,
    this.embeddedInPage = false,
    this.timelineScaleDuration,
    this.availableTimeScales = EventFilterActionBar.defaultTimeScales,
    this.onTimeScaleChanged,
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

      // Use the same dynamic width as the search field
      final screenWidth = MediaQuery.of(context).size.width;
      final searchWidth = (screenWidth * 0.32).clamp(140.0, 220.0);

      if (_suggestionsOverlay == null) {
        _suggestionsOverlay = OverlayEntry(
          builder: (context) => Positioned(
            width: searchWidth,
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
        // Update the overlay width if it already exists
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

  String _shortScaleLabel(Duration duration) {
    if (duration.inDays >= 7) {
      final weeks = duration.inDays ~/ 7;
      return '${weeks}w';
    } else if (duration.inDays >= 1) {
      return '${duration.inDays}d';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adaptive widths based on screen width
    final double dropdownWidth = (screenWidth * 0.28).clamp(120.0, 180.0);
    final double searchWidth = (screenWidth * 0.32).clamp(140.0, 220.0);

    final toolbar = Wrap(
      spacing: 8, // reduced spacing for small screens
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // ---- Timeline scale toggle buttons ----
        if (widget.onTimeScaleChanged != null &&
            widget.availableTimeScales.isNotEmpty)
          ToggleButtons(
            isSelected: widget.availableTimeScales
                .map((d) => d == widget.timelineScaleDuration)
                .toList(),
            borderRadius: BorderRadius.circular(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 30),
            onPressed: (index) =>
                widget.onTimeScaleChanged!(widget.availableTimeScales[index]),
            children: widget.availableTimeScales
                .map(
                  (d) => Tooltip(
                    message: _formatDurationLabel(d),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _shortScaleLabel(d),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

        if (widget.showCategoryDropdown)
          SizedBox(
            width: dropdownWidth,
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.selectedCategory,
                  isExpanded: true,
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, overflow: TextOverflow.ellipsis),
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

        // ---- Date filter ----
        if (widget.showDateFilter)
          TextButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(_dateLabel()),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: widget.onDateRangePicked == null
                ? null
                : () => widget.onDateRangePicked!(),
          ),
        if (widget.showDateFilter &&
            (widget.startDate != null || widget.endDate != null) &&
            widget.onClearDateFilter != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Clear Date Filter',
            onPressed: widget.onClearDateFilter,
          ),

        if (widget.showExportPdf ||
            widget.showExportZip ||
            widget.showExportJson ||
            widget.showExportCsv)
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
                case 'visible_json':
                  widget.onExportJson?.call();
                  break;
                case 'visible_csv':
                  widget.onExportCsv?.call();
                  break;
                case 'range_pdf':
                  widget.onExportDateRangePdf?.call();
                  break;
                case 'range_zip':
                  widget.onExportDateRangeZip?.call();
                  break;
                case 'range_json':
                  widget.onExportDateRangeJson?.call();
                  break;
                case 'range_csv':
                  widget.onExportDateRangeCsv?.call();
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
              if (widget.showExportJson && widget.onExportJson != null) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'visible_json',
                    child: Text('Export as JSON'),
                  ),
                );
              }
              if (widget.showExportCsv && widget.onExportCsv != null) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'visible_csv',
                    child: Text('Export as CSV'),
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
              if (widget.onExportDateRangeJson != null) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'range_json',
                    child: Text('Export date range as JSON'),
                  ),
                );
              }
              if (widget.onExportDateRangeCsv != null) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'range_csv',
                    child: Text('Export date range as CSV'),
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
          SizedBox(
            width: searchWidth,
            child: CompositedTransformTarget(
              link: _searchLayerLink,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  isDense: true,
                ),
              ),
            ),
          ),

        if (widget.showAddEvent)
          TextButton.icon(
            onPressed: widget.onAddEvent,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add event'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

        if (widget.timelineScaleDuration != null && screenWidth > 500)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Scale: ${_formatDurationLabel(widget.timelineScaleDuration!)}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
      ],
    );

    if (widget.embeddedInPage) {
      return toolbar;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: toolbar,
    );
  }
}