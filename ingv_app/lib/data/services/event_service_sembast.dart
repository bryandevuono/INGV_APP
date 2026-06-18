import 'package:sembast/sembast.dart';
import '../models/event_model.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import 'event_service_interface.dart';
import 'group_service_sembast.dart';

class EventServiceSembast implements IEventService {
  static final EventServiceSembast _instance = EventServiceSembast._internal();
  factory EventServiceSembast() => _instance;
  EventServiceSembast._internal();

  static const String _storeName = 'events';
  final Map<String, Color> cellColors = {
    "Volcanic": Colors.red,
    "Earthquake": Colors.green,
    "Hydrological": Colors.blue,
    "Meteorological": Colors.orange,
    "Geological": Colors.purple,
    "Atmospheric": Colors.cyan,
  };

  final AppDatabase _appDatabase = AppDatabase();
  final StoreRef<int, Map<String, dynamic>> _store = intMapStoreFactory.store(
    _storeName,
  );
  final List<EventModel> _events = [];

  bool _initialized = false;
  Future<void>? _initializing;

  Finder get _sortedFinder =>
      Finder(sortOrders: [SortOrder('start_datetime'), SortOrder('event_id')]);

  Future<Database> get _database => _appDatabase.database;

  Future<void> _ensureInitialized() {
    if (_initialized) {
      return Future.value();
    }
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      final db = await _database;
      await _refreshCache(db);
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint(
        'EventServiceSembast initialization failed: $error\n$stackTrace',
      );
      _events.clear();
      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _refreshCache(Database db) async {
    final records = await _store.find(db, finder: _sortedFinder);
    _events
      ..clear()
      ..addAll(records.map((record) => EventModel.fromMap(record.value)));
  }

  @override
  Future<List<EventModel>> getAllEvents() async {
    await _ensureInitialized();
    return List<EventModel>.from(_events);
  }

  @override
  Future<void> saveEvents(List<EventModel> events) async {
    await _ensureInitialized();
    final db = await _database;

    try {
      await db.transaction((txn) async {
        await _store.delete(txn);
        for (final event in events) {
          await _store.record(event.eventId).put(txn, event.toJson());
        }
      });
      await _refreshCache(db);
    } catch (error, stackTrace) {
      debugPrint('EventServiceSembast save failed: $error\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> insertEvent(EventModel event) async {
    await _ensureInitialized();
    final db = await _database;

    try {
      final record = _store.record(event.eventId);
      final existing = await record.get(db);
      if (existing != null) {
        throw StateError('Event with id ${event.eventId} already exists.');
      }
      await record.put(db, event.toJson());
      await _refreshCache(db);
    } catch (error, stackTrace) {
      debugPrint('EventServiceSembast insert failed: $error\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    await _ensureInitialized();
    final db = await _database;

    try {
      final record = _store.record(event.eventId);
      final existing = await record.get(db);
      if (existing == null) {
        throw StateError('Event with id ${event.eventId} not found.');
      }

      await record.put(db, event.toJson());
      await _refreshCache(db);
    } catch (error, stackTrace) {
      debugPrint('EventServiceSembast update failed: $error\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<Map<String, DateTime>> getEventDateRange() async {
    await _ensureInitialized();

    if (_events.isEmpty) {
      final now = DateTime.now();
      return {'minStart': now, 'maxEnd': now};
    }

    var minStart = _events.first.startDt;
    DateTime? maxEnd = _events.first.endDt;

    for (final event in _events) {
      if (event.startDt.isBefore(minStart)) {
        minStart = event.startDt;
      }
      if (event.endDt != null &&
          (maxEnd == null || event.endDt!.isAfter(maxEnd))) {
        maxEnd = event.endDt;
      }
    }

    return {'minStart': minStart, 'maxEnd': maxEnd ?? DateTime.now()};
  }

  @override
  Future<List<String>> getEventCategories() async {
    List<String> categories = [
      'Volcanic',
      'Earthquake',
      'Hydrological',
      'Meteorological',
      'Geological',
      'Atmospheric',
    ];
    return categories;
  }

  @override
  Future<List<MapEntry<String, Color>>> getEventCategoriesWithColors() async {
    if (!_initialized) {
      await _initialize();
    }

    final categories = _events.map((e) => e.category).toSet().toList();
    final categoriesWithColors = categories.map((category) {
      final color =
          cellColors[category] ?? Colors.grey; // Default to grey if not found
      return MapEntry(category, color);
    }).toList();

    return categoriesWithColors;
  }

  @override
  Future<String?> getGroupOfEvent(int eventId) async {
    await _ensureInitialized();
    final event = _events.firstWhere(
      (e) => e.eventId == eventId,
      orElse: () => throw StateError('Event with id $eventId not found.'),
    );
    if (event.groupId == null) {
      return null;
    }
    final groupService = GroupServiceSembast();
    try {
      final group = await groupService.getGroupById(event.groupId!);
      return group?.name;
    } catch (e) {
      debugPrint('Failed to fetch group for event $eventId: $e');
      return null;
    }
  }
}
