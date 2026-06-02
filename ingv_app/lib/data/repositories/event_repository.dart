import '../models/event_model.dart';
import '../services/event_service_interface.dart';

class EventRepository {
  final IEventService _storageService;

  EventRepository(this._storageService);

  Future<List<EventModel>> getAllEvents() {
    return _storageService.getAllEvents();
  }

  Future<void> insertEvent(EventModel event) {
    return _storageService.insertEvent(event);
  }

  Future<Map<String, DateTime>> getEventDateRange() {
    return _storageService.getEventDateRange();
  }

  Future<List<String>> getEventCategories() {
    return _storageService.getEventCategories();
  }
}
