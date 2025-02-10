class Protagonist {
  final String name;
  final String type;  // 人間、動物、魔法使いなど

  Protagonist({
    required this.name,
    required this.type,
  });

  @override
  String toString() => '$type「$name」';
}