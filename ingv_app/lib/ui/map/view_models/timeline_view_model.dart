import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';

class TimelineViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  List<EventModel> events = [];
  List<String> categories = [];
  DateTime minStart = DateTime.now();
  DateTime maxEnd = DateTime.now();

  TimelineViewModel(this._eventRepository);

  Future<void> fetchEvents() async {
    events = await _eventRepository.getAllEvents();
    categories = await _eventRepository.getEventCategories();
    notifyListeners();
  }

  Future<Map<String, DateTime>> getEventDateRange() async {
    final range = await _eventRepository.getEventDateRange();
    minStart = range["minStart"] ?? DateTime.now();
    maxEnd = range["maxEnd"] ?? DateTime.now();
    notifyListeners();
    return {
      "minStart": minStart,
      "maxEnd": maxEnd,
    };
  }
}