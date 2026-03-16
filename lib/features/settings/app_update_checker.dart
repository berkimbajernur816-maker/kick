import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../app/app_metadata.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.hasUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final bool hasUpdate;
}

class AppUpdateChecker {
  AppUpdateChecker({
    http.Client? httpClient,
    String apiUrl = kickLatestReleaseApiUrl,
  }) : _http = httpClient ?? http.Client(),
       _apiUrl = apiUrl;

  final http.Client _http;
  final String _apiUrl;

  Future<AppUpdateInfo> checkForUpdates({required String currentVersion}) async {
    final normalizedCurrentVersion = normalizeVersion(currentVersion);
    final response = await _http.get(
      Uri.parse(_apiUrl),
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'KiCk/$normalizedCurrentVersion',
      },
    );

    if (response.statusCode >= 400) {
      throw StateError('Failed to check updates: ${response.statusCode}');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map) {
      throw const FormatException('Unexpected release payload.');
    }

    final map = payload.cast<String, Object?>();
    final latestVersion = normalizeVersion(map['tag_name']?.toString() ?? '');
    if (latestVersion.isEmpty) {
      throw const FormatException('Release tag is missing.');
    }

    final releaseUrl = (map['html_url']?.toString().trim().isNotEmpty == true)
        ? map['html_url']!.toString().trim()
        : kickLatestReleaseUrl;

    return AppUpdateInfo(
      currentVersion: normalizedCurrentVersion,
      latestVersion: latestVersion,
      releaseUrl: releaseUrl,
      hasUpdate: compareVersions(latestVersion, normalizedCurrentVersion) > 0,
    );
  }

  void dispose() {
    _http.close();
  }

  @visibleForTesting
  static String normalizeVersion(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final withoutPrefix = trimmed.startsWith('v') ? trimmed.substring(1) : trimmed;
    return withoutPrefix.split('+').first.trim();
  }

  @visibleForTesting
  static int compareVersions(String left, String right) {
    final leftParts = _VersionParts.parse(left);
    final rightParts = _VersionParts.parse(right);

    final maxLength = leftParts.numbers.length > rightParts.numbers.length
        ? leftParts.numbers.length
        : rightParts.numbers.length;
    for (var index = 0; index < maxLength; index++) {
      final leftNumber = index < leftParts.numbers.length ? leftParts.numbers[index] : 0;
      final rightNumber = index < rightParts.numbers.length ? rightParts.numbers[index] : 0;
      if (leftNumber != rightNumber) {
        return leftNumber.compareTo(rightNumber);
      }
    }

    if (leftParts.preRelease == rightParts.preRelease) {
      return 0;
    }
    if (leftParts.preRelease == null) {
      return 1;
    }
    if (rightParts.preRelease == null) {
      return -1;
    }
    return leftParts.preRelease!.compareTo(rightParts.preRelease!);
  }
}

class _VersionParts {
  const _VersionParts({required this.numbers, required this.preRelease});

  final List<int> numbers;
  final String? preRelease;

  static _VersionParts parse(String raw) {
    final normalized = AppUpdateChecker.normalizeVersion(raw);
    final separatorIndex = normalized.indexOf('-');
    final numberPart = separatorIndex == -1 ? normalized : normalized.substring(0, separatorIndex);
    final preRelease = separatorIndex == -1
        ? null
        : normalized.substring(separatorIndex + 1).trim();

    final numbers = numberPart
        .split('.')
        .map((item) => int.tryParse(item.trim()) ?? 0)
        .toList(growable: false);

    return _VersionParts(
      numbers: numbers,
      preRelease: preRelease == null || preRelease.isEmpty ? null : preRelease,
    );
  }
}
