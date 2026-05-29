import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class MapMarker extends Marker {
  MapMarker({
    required super.point,
    required String title,
    required String author,
    required String category,
    required String tag,
    required double progress,
    required VoidCallback onAction,
    Color categoryColor = Colors.greenAccent,
    Color tagColor = Colors.red,
    Color fillColor = const Color(0xFF39D353),
    Color ringColor = Colors.deepPurple,
    super.width = 28,
    super.height = 28,
  }) : super(
         child: Tooltip(
           preferBelow: false,
           verticalOffset: 20,
           waitDuration: const Duration(milliseconds: 200),
           showDuration: const Duration(seconds: 15),
           padding: EdgeInsets.zero,
           decoration: const BoxDecoration(color: Colors.transparent),
           richMessage: WidgetSpan(
             child: Container(
               width: 520,
               padding: const EdgeInsets.all(28),
               decoration: BoxDecoration(
                 color: const Color(0xFFF5F5F5),
                 border: Border.all(color: Colors.black54, width: 1),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.15),
                     blurRadius: 12,
                     offset: const Offset(0, 4),
                   ),
                 ],
               ),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   // top part
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // left side of the details
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               title,
                               style: const TextStyle(
                                 fontSize: 38,
                                 fontWeight: FontWeight.bold,
                                 color: Color(0xFF444444),
                               ),
                             ),
                             const SizedBox(height: 12),
                             Row(
                               children: [
                                 const SizedBox(width: 8),
                                 Text(
                                   "Author: $author",
                                   style: const TextStyle(
                                     fontSize: 16,
                                     color: Colors.black54,
                                   ),
                                 ),
                               ],
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(width: 40),
                       // right side of the details
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: [
                               const Text(
                                 "Category:",
                                 style: TextStyle(
                                   fontSize: 16,
                                   color: Colors.black54,
                                 ),
                               ),
                               const SizedBox(width: 12),
                               Container(
                                 padding: const EdgeInsets.symmetric(
                                   horizontal: 12,
                                   vertical: 4,
                                 ),
                                 color: categoryColor,
                                 child: Text(
                                   category,
                                   style: const TextStyle(
                                     fontSize: 16,
                                     color: Colors.black,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 12),
                           Row(
                             children: [
                               const Text(
                                 "Tag:",
                                 style: TextStyle(
                                   fontSize: 16,
                                   color: Colors.black54,
                                 ),
                               ),
                               const SizedBox(width: 46),
                               Container(
                                 padding: const EdgeInsets.symmetric(
                                   horizontal: 18,
                                   vertical: 6,
                                 ),
                                 decoration: BoxDecoration(
                                   color: tagColor,
                                   borderRadius: BorderRadius.circular(6),
                                 ),
                                 child: Text(
                                   tag,
                                   style: const TextStyle(
                                     color: Colors.white,
                                     fontWeight: FontWeight.w600,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ],
                   ),
                   const SizedBox(height: 20),
                   Align(
                     alignment: Alignment.bottomRight,
                     child: SizedBox(
                       width: 150,
                       height: 32,
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF76A7FF),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8),
                           ),
                         ),
                         onPressed: onAction,
                         child: const Text(
                           "Submit a note",
                           style: TextStyle(
                             fontSize: 12,
                             color: Colors.white,
                             height: 1.5,
                           ),
                         ),
                       ),
                     ),
                   ),
                 ],
               ),
             ),
           ),
           // marker
           child: Stack(
             alignment: Alignment.center,
             children: [
               // background circle
               Container(
                 width: width,
                 height: height,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: fillColor,
                 ),
               ),
               // progress
               SizedBox(
                 width: width,
                 height: height,
                 child: CircularProgressIndicator(
                   value: progress,
                   strokeWidth: 6,
                   color: ringColor,
                   backgroundColor: Colors.transparent,
                 ),
               ),
             ],
           ),
         ),
       );
}
