// lib/models/story_settings.dart
import 'package:flutter/foundation.dart';

class StorySettingsModel extends ChangeNotifier {
  String _subject = '';
  String _stage = '';
  List<String> _genres = [];
  List<String> _characters = [];
  int _targetAge = 0;
  int _wordCount = 0;
  bool _useStoryStructure = false;

  // Getters
  String get subject => _subject;
  String get stage => _stage;
  List<String> get genres => _genres;
  List<String> get characters => _characters;
  int get targetAge => _targetAge;
  int get wordCount => _wordCount;
  bool get useStoryStructure => _useStoryStructure;

  // Setters with notification
  void setSubject(String value) {
    _subject = value;
    notifyListeners();
  }

  void setStage(String value) {
    _stage = value;
    notifyListeners();
  }

  void setGenres(List<String> value) {
    _genres = value;
    notifyListeners();
  }

  void setCharacters(List<String> value) {
    _characters = value;
    notifyListeners();
  }

  void setTargetAge(int value) {
    _targetAge = value;
    notifyListeners();
  }

  void setWordCount(int value) {
    _wordCount = value;
    notifyListeners();
  }

  void setUseStoryStructure(bool value) {
    _useStoryStructure = value;
    notifyListeners();
  }

  // データを初期化するメソッド
  void reset() {
    _subject = '';
    _stage = '';
    _genres = [];
    _characters = [];
    _targetAge = 0;
    _wordCount = 0;
    _useStoryStructure = false;
    notifyListeners();
  }
}