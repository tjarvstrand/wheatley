import 'dart:math';

import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart';

import 'mocked_random.dart';

void main() {
  group('generators', () {
    group('generate valid values', () {
      test('integer', () => forAll(integer(min: 0, max: 5))((v) => expect(v, inInclusiveRange(0, 4))));
      test(
        'integer can generate numbers larger than 4294967296',
        () => expect(
          integer(min: 4294967297, max: 9223372036854775807)(Random(), 1).value,
          inInclusiveRange(4294967297, 9223372036854775807),
        ),
      );
      test('positiveInteger', () => forAll(positiveInteger(max: 5))((v) => expect(v, inInclusiveRange(1, 4))));
      test('nonNegativeInteger', () => forAll(nonNegativeInteger(max: 5))((v) => expect(v, inInclusiveRange(0, 4))));
      test('negativeInteger', () => forAll(negativeInteger(min: -5))((v) => expect(v, inInclusiveRange(-5, -1))));
      test('nonPositiveInteger', () => forAll(nonPositiveInteger(min: -5))((v) => expect(v, inInclusiveRange(-5, 0))));
      test('string', () => forAll(string(chars: 'abc'))((v) => matches(RegExp('[abc]*'))));
      test('dateTime', () {
        final now = DateTime.now();
        forAll(dateTime(max: now))(
          (v) => expect(v.microsecondsSinceEpoch, inInclusiveRange(0, now.microsecondsSinceEpoch)),
        );
      });
      test('duration', () {
        final untilNow = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
        forAll(duration(max: untilNow))((v) => expect(v.inMicroseconds, inInclusiveRange(0, untilNow.inMicroseconds)));
      });
    });
    group('listOf', () {
      test('Can generate an empty list', () {
        final random = MockedRandom();
        expect(listOf(always(1), maxSize: 0)(random, 1).allValues, [[]]);
      });
      test('Can generate a non empty list', () {
        final random = MockedRandom(integers: [1]);
        expect(listOf(always(1), maxSize: 1)(random, 1).allValues, [
          [1],
          [],
        ]);
      });
      test('Shrinks by removing elements and then by shrinking individual elements', () {
        final random = MockedRandom(integers: [3]);
        expect(listOf(integer(), maxSize: 3)(random, 1).allValues, [
          [2, 2, 2], // current value
          // shrunk value start
          [], // Minimal case
          // Shrinking by removing elements
          [2, 2],
          [2],
          // Shrinking individual elements
          [2, 2, 1],
          [2, 2, 0],
          [2, 1, 0],
          [2, 0, 0],
          [1, 0, 0],
          [0, 0, 0],
        ]);
      });
      test(
        'Does not generate a list smaller than minSize',
        () => forAll(listOf(integer(), minSize: 10))((list) => expect(list.length, greaterThanOrEqualTo(10))),
      );
      test(
        'Does not generate a list larger than maxSize',
        () => forAll(listOf(always(1), maxSize: 10))((list) => expect(list.length, lessThanOrEqualTo(10))),
      );
    });
    group('setOf', () {
      test('Can generate an empty set', () {
        final random = MockedRandom();
        expect(setOf({1}, maxSize: 0)(random, 1).allValues, [[]]);
      });
      test('Can generate a non empty set', () {
        final random = MockedRandom(integers: [1]);
        expect(setOf({1}, maxSize: 1)(random, 1).allValues, [
          [1],
          [],
        ]);
      });
      test('Shrinks by removing elements and then by shrinking individual elements', () {
        final random = MockedRandom(integers: [2, 2, 3]);
        final allValues = setOf({0, 1, 2}, maxSize: 3)(random, 1).allValues.toList();
        expect(allValues.length, 4);
        expect(allValues[0], {0, 1, 2}); // current value
        expect(allValues[1], []); // Minimal case
        // Shrinking by removing elements
        expect(allValues[2].length, 2);
        expect(allValues[3].length, 1);
      });
      test(
        'Does not generate a set smaller than minSize',
        () => forAll(setOf({1, 2, 3, 4, 5, 6}, minSize: 5))((set) => expect(set.length, greaterThanOrEqualTo(5))),
      );
      test(
        'Does not generate a set larger than maxSize',
        () => forAll(setOf({1, 2, 3, 4, 5, 6}, maxSize: 5))((set) => expect(set.length, lessThanOrEqualTo(5))),
      );
    });
  });
}
