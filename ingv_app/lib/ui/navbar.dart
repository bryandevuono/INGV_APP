import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/timeline/timeline.dart';
import 'package:ingv_app/ui/groups/widgets/groups_screen.dart';

class TopNavigationBar extends StatelessWidget {
  final Widget mapScreen;
  final EventRepository eventRepository;

  const TopNavigationBar({
    super.key,
    required this.mapScreen,
    required this.eventRepository,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
                  Tab(text: "Groups"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const Center(
                child: Text('Home Screen', style: TextStyle(fontSize: 24))),
            TimelineScreen(eventRepository: eventRepository),
            mapScreen,
            GroupsScreen(), 
          ],
        ),
      ),
    );
  }
}