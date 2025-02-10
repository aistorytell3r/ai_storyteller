// 大人向け物語生成画面(保護者向け)の実装

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_settings.dart';
import '../providers/story_provider.dart';
import '../services/gemini_service.dart';
import '../models/protagonist.dart';
import 'story_view_screen.dart';
import '../models/book_settings.dart';

class ParentInputScreen extends StatefulWidget {
  const ParentInputScreen({super.key});

  @override
  State<ParentInputScreen> createState() => _ParentInputScreenState();
}

class _ParentInputScreenState extends State<ParentInputScreen> {
  String? selectedTheme;
  String? selectedStage;
  final List<String> selectedGenres = [];
  String? selectedProtagonistType;
  String protagonistName = '';
  String customStage = '';
  bool _isLoading = false;

  // 基本の題材リスト
  static const List<String> themeOptions = [
    '日常の出来事',
    '自然や動物',
    '心や感情の成長',
    '冒険とファンタジー',
    '教育的なテーマ',
    '社会や道徳のテーマ',
    'ユーモアやナンセンス',
    '夢や想像力を刺激するテーマ',
    '人生のターニングポイント',
    '地域や文化',
  ];

  // 舞台の候補（Geminiから取得）
  List<String> stageOptions = [];

  static const List<String> genreOptions = [
    '冒険',
    '食べ物',
    'SF',
    '動物',
    '友情',
    '乗り物'
  ];

  static const List<String> protagonistTypes = [
    '人間の子ども',
    '動物',
    '魔法使い',
    '妖精',
    'ロボット',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('絵本生成設定（保護者向け）'),
        backgroundColor: Colors
            .purple.shade100, // Set AppBar background color to light purple
        iconTheme: const IconThemeData(
            color: Colors.white), // Set AppBar icon color to white
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20), // Set AppBar title color to white
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 題材選択
                _buildSection(
                  title: '題材を選ぶ',
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '題材の種類',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTheme,
                    items: themeOptions.map((String theme) {
                      return DropdownMenuItem<String>(
                        value: theme,
                        child: Text(theme),
                      );
                    }).toList(),
                    onChanged: (String? value) async {
                      setState(() {
                        selectedTheme = value;
                        selectedStage = null;
                        customStage = '';
                        _isLoading = true;
                      });
                      await _fetchStageOptions();
                    },
                  ),
                ),

                // 舞台選択
                if (selectedTheme != null && stageOptions.isNotEmpty)
                  _buildSection(
                    title: '舞台を選ぶ',
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: stageOptions.map((stage) {
                            return ChoiceChip(
                              label: Text(stage),
                              selected: selectedStage == stage,
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedStage = selected ? stage : null;
                                  customStage = '';
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'カスタム舞台を入力',
                            border: OutlineInputBorder(),
                            hintText: '例：魔法の森、未来都市 など',
                          ),
                          onChanged: (value) {
                            setState(() {
                              customStage = value;
                              selectedStage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // ジャンル選択
                if (selectedStage != null || customStage.isNotEmpty)
                  _buildSection(
                    title: 'ジャンルを選ぶ',
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: genreOptions.map((genre) {
                        return FilterChip(
                          label: Text(
                            genre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, // Make text bold
                            ),
                          ),
                          selected: selectedGenres.contains(genre),
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                selectedGenres.add(genre);
                              } else {
                                selectedGenres.remove(genre);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                // 主人公設定
                if (selectedGenres.isNotEmpty)
                  _buildSection(
                    title: '主人公を設定する',
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: '主人公の種類',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedProtagonistType,
                          items: protagonistTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedProtagonistType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: '主人公の名前',
                            border: OutlineInputBorder(),
                            hintText: '例：ゆうき、ポチ、うさぎ など',
                          ),
                          onChanged: (value) {
                            setState(() {
                              protagonistName = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // 生成ボタン
                if (selectedProtagonistType != null)
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateStory,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.purple.shade100,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                )
                              : const Icon(Icons.auto_stories,
                                  color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _isLoading ? '生成中...' : '絵本を生成する',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold, // Make text bold
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Set text color to black
          ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _fetchStageOptions() async {
    try {
      setState(() => _isLoading = true);

      final storyProvider = context.read<StoryProvider>();
      // mainThemeを渡して舞台候補を取得
      final stages = await storyProvider.getStageOptions(selectedTheme!);

      setState(() {
        stageOptions = stages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('舞台候補の取得に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 生成可能か判定する処理を更新（任意項目の考慮）
  bool _canGenerateStory() {
    return selectedTheme != null;
  }

  // ストーリー生成ボタンの処理
  Future<void> _generateStory() async {
    if (!_canGenerateStory()) return;

    setState(() => _isLoading = true);

    try {
      final storyProvider = context.read<StoryProvider>();
      final bookSettings = context.read<BookSettings>();
      await storyProvider.generateParentStory(
        subject: selectedTheme!,
        stage: customStage.isNotEmpty ? customStage : selectedStage!,
        genres: selectedGenres,
        protagonistType: selectedProtagonistType!,
        protagonistName: protagonistName,
        targetAge: bookSettings.targetAge,
        duration: bookSettings.duration,
        textStyle: bookSettings.textStyle.toString(),
        purpose: bookSettings.purpose,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StoryViewScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
