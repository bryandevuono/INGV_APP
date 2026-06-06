import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/data/repositories/event_search_repository.dart';
import 'package:ingv_app/ui/timeline/timeline.dart';

class TopNavigationBar extends StatelessWidget {
  final Widget mapScreen;
  final IEventRepository eventRepository;
  final IEventSearchRepository eventSearchRepository;

  const TopNavigationBar({
    super.key,
    required this.mapScreen,
    required this.eventRepository,
    required this.eventSearchRepository,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            color: Colors.blue,
            child: const SafeArea(
              child: TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: "Home"),
                  Tab(text: "Timeline"),
                  Tab(text: "Map"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const Center(
              child: Text('Home Screen', style: TextStyle(fontSize: 24)),
            ),
            TimelineScreen(
              eventRepository: eventRepository,
              eventSearchRepository: eventSearchRepository,
            ),
            mapScreen,
          ],
        ),
      ),
    );
  }
}
