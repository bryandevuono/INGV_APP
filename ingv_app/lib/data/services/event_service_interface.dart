import '../models/event_model.dart';

abstract class IEventService {
  Future<List<EventModel>> getAllEvents();
  Future<void> saveEvents(List<EventModel> events);
  Future<void> insertEvent(EventModel event);
}