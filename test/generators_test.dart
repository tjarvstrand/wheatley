import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart';

import 'mocked_random.dart';

void main() {
  group('generators', () {
    group('generate valid values', () {
      test('integer', () => forAll(integer(min: 0, max: 5))((v) => expect(v, inInclusiveRange(0, 4))));
      test('positiveInteger', () => forAll(positiveInteger(max: 5))((v) => expect(v, inInclusiveRange(1, 4))));
      test('nonNegativeInteger', () => forAll(nonNegativeInteger(max: 5))((v) => expect(v, inInclusiveRange(0, 4))));
      test('negativeInteger', () => forAll(negativeInteger(min: -5))((v) => expect(v, inInclusiveRange(-5, -1))));
      test('nonPositiveInteger', () => forAll(nonPositiveInteger(min: -5))((v) => expect(v, inInclusiveRange(-5, 0))));
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
  });
}
