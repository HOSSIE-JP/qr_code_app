import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/data/database/app_database.dart';

void main() {
  group('AppDatabase Web 設定', () {
    test('drift の Web アセットパスが期待値である', () {
      final options = createDriftWebOptions();

      expect(options.sqlite3Wasm.toString(), driftSqliteWasmPath);
      expect(options.driftWorker.toString(), driftWorkerPath);
    });
  });
}
