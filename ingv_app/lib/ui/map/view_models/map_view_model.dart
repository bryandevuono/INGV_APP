import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';

class MapScreenViewModel extends ChangeNotifier {
  final IEventRepository _eventRepository;
  final IEventSearchRepository _searchRepository;

  List<EventModel> events = [];
  List<String> categories = [];

  // Filter states
  String searchQuery = '';
  String selectedCategory = 'All';
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  Map<String, Color> _categoryColors = {};

  Color getCategoryColor(String category) {
    return _categoryColors[category] ??
        const Color(0xFF9E9E9E); 
  }

  int timelineDurationDays = 7;

  MapScreenViewModel(this._eventRepository, this._searchRepository);

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

  // Calculate marker duration as a fraction of the timeline duration
  double calculateMarkerDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0;
    final duration = end.difference(start).inDays.toDouble();

    return duration / timelineDurationDays;
  }

  Future<void> getColors() async {
    try {
      final mapEntryList = await _eventRepository.getEventColors();
      _categoryColors = Map.fromEntries(mapEntryList);
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
}
