import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/services/attachment_service.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/timeline_presentation_models.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/services/event_detail_service.dart';
import 'package:ingv_app/data/services/export_service.dart';
import 'package:ingv_app/data/services/file_operations_service.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';
import 'timeline_interface.dart';
import 'package:ingv_app/data/repositories/group_repository.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/services/group_service_sembast.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';

class TimelineViewModel extends ChangeNotifier implements ITimelineViewModel {
  final IEventRepository _eventRepository;
  final IEventSearchRepository _searchRepository;
  final IEventDetailRepository _detailRepository;
  final AttachmentRepository _attachmentRepository;
  final ILocalFileService _localFileService;
  late final IPdfExportService _pdfExportService;
  late final IZipExportService _zipExportService;

  final GroupRepository? _groupRepository = GroupRepository(
    GroupServiceSembast(),
  );

  // Internal State
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  final List<String> _orderedCategories = [];
  final Set<String> _minimizedCategories = {};
  List<GroupModel> _userGroups = [];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  bool _isExporting = false;
  String? _exportErrorMessage;
  Duration _timeScale = const Duration(days: 7);

  // Color configuration map populated from Repository
  Map<String, Color> _categoryColors = {};

  TimelineViewModel(this._eventRepository, this._searchRepository)
    : _detailRepository = EventDetailRepository(EventDetailService()),
      _attachmentRepository = AttachmentRepository(AttachmentService()),
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
    try {
      await getColors();
      await fetchEvents();
      await getGroupsOfUser();
    } catch (e) {
      _exportErrorMessage = "Initialization failed: $e";
      notifyListeners();
    }
  }

  @override
  List<EventModel> get events => _filteredEvents;

  @override
  List<GroupModel> get userGroups => _userGroups;

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

  void set searchQuery(String query) {
    _searchQuery = query;
    applyFilters();
    notifyListeners();
  }

  List<EventModel> searchSuggestions = [];
  @override
  Future<void> setSearchQuery(String query) async {
    searchQuery = query;
    await applyFilters();
    searchSuggestions = events.take(5).toList();
    notifyListeners();
  }

  Future<void> selectSuggestion(EventModel event) async {
    searchQuery = event.title;
    searchSuggestions = [];
    notifyListeners();

    try {
      jumpToEvent(event);
    } catch (e) {
      debugPrint("Error moving map to selected suggestion: $e");
    }

    await applyFilters();
  }

  // Calculate the min date
  DateTime get minStart {
    if (_allEvents.isEmpty) return DateTime.now();
    return _allEvents
        .map((e) => e.startDt)
        .reduce((value, element) => value.isBefore(element) ? value : element);
  }

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

  @override
  Future<void> fetchEvents() async {
    try {
      final results = await Future.wait([
        _eventRepository.getAllEvents(),
        _eventRepository.getEventCategories(),
      ]);

      _allEvents = results[0] as List<EventModel>;
      await getColors();

      // Re-populate ordered categories if new ones are introduced
      final currentCategories = categories;
      for (var cat in currentCategories) {
        if (!_orderedCategories.contains(cat)) {
          _orderedCategories.add(cat);
        }
      }
      _orderedCategories.removeWhere((cat) => !currentCategories.contains(cat));

      _applyFilters();

      _exportErrorMessage = null;
      notifyListeners();
    } catch (e) {
      _exportErrorMessage = "Failed to load events: $e";
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredEvents = _allEvents.where((event) {
      if (_selectedCategory != 'All' &&
          event.category.trim() != _selectedCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = event.title.toLowerCase().startsWith(query);
        final matchesDescription = event.description.toLowerCase().contains(
          query,
        );
        if (!matchesTitle && !matchesDescription) return false;
      }

      final eventEnd = event.endDt ?? event.startDt;
      final filterDayStart = _filterStartDate ?? event.startDt;

      // Event ends before the filter window starts
      if (eventEnd.isBefore(filterDayStart)) {
        return false;
      }
      // Event starts after the filter window ends (end of that day)
      if (_filterEndDate != null &&
          event.startDt.isAfter(_filterEndDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<void> applyFilters() async {
    _applyFilters();
    notifyListeners();
  }

  @override
  void reorderCategories(int oldIndex, int newIndex) {
    if (_orderedCategories.isEmpty ||
        oldIndex < 0 ||
        oldIndex >= _orderedCategories.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final int targetIndex = newIndex
        .clamp(0, _orderedCategories.length - 1)
        .toInt();
    if (oldIndex == targetIndex) {
      return;
    }

    final String item = _orderedCategories.removeAt(oldIndex);
    _orderedCategories.insert(targetIndex, item);
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
    try {
      return await _eventRepository.getEventDateRange();
    } catch (_) {
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
  }

  @override
  Future<void> addEvent(EventModel event) async {
    await _eventRepository.insertEvent(event);
    await fetchEvents();
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
        final matchesTitle = event.title.toLowerCase().startsWith(query);
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

    if (events.isEmpty) {
      _exportErrorMessage = 'No events to export.';
      _isExporting = false;
      notifyListeners();
      return null;
    }

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

    if (events.isEmpty) {
      _exportErrorMessage = 'No events to export.';
      _isExporting = false;
      notifyListeners();
      return null;
    }

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
    try {
      final categoryColors = await _eventRepository.getEventColors();
      if (categoryColors.isEmpty) {
        _categoryColors = {
          'Volcanic': Colors.red,
          'Earthquake': Colors.green,
          'Hydrological': Colors.blue,
          'Meteorological': Colors.orange,
          'Geological': Colors.brown,
          'Atmospheric': Colors.teal,
        };
      } else {
        _categoryColors = {
          for (final entry in categoryColors) entry.key: entry.value,
        };
      }
    } catch (e) {
      _categoryColors = {
        'Volcanic': Colors.red,
        'Earthquake': Colors.green,
        'Hydrological': Colors.blue,
        'Meteorological': Colors.orange,
        'Geological': Colors.brown,
        'Atmospheric': Colors.teal,
      };
    }
    notifyListeners();
  }

  @override
  Future<String?> getGroupOfEvent(int eventId) async {
    return await _eventRepository.getGroupOfEvent(eventId);
  }

  @override
  Future<void> getGroupsOfUser() async {
    try {
      final userId = await getUserId();
      final List<GroupModel> groups =
          await (_groupRepository?.getGroupsOfUser(userId)) ?? [];
      _userGroups = groups;
      notifyListeners();
    } catch (e) {
      _exportErrorMessage = "Failed to load user groups: $e";
      notifyListeners();
    }
  }

  @override
  Future<String> getUserId() async {
    // placeholder, there is no login system implemented yet
    return "p_1";
  }

  @override
  Future<String?> exportTimelineReport() async {
    return _exportTimelinePdf(events: _filteredEvents);
  }

  @override
  Future<String?> exportTimelineAsZip() async {
    return _exportTimelineZip(events: _filteredEvents);
  }

  void jumpToEvent(EventModel event) {
    _filterStartDate = event.startDt;
    notifyListeners();
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

  @override
  void setTimeScale(Duration scale) {
    _timeScale = scale;
    _eventRepository.setTimeScale(scale);
  }

  @override
  Duration getTimeScale() {
    return _timeScale;
  }
}
