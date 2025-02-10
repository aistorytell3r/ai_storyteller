import 'dart:convert'; // jsonEncode関数をインポート
import 'package:http/http.dart' as http; // httpパッケージをインポート
import '../models/story_scene.dart'; // StorySceneクラスをインポート
import '../models/protagonist.dart'; // Protagonistクラスをインポート

// Gemini APIを呼び出すサービスクラス
class GeminiService {
  static const String _baseUrl =
        'https://Google CloudのプロジェクトID.uc.r.appspot.com/';

  // 題材選択APIを呼び出すメソッド
  Future<List<String>> selectMainTheme(String mainTheme) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/select-main-theme'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mainTheme': mainTheme}),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedBody);
        final parsedData = jsonData is String ? jsonDecode(jsonData) : jsonData;

        if (parsedData is Map<String, dynamic>) {
          final stages = parsedData['stages'] as List;
          return stages.map((stage) => stage.toString()).toList();
        } else {
          return ['不思議な森', '魔法の学校', '雲の上の王国', '海底の都市', '宇宙ステーション', 'おもちゃの国'];
        }
      } else {
        return ['不思議な森', '魔法の学校', '雲の上の王国', '海底の都市', '宇宙ステーション', 'おもちゃの国'];
      }
    } catch (e) {
      print('Error making Gemini request: $e');
      rethrow;
    }
  }

  // 保護者向け物語生成APIを呼び出すメソッド
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
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-story-parent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'subject': subject,
          'stage': stage,
          'genres': genres,
          'protagonistType': protagonistType,
          'protagonistName': protagonistName,
          'targetAge': targetAge,
          'duration': duration,
          'textStyle': textStyle,
          'purpose': purpose,
        }),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedBody);
        final parsedData = jsonData is String ? jsonDecode(jsonData) : jsonData;
        if (parsedData is Map<String, dynamic>) {
          print(parsedData['title']);
          return Story(
            title: parsedData['title'],
            scenes: (parsedData['scenes'] as List<dynamic>)
                .map((scene) => StoryScene(
                      description: scene['description'],
                      text: scene['text'],
                      order: scene['order'],
                      imageStr: scene['imageStr'],
                      audioStr: scene['audioStr'],
                    ))
                .toList(),
          );
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to make Gemini request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error making Gemini request: $e');
      throw Exception('Failed to generate story');
    }
  }

  // 子供向け物語生成APIを呼び出すメソッド
  Future<Story> generateChildStory({
    required List<String> genres,
    required int targetAge,
    required int duration,
    required String textStyle,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-story-child'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'genres': genres,
          'targetAge': targetAge,
          'duration': duration,
          'textStyle': textStyle,
          'purpose': purpose,
        }),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(decodedBody);
        final parsedData = jsonData is String ? jsonDecode(jsonData) : jsonData;
        if (parsedData is Map<String, dynamic>) {
          return Story(
            title: parsedData['title'],
            scenes: (parsedData['scenes'] as List<dynamic>)
                .map((scene) => StoryScene(
                      description: scene['description'],
                      text: scene['text'],
                      order: scene['order'],
                      imageStr: scene['imageStr'],
                      audioStr: scene['audioStr'],
                    ))
                .toList(),
          );
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(
            'Failed to make Gemini request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error making Gemini request: $e');
      throw Exception('Failed to generate story');
    }
  }
}
