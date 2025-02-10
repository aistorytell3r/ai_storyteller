import 'package:flutter/foundation.dart';

// 列挙型の定義
enum TextStyleType {  
  hiraganaOnly,
  hiraganaAndKatakana,
  hiraganaAndKanji
}

class BookSettings extends ChangeNotifier {
  int _targetAge = 5;
  TextStyleType _textStyle = TextStyleType.hiraganaAndKatakana;
  String _purpose = '';
  int _duration = 5;  //デフォルト値
  bool _autoPlayAudio = false; // Add autoPlayAudio property

  // ゲッター
  int get targetAge => _targetAge;
  TextStyleType get textStyle => _textStyle;
  String get purpose => _purpose;  
  int get duration => _duration;
  int get wordCount => _duration * 400;
  bool get autoPlayAudio => _autoPlayAudio; // Getter for autoPlayAudio

  // セッター
  void setTargetAge(int age) {
    _targetAge = age;
    notifyListeners();
  }

  void setTextStyle(TextStyleType style) {
    _textStyle = style;
    notifyListeners();
  }

  void setPurpose(String purpose) {
    _purpose = purpose;
    notifyListeners();
  }

  void setDuration(int minutes) {
    _duration = minutes;
    notifyListeners();
  }

  void setAutoPlayAudio(bool value) { // Setter for autoPlayAudio
    _autoPlayAudio = value;
    notifyListeners();
  }

  // プロンプト修正用のメソッド
  String getTextStylePrompt() {
    switch (_textStyle) {
      case TextStyleType.hiraganaOnly:
        return 'すべての文章をひらがなで書いてください。漢字は使用しないでください。';
      case TextStyleType.hiraganaAndKatakana:
        return 'ひらがなとカタカナのみを使用してください。漢字は使用しないでください。';
      case TextStyleType.hiraganaAndKanji:
        return '$_targetAge歳の子供が読める程度の漢字を使用してください。';
    }
  }
}
