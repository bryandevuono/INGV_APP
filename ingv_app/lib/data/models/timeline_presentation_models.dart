import 'package:flutter/material.dart';

class TimelineLaneData {
  final String id;
  final String label;

  const TimelineLaneData({required this.id, required this.label});
}

class TimelineTaskData {
  final String id;
  final String laneId;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;

  const TimelineTaskData({
    required this.id,
    required this.laneId,
    required this.title,
    required this.start,
    required this.end,
    required this.color,
  });
}
