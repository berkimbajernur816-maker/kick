import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kick/proxy/engine/proxy_isolate.dart';

void main() {
  test('retryProxyPortBind retries transient bind races until the port is released', () async {
    var attempts = 0;

    final result = await retryProxyPortBind(() async {
      attempts += 1;
      if (attempts < 3) {
        throw const SocketException(
          'Failed to create server socket (OS Error: The shared flag to bind() needs to be '
          '`true` if binding multiple times on the same (address, port) combination.)',
        );
      }
      return 'bound';
    }, retryDelays: const <Duration>[Duration.zero, Duration.zero]);

    expect(result, 'bound');
    expect(attempts, 3);
  });

  test('retryProxyPortBind does not retry unrelated bind failures', () async {
    var attempts = 0;

    await expectLater(
      () => retryProxyPortBind(() async {
        attempts += 1;
        throw StateError('unexpected bind failure');
      }),
      throwsStateError,
    );

    expect(attempts, 1);
  });

  test('looksLikeProxyPortInUseError recognizes socket reuse failures', () {
    expect(
      looksLikeProxyPortInUseError(
        'Failed to create server socket: The shared flag to bind() needs to be true.',
      ),
      isTrue,
    );
    expect(looksLikeProxyPortInUseError('Permission denied while opening socket'), isFalse);
  });
}
