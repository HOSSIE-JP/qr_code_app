# CLOUD_STORAGE

## 概要

このアプリのクラウドバックアップは、OneDrive のアプリ専用フォルダを利用します。
認証は Microsoft 推奨の MSAL ベースで行い、API 呼び出しは Microsoft Graph を利用します。

- アクセス方式: OAuth 2.0 Authorization Code Flow 相当の公開クライアント認証
- 認証ライブラリ: MSAL 系ライブラリ
- API: Microsoft Graph
- 最小権限: アプリ専用フォルダ向けの最小スコープ
- 保存先: OneDrive の Apps 配下に作成されるアプリ専用フォルダ

## アプリ側の設定

### Dart / Flutter 側

- OneDrive 用のクライアント ID を dart-define で渡します。
- Tenant を個人 Microsoft アカウント専用にする場合、通常はアプリ側で `consumers` を既定値にします。
- 予約スコープはライブラリ側に任せ、アプリでは必要最小限の Graph スコープのみを明示します。

### Android 側

- Android では MSAL の設定 JSON を用意し、認証 audience を個人 Microsoft アカウント向けに合わせます。
- ブラウザベース認証を使う場合、アプリ登録に対応する redirect URI を Android Manifest 側の intent filter と一致させます。
- 署名ハッシュは debug 用と release 用で別になります。

### Android のキー署名と手順

- debug ビルドでは通常、開発環境の標準 debug keystore を使います。
- release ビルドでは専用 keystore を別途作成します。
- 署名ハッシュは keystore から算出し、Azure 側の Android redirect URI と一致させます。
- keystore の再生成や差し替えを行った場合は、署名ハッシュも再計算して設定を更新します。

### 署名ファイルの外部化

- keystore 本体はプロジェクト外に置きます。
- 署名パスワードや alias は、Git 管理しない外部プロパティファイルにまとめます。
- Gradle 側では `local.properties` などのローカル専用設定から、その外部プロパティファイルの場所だけを参照する構成にします。
- リポジトリにはサンプル書式だけを置き、実値は保存しません。

### Apple プラットフォーム側

- iOS / macOS では bundle identifier と redirect URI scheme を一致させます。
- 認証ライブラリと secure storage の両方が keychain を使うため、entitlements の keychain-access-groups を適切に設定します。
- macOS では sandbox と keychain entitlement の不足で認証後のトークン保存に失敗することがあるため、署名設定を含めて確認します。

## Azure ポータル側の設定

### Entra ID でのアプリ登録

1. Entra 管理画面で新しいアプリ登録を作成します。
2. 対応させたいアカウント種別を選択します。
3. 作成後の概要画面でアプリケーション ID を確認します。
4. この ID を Flutter 側の OneDrive クライアント ID 設定へ渡します。

### クライアント ID の取得確認

- アプリ登録の概要画面に表示される Application (client) ID を使います。
- シークレット値はモバイルアプリでは使いません。

### Redirect URI の設定

- Android:
  - モバイル / デスクトップ向けの公開クライアント redirect URI を設定します。
  - 形式は Android パッケージ名と署名ハッシュに対応する MSAL 形式を使います。
- iOS / macOS:
  - bundle identifier ベースの custom URL scheme を設定します。
  - アプリ側の URL scheme 設定と完全一致させます。

### その他必要な設定

- 公開クライアント フローを許可します。
- Microsoft Graph の delegated permission として、アプリ専用フォルダ用途の最小スコープを追加します。
- 必要に応じて管理者またはユーザー同意の動作を確認します。
- 個人 Microsoft アカウント専用で運用する場合は、アプリ登録の対応アカウント種別とアプリ側 authority 設定を一致させます。

## 運用メモ

- 保存先は OneDrive 直下ではなく、Apps 配下のアプリ専用フォルダです。
- 初回アクセス時は、Graph の app folder が遅延作成されることがあるため、初期化確認と再試行を実装しておくと安定します。
- 認証情報、署名ハッシュ、実ファイルパス、秘密情報は保守ドキュメントへ具体値を書かず、別の安全な手段で管理します。