import '../models/event_model.dart';
import '../services/event_search_service_interface.dart';

abstract interface class IEventSearchRepository {
  Future<List<EventModel>> searchAndFilterEvents({
    String? keyword,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class EventSearchRepository implements IEventSearchRepository {
  final IEventSearchService _searchService;

  EventSearchRepository(this._searchService);

  @override
  Future<List<EventModel>> searchAndFilterEvents({
    String? keyword,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _searchService.searchAndFilterEvents(
      keyword: keyword,
      category: category,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
