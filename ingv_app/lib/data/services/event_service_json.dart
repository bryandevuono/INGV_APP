import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import 'event_service_interface.dart';

class EventServiceJSON implements IEventService {
  // This is a singleton service, that could be replaced with a service that uses an API
  static final EventServiceJSON _instance = EventServiceJSON._internal();
  factory EventServiceJSON() => _instance;
  EventServiceJSON._internal();

  static const String _assetPath = 'assets/data/events.json';
  final List<EventModel> events = [];
  bool _initialized = false;

  @override
  Future<List<EventModel>> getAllEvents() async {
    if (!_initialized) {
      await _initialize();
    }
    return List.from(events);
  }

  Future<void> _initialize() async {
    final String jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> jsonList = json.decode(jsonString);
    final events = jsonList.map((e) => EventModel.fromMap(e as Map<String, dynamic>)).toList();
    this.events.clear();
    this.events.addAll(events);
    _initialized = true;
  }

  @override
  Future<void> saveEvents(List<EventModel> events) async {
    this.events.clear();
    this.events.addAll(events);
  }

  @override
  Future<void> insertEvent(EventModel event) async {
    if (!_initialized) await _initialize();
    events.add(event);
  }

  @override
  Future<Map<String, DateTime>> getEventDateRange() async {
    if (events.isEmpty) {
      return {
        "minStart": DateTime.now(),
        "maxEnd": DateTime.now(),
      };
    }

    DateTime minStart = events.first.startDt;
    DateTime maxEnd = events.first.endDt;

    for (var event in events) {
      if (event.startDt.isBefore(minStart)) {
        minStart = event.startDt;
      }
      if (event.endDt.isAfter(maxEnd)) {
        maxEnd = event.endDt;
      }
    }

    return {
      "minStart": minStart,
      "maxEnd": maxEnd,
    };
  }

  Future<List<String>> getEventCategories() async {
    if (events.isEmpty) {
      return [];
    }

    final categories = events.map((e) => e.category).toSet().toList();
    return categories;
  }
}
