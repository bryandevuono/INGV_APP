import 'package:flutter/material.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';

class EditEventViewModel extends ChangeNotifier {
  final IEventRepository _eventRepository;
  final EventModel originalEvent;
  final List<GroupModel> groupOptions;

  late final TextEditingController titleController;
  late final TextEditingController categoryController;
  late final TextEditingController tagController;
  late final TextEditingController descriptionController;
  late final TextEditingController authorController;
  late final TextEditingController latitudeController;
  late final TextEditingController longitudeController;

  String? selectedGroupId;
  DateTime? startDateTime;
  DateTime? endDateTime;

  bool isSaving = false;
  String? generalError;
  String? titleError;
  String? categoryError;
  String? startError;
  String? endError;
  String? latitudeError;
  String? longitudeError;

  EditEventViewModel({
    required IEventRepository eventRepository,
    required this.originalEvent,
    required this.groupOptions,
  }) : _eventRepository = eventRepository {
    titleController = TextEditingController(text: originalEvent.title);
    categoryController = TextEditingController(text: originalEvent.category);
    tagController = TextEditingController(text: originalEvent.tag);
    descriptionController = TextEditingController(
      text: originalEvent.description,
    );
    authorController = TextEditingController(text: originalEvent.author);
    latitudeController = TextEditingController(
      text: originalEvent.lat.toString(),
    );
    longitudeController = TextEditingController(
      text: originalEvent.long.toString(),
    );
    selectedGroupId = originalEvent.groupId;
    startDateTime = originalEvent.startDt;
    endDateTime = originalEvent.endDt;
  }

  void setStartDateTime(DateTime value) {
    startDateTime = value;
    if (endDateTime != null && endDateTime!.isBefore(value)) {
      endDateTime = null;
    }
    notifyListeners();
  }

  void setEndDateTime(DateTime? value) {
    endDateTime = value;
    notifyListeners();
  }

  void setGroupId(String? value) {
    selectedGroupId = value;
    notifyListeners();
  }

  void setCategory(String value) {
    categoryController.text = value;
    notifyListeners();
  }

  bool validate() {
    generalError = null;
    titleError = null;
    categoryError = null;
    startError = null;
    endError = null;
    latitudeError = null;
    longitudeError = null;

    final title = titleController.text.trim();
    final category = categoryController.text.trim();
    final latitudeText = latitudeController.text.trim();
    final longitudeText = longitudeController.text.trim();

    if (title.isEmpty) {
      titleError = 'Title is required.';
    }

    if (category.isEmpty) {
      categoryError = 'Category is required.';
    }

    if (startDateTime == null) {
      startError = 'Start date/time is required.';
    }

    final parsedLatitude = double.tryParse(latitudeText);
    if (parsedLatitude == null || parsedLatitude < -90 || parsedLatitude > 90) {
      latitudeError = 'Latitude must be between -90 and 90.';
    }

    final parsedLongitude = double.tryParse(longitudeText);
    if (parsedLongitude == null ||
        parsedLongitude < -180 ||
        parsedLongitude > 180) {
      longitudeError = 'Longitude must be between -180 and 180.';
    }

    if (startDateTime != null &&
        endDateTime != null &&
        endDateTime!.isBefore(startDateTime!)) {
      endError = 'End date/time cannot be before start date/time.';
    }

    final hasErrors =
        titleError != null ||
        categoryError != null ||
        startError != null ||
        endError != null ||
        latitudeError != null ||
        longitudeError != null;

    if (hasErrors) {
      notifyListeners();
    }

    return !hasErrors;
  }

  Future<EventModel?> save() async {
    if (!validate()) {
      return null;
    }

    isSaving = true;
    generalError = null;
    notifyListeners();

    try {
      final updatedEvent = originalEvent.copyWith(
        title: titleController.text.trim(),
        category: categoryController.text.trim(),
        tag: tagController.text.trim(),
        description: descriptionController.text.trim(),
        author: originalEvent.author,
        startDt: startDateTime!,
        endDt: endDateTime,
        lat: double.parse(latitudeController.text.trim()),
        long: double.parse(longitudeController.text.trim()),
        groupId: selectedGroupId,
      );

      await _eventRepository.updateEvent(updatedEvent);
      return updatedEvent;
    } catch (error) {
      generalError = error is StateError
          ? error.message
          : 'Failed to save event changes.';
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    categoryController.dispose();
    tagController.dispose();
    descriptionController.dispose();
    authorController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }
}
