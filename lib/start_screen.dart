import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: SizedBox(
                              width: 82,
                              height: 40,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Text(
                                  'FLUTTER 0주차',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: GoogleFonts.notoSansKr(
                                    color: const Color(0xFF353238),
                                    fontSize: 11,
                                    height: 16 / 11,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.55,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Center(
                            child: SizedBox(
                              width: 128,
                              height: 160,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 32),
                                child: Icon(
                                  Icons.movie_outlined,
                                  size: 64,
                                  color: Color(0xFF4F378A),
                                  semanticLabel: '영화 아이콘',
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 358),
                              child: SizedBox(
                                width: double.infinity,
                                height: 120,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '영화의 순간을\n기록하세요',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.notoSansKr(
                                          color: const Color(0xFF242126),
                                          fontSize: 28,
                                          height: 36 / 28,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.notoSansKr(
                                          color: const Color(0xFF5D5961),
                                          fontSize: 14,
                                          height: 20 / 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 326),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                debugPrint('시작하기 버튼을 눌렀습니다.');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F378A),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(326, 56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: SizedBox(
                                width: 52,
                                height: 20,
                                child: Text(
                                  '시작하기',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: GoogleFonts.notoSansKr(
                                    fontSize: 14,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
