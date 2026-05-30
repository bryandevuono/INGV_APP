import '../models/event_model.dart';
import '../services/storage_service.dart';

class EventRepository {
  final StorageService _storageService;

  EventRepository(this._storageService);

  Future<List<EventModel>> getAllEvents() {
    return _storageService.getAllEvents();
  }

  Future<void> insertEvent(EventModel event) {
    return _storageService.insertEvent(event);
  }
}