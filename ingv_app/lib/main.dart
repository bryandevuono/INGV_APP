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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = EventServiceSembast();
    final eventRepository = EventRepository(storageService);

    final detailRepository = EventDetailRepository(EventDetailService()); 
    final attachmentRepository = LocalAttachmentRepository(); 
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
        ),
        eventRepository: eventRepository,
        // 2. Feed the new required arguments directly into the navbar constructor
        detailRepository: detailRepository,
        attachmentRepository: attachmentRepository,
        localFileService: localFileService,
        fileOpenService: fileOpenService,
      ),
    );
  }
}