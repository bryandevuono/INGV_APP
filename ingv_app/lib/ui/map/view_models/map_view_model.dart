import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';
import 'package:ingv_app/data/services/export_service.dart';
import 'package:ingv_app/ui/map/ui_services/map_service_interface.dart';

class MapScreenViewModel extends ChangeNotifier {
  final IEventRepository _eventRepository;
  final IEventSearchRepository _searchRepository;
  final IEventDetailRepository detailRepository;
  final AttachmentRepository attachmentRepository;
  final ILocalFileService localFileService;
  final IFileOpenService fileOpenService;
  final IPdfExportService _pdfExportService;
  final IZipExportService _zipExportService;

  late final EventDetailViewModel detailViewmodel;
  EventModel? selectedEvent;

  List<EventModel> events = [];
  List<String> categories = [];

  // Filter states
  String searchQuery = '';
  String selectedCategory = 'All';
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  MapController mapController = MapController();
  Map<String, Color> _categoryColors = {};

  bool isLoading = false;
  bool isExporting = false;
  String? errorMessage;
  String? exportErrorMessage;
  Duration timelineDuration = const Duration(days: 7);

  Color getCategoryColor(String category) {
    return _categoryColors[category] ?? const Color(0xFF9E9E9E);
  }

  // Unified constructor mapping all final fields
  MapScreenViewModel(
    this._eventRepository,
    this._searchRepository,
    this.detailRepository,
    this.attachmentRepository,
    this.localFileService,
    this.fileOpenService,
    this._pdfExportService,
    this._zipExportService,
  ) {
    detailViewmodel = EventDetailViewModel(
      detailRepository,
      attachmentRepository,
      localFileService,
      fileOpenService,
      _eventRepository,
    );
  }

  Future<void> fetchEvents() async {
    isLoading = true;
    errorMessage = null;
    getTimeScale();
    notifyListeners();

    try {
      final fetchedCategories = await _eventRepository.getEventCategories();
      categories = ['All'];
      for (final category in fetchedCategories) {
        if (category != 'All' && !categories.contains(category)) {
          categories.add(category);
        }
      }
      await applyFilters();
    } catch (e) {
      errorMessage = 'Failed to load events.';
      debugPrint('Map fetchEvents error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters() async {
    try {
      events = await _searchRepository.searchAndFilterEvents(
        keyword: searchQuery,
        category: selectedCategory,
        startDate: filterStartDate,
        endDate: filterEndDate,
      );
    } catch (e) {
      errorMessage = 'Failed to filter events.';
      events = [];
      debugPrint('Map applyFilters error: $e');
    } finally {
      notifyListeners();
    }
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

  double calculateMarkerDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0;
    final eventDurationMs = end.difference(start).inMilliseconds.toDouble();
    return (eventDurationMs / timelineDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  double calculateAverageDuration(List<AppMarker> markers) {
    double totalProgress = 0;
    for (var m in markers) {
      totalProgress += m.progress;
    }
    final double avgProgress = markers.isNotEmpty
        ? (totalProgress / markers.length).clamp(0.0, 1.0)
        : 0.0;
    return avgProgress;
  }

  Future<void> getColors() async {
    try {
      final mapEntryList = await _eventRepository.getEventColors();
      _categoryColors = Map.fromEntries(mapEntryList);
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

  void jumpToLocation({double zoom = 6}) async {
    try {
      final foundEvent = await _searchRepository.getClosestMatch(searchQuery);
      mapController.move(
        latlong2.LatLng(foundEvent.lat, foundEvent.long),
        zoom,
      );
    } catch (e) {
      print("Error finding closest match: $e");
    }
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

      if (exportEvents.isEmpty) {
        exportErrorMessage = 'No events to export.';
        return null;
      }

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

      if (exportEvents.isEmpty) {
        exportErrorMessage = 'No events to export.';
        return null;
      }

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
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  void getTimeScale() {
    timelineDuration = _eventRepository.getTimeScale();
    notifyListeners();
  }

  void zoomIn() {
    final camera = mapController.camera;
    mapController.move(camera.center, camera.zoom + 1);
  }

  void zoomOut() {
    final camera = mapController.camera;
    mapController.move(camera.center, camera.zoom - 1);
  }
}
