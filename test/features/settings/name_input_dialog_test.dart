import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/features/settings/widgets/name_input_dialog.dart';

void main() {
  testWidgets('入力して作成を押すと値を返し例外が発生しない', (tester) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<String>(
                      context: context,
                      builder: (_) => const NameInputDialog(
                        title: '新規作成',
                        label: '名称',
                        actionLabel: '作成',
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'テスト名');
    await tester.tap(find.text('作成'));
    await tester.pumpAndSettle();

    expect(result, 'テスト名');
    expect(tester.takeException(), isNull);
  });

  testWidgets('キャンセル時はnullを返し例外が発生しない', (tester) async {
    String? result = 'initial';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<String>(
                      context: context,
                      builder: (_) => const NameInputDialog(
                        title: '新規作成',
                        label: '名称',
                        actionLabel: '作成',
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
