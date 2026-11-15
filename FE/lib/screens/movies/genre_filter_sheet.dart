import 'package:flutter/material.dart';

import '../../data/models/tmdb_genre_dto.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelection,
    required this.scrollController,
  });

  final List<TmdbGenreDto> genres;
  final List<int> initialSelection;
  final ScrollController scrollController;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<int> _selection = {...widget.initialSelection};

  void _toggle(int genreId, bool checked) {
    setState(() {
      if (checked) {
        _selection.add(genreId);
      } else {
        _selection.remove(genreId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '장르 필터',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 4),
              const Text('여러 장르를 선택할 수 있어요', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: widget.genres.length,
            itemBuilder: (context, index) {
              final genre = widget.genres[index];
              return CheckboxListTile(
                value: _selection.contains(genre.id),
                onChanged: (checked) => _toggle(genre.id, checked ?? false),
                title: Text(genre.name, style: AppTextStyles.bodyMedium),
                activeColor: AppColors.violet,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selection.toList()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
