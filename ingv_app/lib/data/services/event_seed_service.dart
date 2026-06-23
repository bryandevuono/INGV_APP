/// Service for seeding demo/development events.
///
/// Provides deterministic insertion and cleanup of seed events
/// with IDs in the range 900000–900099.
library;

import 'package:flutter/material.dart';
import '../seed/event_seed_data.dart';
import 'event_service_sembast.dart';

/// Fixed ID range for seeded demo events.
const int seedIdMin = 900000;
const int seedIdMax = 900099;

/// Service for managing demo event seeding.
class EventSeedService {
  final EventServiceSembast _storage;

  EventSeedService({EventServiceSembast? storage})
    : _storage = storage ?? EventServiceSembast();

  /// Check if an event ID belongs to the seed range.
  bool isSeedId(int eventId) => eventId >= seedIdMin && eventId <= seedIdMax;

  /// Seed demo events into the database.
  ///
  /// [replaceExistingSeedEvents] If true (default), existing seed events
  /// (IDs in 900000–900099) are deleted before inserting new ones.
  /// User-created events outside this range are never deleted.
  ///
  /// Returns the number of events inserted.
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

  /// Delete all existing seed events (IDs in the seed range).
  ///
  /// This only removes seeded demo events and never affects
  /// user-created events outside the seed ID range.
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

  /// Count how many seed events currently exist in the database.
  Future<int> getSeedEventCount() async {
    final allEvents = await _storage.getAllEvents();
    return allEvents
        .where((e) => e.eventId >= seedIdMin && e.eventId <= seedIdMax)
        .length;
  }

  /// Check if any seed events exist.
  Future<bool> hasSeedEvents() async {
    return await getSeedEventCount() > 0;
  }
}
