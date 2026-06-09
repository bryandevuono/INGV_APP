import 'package:flutter/material.dart';

class HybridViewModel extends ChangeNotifier {
  double _topHeightRatio = 0.5;
  final double _minSizeRatio = 0.1;

  double get topHeightRatio => _topHeightRatio;

  void changeRatio(double delta, double totalHeight) {
    double newRatio = _topHeightRatio + (delta / totalHeight);
    _topHeightRatio = newRatio.clamp(_minSizeRatio, 1.0 - _minSizeRatio);
    notifyListeners(); 
  }
}