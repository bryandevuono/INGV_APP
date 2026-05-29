import '../models/event_model.dart';
import '../services/database_service.dart';

class EventRepositoy {
  final DatabaseService _databaseService;

  EventRepositoy(this._databaseService);
  
  Future<List<EventModel>> getAllEvents() {
    return _databaseService.getAllEvents();
  }
}