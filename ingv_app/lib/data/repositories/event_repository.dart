import '../models/event_model.dart';
import '../services/event_service_interface.dart';

abstract interface class IEventRepository {
  Future<List<EventModel>> getAllEvents();
  Future<void> insertEvent(EventModel event);
  Future<Map<String, DateTime>> getEventDateRange();
  Future<List<String>> getEventCategories();
}

class EventRepository implements IEventRepository {
  final IEventService _storageService;

  EventRepository(this._storageService);

  @override
  Future<List<EventModel>> getAllEvents() {
    return _storageService.getAllEvents();
  }

  @override
  Future<void> insertEvent(EventModel event) {
    return _storageService.insertEvent(event);
  }

  @override
  Future<Map<String, DateTime>> getEventDateRange() {
    return _storageService.getEventDateRange();
  }

  @override
  Future<List<String>> getEventCategories() {
    return _storageService.getEventCategories();
  }
}
