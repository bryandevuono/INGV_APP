import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:ingv_app/data/repositories/attachment_repository_interface.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';


class MapScreenViewModel extends ChangeNotifier {
  final IEventRepository _eventRepository;
  final IEventSearchRepository _searchRepository;
  final IEventDetailRepository detailRepository;
  final IAttachmentRepository attachmentRepository;
  final ILocalFileService localFileService;
  final IFileOpenService fileOpenService;
  EventModel? selectedEvent;

  
  late final EventDetailViewModel detailViewmodel = EventDetailViewModel(
                    detailRepository,
                    attachmentRepository,
                    localFileService,
                    fileOpenService,
                    _eventRepository, 
                  );

  List<EventModel> events = [];
  List<String> categories = [];

  // Filter states
  String searchQuery = '';
  String selectedCategory = 'All';
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  MapController mapController = MapController();
  Map<String, Color> _categoryColors = {};

  Color getCategoryColor(String category) {
    return _categoryColors[category] ??
        const Color(0xFF9E9E9E); 
  }

  int timelineDurationDays = 7;

  // FIXED: All final fields are now required in the constructor
  MapScreenViewModel(
    this._eventRepository, 
    this._searchRepository,
    this.detailRepository,
    this.attachmentRepository,
    this.localFileService,
    this.fileOpenService,
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
    jumpToLocation();
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

}