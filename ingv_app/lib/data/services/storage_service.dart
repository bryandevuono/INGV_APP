import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/event_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _assetPath = 'assets/data/events.json';
  final List<EventModel> _inMemoryEvents = [];
  bool _initialized = false;

  Future<List<EventModel>> getAllEvents() async {
    if (!_initialized) {
      await _initialize();
    }
    return List.from(_inMemoryEvents);
  }

  Future<void> _initialize() async {
    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      final events = jsonList.map((e) => EventModel.fromMap(e as Map<String, dynamic>)).toList();
      _inMemoryEvents.clear();
      _inMemoryEvents.addAll(events);
      _initialized = true;
    } catch (e) {
      // Fallback if asset missing
      _initialized = true;
    }
  }

  Future<void> saveEvents(List<EventModel> events) async {
    _inMemoryEvents.clear();
    _inMemoryEvents.addAll(events);
    // Note: Changes are preserved in memory but lost on app restart
    // because we removed the persistent storage packages.
  }

  Future<void> insertEvent(EventModel event) async {
    if (!_initialized) await _initialize();
    _inMemoryEvents.add(event);
  }
}
