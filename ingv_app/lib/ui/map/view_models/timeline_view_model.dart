import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/data/services/event_search_service.dart';

class TimelineViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  late final EventSearchRepository _searchRepository;

  // Managed UI states migrated from the Screen
  final Set<String> _minimizedCategories = {};
  List<String> _orderedCategories = [];

  List<EventModel> events = [];
  List<String> categories = [];

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
      EventSearchService(_eventRepository.service),
    );
  }

  Future<void> fetchEvents() async {
    final fetchedCategories = await _eventRepository.getEventCategories();
    categories = ['All', ...fetchedCategories];
    await applyFilters();
  }

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


  void reorderCategories(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _orderedCategories.removeAt(oldIndex);
    _orderedCategories.insert(newIndex, item);
    notifyListeners();
  }

  void toggleCategoryMinimized(String category) {
    if (_minimizedCategories.contains(category)) {
      _minimizedCategories.remove(category);
    } else {
      _minimizedCategories.add(category);
    }
    notifyListeners();
  }

  bool isCategoryMinimized(String category) {
    return _minimizedCategories.contains(category);
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    applyFilters();
  }

  void setCategoryFilter(String category) {
    selectedCategory = category;
    applyFilters();
  }

  void setDateRangeFilter(DateTime? start, DateTime? end) {
    filterStartDate = start;
    filterEndDate = end;
    applyFilters();
  }

  Future<Map<String, DateTime>> getEventDateRange() async {
    final range = await _eventRepository.getEventDateRange();
    minStart = range["minStart"] ?? DateTime.now();
    maxEnd = range["maxEnd"] ?? DateTime.now();
    notifyListeners();
    return {"minStart": minStart, "maxEnd": maxEnd};
  }

  Future<void> addEvent(EventModel event) async {
    await _eventRepository.insertEvent(event);
    await getEventDateRange();
    await fetchEvents();
  }
}