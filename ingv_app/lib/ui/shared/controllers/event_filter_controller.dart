import 'package:flutter/material.dart';

class EventFilterController extends ChangeNotifier {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  bool get hasDateFilter => _startDate != null || _endDate != null;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }
}
