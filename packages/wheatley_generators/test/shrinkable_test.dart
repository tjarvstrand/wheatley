import 'package:test/test.dart';
import 'package:wheatley_generators/wheatley.dart' as gen;

import 'mocked_random.dart';

void main() {
  group('Shrinkable', () {
    group('map', () {
      test('should apply the mapper to the value', () {
        final random = MockedRandom();
        expect(gen.constant(1).map((value) => value * 2)(random, 1).values, [2]);
      });
    });
    group('flatMap', () {
      test('should apply the mapper to the value', () {
        final mappedGenerator = gen.boolean.flatMap((value) => value ? gen.constant(1) : gen.constant(-1));

        expect(mappedGenerator(MockedRandom(booleans: [true]), 1).values, [1]);
        expect(mappedGenerator(MockedRandom(booleans: [false]), 1).values, [-1]);
      });
    });

    group('nullable', () {
      test('allows shrinking down to null', () {
        final shrinkable = gen.constant(1).nullable(MockedRandom(), 1);
        expect(shrinkable.values, [1, null]);
        expect(shrinkable.shrunken.map((s) => s.value), [null]);
      });
    });

    group('zip', () {
      test('combines values and shrinks to the cartesian product of the shrink candidates of both parts', () {
        final random = MockedRandom(integers: [1, 2, 3, 4, 5]);
        final generator = gen.integer(min: 0, max: 5);

        expect(generator.zip(generator)(random, 1).values, [(1, 2), (0, 2), (0, 1), (0, 0)]);
      });
    });
  });
}
