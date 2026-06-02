import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/data/services/event_search_service.dart';
import 'package:ingv_app/data/services/event_service_json.dart';

class MapScreenViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  late final EventSearchRepository _searchRepository;

  List<EventModel> events = [];
  List<String> categories = [];

  // Filter states
  String searchQuery = '';
  String selectedCategory = 'All';
  DateTime? filterStartDate;
  DateTime? filterEndDate;

  MapScreenViewModel(this._eventRepository) {
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
}
