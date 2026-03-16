const kickDefaultAppVersion = '0.1.0';
const kickBuildAppVersion = String.fromEnvironment(
  'FLUTTER_BUILD_NAME',
  defaultValue: kickDefaultAppVersion,
);
const kickAppIconAssetPath = 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png';
const kickRepositoryUrl = 'https://github.com/mxnix/kick';
const kickLatestReleaseUrl = '$kickRepositoryUrl/releases/latest';
const kickLatestReleaseApiUrl = 'https://api.github.com/repos/mxnix/kick/releases/latest';
