import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/timeline_presentation_models.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'timeline_interface.dart';
import 'package:ingv_app/data/repositories/group_repository.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/services/group_service_sembast.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';

class TimelineViewModel extends ChangeNotifier implements ITimelineViewModel {
  final IEventRepository _eventRepository;
  IEventSearchRepository _searchRepository;
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  List<String> _orderedCategories = [];
  GroupRepository? _groupRepository = GroupRepository(GroupServiceSembast());
  List<GroupModel> _userGroups = [];
  final Set<String> _minimizedCategories = {};

  String _selectedCategory = 'All';
  String _searchQuery = '';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  bool _isExporting = false;
  String? _exportErrorMessage;

  // Color configuration map populated from Repository
  Map<String, Color> _categoryColors = {};

  TimelineViewModel(this._eventRepository, this._searchRepository) {
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
      final List<String> currentCategories = results[1] as List<String>;

      // Track missing or updated categories 
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
        final matchesTitle = event.title.toLowerCase().contains(query);
        final matchesDescription =
            event.description?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesDescription) return false;
      }

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
  }

  @override
  Future<void> applyFilters() async {
    _applyFilters();
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
    if (query.isNotEmpty) {
    _searchRepository.getClosestMatch(query).then((event) {
      if (event != null) {
        jumpToEvent(event);
      }
    });
    } else {
      setDateRangeFilter(null, null);
    }
    notifyListeners();
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

  @override
  Future<void> getColors() async {
    try {
      final MapEntryList = await _eventRepository.getEventColors();
      
      _categoryColors = Map.fromEntries(MapEntryList);
    } catch (e) {
      _categoryColors = {
        'Volcanic': Colors.red,
        'Earthquake': Colors.orange,
        'Hydrological': Colors.blue,
        'Meteorological': Colors.cyan,
        'Geological': Colors.brown,
        'Atmospheric': Colors.green,
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
      final List<GroupModel> groups = await (_groupRepository?.getGroupsOfUser(userId)) ?? [];
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
    _isExporting = true;
    _exportErrorMessage = null;
    notifyListeners();

    try {
      _isExporting = false;
      notifyListeners();
      return "reports/pdf/timeline_export_${DateTime.now().millisecondsSinceEpoch}.pdf";
    } catch (e) {
      _isExporting = false;
      _exportErrorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  Future<String?> exportTimelineAsZip() async {
    _isExporting = true;
    notifyListeners();
    _isExporting = false;
    notifyListeners();
    return "exports/archives/bundle.zip";
  }

  void jumpToEvent(EventModel event) {
    _filterStartDate = event.startDt;
    notifyListeners();
  }
}