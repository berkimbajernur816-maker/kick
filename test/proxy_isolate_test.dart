import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kick/proxy/engine/proxy_isolate.dart';

void main() {
  test('normalizeOpenAiCompatRequest injects google web search from headers', () {
    final normalized = normalizeOpenAiCompatRequest(
      body: {
        'model': 'gemini-3-flash-preview',
        'messages': [
          {'role': 'user', 'content': 'Find fresh Flutter news'},
        ],
      },
      headers: {'x-kick-web-search': 'true'},
    );

    expect(
      ((normalized['extra_body'] as Map?)?['google'] as Map?)?['web_search'],
      isTrue,
    );
  });

  test('normalizeOpenAiCompatRequest keeps explicit body setting over headers', () {
    final normalized = normalizeOpenAiCompatRequest(
      body: {
        'model': 'gemini-3-flash-preview',
        'web_search': false,
      },
      headers: {'x-kick-web-search': 'true'},
    );

    expect(
      ((normalized['extra_body'] as Map?)?['google'] as Map?)?['web_search'],
      isFalse,
    );
  });

  test('normalizeOpenAiCompatRequest applies default google web search when request is silent', () {
    final normalized = normalizeOpenAiCompatRequest(
      body: {
        'model': 'gemini-3-flash-preview',
        'messages': [
          {'role': 'user', 'content': 'Find fresh Flutter news'},
        ],
      },
      headers: const {},
      defaultGoogleWebSearchEnabled: true,
    );

    expect(
      ((normalized['extra_body'] as Map?)?['google'] as Map?)?['web_search'],
      isTrue,
    );
  });

  test('normalizeOpenAiCompatRequest does not apply default search when tools are present', () {
    final normalized = normalizeOpenAiCompatRequest(
      body: {
        'model': 'gemini-3-flash-preview',
        'tools': [
          {
            'type': 'function',
            'function': {'name': 'lookupWeather', 'parameters': {'type': 'object'}},
          },
        ],
      },
      headers: const {},
      defaultGoogleWebSearchEnabled: true,
    );

    expect(normalized['extra_body'], isNull);
  });

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
