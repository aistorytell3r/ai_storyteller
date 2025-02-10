1. Google Cloudでプロジェクトを作成します。
2. 作成したプロジェクトで以下のAPIを有効にします。
    - Vertex AI API
3. Flutterプロジェクトを作成します。
    - `flutter create ai_storyteller`
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
    - `mv assets/ lib/ pubspec.yaml ai_storyteller/`
7. 作成したFlutterプロジェクトに移動します。
    - `cd ai_storyteller`
8. 必要なパッケージをインストールします。
    - `flutter pub get`
9. ビルドします。
    - `flutter build web --base-href "/static/"`
10. App Engineへのデプロイ用にフォルダを作成します。
    - `mkdir -Force deploy/static`
11. リポジトリ内のファイルをデプロイ用のフォルダに移動します。
    - `mv main.py requirements.txt app.yaml deploy/`
12. ビルドにより生成されたファイルをデプロイ用のフォルダに移動します。
    - `mv build/web/* deploy/static/`
13. ビルド先に移動します。
    - `cd deploy`
14. App Engineにデプロイします。

    ```ps1
    # 作成したGoogle Cloudのプロジェクトをデプロイ先に指定します。
    gcloud config set project 作成したGoogle CloudのプロジェクトID

    # App Engineにデプロイします。
    # デプロイ先のリージョンを聞かれたら、us-central1を選択してください。
    gcloud app deploy
    ```

15. デプロイが成功したら、生成されたURLにアクセスし、Webアプリが利用できることを確認します。
16. WebアプリにGoogleの認証画面を付けたい場合、Google Cloudにて以下を実施してください。
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
