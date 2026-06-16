import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/repositories/attachment_repository_interface.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/timeline_presentation_models.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/services/event_detail_service.dart';
import 'package:ingv_app/data/services/export_service.dart';
import 'package:ingv_app/data/services/file_operations_service.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';
import 'timeline_interface.dart';

class TimelineViewModel extends ChangeNotifier implements ITimelineViewModel {
  final IEventRepository _eventRepository;
  final IEventDetailRepository _detailRepository;
  final IAttachmentRepository _attachmentRepository;
  final ILocalFileService _localFileService;
  late final IPdfExportService _pdfExportService;
  late final IZipExportService _zipExportService;

  // Internal State
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  final List<String> _orderedCategories = [];
  final Set<String> _minimizedCategories = {};

  String _selectedCategory = 'All';
  String _searchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  bool _isExporting = false;
  String? _exportErrorMessage;

  // Color configuration map (populated via getColors)
  Map<String, Color> _categoryColors = {};

  TimelineViewModel(this._eventRepository)
    : _detailRepository = EventDetailRepository(EventDetailService()),
      _attachmentRepository = LocalAttachmentRepository(),
      _localFileService = LocalFileService() {
    _pdfExportService = PdfExportService(
      _detailRepository,
      _attachmentRepository,
      _localFileService,
    );
    _zipExportService = ZipExportService(
      pdfExportService: _pdfExportService,
      detailRepository: _detailRepository,
      attachmentRepository: _attachmentRepository,
      localFileService: _localFileService,
    );
    // Initial setup sequence
    _init();
  }

  Future<void> _init() async {
    await getColors();
    await fetchEvents();
  }

  // --- ITimelineViewModel Getters ---

  @override
  List<EventModel> get events => _filteredEvents;

  @override
  List<String> get categories =>
      _allEvents.map((e) => e.category.trim()).toSet().toList();

  @override
  List<String> get orderedCategories => _orderedCategories;

  @override
  bool get isExporting => _isExporting;

  @override
  String? get exportErrorMessage => _exportErrorMessage;

  @override
  String get selectedCategory => _selectedCategory;

  @override
  DateTime? get filterStartDate => _filterStartDate;

  @override
  DateTime? get filterEndDate => _filterEndDate;

  @override
  String get searchQuery => _searchQuery;

  // Calculate the absolute baseline minimum date across all loaded events
  DateTime get minStart {
    if (_allEvents.isEmpty) return DateTime.now();
    return _allEvents
        .map((e) => e.startDt)
        .reduce((value, element) => value.isBefore(element) ? value : element);
  }

  // --- Abstract Presentation Layer Mappings ---

  @override
  List<TimelineLaneData> get timelineLanes {
    return _orderedCategories.map((category) {
      return TimelineLaneData(id: category, label: category);
    }).toList();
  }

  @override
  List<TimelineTaskData> getTimelineTasksForCategory(String category) {
    final laneEvents = _filteredEvents
        .where((e) => e.category.trim() == category)
        .toList();

    return laneEvents.map((event) {
      final color = _categoryColors[event.category.trim()] ?? Colors.grey;

      return TimelineTaskData(
        id: event.eventId.toString(),
        laneId: category,
        title: event.title,
        start: event.startDt,
        end: event.endDt ?? event.startDt.add(const Duration(hours: 1)),
        color: color,
      );
    }).toList();
  }

  // --- Business Logic & State Mutations ---

  @override
  Future<void> fetchEvents() async {
    try {
      // Fetching raw model data through the abstract repository link
      _allEvents = await _eventRepository.getAllEvents();
      await getColors();

      // Re-populate ordered categories if new ones are introduced
      final currentCategories = categories;
      for (var cat in currentCategories) {
        if (!_orderedCategories.contains(cat)) {
          _orderedCategories.add(cat);
        }
      }
      // Remove stale categories that no longer have events
      _orderedCategories.removeWhere((cat) => !currentCategories.contains(cat));

      await applyFilters();
    } catch (e) {
      _exportErrorMessage = "Failed to load events: $e";
      notifyListeners();
    }
  }

  @override
  Future<void> applyFilters() async {
    _filteredEvents = _allEvents.where((event) {
      if (_selectedCategory != 'All' &&
          event.category.trim() != _selectedCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = event.title.toLowerCase().contains(query);
        final matchesDescription = event.description.toLowerCase().contains(
          query,
        );
        if (!matchesTitle && !matchesDescription) return false;
      }

      // 3. Date Frame Filter Match
      if (_filterStartDate != null &&
          event.startDt.isBefore(_filterStartDate!)) {
        return false;
      }
      if (_filterEndDate != null &&
          event.endDt != null &&
          event.endDt!.isAfter(_filterEndDate!)) {
        return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  @override
  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String item = _orderedCategories.removeAt(oldIndex);
    _orderedCategories.insert(newIndex, item);
    notifyListeners();
  }

  @override
  void toggleCategoryMinimized(String category) {
    if (_minimizedCategories.contains(category)) {
      _minimizedCategories.remove(category);
    } else {
      _minimizedCategories.add(category);
    }
    notifyListeners();
  }

  @override
  bool isCategoryMinimized(String category) =>
      _minimizedCategories.contains(category);

  @override
  void setSearchQuery(String query) {
    _searchQuery = query;
    applyFilters();
  }

  @override
  void setCategoryFilter(String category) {
    _selectedCategory = category;
    applyFilters();
  }

  @override
  void setDateRangeFilter(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    applyFilters();
  }

  @override
  Future<Map<String, DateTime>> getEventDateRange() async {
    if (_allEvents.isEmpty) {
      return {
        'start': DateTime.now(),
        'end': DateTime.now().add(const Duration(days: 2)),
      };
    }
    final start = minStart;
    final end = _allEvents
        .map((e) => e.endDt ?? e.startDt)
        .reduce((value, element) => value.isAfter(element) ? value : element);
    return {'start': start, 'end': end};
  }

  @override
  Future<void> addEvent(EventModel event) async {
    await _eventRepository.insertEvent(event);
    await fetchEvents(); // Reload and re-filter array map downstream
  }

  List<EventModel> _exportEventsForDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _allEvents.where((event) {
      if (_selectedCategory != 'All' &&
          event.category.trim() != _selectedCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = event.title.toLowerCase().contains(query);
        final matchesDescription = event.description.toLowerCase().contains(
          query,
        );
        if (!matchesTitle && !matchesDescription) {
          return false;
        }
      }

      if (startDate != null && endDate != null) {
        final eventEnd = event.endDt ?? event.startDt;
        final overlapsRange =
            event.startDt.isBefore(endDate.add(const Duration(days: 1))) &&
            eventEnd.isAfter(startDate.subtract(const Duration(seconds: 1)));
        if (!overlapsRange) {
          return false;
        }
      } else if (startDate != null) {
        final eventEnd = event.endDt ?? event.startDt;
        if (eventEnd.isBefore(startDate.subtract(const Duration(seconds: 1)))) {
          return false;
        }
      } else if (endDate != null) {
        if (event.startDt.isAfter(endDate.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<String> _orderedCategoriesForExport(List<EventModel> events) {
    final categorySet = events.map((event) => event.category.trim()).toSet();
    return _orderedCategories.where(categorySet.contains).toList();
  }

  Future<String?> _exportTimelinePdf({
    required List<EventModel> events,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) async {
    _isExporting = true;
    _exportErrorMessage = null;
    notifyListeners();

    try {
      final result = await _pdfExportService.exportTimelineReport(
        events: events,
        orderedCategories: _orderedCategoriesForExport(events),
        filterStartDate: filterStartDate,
        filterEndDate: filterEndDate,
      );
      return result.saveLocation;
    } catch (error) {
      _exportErrorMessage = 'Failed to export timeline report: $error';
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<String?> _exportTimelineZip({
    required List<EventModel> events,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) async {
    _isExporting = true;
    _exportErrorMessage = null;
    notifyListeners();

    try {
      final result = await _zipExportService.exportTimelineAsZip(
        events: events,
        orderedCategories: _orderedCategoriesForExport(events),
        filterStartDate: filterStartDate,
        filterEndDate: filterEndDate,
      );
      return result.saveLocation;
    } catch (error) {
      _exportErrorMessage = 'Failed to export timeline archive: $error';
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  @override
  Future<void> getColors() async {
    final categoryColors = await _eventRepository.getEventColors();
    if (categoryColors.isEmpty) {
      _categoryColors = {
        'Work': Colors.blue,
        'Personal': Colors.green,
        'Urgent': Colors.red,
        'Education': Colors.purple,
      };
    } else {
      _categoryColors = {
        for (final entry in categoryColors) entry.key: entry.value,
      };
    }
    notifyListeners();
  }

  @override
  Future<void> getGroupsOfUser() async {
    // Implementation placeholder for tracking collaborative user groups
  }

  @override
  Future<String> getUserId() async {
    return "user_fallback_dev_123";
  }

  @override
  Future<String?> exportTimelineReport() async {
    return _exportTimelinePdf(events: _filteredEvents);
  }

  @override
  Future<String?> exportTimelineAsZip() async {
    return _exportTimelineZip(events: _filteredEvents);
  }

  @override
  Future<String?> exportTimelineReportForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _exportTimelinePdf(
      events: _exportEventsForDateRange(startDate: startDate, endDate: endDate),
      filterStartDate: startDate,
      filterEndDate: endDate,
    );
  }

  @override
  Future<String?> exportTimelineAsZipForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _exportTimelineZip(
      events: _exportEventsForDateRange(startDate: startDate, endDate: endDate),
      filterStartDate: startDate,
      filterEndDate: endDate,
    );
  }
}
