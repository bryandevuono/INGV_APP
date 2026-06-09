import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/data/services/event_search_service.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/repositories/group_repository.dart';
import 'package:ingv_app/data/services/group_service_sembast.dart';

// interface for the view model to interact with the repositories
abstract interface class ITimelineViewModel {
  Future<void> fetchEvents();
  Future<void> applyFilters();
  void reorderCategories(int oldIndex, int newIndex);
  void toggleCategoryMinimized(String category);
  bool isCategoryMinimized(String category);
  void setSearchQuery(String query);
  void setCategoryFilter(String category);
  void setDateRangeFilter(DateTime? start, DateTime? end);
  Future<Map<String, DateTime>> getEventDateRange();
  Future<void> addEvent(EventModel event);
  Future<void> getColors();
  Future<void> getGroupsOfUser();
  Future<String> getUserId();
}

class TimelineViewModel extends ChangeNotifier implements ITimelineViewModel {
  final EventRepository _eventRepository;
  final GroupRepository _groupRepository = GroupRepository(GroupServiceSembast());
  late final EventSearchRepository _searchRepository;

  // Managed UI states migrated from the Screen
  final Set<String> _minimizedCategories = {};
  List<String> _orderedCategories = [];

  List<EventModel> events = [];
  List<String> categories = [];
  List<GroupModel> groupOptions = [];
  List<MapEntry<String, Color>> categoryColors = [];

  List<String> get orderedCategories => _orderedCategories;
  Set<String> get minimizedCategories => _minimizedCategories;

  // Filter states
  String searchQuery = '';
  String selectedCategory = 'All';
  DateTime? filterStartDate;
  DateTime? filterEndDate;

  DateTime minStart = DateTime.now();
  DateTime maxEnd = DateTime.now();
  final startDate = DateTime.now().subtract(const Duration(days: 1));

  TimelineViewModel(this._eventRepository) {
    _searchRepository = EventSearchRepository(
      EventSearchService(_eventRepository.storageService),
    );
  }

  @override
  Future<void> fetchEvents() async {
    final fetchedCategories = await _eventRepository.getEventCategories();
    categories = ['All'];
    for (final category in fetchedCategories) {
      if (category != 'All' && !categories.contains(category)) {
        categories.add(category);
      }
    }
    await applyFilters();
  }

  @override
  Future<void> applyFilters() async {
    events = await _searchRepository.searchAndFilterEvents(
      keyword: searchQuery,
      category: selectedCategory,
      startDate: filterStartDate,
      endDate: filterEndDate,
    );

    _syncOrderedCategories();
    notifyListeners();
  }

  void _syncOrderedCategories() {
    final sourceCategories = categories.where((cat) => cat != 'All').toList();

    // Insert newly discovered categories
    for (var cat in sourceCategories) {
      if (!_orderedCategories.contains(cat)) {
        _orderedCategories.add(cat);
      }
    }

    // Strip out categories no longer present in current dataset
    _orderedCategories = _orderedCategories
        .where((cat) => sourceCategories.contains(cat))
        .toList();
  }

  @override
  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _orderedCategories.removeAt(oldIndex);
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
  bool isCategoryMinimized(String category) {
    return _minimizedCategories.contains(category);
  }

  @override
  void setSearchQuery(String query) {
    searchQuery = query;
    applyFilters();
  }

  @override
  void setCategoryFilter(String category) {
    selectedCategory = category;
    applyFilters();
  }

  @override
  void setDateRangeFilter(DateTime? start, DateTime? end) {
    filterStartDate = start;
    filterEndDate = end;
    applyFilters();
  }

  @override
  Future<Map<String, DateTime>> getEventDateRange() async {
    final range = await _eventRepository.getEventDateRange();
    minStart = range["minStart"] ?? DateTime.now();
    maxEnd = range["maxEnd"] ?? DateTime.now();
    notifyListeners();
    return {"minStart": minStart, "maxEnd": maxEnd};
  }

  @override
  Future<void> addEvent(EventModel event) async {
    await _eventRepository.insertEvent(event);
    await getEventDateRange();
    await fetchEvents();
  }

  @override
  Future<void> getColors() async {
    categoryColors = await _eventRepository.getEventColors();
    notifyListeners();
  }

  @override
  Future<String> getUserId() async {
    // this would come from an authentication service with an Id not a name in a real backend
    return 'p_1';
  }
  @override
  Future<void> getGroupsOfUser() async {
    final groups = await _groupRepository.getGroupsOfUser(await getUserId());
    groupOptions = groups;
    print('Groups for user: ${groupOptions.map((g) => g.name).join(', ')}');
    notifyListeners();
  }
}
