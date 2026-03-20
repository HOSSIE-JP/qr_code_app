---
name: flutter-feature-delivery
description: 'Flutter と Dart の機能追加、修正、リファクタリング、レビューに使います。Riverpod 3.x と auto_route 前提で、Widget 変更、状態管理、非同期処理、画面遷移、描画問題、テスト追加、デグレード防止を扱います。'
argument-hint: 'Flutter 機能、Riverpod の状態フロー、auto_route の画面遷移、Widget 修正、または不足しているテスト内容を指定してください。'
user-invocable: true
disable-model-invocation: false
---

# Flutter Feature Delivery

このスキルは、このリポジトリで一定以上の規模の Flutter / Dart 変更を行うときに使います。

## 目的
- Flutter らしい構成で要求された挙動を実装すること。
- 同じタスク内で自動テストを追加または更新し、デグレードを早い段階で検出できるようにすること。
- 変更後に対象を絞った検証を行うこと。

## 手順
1. 変更前に、関連する Widget、Riverpod provider、サービス、route 定義、既存テストを確認します。
2. 広いリファクタリングを避けつつ、問題を解くための最小変更を決めます。
3. UI、状態、ロジックの責務を分離して本番コードを実装します。
4. 実装直後に、対応するテストを追加または更新します。
5. 純粋 Dart ロジックには unit test、UI・操作・画面遷移には widget test を優先します。
6. まず対象を絞って検証し、必要な場合だけ広い検証に広げます。

## Riverpod 3.x 前提
- 状態管理の追加や修正は Riverpod 3.x 系を前提にします。
- provider の責務を曖昧にせず、Widget で状態を作り込みすぎないでください。
- テストでは provider override や依存差し替えがしやすい設計を優先してください。

## auto_route 前提
- 画面遷移は auto_route を基準に扱います。
- ルート追加や変更では、型安全な route、引数、戻り値、ネスト構成の整合性を確認してください。
- 画面遷移の変更には、必要に応じて導線確認を含むテストを追加してください。

## テスト期待値
- 本番挙動を変える変更には、必ず対応する自動テストを付けてください。
- 新しい UI 状態は、原則として widget test で表示内容と操作結果を検証してください。
- 非同期ロジックは、必要に応じて loading、success、failure、empty の各状態を検証してください。
- バグ修正では、修正前に落ちるはずの回帰テストを含めてください。
- test、testWidgets、group の説明は日本語で記述してください。

## Flutter 実装ガイダンス
- Widget は小さく分割し、再利用しやすく保ってください。
- build メソッドに重い処理を書かないでください。
- async gap をまたぐ BuildContext 利用に注意してください。
- 状態遷移は決定的にし、エラーハンドリングは明示してください。
- UI 調整時もアクセシビリティとレスポンシブ性を維持してください。
- クラスや関数にはドキュメントコメントを付け、実装の意図や注意点は日本語コメントで残してください。

## 検証
- まず最小の対象に絞って検証し、必要な場合だけ広げてください。
- 優先するコマンドは次の通りです。
  - `flutter test test/path_to_target_test.dart`
  - `flutter analyze`
  - `flutter test`
- 検証を完了できない場合は、ブロッカーと未検証範囲を明示してください。