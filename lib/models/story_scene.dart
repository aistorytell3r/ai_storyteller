/// 物語の1シーンを表すクラス(テキストと画像データを持つ)
class StoryScene {
  /// シーンの説明文 (画像生成用)
  final String description;

  /// シーンのテキスト内容
  final String text;

  /// 生成された画像のBase64エンコードデータ
  final String imageStr;

  /// 生成された音声のBase64エンコードデータ
  final String audioStr;


  /// このシーンの表示順序
  final int order;

  StoryScene({
    required this.description,
    required this.text,
    required this.imageStr,
    required this.audioStr,
    required this.order,
  });

  /// JSONからStorySceneを作成するファクトリコンストラクタ
  factory StoryScene.fromJson(Map<String, dynamic> json) {
    return StoryScene(
      description: json['description'] as String,
      text: json['text'] as String,
      imageStr: json['imageStr'] as String,
      audioStr: json['audioStr'] as String,
      order: json['order'] as int,
    );
  }

  /// StorySceneをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'text': text,
      'imageStr': imageStr,
      'audioStr': audioStr,
      'order': order,
    };
  }

  /// シーンの内容をコピーして新しいインスタンスを作成するメソッド
  StoryScene copyWith({
    String? description,
    String? text,
    String? imageStr,
    String? audioStr,
    String? audioUrl,
    int? order,
  }) {
    return StoryScene(
      description: description ?? this.description,
      text: text ?? this.text,
      imageStr: imageStr ?? this.imageStr,
      audioStr: audioStr ?? this.audioStr,
      order: order ?? this.order,
    );
  }

  /// 文字列表現を返すメソッド
  @override
  String toString() {
    return 'StoryScene(description: $description, text: $text, imageStr: $imageStr, audioStr: $audioStr, order: $order)';
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StoryScene &&
        other.description == description &&
        other.text == text &&
        other.imageStr == imageStr &&
        other.audioStr == audioStr &&
        other.order == order;
  }

  /// ハッシュコード
  @override
  int get hashCode {
    return description.hashCode ^
        text.hashCode ^
        imageStr.hashCode ^
        audioStr.hashCode ^
        order.hashCode;
  }
}

/// 物語全体を表すクラス(複数の StoryScene インスタンスで構成されるストーリー全体)
class Story {
  /// 物語のタイトル
  final String title;

  /// シーンのリスト
  final List<StoryScene> scenes;

  /// 対象年齢
  // final int targetAge;

  /// 作成日時
  final DateTime createdAt;

  Story({
    required this.title,
    required this.scenes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// JSONからStoryを作成するファクトリコンストラクタ
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      title: json['title'] as String,
      scenes: (json['scenes'] as List<dynamic>)
          .map((scene) => StoryScene.fromJson(scene as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// StoryをJSONに変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'scenes': scenes.map((scene) => scene.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 物語の内容をコピーして新しいインスタンスを作成するメソッド
  Story copyWith({
    String? title,
    List<StoryScene>? scenes,
    int? targetAge,
    DateTime? createdAt,
    String? imageStr, 
  }) {
    return Story(
      title: title ?? this.title,
      scenes: scenes ?? this.scenes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// シーンの総数を取得
  int get sceneCount => scenes.length;

  /// 指定されたインデックスのシーンを取得
  StoryScene? getScene(int index) {
    if (index < 0 || index >= scenes.length) return null;
    return scenes[index];
  }

  /// 物語の文字数を取得
  int get totalCharacterCount {
    return scenes.fold(0, (sum, scene) => sum + scene.text.length);
  }

  /// 文字列表現を返すメソッド
  @override
  String toString() {
    // return 'Story(title: $title, scenes: ${scenes.length}, targetAge: $targetAge)';
    return 'Story(title: $title, scenes: ${scenes.length})';
  }

  /// 等価性の比較
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Story &&
        other.title == title &&
        listEquals(other.scenes, scenes) &&
        // other.targetAge == targetAge &&
        other.createdAt == createdAt;
    // other.imageStr == imageStr; // imageStr パラメータを追加
  }

  /// ハッシュコード
  @override
  int get hashCode {
    return title.hashCode ^
        scenes.hashCode ^
        // targetAge.hashCode ^
        createdAt.hashCode;
    // imageStr.hashCode; // imageStr パラメータを追加
  }
}

/// リストの等価性を比較するユーティリティ関数
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
