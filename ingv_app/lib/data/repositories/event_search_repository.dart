import '../models/event_model.dart';
import '../services/event_search_service_interface.dart';

class EventSearchRepository {
  final IEventSearchService _searchService;

  EventSearchRepository(this._searchService);

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
