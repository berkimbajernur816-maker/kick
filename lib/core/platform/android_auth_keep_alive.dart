import 'android_foreground_runtime.dart';

typedef AndroidAuthKeepAliveStarter = Future<bool> Function({String? notificationTitle});
typedef AndroidAuthKeepAliveStopper = Future<void> Function();
typedef ProxyRunningReader = bool Function();

class AndroidAuthKeepAlive {
  const AndroidAuthKeepAlive({
    required ProxyRunningReader isProxyRunning,
    AndroidAuthKeepAliveStarter startTemporaryRuntime =
        AndroidForegroundRuntime.ensureTemporaryRunning,
    AndroidAuthKeepAliveStopper stopRuntimeIfRunning = AndroidForegroundRuntime.stopIfRunning,
  }) : _isProxyRunning = isProxyRunning,
       _startTemporaryRuntime = startTemporaryRuntime,
       _stopRuntimeIfRunning = stopRuntimeIfRunning;

  final ProxyRunningReader _isProxyRunning;
  final AndroidAuthKeepAliveStarter _startTemporaryRuntime;
  final AndroidAuthKeepAliveStopper _stopRuntimeIfRunning;

  Future<bool> begin({String? notificationTitle}) async {
    try {
      return await _startTemporaryRuntime(notificationTitle: notificationTitle);
    } catch (_) {
      return false;
    }
  }

  Future<void> end(bool keepAliveStarted) async {
    if (!keepAliveStarted) {
      return;
    }

    try {
      if (!_isProxyRunning()) {
        await _stopRuntimeIfRunning();
      }
    } catch (_) {
      // Best-effort cleanup for the temporary Android foreground runtime.
    }
  }
}
