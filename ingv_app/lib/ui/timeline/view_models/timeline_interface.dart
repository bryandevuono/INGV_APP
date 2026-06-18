import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/timeline_presentation_models.dart';
import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/group_model.dart';

abstract interface class ITimelineViewModel implements Listenable {
  List<EventModel> get events;
  List<String> get orderedCategories;
  bool get isExporting;
  String? get exportErrorMessage;
  String get selectedCategory;
  DateTime? get filterStartDate;
  List<GroupModel> get userGroups;

  DateTime? get filterEndDate;
  List<String> get categories;
  String get searchQuery;

  List<TimelineLaneData> get timelineLanes;
  List<TimelineTaskData> getTimelineTasksForCategory(String category);

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
  Future<String?> exportTimelineReport();
  Future<String?> exportTimelineAsZip();
  Future<String?> exportTimelineReportForDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<String?> exportTimelineAsZipForDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
