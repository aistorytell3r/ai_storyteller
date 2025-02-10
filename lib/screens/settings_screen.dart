// 設定画面の実装

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.purple.shade100, // AppBarの背景色を薄紫に設定
        iconTheme: const IconThemeData(color: Colors.white), // AppBarのアイコン色を白に設定
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20), // AppBarのタイトル色を白に設定
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<BookSettings>(
        builder: (context, settings, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 対象年齢設定
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '対象年齢',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: settings.targetAge,
                        items: List.generate(10, (index) => index + 3)
                            .map((age) => DropdownMenuItem(
                                  value: age,
                                  child: Text('$age歳'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) settings.setTargetAge(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 使用文字設定
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '使用文字',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...TextStyleType.values
                          .map((style) => RadioListTile<TextStyleType>(
                                title: Text(_getTextStyleLabel(style)),
                                value: style,
                                groupValue: settings.textStyle,
                                onChanged: (value) {
                                  if (value != null)
                                    settings.setTextStyle(value);
                                },
                              )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 目的設定
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '目的',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setState) {
                          final textController = TextEditingController(text: settings.purpose);
                          textController.addListener(() {
                            settings.setPurpose(textController.text);
                          });
                          return TextField(
                            decoration: const InputDecoration(
                              hintText: '例：物語を通して情緒教育をしたい',  // ヒントテキスト
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            controller: textController,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 時間設定
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '物語の時間',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: settings.duration,
                        items: [3, 5, 7, 10]
                            .map((minutes) => DropdownMenuItem(
                                  value: minutes,
                                  child: Text('$minutes分'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) settings.setDuration(value);
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '約${settings.wordCount}文字の物語が生成されます',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 音声自動再生設定
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '音声を自動再生する',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: settings.autoPlayAudio,
                            onChanged: (value) {
                              settings.setAutoPlayAudio(value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'VOICEVOX:ずんだもん',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  String _getTextStyleLabel(TextStyleType style) {
    switch (style) {
      case TextStyleType.hiraganaOnly:
        return 'ひらがなのみ';
      case TextStyleType.hiraganaAndKatakana:
        return 'ひらがなとカタカナ';
      case TextStyleType.hiraganaAndKanji:
        return 'ひらがなと漢字';
    }
  }
}
