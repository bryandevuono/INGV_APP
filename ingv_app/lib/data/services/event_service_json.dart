import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/event_model.dart';
import 'event_service_interface.dart';

class EventServiceJSON implements IEventService {
  // This is a singleton service, that could be replaced with a service that uses an API, without logic
  static final EventServiceJSON _instance = EventServiceJSON._internal();
  factory EventServiceJSON() => _instance;
  EventServiceJSON._internal();

  static const String _assetPath = 'assets/data/events.json';
  final List<EventModel> events = [];
  bool _initialized = false;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/events.json');
  }

  @override
  Future<List<EventModel>> getAllEvents() async {
    if (!_initialized) {
      await _initialize();
    }
    return List.from(events);
  }

  Future<void> _initialize() async {
    try {
      final file = await _localFile;
      String jsonString;

      if (await file.exists()) {
        jsonString = await file.readAsString();
      } else {
        jsonString = await rootBundle.loadString(_assetPath);
        await file.writeAsString(jsonString);
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final loadedEvents = jsonList
          .map((e) => EventModel.fromMap(e as Map<String, dynamic>))
          .toList();
      events.clear();
      events.addAll(loadedEvents);
    } catch (e) {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      final loadedEvents = jsonList
          .map((e) => EventModel.fromMap(e as Map<String, dynamic>))
          .toList();
      events.clear();
      events.addAll(loadedEvents);
    }
    _initialized = true;
  }

  @override
  Future<void> saveEvents(List<EventModel> events) async {
    this.events.clear();
    this.events.addAll(events);
    await _writeEventsToJson();
  }

  @override
  Future<void> insertEvent(EventModel event) async {
    if (!_initialized) await _initialize();
    events.add(event);
    await _writeEventsToJson();
  }

  Future<void> _writeEventsToJson() async {
    final file = await _localFile;
    final List<Map<String, dynamic>> jsonList = events
        .map((e) => e.toJson())
        .toList();
    final String jsonString = json.encode(jsonList);
    await file.writeAsString(jsonString);
  }

  @override
  Future<Map<String, DateTime>> getEventDateRange() async {
    if (events.isEmpty) {
      return {"minStart": DateTime.now(), "maxEnd": DateTime.now()};
    }

    DateTime minStart = events.first.startDt;
    DateTime? maxEnd = events.first.endDt;

    for (var event in events) {
      if (event.startDt.isBefore(minStart)) {
        minStart = event.startDt;
      }
      if (event.endDt != null &&
          (maxEnd == null || event.endDt!.isAfter(maxEnd))) {
        maxEnd = event.endDt;
      }
    }

    return {"minStart": minStart, "maxEnd": maxEnd ?? DateTime.now()};
  }

  @override
  Future<List<String>> getEventCategories() async {
    if (!_initialized) {
      await _initialize();
    }

    final categories = events.map((e) => e.category).toSet().toList();
    return categories;
  }
}
