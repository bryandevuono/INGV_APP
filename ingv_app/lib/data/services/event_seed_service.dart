library;

import 'package:flutter/material.dart';
import '../seed/event_seed_data.dart';
import 'event_service_sembast.dart';

/// Fixed ID range for seeded demo events.
const int seedIdMin = 900000;
const int seedIdMax = 900099;

class EventSeedService {
  final EventServiceSembast _storage;

  EventSeedService({EventServiceSembast? storage})
    : _storage = storage ?? EventServiceSembast();

  bool isSeedId(int eventId) => eventId >= seedIdMin && eventId <= seedIdMax;

  /// [replaceExistingSeedEvents] If true (default), existing seed events
  Future<int> seedDemoEvents({bool replaceExistingSeedEvents = true}) async {
    try {
      // Ensure service is initialized
      await _storage.getAllEvents();

      if (replaceExistingSeedEvents) {
        await _deleteExistingSeedEvents();
      }

      final demoEvents = generateDemoEvents();
      debugPrint(
        'EventSeedService: seeding ${demoEvents.length} demo events...',
      );

      int inserted = 0;
      for (final event in demoEvents) {
        try {
          await _storage.insertEvent(event);
          inserted++;
        } on StateError catch (e) {
          // Skip duplicates
          debugPrint(
            'EventSeedService: skipped duplicate ${event.eventId}: $e',
          );
        }
      }

      // Refresh cache to ensure consistency
      await _storage.getAllEvents();

      debugPrint(
        'EventSeedService: inserted $inserted/${demoEvents.length} demo events successfully',
      );

      return inserted;
    } catch (e, stackTrace) {
      debugPrint('EventSeedService: seed failed: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<int> _deleteExistingSeedEvents() async {
    try {
      final allEvents = await _storage.getAllEvents();
      final seedEvents = allEvents
          .where((e) => e.eventId >= seedIdMin && e.eventId <= seedIdMax)
          .toList();

      if (seedEvents.isEmpty) {
        debugPrint('EventSeedService: no existing seed events to delete');
        return 0;
      }

      debugPrint(
        'EventSeedService: deleting ${seedEvents.length} existing seed events',
      );

      int deleted = 0;
      for (final event in seedEvents) {
        try {
          await _storage.deleteEvent(event.eventId);
          deleted++;
        } catch (e) {
          debugPrint(
            'EventSeedService: failed to delete seed event ${event.eventId}: $e',
          );
        }
      }

      debugPrint('EventSeedService: deleted $deleted seed events');
      return deleted;
    } catch (e, stackTrace) {
      debugPrint(
        'EventSeedService: delete seed events failed: $e\n$stackTrace',
      );
      rethrow;
    }
  }

  Future<int> getSeedEventCount() async {
    final allEvents = await _storage.getAllEvents();
    return allEvents
        .where((e) => e.eventId >= seedIdMin && e.eventId <= seedIdMax)
        .length;
  }

  Future<bool> hasSeedEvents() async {
    return await getSeedEventCount() > 0;
  }
}
