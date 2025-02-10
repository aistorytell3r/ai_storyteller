// ページめくり機能を実

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // StreamSubscription用に追加
import '../providers/story_provider.dart';
import '../models/story_scene.dart';
import '../models/book_settings.dart';
import 'dart:convert'; // for base64 decoding
import 'dart:typed_data'; // Uint8Listのインポートを追加
import 'package:audioplayers/audioplayers.dart'; // audio playback

class StoryViewScreen extends StatefulWidget {
  const StoryViewScreen({super.key});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      keepPage: true,
    );
  }

  @override
  void dispose() {
    // ページコントローラの破棄を確実に行う
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageController.dispose();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = context
        .select<StoryProvider, Story?>((provider) => provider.currentStory);
    final autoPlayAudio = context
        .select<BookSettings, bool>((settings) => settings.autoPlayAudio);

    if (story == null) {
      return const Scaffold(
        body: Center(
          child: Text('おはなしが見つかりません'),
        ),
      );
    }

    // タイトルページと各シーンのページを作成
    final pages = [
      _TitlePage(title: story.title),
      ...story.scenes.map(
          (scene) => _StoryPage(scene: scene, autoPlayAudio: autoPlayAudio)),
      const _EndPage(), // Add "おしまい" page at the end
    ];

    return Scaffold(
      body: Container(
        color: Colors.white, // Set background color to white
        child: Stack(
          children: [
            // PageViewの修正
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false, // スクロールバーを無効化
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  if (mounted) {
                    setState(() {
                      _currentPage = index;
                    });
                  }
                },
                itemBuilder: (context, index) => pages[index],
              ),
            ),

            // ページめくりボタン
            if (_currentPage > 0)
              Positioned(
                left: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'prev_page', // 一意のタグを追加
                  mini: true,
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Icon(Icons.arrow_back),
                ),
              ),

            if (_currentPage < pages.length - 1)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'next_page', // 一意のタグを追加
                  mini: true,
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Icon(Icons.arrow_forward),
                ),
              ),

            // ページ番号表示
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${pages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // 戻るボタン
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'back_button', // 一意のタグを追加
                mini: true,
                onPressed: () {
                  Navigator.pop(context);
                },
                tooltip: '戻る',
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitlePage extends StatelessWidget {
  final String title;

  const _TitlePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade900,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatefulWidget {
  final StoryScene scene;
  final bool autoPlayAudio;

  const _StoryPage({
    required this.scene,
    required this.autoPlayAudio,
  });

  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage>
    with AutomaticKeepAliveClientMixin {
  bool isPlaying = false;
  bool hasAutoPlayed = false;
  Uint8List? _audioBytes;
  bool _isInitialized = false; // 初期化状態を追跡
  StreamSubscription<void>? _playerCompleteSubscription; // nullableに変更
  // 各ページで個別のAudioPlayerインスタンスを使用
  final AudioPlayer _pageAudioPlayer = AudioPlayer();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      // Base64デコード前のバリデーション
      if (!widget.scene.audioStr.startsWith('RIFF') &&
          !widget.scene.audioStr.startsWith('UklGR')) {
        print('Invalid audio data format');
        return;
      }

      _audioBytes = base64Decode(widget.scene.audioStr);

      if (_audioBytes == null || _audioBytes!.length < 44) {
        print('Invalid audio data length');
        return;
      }

      // WAVヘッダーの検証
      final header = String.fromCharCodes(_audioBytes!.sublist(0, 4));
      if (header != 'RIFF') {
        print('Invalid WAV header: $header');
        return;
      }

      // プレイヤーの設定
      await _pageAudioPlayer.setReleaseMode(ReleaseMode.stop);
      await _pageAudioPlayer.setPlayerMode(PlayerMode.mediaPlayer);

      // 完了イベントのリスナー設定
      _playerCompleteSubscription =
          _pageAudioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }
      });

      // 音声ソースの設定
      final source = BytesSource(_audioBytes!, mimeType: 'audio/wav');
      await _pageAudioPlayer.setSource(source);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // 自動再生の処理
        if (widget.autoPlayAudio && !hasAutoPlayed) {
          await Future.delayed(const Duration(milliseconds: 800));
          await _playAudio();
        }
      }
    } catch (e) {
      print('Error in _initializeAudio: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _playAudio() async {
    if (!_isInitialized || _audioBytes == null) {
      print('Audio not initialized or audio data is null');
      return;
    }

    try {
      if (isPlaying) {
        await _pageAudioPlayer.stop();
        setState(() {
          isPlaying = false;
        });
        return;
      }

      // 音声を再生
      await _pageAudioPlayer.resume();
      // print('Audio playback started'); // 修正：結果の出力を単純なメッセージに変更

      if (mounted) {
        setState(() {
          isPlaying = true;
          hasAutoPlayed = true;
        });
      }
    } catch (e) {
      print('Error in _playAudio: $e');
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    }
  }

  Future<void> toggleAudio() async {
    try {
      if (isPlaying) {
        await _pageAudioPlayer.stop();
        setState(() {
          isPlaying = false;
        });
      } else {
        await _playAudio();
      }
    } catch (e) {
      print('Error in toggleAudio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final imageBytes = base64Decode(widget.scene.imageStr);

    // 自動再生の処理を削除（_initializeAudioで処理）

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 左ページ（テキスト）
          Expanded(
            child: Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          widget.scene.text,
                          style: const TextStyle(
                            fontSize: 24,
                            height: 2.0,
                          ),
                        ),
                        // 音声コントロールボタン
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.stop : Icons.play_arrow,
                            color: _isInitialized ? Colors.black : Colors.grey,
                          ),
                          onPressed: _isInitialized ? toggleAudio : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 右ページ（画像）
          Expanded(
            child: Card(
              elevation: 4,
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: SingleChildScrollView(
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $error');
                        return Icon(
                          Icons.image_not_supported,
                          size: 120,
                          color: Colors.grey.shade400,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _pageAudioPlayer.dispose(); // 個別のプレイヤーを破棄
    super.dispose();
  }
}

class _EndPage extends StatelessWidget {
  const _EndPage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              'おしまい',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade900,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
