import 'package:test/test.dart';
import 'package:wheatley_generators/generators.dart' as gen;

import 'mocked_random.dart';

void main() {
  group('Shrinkable', () {
    group('map', () {
      test('should apply the mapper to the value', () {
        final random = MockedRandom();
        final generator = gen.constant(1);
        final mappedGenerator = generator.map((value) => value * 2);

        final shrinkable = mappedGenerator(random, 1);
        expect(shrinkable.value, 2);
        expect(shrinkable.values, [2]);
      });
    });
    group('flatMap', () {
      test('should apply the mapper to the value', () {
        final random = MockedRandom(booleans: [true, false]);
        final mappedGenerator = gen.boolean.flatMap((value) => value ? gen.constant(1) : gen.constant(-1));

        {
          final shrinkable = mappedGenerator(random, 1);
          expect(shrinkable.value, 1);
          expect(shrinkable.values, [1]);
        }

        {
          final shrinkable = mappedGenerator(random, 1);
          expect(shrinkable.value, -1);
          expect(shrinkable.values, [-1]);
        }
      });
    });

    group('nullable', () {
      test('allows shrinking down to null', () {
        final random = MockedRandom();
        final mappedGenerator = gen.constant(1).nullable;

        {
          final shrinkable = mappedGenerator(random, 1);
          expect(shrinkable.value, 1);
          expect(shrinkable.values, [1, null]);
          expect(shrinkable.shrink().map((s) => s.value), [null]);
        }
      });
    });

    group('zip', () {
      test('combines values and shrinks to the cartesian product of the shrink candidates of both parts', () {
        final random = MockedRandom(integers: [1, 2, 3, 4, 5]);
        final generator = gen.integer(min: 0, max: 5);

        {
          final shrinkable = generator.zip(generator)(random, 1);
          expect(shrinkable.value, (1, 2));
          expect(shrinkable.values, [(1, 2), (0, 2), (0, 1), (0, 0)]);
        }
      });
    });
  });
}
