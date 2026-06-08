import '../models/event_model.dart';
import 'package:flutter/material.dart';

abstract interface class IEventService {
  Future<List<EventModel>> getAllEvents();
  Future<void> saveEvents(List<EventModel> events);
  Future<void> insertEvent(EventModel event);
  Future<Map<String, DateTime>> getEventDateRange();
  Future<List<String>> getEventCategories();
  Future<List<MapEntry<String, Color>>> getEventCategoriesWithColors();
}
