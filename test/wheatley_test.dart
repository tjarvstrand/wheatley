import 'dart:async';

import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart';

Future<void> main() async {
  group('Wheatley', () {
    group('forAll', () {
      test('Succeeds when the body succeeds', () {
        expect(forAll(constant('a'))((v) => expect(v, equals('a'))), completes);
      });
      test('Fails with the original error when an [expect] fails inside the body ', () {
        expect(
          forAll(constant('a'), log: (_) {})((v) => expect(v, equals('b'))),
          throwsA(
            isA<TestFailure>().having((a) => a.message?.split('\n').take(2).map((s) => s.trim()), 'message', [
              "Expected: 'b'",
              "Actual: 'a'",
            ]),
          ),
        );
      });
    });
  });
}
