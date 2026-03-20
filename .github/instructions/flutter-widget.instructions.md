---
name: Flutter Widget Instructions
description: "Flutter の Widget 実装、UI 修正、レイアウト調整、widget test 追加、ConsumerWidget や HookConsumerWidget の変更時に使います。Riverpod 3.x と auto_route 前提の Widget 実装ルールです。"
applyTo: "lib/**/*.dart"
---

# Flutter Widget 実装指針

## 対象
- 画面 Widget
- 再利用 Widget
- Riverpod を読む Consumer 系 Widget
- auto_route によって表示される画面

## 方針
- Widget は表示責務を中心に保ち、状態生成やデータ取得の中心にしないでください。
- 1つの Widget が大きくなりすぎる場合は、表示のまとまり単位で分割してください。
- 定数化できる Widget は const を優先し、不要な rebuild を増やさないでください。
- build の中で重い計算、複雑な分岐、非同期開始を行わないでください。
- Widget クラスや主要メソッドには、役割が分かるドキュメントコメントを日本語で付けてください。
- 表示分岐、状態による描画差、回避している落とし穴などは、日本語コメントで意図が追えるようにしてください。

## Riverpod 3.x 前提
- UI から状態を読む処理は Riverpod に寄せ、画面ローカルの場当たり的な状態を増やしすぎないでください。
- watch と read の責務を分けて使ってください。
- AsyncValue など非同期状態を扱う場合は、loading、error、data の描画を明示してください。
- provider の都合で Widget が複雑になるなら、provider 側または中間 Widget に責務を逃がしてください。

## auto_route 前提
- 画面遷移の起点は auto_route の route クラスを使ってください。
- 遷移時に必要な引数や戻り値を型安全に扱ってください。
- Widget 内にルート文字列や場当たり的なナビゲーション処理を直接埋め込まないでください。

## テスト
- Widget を修正したら、見た目だけでなくユーザー操作と状態変化を確認する widget test を優先してください。
- Riverpod を使う Widget は provider override を使って状態差し替え可能にしてください。
- ルーティングに関わる Widget は、押下で期待する遷移が発生するか、遷移後に必要な UI が出るかを必要に応じて検証してください。
- widget test の group 名、testWidgets 名、補足説明も日本語で記述してください。