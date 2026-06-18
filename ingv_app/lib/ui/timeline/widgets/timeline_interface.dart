import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';

abstract interface class ITimeline {
  Widget buildTimeline(List<EventModel> events);
  Widget buildEventContainer(String eventId);
}
