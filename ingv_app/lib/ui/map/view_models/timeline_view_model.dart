import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';

class TimelineViewModel extends ChangeNotifier {
  final IEventRepository _eventRepository;
  final IEventSearchRepository _searchRepository;

  List<EventModel> events = [];
  List<String> categories = [];

  // Filter states
  String searchQuery = '';
  String selectedCategory = 'All';
  DateTime? filterStartDate;
  DateTime? filterEndDate;

  DateTime minStart = DateTime.now();
  DateTime maxEnd = DateTime.now();

  TimelineViewModel(this._eventRepository, this._searchRepository);

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
    notifyListeners();
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
