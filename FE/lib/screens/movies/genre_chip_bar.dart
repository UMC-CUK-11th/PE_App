import 'package:flutter/material.dart';

import '../../data/movie.dart';

class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.selectedGenres,
    required this.onChanged,
  });

  final Set<String> selectedGenres;
  final ValueChanged<Set<String>> onChanged;

  void _toggle(String genre, bool selected) {
    final next = {...selectedGenres};
    if (selected) {
      next.add(genre);
    } else {
      next.remove(genre);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allGenres.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return FilterChip(
              label: const Text('전체'),
              selected: selectedGenres.isEmpty,
              showCheckmark: false,
              onSelected: (_) => onChanged(<String>{}),
            );
          }

          final genre = allGenres[index - 1];
          return FilterChip(
            label: Text(genre),
            selected: selectedGenres.contains(genre),
            onSelected: (selected) => _toggle(genre, selected),
          );
        },
      ),
    );
  }
}
