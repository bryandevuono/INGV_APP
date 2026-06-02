import '../models/event_model.dart';

abstract interface class IEventSearchService {
  Future<List<EventModel>> searchAndFilterEvents({
    String? keyword,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  });
}
