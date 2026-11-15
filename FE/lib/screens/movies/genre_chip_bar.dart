import 'package:flutter/material.dart';

import '../../data/models/tmdb_genre_dto.dart';

/// Genre API 결과로 Chip을 그립니다. [onChanged]가 null이면 Chip을 비활성화합니다.
class GenreChipBar extends StatelessWidget {
  const GenreChipBar({
    super.key,
    required this.genres,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<TmdbGenreDto> genres;
  final List<int> selectedIds;
  final ValueChanged<List<int>>? onChanged;

  void _toggle(int id, bool selected) {
    final next = [...selectedIds];
    selected ? next.add(id) : next.remove(id);
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return FilterChip(
              label: const Text('전체'),
              selected: selectedIds.isEmpty,
              showCheckmark: false,
              onSelected: onChanged == null
                  ? null
                  : (_) => onChanged(const <int>[]),
            );
          }

          final genre = genres[index - 1];
          return FilterChip(
            label: Text(genre.name),
            selected: selectedIds.contains(genre.id),
            onSelected: onChanged == null
                ? null
                : (selected) => _toggle(genre.id, selected),
          );
        },
      ),
    );
  }
}
