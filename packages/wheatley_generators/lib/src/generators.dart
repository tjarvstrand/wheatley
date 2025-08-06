import 'package:wheatley_generators/src/generator.dart';
import 'package:wheatley_generators/src/shrinkable.dart';

export 'package:wheatley_generators/src/generator.dart';

/// Always generates the same value.
Generator<T> constant<T>(T value) => (random, size) => Shrinkable(value, () => []);

/// A constant generator that always returns `null`.
final empty = constant<Null>(null);

final boolean = generator(generate: (random, _) => random.nextBool());

Generator<int> integer({int? min, int? max, int? shrinkInterval}) {
  assert(min == null || max == null || min < max, 'min must be less than max');
  return generator(
    generate: (random, size) {
      final actualMin = min ?? -size;
      final actualMax = max ?? size;
      final r = random.nextInt(actualMax - actualMin);
      return actualMin + r;
    },
    shrink: (input) sync* {
      if (input > 0 && input > (min ?? 0)) yield input - (shrinkInterval ?? 1);
      if (input < 0 && input < (max ?? 0)) yield input + (shrinkInterval ?? 1);
    },
  );
}

Generator<double> double_({double? min, double? max, double? shrinkInterval}) {
  assert(min == null || max == null || min < max, 'min must be less than max');
  return generator(
    generate: (random, size) {
      final actualMin = min ?? -size;
      final actualMax = max ?? size;
      return actualMin + random.nextDouble() * (actualMax - actualMin);
    },
    shrink: (input) sync* {
      if (input > 0 && input > (min ?? 0)) yield input - (shrinkInterval ?? .01);
      if (input < 0 && input < (max ?? 0)) yield input + (shrinkInterval ?? .01);
    },
  );
}

Generator<int> positiveInteger = integer(min: 1);
Generator<int> nonNegativeInteger = integer(min: 0);
Generator<int> negativeInteger = integer(max: -1);
Generator<int> nonPositiveInteger = integer(max: 1);

Generator<int> uint8 = integer(min: 0, max: 2 << 8);
Generator<int> uint16 = integer(min: 0, max: 2 << 16);
Generator<int> uint32 = integer(min: 0, max: 2 << 32);
Generator<int> int8 = integer(min: -(2 << 7), max: 2 << 7);
Generator<int> int16 = integer(min: -(2 << 15), max: 2 << 15);
Generator<int> int32 = integer(min: -(2 << 31), max: 2 << 31);
Generator<int> int64 = integer(min: -(2 << 63), max: 2 << 63);

Generator<double> positiveDouble({double shrinkInterval = .01}) =>
    double_(min: 0 + shrinkInterval, shrinkInterval: shrinkInterval);
Generator<double> nonNegativeDouble({double shrinkInterval = .01}) => double_(min: 0, shrinkInterval: shrinkInterval);
Generator<double> negativeDouble({double shrinkInterval = .01}) =>
    double_(max: 0 - shrinkInterval, shrinkInterval: shrinkInterval);
Generator<double> nonPositiveDouble({double shrinkInterval = .01}) => double_(max: 0, shrinkInterval: shrinkInterval);

Generator<num> number({num? min, num? max, num? shrinkInterval}) => boolean.flatMap((v) => v
    ? integer(min: min?.toInt(), max: max?.toInt(), shrinkInterval: shrinkInterval?.toInt())
    : double_(min: min?.toDouble(), max: max?.toDouble(), shrinkInterval: shrinkInterval?.toDouble()));

Generator<BigInt> bigInt({BigInt? min, BigInt? max, BigInt? shrinkInterval}) {
  return generator(
    generate: (random, size) {
      final actualMin = min ?? BigInt.from(-size);
      final actualMax = max ?? BigInt.from(size);
      assert(actualMax > actualMin, 'min must be less than max');
      final bits = (actualMax - actualMin).bitLength;
      var bigInt = BigInt.zero;
      for (var i = 0; i < bits; i++) {
        bigInt = bigInt * BigInt.two;
        if (random.nextBool()) {
          bigInt += BigInt.one;
        }
      }
      return actualMin + (bigInt % (actualMax - actualMin));
    },
    shrink: (input) sync* {
      if (input > BigInt.zero) {
        yield input - (shrinkInterval ?? BigInt.one);
      } else if (input < BigInt.zero) {
        yield input + (shrinkInterval ?? BigInt.one);
      }
    },
  );
}

/// Chooses between the given values. Values further at the front of the
/// list are considered less complex.
Generator<T> oneOf<T>(Iterable<T> values) {
  final strictValues = <T>[];
  final index = <T, int>{};

  for (final (i, value) in strictValues.indexed) {
    strictValues.add(value);
    index[value] ??= i;
  }

  return generator(
    generate: (random, size) => strictValues[random.nextInt(size.clamp(0, strictValues.length))],
    shrink: (option) sync* {
      final previousIndex = index[option];
      if (previousIndex != null) {
        yield strictValues[previousIndex];
      }
    },
  );
}
