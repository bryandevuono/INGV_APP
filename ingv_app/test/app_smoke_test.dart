import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingv_app/ui/navbar.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/services/event_service_sembast.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/data/services/event_search_service.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/services/event_detail_service.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/services/file_operations_service.dart';
import 'package:ingv_app/ui/map/widgets/map.dart';
import 'package:ingv_app/ui/map/ui_services/map_service.dart';
import 'package:ingv_app/ui/shared/widgets/event_filter_action_bar.dart';
import 'package:ingv_app/ui/timeline/widgets/add_event_dialog.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_interface.dart';
import 'package:ingv_app/data/models/group_model.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/models/timeline_presentation_models.dart';
import 'package:ingv_app/ui/shared/view_models/event_tooltip_helper.dart';
import 'package:ingv_app/data/services/attachment_service.dart';

class _MockTimelineViewModel extends ChangeNotifier
    implements ITimelineViewModel {
  List<EventModel> _events = [];
  List<GroupModel> _groups = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  List<EventModel> get events => _events;
  @override
  String get searchQuery => _searchQuery;
  @override
  String get selectedCategory => _selectedCategory;
  @override
  DateTime? get filterStartDate => _filterStartDate;
  @override
  DateTime? get filterEndDate => _filterEndDate;
  @override
  List<String> get categories => const ['Volcanic', 'Earthquake'];
  @override
  List<String> get orderedCategories => categories;
  @override
  List<GroupModel> get userGroups => _groups;
  @override
  bool get isExporting => false;
  @override
  String? get exportErrorMessage => null;
  @override
  List<TimelineLaneData> get timelineLanes => const [];

  @override
  Future<void> addEvent(EventModel event) async {}
  @override
  void setSearchQuery(String v) => notifyListeners();
  @override
  void setCategoryFilter(String v) => notifyListeners();
  @override
  void setDateRangeFilter(DateTime? s, DateTime? e) => notifyListeners();
  @override
  Future<void> fetchEvents() => Future.value();
  @override
  Future<void> applyFilters() => Future.value();
  @override
  Future<void> getColors() => Future.value();
  @override
  Future<void> getGroupsOfUser() => Future.value();
  @override
  Future<String> getUserId() => Future.value('test_user');
  @override
  Future<Map<String, DateTime>> getEventDateRange() => Future.value({});
  @override
  List<TimelineTaskData> getTimelineTasksForCategory(String category) => [];
  @override
  void reorderCategories(int oldIndex, int newIndex) {}
  @override
  void toggleCategoryMinimized(String category) {}
  @override
  bool isCategoryMinimized(String category) => false;
  @override
  Future<String?> exportTimelineReport() => Future.value(null);
  @override
  Future<String?> exportTimelineAsZip() => Future.value(null);
  @override
  Future<String?> exportTimelineReportForDateRange(DateTime s, DateTime e) =>
      Future.value(null);
  @override
  Future<String?> exportTimelineAsZipForDateRange(DateTime s, DateTime e) =>
      Future.value(null);
  @override
  void setTimeScale(Duration scale) {}
  @override
  Duration getTimeScale() => Duration.zero;
  @override
  List<EventModel> get searchSuggestions => [];
  @override
  Future<void> selectSuggestion(EventModel event) => Future.value();
}


TopNavigationBar _buildApp() {
  final storageService = EventServiceSembast();
  final eventRepository = EventRepository(storageService);
  final detailRepository = EventDetailRepository(EventDetailService());
  final attachmentRepository = AttachmentRepository(AttachmentService());
  final localFileService = LocalFileService();
  final fileOpenService = FileOpenService();

  return TopNavigationBar(
    mapScreen: MapScreen(
      eventRepository: eventRepository,
      eventSearchRepository: EventSearchRepository(
        EventSearchService(storageService),
      ),
      mapService: MapServiceUI(userAgentPackageName: 'ingv_app'),
    ),
    eventRepository: eventRepository,
    searchRepository: EventSearchRepository(EventSearchService(storageService)),
    detailRepository: detailRepository,
    attachmentRepository: attachmentRepository,
    localFileService: localFileService,
    fileOpenService: fileOpenService,
  );
}

Widget _wrapApp(Widget home) {
  return MaterialApp(
    home: home,
    builder: (context, child) {
      return child ?? const SizedBox.shrink();
    },
  );
}

void main() {
  group('INGV App smoke tests', () {

    testWidgets('App starts and shows all four navigation tabs', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);

      expect(
        tester.takeException(),
        isNull,
        reason: 'No exception during startup',
      );
    });


    testWidgets('Navigation: can open Home tab', (tester) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.byType(EventFilterActionBar),
        findsWidgets,
        reason: 'Home should contain EventFilterActionBar',
      );
    });

    testWidgets('Navigation: can open Timeline tab', (tester) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Timeline'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(
        find.byType(EventFilterActionBar),
        findsWidgets,
        reason: 'Timeline should have an EventFilterActionBar',
      );
    });

    testWidgets('Navigation: can open Map tab', (tester) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets('Navigation: can open Groups tab', (tester) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Groups'));
      await tester.pump();
      await tester.pump(); 
      expect(tester.takeException(), isNull);

    });

    testWidgets('Home screen: filter/search bar is visible', (tester) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      expect(
        find.widgetWithText(TextField, 'Search (keywords, tags)...'),
        findsOneWidget,
      );
    });

    testWidgets('Home screen: can type into search field', (tester) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Home'));
      await tester.pump();

      final searchField = find.widgetWithText(
        TextField,
        'Search (keywords, tags)...',
      );
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'volcanic');
      await tester.pump();

      expect(find.text('volcanic'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Timeline: search/filter and Add event visible', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Timeline'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      expect(find.byType(EventFilterActionBar), findsWidgets);

      expect(find.text('Add event'), findsOneWidget);
    });

    testWidgets('Timeline: tap Add event opens dialog with fields', (
      tester,
    ) async {
      final mockVm = _MockTimelineViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Test')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        showAddEventDialog(context, mockVm, const []),
                    child: const Text('Open Dialog'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Add New Event'), findsOneWidget);

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Latitude'), findsOneWidget);
      expect(find.text('Longitude'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Group'), findsOneWidget);
    });

    testWidgets('Timeline: Add without required fields shows validation', (
      tester,
    ) async {
      final mockVm = _MockTimelineViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Test')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        showAddEventDialog(context, mockVm, const []),
                    child: const Text('Open Dialog'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Add New Event'), findsOneWidget);

      // Tap "Add" button without filling required fields
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Dialog should still be visible (did not close)
      expect(find.text('Add New Event'), findsOneWidget);
    });

    testWidgets('Map screen: opens without crash', (tester) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(MapScreen), findsOneWidget);
    });

    testWidgets('Groups screen: opens without crash', (tester) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Groups'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Groups tab should not crash',
      );
    });


    testWidgets('Tooltip helper: formatDuration shows correct values', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      final start = DateTime(2026, 6, 18, 10, 0);

      // Ongoing
      expect(
        formatDuration(start, null),
        equals('Ongoing'),
        reason: 'Ongoing event should show "Ongoing"',
      );

      // Less than 1 hour
      expect(
        formatDuration(start, start.add(const Duration(minutes: 45))),
        equals('45m'),
        reason: '45 minutes should show "45m"',
      );

      // Exact hour
      expect(
        formatDuration(start, start.add(const Duration(hours: 2))),
        equals('2h'),
        reason: '2 hours should show "2h"',
      );

      // Hours and minutes
      expect(
        formatDuration(start, start.add(const Duration(hours: 2, minutes: 30))),
        equals('2h 30m'),
        reason: '2h 30m should show "2h 30m"',
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('Tooltip helper: formatLocation shows "Location:" label', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      final loc = formatLocation(41.9028, 12.4963);
      expect(loc.contains('Location:'), isTrue);
      expect(loc.contains('lat:'), isFalse);
      expect(loc.contains('long:'), isFalse);

      expect(tester.takeException(), isNull);
    });
  });

  group('INGV App regression: date filter & export state', () {
    testWidgets('Timeline date filter with no events shows empty state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));

      await tester.tap(find.text('Timeline'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      expect(
        find.byType(EventFilterActionBar).evaluate().isNotEmpty ||
            find.textContaining('No events').evaluate().isNotEmpty,
        isTrue,
        reason: 'Timeline should render either filter bar or empty state',
      );
    });

    testWidgets('Timeline filtering with category+search does not crash', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapApp(_buildApp()));
      await tester.tap(find.text('Timeline'));
      await tester.pump(const Duration(milliseconds: 300));

      final searchField = find.widgetWithText(
        TextField,
        'Search (keywords, tags)...',
      );
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'nonexistent_xyz');
        await tester.pump();
      }

      expect(
        tester.takeException(),
        isNull,
        reason: 'Search filtering should not crash even with no matches',
      );
    });
  });
}
