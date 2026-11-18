import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../view_models/load_phase.dart';
import '../../view_models/paged_movies_view_model.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/movie_cards.dart';
import '../../widgets/movie_page_footer.dart';
import '../../widgets/movielog_button.dart';

/// 영화 검색(/movies/search). 영화 목록과 별도의 PagedMoviesViewModel을 씁니다.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  /// Challenge: 입력이 이 시간만큼 멈추면 마지막 검색어로 한 번만 요청합니다.
  static const debounce = Duration(milliseconds: 500);

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _text = TextEditingController();
  Timer? _debounce;
  String? _inputError;

  /// 빈 검색어는 서버에 보내지 않습니다. 같은 검색어를 다시 보내면 page 1부터 새로 불러옵니다.
  void _submit(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _inputError = '검색어를 입력해 주세요.');
      return;
    }
    setState(() => _inputError = null);
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) return;
    _debounce = Timer(MovieSearchScreen.debounce, () {
      if (!mounted) return;
      final query = value.trim();
      // 이미 같은 검색어로 결과를 보고 있으면 다시 요청하지 않습니다.
      if (query == context.read<PagedMoviesViewModel>().query) return;
      _submit(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화 검색',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/movies'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _text,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _submit,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: '영화 제목을 입력하세요',
                errorText: _inputError,
                suffixIcon: IconButton(
                  tooltip: '검색',
                  icon: const Icon(Icons.search),
                  onPressed: () => _submit(_text.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, vm, _) => switch (vm.phase) {
                LoadPhase.idle => const _SearchMessage('검색어를 입력해 주세요.'),
                LoadPhase.loading => const Center(
                  child: CircularProgressIndicator(color: AppColors.violet),
                ),
                LoadPhase.empty => _SearchMessage('"${vm.query}" 검색 결과가 없습니다.'),
                LoadPhase.error => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vm.errorMessage ?? '검색 결과를 불러오지 못했습니다.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      MovieLogButton(
                        label: '다시 시도',
                        width: 120,
                        onPressed: () => vm.loadInitial(query: vm.query),
                      ),
                    ],
                  ),
                ),
                LoadPhase.ready => ListView.builder(
                  itemCount: vm.movies.length + 1,
                  itemBuilder: (context, index) {
                    if (index == vm.movies.length) {
                      return MoviePageFooter(viewModel: vm);
                    }
                    final movie = vm.movies[index];
                    return MovieListTile(
                      movie: movie,
                      onTap: () =>
                          context.push('/movies/${movie.id}', extra: movie),
                    );
                  },
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: AppTextStyles.bodyMedium));
  }
}
