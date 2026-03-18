import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kick/app/app_metadata.dart';

void main() {
  test('default app version matches pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml must declare a version.');

    final pubspecVersion = match!.group(1)!.trim().split('+').first;
    expect(kickDefaultAppVersion, pubspecVersion);
  });
}
