// 子供向け物語生成画面（ジャンル選択画面）を実装

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_settings.dart';
import '../providers/story_provider.dart';
import 'story_view_screen.dart';
import '../models/book_settings.dart';

class ChildInputScreen extends StatefulWidget {
  const ChildInputScreen({super.key});

  @override
  State<ChildInputScreen> createState() => _ChildInputScreenState();
}

class _ChildInputScreenState extends State<ChildInputScreen> {
  // 物語生成中かどうかを示すフラグ
  bool _isGenerating = false;

  // 選択可能なジャンルのリスト
  static const List<String> genreOptions = [
    'ぼうけん',
    'たべもの',
    'ファンタジー',
    'ともだち',
    'のりもの',
    'どうぶつ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, // Ensure the container takes the full width
        color: Colors.white, // Set background color to white
        child: Stack(
          children: [
            // メインコンテンツ: ジャンル選択部分
            Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Consumer<StorySettingsModel>(
                  builder: (context, settings, child) {
                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center align the text
                      children: [
                        // ジャンル選択
                        const SizedBox(height: 20),
                        const Text(
                          'どんな絵本がよみたい？',
                          style: TextStyle(
                            fontSize: 24, // Increase font size
                            fontWeight: FontWeight.bold, // Make text bold
                            color: Colors.black, // Set text color to black
                          ),
                          textAlign: TextAlign.center, // Center align the text
                        ),
                        const SizedBox(height: 20),

                        // ジャンル選択グリッド
                        Center(
                          child: Wrap(
                            spacing: 12.0,
                            runSpacing: 12.0,
                            alignment: WrapAlignment.center, // 中央揃え
                            children: genreOptions.map((genre) {
                              // sizeboxのサイズを画面の大きさに合わせて動的に変更する
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = MediaQuery.of(context)
                                      .size
                                      .width; // 画面の幅を取得
                                  final itemWidth = width < 600
                                      ? width * 0.45
                                      : width *
                                          0.3; // 小さい画面では画面幅の45%,大きい画面では画面幅の30%
                                  final itemHeight =
                                      itemWidth * 0.7; // 高さは幅の70%に設定
                                  // ジャンルカードの作成
                                  return SizedBox(
                                    width: itemWidth,
                                    height: itemHeight,
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                            color: Colors
                                                .purple.shade300), // Add black border
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      // 選択状態に応じて見た目を変更
                                      elevation: settings.genres.contains(genre)
                                          ? 8
                                          : 2,
                                      color: settings.genres.contains(genre)
                                          ? Colors.purple.shade50
                                          : Colors.white,
                                      child: InkWell(
                                        // タップ時のジャンル選択処理
                                        onTap: () {
                                          List<String> newGenres =
                                              List.from(settings.genres);
                                          if (newGenres.contains(genre)) {
                                            newGenres.remove(genre);
                                          } else {
                                            newGenres.add(genre);
                                          }
                                          settings.setGenres(newGenres);
                                        },
                                        // カードの内容（画像とテキスト）
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // 画像部分：利用可能な空間いっぱいに拡大
                                              Expanded(
                                                  child: _getGenreImage(
                                                      genre)), // ジャンルに応じた画像を表示
                                              // 画像とテキストの間のスペース
                                              const SizedBox(height: 7),
                                              // ジャンル名のテキスト表示
                                              Text(
                                                genre, // ジャンル名
                                                style: const TextStyle(
                                                  fontSize: 18, // 18ptのフォントサイズ
                                                  fontWeight: FontWeight
                                                      .bold, // Make text bold
                                                  color: Colors
                                                      .black, // Set text color to black
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(
                            height:
                                80), // Add space to avoid overlap with the button
                      ],
                    );
                  },
                ),
              ),
            ),
            // 生成中のローディング表示
            if (_isGenerating)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            // 物語生成ボタン
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: ElevatedButton.icon(
                  // 生成中は無効化
                  onPressed: _isGenerating
                      ? null
                      : () async {
                          final settings = context.read<StorySettingsModel>();
                          // ジャンル未選択時の表示
                          if (settings.genres.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('すきなジャンルを選んでね！'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setState(() => _isGenerating = true);

                          try {
                            // 物語生成の実行
                            final storyProvider = context
                                .read<StoryProvider>(); // StoryProviderを取得
                            final bookSettings =
                                context.read<BookSettings>(); // BookSettingsを取得
                            await storyProvider.generateChildStory(
                              // 物語生成メソッドを呼び出し
                              genres: settings.genres, // 選択されたジャンルのリスト
                              targetAge: bookSettings.targetAge, // 対象年齢
                              duration: bookSettings.duration, // 読む時間
                              textStyle:
                                  bookSettings.textStyle.toString(), // 使用文字
                              purpose: bookSettings.purpose,
                            );

                            if (!mounted) return;

                            // 生成成功時は表示画面に遷移
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const StoryViewScreen(),
                              ),
                            );
                          } catch (e) {
                            // エラー処理
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('エラーが起きちゃった: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isGenerating = false);
                            }
                          }
                        },
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Icon(Icons.auto_stories,
                          color: Colors.white), // Set icon color to white
                  label: Text(
                    _isGenerating ? 'おはなしを作ってるよ...' : 'おはなしを作る',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white, // Set text color to white
                      fontWeight: FontWeight.bold, // Make text bold
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    backgroundColor: Colors.purple
                        .shade100, // Set button background color to light purple
                    foregroundColor: Colors.white,
                    elevation: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ジャンルに応じた画像アセットを返すメソッド
  Widget _getGenreImage(String genre) {
    switch (genre) {
      case 'ぼうけん':
        return Image.asset('assets/images/adventure.png');
      case 'たべもの':
        return Image.asset('assets/images/food.png');
      case 'ファンタジー':
        return Image.asset('assets/images/fantasy.png');
      case 'ともだち':
        return Image.asset('assets/images/friendship.png');
      case 'のりもの':
        return Image.asset('assets/images/vehicle.png');
      case 'どうぶつ':
        return Image.asset('assets/images/animal.png');
      default:
        return Icon(Icons.book,
            size: 64, color: Colors.white); // Change icon color to white
    }
  }
}
