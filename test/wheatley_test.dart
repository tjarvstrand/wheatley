import 'dart:async';

import 'package:test/test.dart';
import 'package:wheatley/src/explore_config.dart';
import 'package:wheatley/wheatley.dart';

Future<void> main() async {
  group('Wheatley', () {
    group('forAll', () {
      test('Succeeds when the body succeeds', () {
        expect(forAll(always('a'))((v) => expect(v, equals('a'))), completes);
      });
      test('Executes the specified number of times when succeeding', () async {
        var count = 0;
        final f = forAll(always('a'), config: ExploreConfig(runs: 42))((_) => count++);
        expect(f, completes);
        await f;
        expect(count, 42);
      });
      test('Fails with the original error when an [expect] fails inside the body ', () {
        expect(
          forAll(string(chars: 'a', minSize: 3, maxSize: 3), log: (_) {})((v) => expect(v, equals('b'))),
          throwsA(
            isA<TestFailure>().having((a) => a.message?.split('\n').take(2).map((s) => s.trim()), 'message', [
              "Expected: 'b'",
              "Actual: 'aaa'",
            ]),
          ),
        );
      });
    });
  });
}
