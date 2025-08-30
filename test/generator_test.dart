import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart' as gen;
import 'package:wheatley/wheatley.dart';

import 'mocked_random.dart';

void main() {
  group('Generator', () {
    group('map', () {
      test('should apply the mapper to the value', () {
        final random = MockedRandom();
        expect(gen.always(1).map((value) => value * 2)(random, 1).allValues, [2]);
      });
    });
    group('flatMap', () {
      test('should apply the mapper to the value', () {
        final mappedGenerator = gen.boolean.flatMap((value) => value ? gen.always(1) : gen.always(-1));

        expect(mappedGenerator(MockedRandom(booleans: [true]), 1).allValues, [1]);
        expect(mappedGenerator(MockedRandom(booleans: [false]), 1).allValues, [-1]);
      });
    });

    group('nullable', () {
      test('allows shrinking down to null', () {
        final candidate = gen.always(1).nullable(MockedRandom(), 1);
        expect(candidate.allValues, [1, null]);
        expect(candidate.shrunk.map((s) => s.value), [null]);
      });
    });

    group('zip', () {
      test('combines values and shrinks to the cartesian product of the shrink candidates of both parts', () {
        final random = MockedRandom(integers: [1, 2, 3, 4, 5]);
        final generator = gen.integer(min: 0, max: 5);

        expect(generator.zip(generator)(random, 1).allValues, [(1, 2), (0, 2), (0, 1), (0, 0)]);
      });
    });

    group('where', () {
      test('Does not produce values that do not fulfill the predicate', () {
        forAll(gen.integer(min: 0, max: 20).where((i) => i.isEven))((v) => expect(v.isEven, isTrue));
      });
    });
  });
}
