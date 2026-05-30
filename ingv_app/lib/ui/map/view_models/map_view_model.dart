import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';

class MapScreenViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;
  List<EventModel> events = [];

  MapScreenViewModel(this._eventRepository);

  Future<void> fetchEvents() async {
    events = await _eventRepository.getAllEvents();
    notifyListeners();
  }
}