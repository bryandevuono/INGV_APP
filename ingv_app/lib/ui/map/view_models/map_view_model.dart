import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/data/services/export_service.dart';

class MapScreenViewModel extends ChangeNotifier {
  final IEventRepository _eventRepository;
  final IEventSearchRepository _searchRepository;
  final IPdfExportService _pdfExportService;
  final IZipExportService _zipExportService;

  List<EventModel> events = [];
  List<String> categories = [];

  // Filter states
  String searchQuery = '';
  String selectedCategory = 'All';
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  bool isExporting = false;
  String? exportErrorMessage;

  MapScreenViewModel(
    this._eventRepository,
    this._searchRepository,
    this._pdfExportService,
    this._zipExportService,
  );

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

  Future<List<EventModel>> _getExportEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final effectiveStart = startDate ?? filterStartDate;
    final effectiveEnd = endDate ?? filterEndDate;
    if (effectiveStart == filterStartDate &&
        effectiveEnd == filterEndDate &&
        events.isNotEmpty) {
      return events;
    }

    return _searchRepository.searchAndFilterEvents(
      keyword: searchQuery,
      category: selectedCategory,
      startDate: effectiveStart,
      endDate: effectiveEnd,
    );
  }

  Future<String?> exportVisibleEventsPdf({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    isExporting = true;
    exportErrorMessage = null;
    notifyListeners();

    try {
      final exportEvents = await _getExportEvents(
        startDate: startDate,
        endDate: endDate,
      );
      final result = await _pdfExportService.exportTimelineReport(
        events: exportEvents,
        orderedCategories: categories
            .where((category) => category != 'All')
            .toList(),
        filterStartDate: startDate ?? filterStartDate,
        filterEndDate: endDate ?? filterEndDate,
      );
      return result.saveLocation;
    } catch (error) {
      exportErrorMessage = 'Failed to export map PDF: $error';
      return null;
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  Future<String?> exportVisibleEventsZip({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    isExporting = true;
    exportErrorMessage = null;
    notifyListeners();

    try {
      final exportEvents = await _getExportEvents(
        startDate: startDate,
        endDate: endDate,
      );
      final result = await _zipExportService.exportTimelineAsZip(
        events: exportEvents,
        orderedCategories: categories
            .where((category) => category != 'All')
            .toList(),
        filterStartDate: startDate ?? filterStartDate,
        filterEndDate: endDate ?? filterEndDate,
      );
      return result.saveLocation;
    } catch (error) {
      exportErrorMessage = 'Failed to export map ZIP: $error';
      return null;
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }
}
