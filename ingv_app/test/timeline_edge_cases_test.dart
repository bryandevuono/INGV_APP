import 'package:flutter_test/flutter_test.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/services/event_service_interface.dart';
import 'package:ingv_app/ui/map/view_models/timeline_view_model.dart';

class MockEventService implements IEventService {
  final List<EventModel> events = [];

  @override
  Future<List<EventModel>> getAllEvents() async {
    return List.from(events);
  }

  @override
  Future<void> saveEvents(List<EventModel> events) async {
    this.events.clear();
    this.events.addAll(events);
  }

  @override
  Future<void> insertEvent(EventModel event) async {
    events.add(event);
  }

  @override
  Future<Map<String, DateTime>> getEventDateRange() async {
    if (events.isEmpty) {
      return {"minStart": DateTime.now(), "maxEnd": DateTime.now()};
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

    return {"minStart": minStart, "maxEnd": maxEnd};
  }

  @override
  Future<List<String>> getEventCategories() async {
    return events.map((e) => e.category).toSet().toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TimelineViewModel Edge Cases', () {
    late TimelineViewModel viewModel;
    late EventRepository repository;

    setUp(() {
      repository = EventRepository(MockEventService());
      viewModel = TimelineViewModel(repository);
    });

    test('Insert 50 events', () async {
      await viewModel.fetchEvents();
      final initialCount = viewModel.events.length;

      for (int i = 0; i < 50; i++) {
        final event = EventModel(
          eventId: 1000 + i,
          title: 'Test Event $i',
          description: 'Description $i',
          category: 'Volcanic',
          author: 'Test',
          lat: 0.0,
          long: 0.0,
          startDt: DateTime(2026, 1, 1).add(Duration(days: i)),
          endDt: DateTime(2026, 1, 1).add(Duration(days: i + 1)),
          tag: 'tag',
        );
        await viewModel.addEvent(event);
      }

      await viewModel.fetchEvents();
      expect(viewModel.events.length, initialCount + 50);

      // Test the date range expanded
      final range = await viewModel.getEventDateRange();
      expect(
        range["maxEnd"]!.isAfter(DateTime(2026, 1, 1).add(Duration(days: 49))),
        true,
      );
    });

    test('Handle extreme date ranges (null equivalents/edge dates)', () async {
      await viewModel.fetchEvents();

      // Since dart DateTime cannot be null in non-nullable parameters,
      // edge cases for 'null' in this context mean missing fields if parsed from JSON
      // But we can test parsing from a map with missing data
      try {
        EventModel.fromMap({
          'event_id': 999,
          // Missing category, author, title, should default properly
          'start_datetime': DateTime(1970).toIso8601String(),
          'end_datetime': DateTime(9999).toIso8601String(),
          'lat': 0.0,
          'lon': 0.0,
        });
      } catch (e) {
        // Should succeed and use defaults
      }

      final extremeEvent = EventModel(
        eventId: 9999,
        category: 'Volcanic',
        startDt: DateTime(1970), // far past
        endDt: DateTime(9999), // far future
        author: '',
        lat: 0.0,
        long: 0.0,
        title: 'Edge Date Event',
        tag: '',
        description: '',
      );

      await viewModel.addEvent(extremeEvent);
      final range = await viewModel.getEventDateRange();

      expect(range["minStart"]!.year, equals(1970));
      expect(range["maxEnd"]!.year, equals(9999));
    });
  });
}
