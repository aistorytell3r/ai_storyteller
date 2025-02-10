# AI StoryTeller

「AI StoryTeller」はAIを使って絵本の読み聞かせをしてくれるWebアプリです。読み聞かせにはVOICEVOXのずんだもんを利用しています。

## 概要

「AI StoryTeller」の概要や環境、使い方等は[絵本の読み聞かせアプリ「AI StoryTeller」による課題解決と実装方法](https://zenn.dev/knmknm/articles/4d08429c8e6864)に記載しています。

## 環境構築手順

既にFlutter、Google Cloud SDKはインストール済みとします。
以下の手順で使用するコマンドはWindows 11上での実行を想定しています。

1. Google Cloudでプロジェクトを作成します。
2. 作成したプロジェクトで以下のAPIを有効にします。
    - Vertex AI API
3. Flutterプロジェクトを作成します。
    - `flutter create "AI StoryTeller"`
4. 本リポジトリをクローンします。
    - `git clone https://github.com/aistorytell3r/ai_storyteller.git`
5. リポジトリ内の以下ファイルを各自の環境に合わせて変更します。
    - `lib/services/gemini_service.dart`
        - `_baseUrl`: `https://Google CloudのプロジェクトID.uc.r.appspot.com/`
            - 上記はApp EngineにWebアプリをデプロイした際に生成されるURLです。
    - `app.yaml`
        - `PROJECT_ID`: "作成したGoogle CloudのプロジェクトID"
        - `VOICEVOX_API_KEY`: "「[WEB版VOICEVOX API（高速）](https://voicevox.su-shiki.com/su-shikiapis/)」より取得したVOICEVOXのAPIキー"
6. リポジトリ内の以下のファイルをFlutterプロジェクトに移動します。
    - `mv assets/ lib/ pubspec.yaml "AI StoryTeller/"`
7. 作成したFlutterプロジェクトに移動します。
    - `cd "AI StoryTeller"`
8. 必要なパッケージをインストールします。
    - `flutter pub get`
9. ビルドします。
    - `flutter build web --base-href "/static/"`
10. リポジトリ内のファイルをビルド先に移動します。
    - `mv main.py requirements.txt app.yaml build/web/`
11. ビルド先に移動します。
    - `cd build/web/`
12. App Engineにデプロイします。

    ```ps1
    # 作成したGoogle Cloudのプロジェクトをデプロイ先に指定します。
    gcloud config set project 作成したGoogle CloudのプロジェクトID

    # App Engineにデプロイします。
    # デプロイ先のリージョンを聞かれたら、us-central1を選択してください。
    gcloud app deploy
    ```

13. デプロイが成功したら、生成されたURLにアクセスし、Webアプリが利用できることを確認します。
14. WebアプリにGoogleの認証画面を付けたい場合、Google Cloudにて以下を実施してください。
    1. 作成したGoogle Cloudのプロジェクトで以下のAPIを有効にします。
        - `Identity-Aware Proxy API`
    2. OAuth同意画面を作成します。
    3. Identity-Aware Proxyの設定画面にアクセスし、デプロイしたApp EngineでIAPを有効化します。
    4. IAPのIAMポリシーで以下を設定します。
        - プリンシパル: Googleアカウントのメールアドレス
            - 上記で指定したユーザーのみWebアプリにアクセスできるようになります。
            - Googleアカウントを持っている全ユーザーにアクセスを許可する場合、以下を指定してください。
                - allAuthenticatedUsers
        - ロール: IAP-secured Web App User
    5. Webアプリにアクセスし、Googleの認証画面が表示されることを確認します。
