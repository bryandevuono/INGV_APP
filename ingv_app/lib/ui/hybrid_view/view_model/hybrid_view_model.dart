import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';

class HybridViewModel extends ChangeNotifier {
  double _topHeightRatio = 0.5;
  final double _minSizeRatio = 0.1;

  double get topHeightRatio => _topHeightRatio;

  EventModel? get selectedEvent => _selectedEvent;
  EventModel? _selectedEvent;
  bool _selectedFromMap = true;
  bool get selectedFromMap => _selectedFromMap;

  void changeRatio(double delta, double totalHeight) {
    double newRatio = _topHeightRatio + (delta / totalHeight);
    _topHeightRatio = newRatio.clamp(_minSizeRatio, 1.0 - _minSizeRatio);
    notifyListeners();
  }

  void updateRatio(double explicitRatio) {
    _topHeightRatio = explicitRatio.clamp(_minSizeRatio, 1.0 - _minSizeRatio);
    notifyListeners();
  }

  void selectEvent(EventModel event, {required bool fromMap}) {
    _selectedEvent = event;
    _selectedFromMap = fromMap;
    notifyListeners();
  }

  void clearEvent() {
    _selectedEvent = null;
    notifyListeners();
  }
}
