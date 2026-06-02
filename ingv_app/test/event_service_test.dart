import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingv_app/data/models/event_model.dart';
import 'package:ingv_app/data/services/event_service_json.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock PathProviderPlatform to control where files are written in tests
class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String _tempPath = Directory.systemTemp.createTempSync().path;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    // Use a temporary directory for tests
    return _tempPath;
  }
}

void main() {
  group('EventServiceJSON', () {
    late EventServiceJSON eventService;
    late String tempPath;

    setUp(() async {
      // Set up the mock path provider before each test
      TestWidgetsFlutterBinding.ensureInitialized();
      final platform = FakePathProviderPlatform();
      PathProviderPlatform.instance = platform;
      tempPath = (await platform.getApplicationDocumentsPath())!;

      // Create a new service instance for each test to ensure isolation
      eventService = EventServiceJSON();

      // Mock the rootBundle to load initial asset data
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter/services'), (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'flutter/assets') {
              final String key = methodCall.arguments['key'];
              if (key == 'assets/data/events.json') {
                // Provide a minimal, valid JSON structure for initialization
                return utf8.encode(json.encode([]));
              }
            }
            return null;
          });
    });

    tearDown(() async {
      // Clean up the temporary directory
      final dir = Directory(tempPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    test('insertEvent writes the new event to the JSON file', () async {
      // 1. Initialize the service (it will create an empty events.json)
      await eventService.getAllEvents();

      // 2. Create a new event
      final newEvent = EventModel(
        eventId: 999,
        category: 'TestCategory',
        startDt: DateTime.now(),
        author: 'Test Author',
        lat: 10.0,
        long: 20.0,
        title: 'Test Event Title',
        tag: 'TestTag',
        description: 'Test event description.',
      );

      // 3. Insert the event
      await eventService.insertEvent(newEvent);

      // 4. Verify the file content
      final file = File('$tempPath/events.json');
      final fileExists = await file.exists();
      expect(
        fileExists,
        isTrue,
        reason: 'The events.json file should be created.',
      );

      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);

      expect(
        jsonList.length,
        greaterThanOrEqualTo(1),
        reason: 'The JSON file should contain the new event.',
      );
      final lastEvent = jsonList.last;
      expect(lastEvent['event_id'], 999);
      expect(lastEvent['title'], 'Test Event Title');
    });
  });
}
