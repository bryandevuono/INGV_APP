import '../models/event_model.dart';
import '../services/database_service.dart';


class EventRepository {
  final DatabaseService _databaseService;

  EventRepository(this._databaseService);

  Future<List<EventModel>> getAllEvents() {
    return _databaseService.getAllEvents();
  }

  
}