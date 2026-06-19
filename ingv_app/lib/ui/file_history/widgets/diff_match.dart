import 'package:flutter/material.dart';
import 'package:diff_match_patch/diff_match_patch.dart';

class DiffText extends StatelessWidget {
  final String originalText;
  final String modifiedText;
  final bool isLeftColumn;

  const DiffText({
    super.key,
    required this.originalText,
    required this.modifiedText,
    required this.isLeftColumn,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate differences between old and new text block contents
    final List<Diff> diffs = diff(originalText, modifiedText);

    // 2. Format it cleanly for human readability
    cleanupSemantic(diffs);

    // 3. Turn differences into styled TextSpans
    final List<TextSpan> spans = diffs.map((d) {
      if (d.operation == DIFF_INSERT) {
        // If this is the left column, we don't display what was added to the right column
        if (isLeftColumn) return const TextSpan();

        return TextSpan(
          text: d.text,
          style: TextStyle(
            backgroundColor: Colors.green.shade100,
            color: Colors.green.shade900,
            fontWeight: FontWeight.bold,
          ),
        );
      } else if (d.operation == DIFF_DELETE) {
        // If this is the right column, we don't display what was completely removed from the left
        if (!isLeftColumn) return const TextSpan();

        return TextSpan(
          text: d.text,
          style: TextStyle(
            backgroundColor: Colors.red.shade100,
            color: Colors.red.shade900,
            decoration: TextDecoration.lineThrough,
          ),
        );
      } else {
        // Common unchanged text elements
        return TextSpan(
          text: d.text,
          style: const TextStyle(color: Colors.black87),
        );
      }
    }).toList();

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.4),
        children: spans,
      ),
    );
  }
}
