import 'dart:io';

const _loopbackHosts = <String>{'localhost', '127.0.0.1', '::1', '[::1]'};

// Known browser clients that legitimately talk to the local proxy from a public origin.
const _trustedBrowserOrigins = <String>{
  'https://janitorai.com',
  'https://www.janitorai.com',
  'https://beta.janitorai.com',
};

String? resolveProxyCorsOrigin({
  required String? origin,
  required bool allowLan,
  required String configuredHost,
}) {
  final trimmedOrigin = origin?.trim();
  if (trimmedOrigin == null || trimmedOrigin.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmedOrigin);
  final host = uri?.host.toLowerCase();
  if (uri == null || uri.scheme.isEmpty || host == null || host.isEmpty) {
    return null;
  }

  final normalizedOrigin = _normalizeOrigin(uri);
  if (_trustedBrowserOrigins.contains(normalizedOrigin)) {
    return normalizedOrigin;
  }

  if (_isLoopbackHost(host)) {
    return normalizedOrigin;
  }

  if (!allowLan) {
    return null;
  }

  if (host == configuredHost.toLowerCase() || _isPrivateHost(host)) {
    return normalizedOrigin;
  }

  return null;
}

Map<String, String> buildProxyCorsHeaders({
  required String? allowedOrigin,
  String? requestedHeaders,
  String? requestedPrivateNetwork,
}) {
  final allowedHeaders = <String>{'Authorization', 'Content-Type'};
  for (final candidate in _parseRequestedHeaders(requestedHeaders)) {
    allowedHeaders.add(candidate);
  }

  final sortedAllowedHeaders = allowedHeaders.toList()
    ..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));

  final headers = <String, String>{
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': sortedAllowedHeaders.join(', '),
  };

  if (allowedOrigin != null) {
    headers['access-control-allow-origin'] = allowedOrigin;
    headers['vary'] = 'Origin';
  }

  if (requestedPrivateNetwork?.trim().toLowerCase() == 'true') {
    headers['access-control-allow-private-network'] = 'true';
  }

  return headers;
}

Iterable<String> _parseRequestedHeaders(String? requestedHeaders) sync* {
  if (requestedHeaders == null || requestedHeaders.trim().isEmpty) {
    return;
  }

  for (final rawHeader in requestedHeaders.split(',')) {
    final candidate = rawHeader.trim();
    if (candidate.isEmpty || !_isValidHeaderName(candidate)) {
      continue;
    }

    switch (candidate.toLowerCase()) {
      case 'authorization':
        yield 'Authorization';
      case 'content-type':
        yield 'Content-Type';
      default:
        yield candidate;
    }
  }
}

bool _isValidHeaderName(String value) => RegExp(r'^[A-Za-z0-9-]+$').hasMatch(value);

String _normalizeOrigin(Uri uri) {
  final defaultPort =
      (uri.scheme == 'http' && uri.port == 80) || (uri.scheme == 'https' && uri.port == 443);
  final host = uri.host.toLowerCase();
  final hostSegment = host.contains(':') ? '[$host]' : host;
  final portSegment = uri.hasPort && !defaultPort ? ':${uri.port}' : '';
  return '${uri.scheme.toLowerCase()}://$hostSegment$portSegment';
}

bool _isLoopbackHost(String host) {
  if (_loopbackHosts.contains(host)) {
    return true;
  }

  final address = InternetAddress.tryParse(host);
  return address?.isLoopback ?? false;
}

bool _isPrivateHost(String host) {
  final address = InternetAddress.tryParse(host);
  if (address == null) {
    return false;
  }
  if (address.type == InternetAddressType.IPv6) {
    final octets = address.rawAddress;
    final isUniqueLocal = octets.isNotEmpty && (octets.first & 0xfe) == 0xfc;
    return address.isLinkLocal || address.isLoopback || isUniqueLocal;
  }

  final octets = address.rawAddress;
  if (octets.length != 4) {
    return false;
  }

  final first = octets[0];
  final second = octets[1];
  return first == 10 ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168) ||
      (first == 169 && second == 254);
}
