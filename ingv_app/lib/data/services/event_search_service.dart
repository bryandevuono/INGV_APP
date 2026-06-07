import '../models/event_model.dart';
import 'event_search_service_interface.dart';
import 'event_service_interface.dart';

class EventSearchService implements IEventSearchService {
  final IEventService _eventService;

  EventSearchService(this._eventService);

  @override
  Future<List<EventModel>> searchAndFilterEvents({
    String? keyword,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allEvents = await _eventService.getAllEvents();
    
    return allEvents.where((event) {
      bool matchesKeyword = true;
      if (keyword != null && keyword.isNotEmpty) {
        final lowerKeyword = keyword.toLowerCase();
        matchesKeyword = event.title.toLowerCase().contains(lowerKeyword) ||
            event.description.toLowerCase().contains(lowerKeyword) ||
            event.tag.toLowerCase().contains(lowerKeyword) ||
            event.author.toLowerCase().contains(lowerKeyword);
      }

      bool matchesCategory = true;
      if (category != null && category.isNotEmpty && category != 'All') {
        matchesCategory = event.category == category;
      }

      bool matchesTime = true;
      if (startDate != null && endDate != null) {
        final eventEnd = event.endDt ?? event.startDt;
        matchesTime = event.startDt.isBefore(endDate.add(const Duration(days: 1))) && 
                      eventEnd.isAfter(startDate.subtract(const Duration(seconds: 1)));
      } else if (startDate != null) {
        final eventEnd = event.endDt ?? event.startDt;
        matchesTime = eventEnd.isAfter(startDate.subtract(const Duration(seconds: 1)));
      } else if (endDate != null) {
        matchesTime = event.startDt.isBefore(endDate.add(const Duration(days: 1)));
      }

      return matchesKeyword && matchesCategory && matchesTime;
    }).toList();
  }
}
