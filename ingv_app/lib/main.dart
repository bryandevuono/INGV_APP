import 'package:flutter/material.dart';
import 'package:ingv_app/ui/map/widgets/map.dart';
import 'data/repositories/event_repository.dart';
import 'data/services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();
    final eventRepository = EventRepository(storageService);

    return MaterialApp(
      title: 'INGV App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 58, 143, 183)),
        useMaterial3: true,
      ),
      home: MapScreen(eventRepository: eventRepository),
    );
  }
}