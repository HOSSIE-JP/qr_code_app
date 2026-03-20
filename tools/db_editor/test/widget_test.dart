import 'package:flutter_test/flutter_test.dart';

import 'package:db_editor/src/app.dart';

void main() {
  testWidgets('初期表示でエディタタイトルが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const DbEditorApp());

    expect(find.text('QR DB Editor'), findsOneWidget);
  });
}
