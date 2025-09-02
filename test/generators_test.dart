import 'dart:math';

import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart';

import 'mocked_random.dart';

void main() {
  group('generators', () {
    group('integer', () {
      test(
        'integer generates valid values',
        () => forAll(integer(min: 0, max: 5))((v) => expect(v, inInclusiveRange(0, 4))),
      );
      test('integer shrinks according to shrinkInterval', () {
        expect(integer(min: 0, max: 5, shrinkInterval: 2)(MockedRandom(integers: [4]), 1).allValues, [4, 2, 0]);
        // Since max is exclusive, negative values should only shrink down the value closes to 0 that can be reached
        // by incrementally subtracting shrinkInterval from the original value.
        expect(integer(min: -4, max: 0, shrinkInterval: 2)(MockedRandom(integers: [0]), 1).allValues, [-4, -2]);
      });
      test(
        'positiveInteger generates valid values',
        () => forAll(positiveInteger(max: 5))((v) => expect(v, inInclusiveRange(1, 4))),
      );
      test(
        'nonNegativeInteger generates valid values',
        () => forAll(nonNegativeInteger(max: 5))((v) => expect(v, inInclusiveRange(0, 4))),
      );
      test(
        'negativeInteger generates valid values',
        () => forAll(negativeInteger(min: -5))((v) => expect(v, inInclusiveRange(-5, -1))),
      );
      test(
        'nonPositiveInteger generates valid values',
        () => forAll(nonPositiveInteger(min: -5))((v) => expect(v, inInclusiveRange(-5, 0))),
      );

      test(
        'integer can generate numbers larger than 4294967296',
        () => expect(
          integer(min: 4294967297, max: 9223372036854775807)(Random(), 1).value,
          inInclusiveRange(4294967297, 9223372036854775807),
        ),
      );
    });
    group('double_', () {
      test(
        'double_generates valid values',
        () => forAll(float(min: 0, max: 5))((v) => expect(v >= 0 && v < 5, isTrue)),
      );
      test('double_ shrinks according to shrinkInterval', () {
        expect(float(min: 0, max: 2, shrinkInterval: .5)(MockedRandom(doubles: [1]), 1).allValues, [
          2.0,
          1.5,
          1.0,
          .5,
          0,
        ]);
        // Since max is exclusive, negative values should only shrink down the value closes to 0 that can be reached
        // by incrementally subtracting shrinkInterval from the original value.
        expect(float(min: -2, max: 0, shrinkInterval: .5)(MockedRandom(doubles: [0]), 1).allValues, [
          -2.0,
          -1.5,
          -1.0,
          -.5,
        ]);
      });
    });
    group('number', () {
      test('number generates both doubles and integers', () {
        expect(number(min: 0)(MockedRandom(booleans: [true], integers: [1]), 2).allValues, [1, 0]);
        expect(number(min: 0)(MockedRandom(booleans: [false], doubles: [1.0]), 1).allValues, [1.0, 0.0]);
      });
    });

    group('bigInt', () {
      test('bigInt generates valid values', () {
        final int64Max = BigInt.from(9223372036854775807);
        final min = int64Max + BigInt.from(1);
        final max = int64Max + BigInt.from(10);
        return forAll(bigInt(min: min, max: max))((v) => expect(v >= min && v < max, isTrue));
      });
    });
    group('string', () {
      test(' generates valid values', () => forAll(string(chars: 'abc'))((v) => expect(v, matches(RegExp('[abc]*')))));
      test(
        ' generates valid values',
        () => forAll(string(chars: 'abc').upperCase)((v) => expect(v, matches(RegExp('[ABC]*')))),
      );
      test(
        ' generates valid values',
        () => forAll(string(chars: 'ABC').lowerCase)((v) => expect(v, matches(RegExp('[abc]*')))),
      );
    });

    group('dateTime', () {
      test('generates valid values', () {
        final now = DateTime.now();
        forAll(dateTime(max: now))(
          (v) => expect(v.microsecondsSinceEpoch, inInclusiveRange(0, now.microsecondsSinceEpoch)),
        );
      });
    });

    group('duration', () {
      test('generates valid values', () {
        final untilNow = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);
        forAll(duration(max: untilNow))((v) => expect(v.inMicroseconds, inInclusiveRange(0, untilNow.inMicroseconds)));
      });
    });

    group('oneOf', () {
      test('generates valid values', () {
        final values = {1, 2, 3};
        final generator = oneOf(values);
        forAll(generator)((v) => expect(values.contains(v), isTrue));
        expect(generator(MockedRandom(integers: [0]), 3).value, 1);
        expect(generator(MockedRandom(integers: [1]), 3).value, 2);
        expect(generator(MockedRandom(integers: [2]), 3).value, 3);
      });
    });

    group('listOf', () {
      test('listOf can generate an empty list', () {
        final random = MockedRandom();
        expect(listOf(always(1), maxSize: 0)(random, 1).allValues, [[]]);
      });
      test('listOf can generate a non empty list', () {
        final random = MockedRandom(integers: [1]);
        expect(listOf(always(1), maxSize: 1)(random, 1).allValues, [
          [1],
          [],
        ]);
      });
      test('listOf shrinks by removing elements and then by shrinking individual elements', () {
        final random = MockedRandom(integers: [3, 2, 2, 2]);
        expect(listOf(integer(min: 0, max: 3), maxSize: 4)(random, 1).allValues, [
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
        'listOf does not generate a list smaller than minSize',
        () => forAll(listOf(integer(), minSize: 10))((list) => expect(list.length, greaterThanOrEqualTo(10))),
      );
      test(
        'listOf does not generate a list larger than maxSize',
        () => forAll(listOf(always(1), maxSize: 10))((list) => expect(list.length, lessThanOrEqualTo(10))),
      );
    });
    group('setOf', () {
      test('setOf can generate an empty set', () {
        final random = MockedRandom();
        expect(setOf({1}, maxSize: 0)(random, 1).allValues, [[]]);
      });
      test('Can generate a non empty set', () {
        final random = MockedRandom(integers: [1]);
        expect(setOf({1, 2}, maxSize: 2)(random, 1).allValues, [
          [1],
          [],
        ]);
      });
      test('setOf shrinks by removing elements and then by shrinking individual elements', () {
        final random = MockedRandom(integers: [2, 1, 3]);
        final allValues = setOf({0, 1, 2}, maxSize: 3)(random, 1).allValues.toList();
        expect(allValues.length, 4);
        expect(allValues[0], {0, 1, 2}); // current value
        expect(allValues[1], []); // Minimal case
        // Shrinking by removing elements
        expect(allValues[2].length, 2);
        expect(allValues[3].length, 1);
      });
      test(
        'setOf does not generate a set smaller than minSize',
        () => forAll(setOf({1, 2, 3, 4, 5, 6}, minSize: 5))((set) => expect(set.length, greaterThanOrEqualTo(5))),
      );
      test(
        'setOf does not generate a set larger than maxSize',
        () => forAll(setOf({1, 2, 3, 4, 5, 6}, maxSize: 5))((set) => expect(set.length, lessThanOrEqualTo(5))),
      );
    });
  });
}
