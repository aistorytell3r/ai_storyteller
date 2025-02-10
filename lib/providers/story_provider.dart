// GeminiServiceを使って物語生成APIにリクエストを送信

import 'package:flutter/foundation.dart';
import '../services/gemini_service.dart';
import '../models/story_scene.dart';

class StoryProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  Story? _currentStory;
  bool _isLoading = false;
  String? _error;

  // コンストラクタでGeminiServiceを初期化
  StoryProvider();

  // ゲッター
  Story? get currentStory => _currentStory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  GeminiService get service => _geminiService;

  // 大人向け物語生成メソッドを更新
  Future<Story> generateParentStory({
    required String subject,
    required String stage,
    required List<String> genres,
    required String protagonistType,
    String? protagonistName,
    required int targetAge,
    required int duration,
    required String textStyle,
    required String purpose,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final story = await _geminiService.generateParentStory(
        subject: subject,
        stage: stage,
        genres: genres,
        protagonistType: protagonistType,
        protagonistName: protagonistName,
        targetAge: targetAge,
        duration: duration,
        textStyle: textStyle,
        purpose: purpose,
      );

      _currentStory = story;
      _isLoading = false;
      notifyListeners();
      return story;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 子供向け物語生成
  Future<void> generateChildStory({
    required List<String> genres,
    required int targetAge,
    required int duration,
    required String textStyle,
    required String purpose,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final story = await _geminiService.generateChildStory(
        genres: genres,
        targetAge: targetAge,
        duration: duration,
        textStyle: textStyle,
        purpose: purpose,
      );

      _currentStory = story;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 舞台候補を取得
  Future<List<String>> getStageOptions(String mainTheme) async {
    try {
      return await _geminiService.selectMainTheme(mainTheme);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // 状態をクリア
  void clearStory() {
    _currentStory = null;
    _error = null;
    notifyListeners();
  }
}
