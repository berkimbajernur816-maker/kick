import 'package:flutter_test/flutter_test.dart';
import 'package:kick/proxy/engine/proxy_cors.dart';

void main() {
  test('allows JanitorAI browser origins on loopback proxy', () {
    expect(
      resolveProxyCorsOrigin(
        origin: 'https://janitorai.com',
        allowLan: false,
        configuredHost: '127.0.0.1',
      ),
      'https://janitorai.com',
    );
    expect(
      resolveProxyCorsOrigin(
        origin: 'https://www.janitorai.com',
        allowLan: false,
        configuredHost: '127.0.0.1',
      ),
      'https://www.janitorai.com',
    );
    expect(
      resolveProxyCorsOrigin(
        origin: 'https://beta.janitorai.com',
        allowLan: false,
        configuredHost: '127.0.0.1',
      ),
      'https://beta.janitorai.com',
    );
  });

  test('rejects unrelated public origins when LAN access is disabled', () {
    expect(
      resolveProxyCorsOrigin(
        origin: 'https://example.com',
        allowLan: false,
        configuredHost: '127.0.0.1',
      ),
      isNull,
    );
  });

  test('keeps loopback origins allowed', () {
    expect(
      resolveProxyCorsOrigin(
        origin: 'http://127.0.0.1:8080',
        allowLan: false,
        configuredHost: '127.0.0.1',
      ),
      'http://127.0.0.1:8080',
    );
    expect(
      resolveProxyCorsOrigin(
        origin: 'http://localhost:3001',
        allowLan: false,
        configuredHost: '127.0.0.1',
      ),
      'http://localhost:3001',
    );
  });

  test('echoes preflight headers and private network approval for allowed origins', () {
    final headers = buildProxyCorsHeaders(
      allowedOrigin: 'https://janitorai.com',
      requestedHeaders: 'authorization, content-type, x-request-id, x-app-version',
      requestedPrivateNetwork: 'true',
    );

    expect(headers['access-control-allow-origin'], 'https://janitorai.com');
    expect(headers['access-control-allow-private-network'], 'true');
    expect(headers['access-control-allow-headers'], contains('Authorization'));
    expect(headers['access-control-allow-headers'], contains('Content-Type'));
    expect(headers['access-control-allow-headers'], contains('x-request-id'));
    expect(headers['access-control-allow-headers'], contains('x-app-version'));
  });

  test('drops malformed requested header names', () {
    final headers = buildProxyCorsHeaders(
      allowedOrigin: 'https://janitorai.com',
      requestedHeaders: 'x-request-id, bad header, x-app-version',
    );

    expect(headers['access-control-allow-headers'], contains('x-request-id'));
    expect(headers['access-control-allow-headers'], contains('x-app-version'));
    expect(headers['access-control-allow-headers'], isNot(contains('bad header')));
  });
}
