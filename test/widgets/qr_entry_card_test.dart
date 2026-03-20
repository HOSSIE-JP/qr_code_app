import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/models/qr_entry_model.dart';
import 'package:qr_code_app/widgets/qr_entry_card.dart';

void main() {
  Widget buildCard({
    required QrEntryModel entry,
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onFavoriteToggle,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 300,
          child: QrEntryCard(
            entry: entry,
            isSelected: isSelected,
            onTap: onTap,
            onLongPress: onLongPress,
            onFavoriteToggle: onFavoriteToggle,
          ),
        ),
      ),
    );
  }

  QrEntryModel createEntry({
    int dataSize = 100,
    bool isFavorite = false,
    String name = 'テスト',
  }) {
    return QrEntryModel(
      id: 'entry-1',
      name: name,
      originalData: Uint8List(dataSize),
      dataSize: dataSize,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      isFavorite: isFavorite,
    );
  }

  group('QrEntryCard 基本表示', () {
    testWidgets('エントリ名が表示される', (tester) async {
      await tester.pumpWidget(buildCard(entry: createEntry(name: '名前テスト')));
      expect(find.text('名前テスト'), findsOneWidget);
    });

    testWidgets('QR 登録済みエントリはサイズを表示する', (tester) async {
      await tester.pumpWidget(buildCard(entry: createEntry(dataSize: 512)));
      expect(find.text('512 B'), findsOneWidget);
    });

    testWidgets('QR 未登録エントリは「QR未登録」を表示する', (tester) async {
      await tester.pumpWidget(buildCard(entry: createEntry(dataSize: 0)));
      // バッジとラベルで2箇所表示
      expect(find.text('QR未登録'), findsWidgets);
    });

    testWidgets('QR 未登録エントリはサムネイルをグレースケール表示する', (tester) async {
      await tester.pumpWidget(buildCard(entry: createEntry(dataSize: 0)));
      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('QR 登録済みエントリはグレースケール表示しない', (tester) async {
      await tester.pumpWidget(buildCard(entry: createEntry(dataSize: 10)));
      expect(find.byType(ColorFiltered), findsNothing);
    });
  });

  group('QrEntryCard 選択モード', () {
    testWidgets('isSelected=true のときチェックアイコンが表示される', (tester) async {
      await tester.pumpWidget(
        buildCard(entry: createEntry(), isSelected: true),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('isSelected=false のときチェックアイコンは表示されない', (tester) async {
      await tester.pumpWidget(
        buildCard(entry: createEntry(), isSelected: false),
      );
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });

  group('QrEntryCard お気に入り', () {
    testWidgets('お気に入りエントリにハートアイコンが表示される', (tester) async {
      await tester.pumpWidget(
        buildCard(
          entry: createEntry(isFavorite: true),
          onFavoriteToggle: () {},
        ),
      );
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('QrEntryCard タップ', () {
    testWidgets('タップで onTap が呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildCard(entry: createEntry(), onTap: () => tapped = true),
      );
      await tester.tap(find.byType(QrEntryCard));
      expect(tapped, isTrue);
    });

    testWidgets('長押しで onLongPress が呼ばれる', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        buildCard(entry: createEntry(), onLongPress: () => longPressed = true),
      );
      await tester.longPress(find.byType(QrEntryCard));
      expect(longPressed, isTrue);
    });
  });
}
