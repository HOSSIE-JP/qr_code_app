# プリQR

プリQR は、QR コードの生成・読み取り・管理を1つのアプリで行えるクロスプラットフォーム Flutter アプリです。

## 主な機能

- テキスト/ファイルから QR コードを生成
- カメラ・画像ファイルから QR コードを読み取り
- QR エントリの保存、編集、削除
- お気に入り管理とカテゴリ別アコーディオン表示
- 名称/説明/タグ名を対象にした検索
- QR 未登録エントリの作成と後からの QR 登録
- データベース（コレクション）の複数管理
- データベース単位のエクスポート/インポート
- QR 詳細画面での前後スワイプ・左右ボタン遷移
- QR 詳細画面下部の固定アクション
	- QRコードを表示
	- URLをブラウザで開く
	- 情報を編集する

## 対応プラットフォーム

- Android
- iOS
- macOS
- Windows
- Web

## セットアップ

```bash
flutter pub get
```

## 実行方法

```bash
flutter run
```

## 使い方

1. ホーム画面下部中央の `QRをスキャン` から QR を読み取ります。
2. `＋` ボタンで QR 未登録エントリを追加し、後から編集画面で QR を登録できます。
3. エントリをタップすると詳細画面へ移動し、名称・説明・タグ・サムネイル・QR プレビューを確認できます。
4. 詳細画面では左右スワイプ、または画面中央左右のボタンで前後エントリを切り替えられます。
5. 必要に応じて設定画面でデータベースやカテゴリ、タグを管理します。

## Web / PWA

- Web 版では QR 表示画面右上の「ホーム画面に追加」ボタンから、PWA のインストール導線を開けます。
- ブラウザが `beforeinstallprompt` を提供している場合は、そのまま追加ダイアログが表示されます。
- 一部ブラウザでは自動プロンプトを提供しないため、その場合はブラウザメニューの「ホーム画面に追加」を利用してください。

### GitHub Pages 公開

- GitHub Actions ワークフローは [.github/workflows/deploy-web-pages.yml](.github/workflows/deploy-web-pages.yml) を利用します。
- push 先が `main` ブランチのときに **アプリ本体** と **DBエディター** の Web ビルド + Pages デプロイを実行します。
- ビルド時の base-href はワークフロー内で自動設定します（アプリ本体 + DBエディターを別パスで出力）。
	- `<owner>/<repo>` 形式の通常リポジトリ: `/$repo/`
	- User/Org Pages (`<name>.github.io`): `/`
- 公開先 URL は次のとおりです。
	- アプリ本体: `<pages-url>/`
	- DBエディター: `<pages-url>/db_editor/`
- 初回のみ GitHub の Settings → Pages で Source を **GitHub Actions** に設定してください。

### Web のデータベース保存先

- Web 版のローカルデータベースはブラウザ内ストレージ（drift + sqlite3.wasm）に保存されます。
- 通常はセッションごとに再インポートは不要です。
- ただし、ブラウザデータ削除・シークレットモード・ブラウザ仕様によっては永続化されない場合があります。
- 端末移行やブラウザ変更時は、必要に応じて Export / Import を利用してください。

## DBエディター (Web)

- `tools/db_editor` は Web ビルドに対応しています。
- 起動例:

```bash
cd tools/db_editor
flutter run -d chrome
```

- Web 用ビルド例:

```bash
cd tools/db_editor
flutter build web
```

## 開発時の確認コマンド

```bash
dart format .
flutter analyze
flutter test
```

## OneDrive / MSAL 設定

- iOS / macOS の本番 bundle identifier は `jp.co.geroneko.priqr` です。
- Android の `assets/msal_config.json` は `PersonalMicrosoftAccount` と `https://login.microsoftonline.com/consumers` を使い、MSAL の既定 authority も個人 Microsoft アカウント専用にしてください。
- OneDrive の要求スコープは `Files.ReadWrite.AppFolder` のみを明示し、`openid` / `profile` / `offline_access` は MSAL の予約スコープとして明示指定しません。
- VS Code の [ .vscode/launch.json ](.vscode/launch.json) では Tenant ID の入力は不要です。通常は `consumers` が既定値として使われます。
- OneDrive の保存先はユーザーの OneDrive 直下ではなく、`Apps/<アプリ登録名>` 配下のアプリ専用フォルダです。
- Azure Portal の redirect URI は次を登録してください。
	- Android: `msauth://jp.co.geroneko/zzvXMUAcU3YjMd0QbTOeRb7g8dY%3D`
	- iOS / macOS: `msauth.jp.co.geroneko.priqr://auth`

- 詳細な運用手順は [CLOUD_STORAGE.md](CLOUD_STORAGE.md) を参照してください。

## Android 署名設定

- release 署名は debug keystore を使わず、プロジェクト外の keystore ファイルを参照します。
- keystore 本体は Git 管理外の任意ディレクトリに置いてください。
- 署名情報ファイルの例は [android/signing.properties.example](android/signing.properties.example) です。
- 実ファイルはたとえば `/Users/yourname/secure/android/priqr-signing.properties` に配置し、内容は次の 4 項目です。
	- `storeFile`
	- `storePassword`
	- `keyAlias`
	- `keyPassword`
- [android/local.properties](android/local.properties) に次の 1 行を追加すると、Gradle がその外部ファイルを読み込みます。

```properties
priqr.signing.properties=/Users/yourname/secure/android/priqr-signing.properties
```

- `local.properties` と keystore / signing properties はいずれも Git に載りません。
