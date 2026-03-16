import 'package:package_info_plus/package_info_plus.dart';

import 'app_metadata.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();

class AppVersionReader {
  const AppVersionReader({
    PackageInfoLoader? packageInfoLoader,
    String buildVersionFallback = kickBuildAppVersion,
    String defaultVersion = kickDefaultAppVersion,
  }) : _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
       _buildVersionFallback = buildVersionFallback,
       _defaultVersion = defaultVersion;

  final PackageInfoLoader _packageInfoLoader;
  final String _buildVersionFallback;
  final String _defaultVersion;

  Future<String> readVersion() async {
    try {
      final packageInfo = await _packageInfoLoader();
      final version = packageInfo.version.trim();
      if (version.isNotEmpty) {
        return version;
      }
    } catch (_) {
      // Fall back to the build metadata if runtime package info is unavailable.
    }

    final buildVersion = _buildVersionFallback.trim();
    if (buildVersion.isNotEmpty) {
      return buildVersion;
    }

    return _defaultVersion;
  }
}
