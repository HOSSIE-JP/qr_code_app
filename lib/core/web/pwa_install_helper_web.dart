import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// PWA インストールプロンプトを表示する。
///
/// `beforeinstallprompt` が発火済みの場合のみ true を返す。
Future<bool> promptPwaInstall() async {
  final deferredPrompt = web.window.getProperty(
    '_priqrDeferredInstallPrompt'.toJS,
  );
  if (deferredPrompt.isUndefinedOrNull) {
    return false;
  }

  final promptObject = deferredPrompt as JSObject;
  promptObject.callMethodVarArgs('prompt'.toJS, const []);
  web.window.setProperty('_priqrDeferredInstallPrompt'.toJS, null);
  return true;
}
