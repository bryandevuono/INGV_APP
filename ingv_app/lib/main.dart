import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ingv_app/ui/map/widgets/map.dart';
import 'data/repositories/event_repository.dart';
import 'data/repositories/event_search_repository.dart';
import 'data/services/event_search_service.dart';
import 'data/services/event_service_sembast.dart';
import 'ui/navbar.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/services/event_detail_service.dart';
import 'package:ingv_app/data/repositories/attachment_repository.dart';
import 'package:ingv_app/data/services/file_operations_service.dart';
import 'package:ingv_app/ui/map/ui_services/map_service.dart';
import 'package:ingv_app/data/services/attachment_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Object? _initError;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final storageService = EventServiceSembast();
      EventRepository(storageService);
      EventDetailRepository(EventDetailService());
      AttachmentRepository(AttachmentService());
      LocalFileService();
      FileOpenService();
      
      setState(() {
        _initError = null;
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('App initialization error: $e');
      setState(() {
        _initError = e;
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to start application',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initError.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isInitializing) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final storageService = EventServiceSembast();
    final eventRepository = EventRepository(storageService);
    final detailRepository = EventDetailRepository(EventDetailService());
    final attachmentRepository = AttachmentRepository(AttachmentService());
    final localFileService = LocalFileService();
    final fileOpenService = FileOpenService();

    return MaterialApp(
      title: 'INGV App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 58, 143, 183),
        ),
        useMaterial3: true,
      ),
      home: TopNavigationBar(
        mapScreen: MapScreen(
          eventRepository: eventRepository,
          eventSearchRepository: EventSearchRepository(
            EventSearchService(storageService),
          ),
          mapService: MapServiceUI(userAgentPackageName: 'ingv_app'),
        ),
        eventRepository: eventRepository,
        searchRepository: EventSearchRepository(
          EventSearchService(storageService),
        ),
        detailRepository: detailRepository,
        attachmentRepository: attachmentRepository,
        localFileService: localFileService,
        fileOpenService: fileOpenService,
      ),
    );
  }
}