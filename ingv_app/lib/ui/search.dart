import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  final dynamic viewModel;
  
  const Search({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: TextField(
        onChanged: viewModel.setSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search (keywords, tags)...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 0,
          ),
        ),
      ),
    );
  }
}
