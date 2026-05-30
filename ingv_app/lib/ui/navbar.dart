import 'package:flutter/material.dart';


class TopNavigationBar extends StatelessWidget {
  final Widget mapScreen;
  const TopNavigationBar({super.key, required this.mapScreen});

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
                child: Text('Car Screen', style: TextStyle(fontSize: 24))),
            const Center(
                child: Text('Transit Screen', style: TextStyle(fontSize: 24))),
            mapScreen,
          ],
        ),
      ),
    );
  }
}
