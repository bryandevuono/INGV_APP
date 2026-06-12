import 'package:flutter/material.dart';
import 'package:ingv_app/data/repositories/event_repository.dart';
import 'package:ingv_app/ui/timeline/widgets/timeline.dart';
import 'package:ingv_app/ui/groups/widgets/groups_screen.dart';
import 'package:ingv_app/ui/timeline/view_models/timeline_view_model.dart';
import 'package:ingv_app/ui/hybrid_view/widgets/hybrid_view.dart';
import 'package:ingv_app/data/repositories/event_detail_repository.dart';
import 'package:ingv_app/data/repositories/attachment_repository_interface.dart';
import 'package:ingv_app/ui/event_detail/view_models/event_detail_view_model.dart';
import 'package:ingv_app/data/services/file_operations_interface.dart';

class TopNavigationBar extends StatelessWidget {
  final Widget mapScreen;
  final EventRepository eventRepository;
  
  final IEventDetailRepository detailRepository;
  final IAttachmentRepository attachmentRepository;
  final ILocalFileService localFileService;
  final IFileOpenService fileOpenService;

  const TopNavigationBar({
    super.key,
    required this.mapScreen,
    required this.eventRepository,
    required this.detailRepository,
    required this.attachmentRepository,
    required this.localFileService,
    required this.fileOpenService,
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
            ClipRect(
              child: ResizableHybridView(
                topWidget: mapScreen,
                bottomWidget: TimelineScreen(
                  viewModel: TimelineViewModel(eventRepository),
                  detailViewModel: EventDetailViewModel(
                    detailRepository,
                    attachmentRepository,
                    localFileService,
                    fileOpenService,
                    eventRepository, // Implements IEventRepository implicitly
                  ),
                ),
              ),
            ),
            TimelineScreen(
              viewModel: TimelineViewModel(eventRepository),
              detailViewModel: EventDetailViewModel(
                detailRepository,
                attachmentRepository,
                localFileService,
                fileOpenService,
                eventRepository,
              ),
            ),
            mapScreen,
            GroupsScreen(), 
          ],
        ),
      ),
    );
  }
}