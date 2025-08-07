import 'dart:math';

import 'package:wheatley/src/generator.dart';
import 'package:wheatley/src/shrinkable.dart';

export 'package:wheatley/src/generator.dart';

/// Always generates the same value.
Generator<T> always<T>(T value) => (random, size) => Shrinkable(value, (_) => []);

/// A constant generator that always returns `null`.
final empty = always<Null>(null);

final boolean = generator(generate: (random, _) => random.nextBool());

/// Generates a non-negative random integer uniformly distributed in the range
/// from [min], inclusive, to [max], exclusive.
///
/// See also [Random.nextInt]
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

/// Generates a random floating point value uniformly distributed in the range from [min], inclusive, to [max],
/// exclusive.
///
/// See also [Random.nextDouble]
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

Generator<int> positiveInteger({int? max}) => integer(min: 1, max: max);
Generator<int> nonNegativeInteger({int? max}) => integer(min: 0, max: max);
Generator<int> negativeInteger({int? min}) => integer(min: min, max: 0);
Generator<int> nonPositiveInteger({int? min}) => integer(min: min, max: 1);

Generator<int> uint8 = integer(min: 0, max: 256);
Generator<int> uint16 = integer(min: 0, max: 65536);
Generator<int> uint32 = integer(min: 0, max: 4294967296);
Generator<int> int8 = integer(min: -128, max: 128);
Generator<int> int16 = integer(min: -32768, max: 32768);
Generator<int> int32 = integer(min: -2147483648, max: 2147483648);
Generator<int> int64 = integer(
  min: -9223372036854775808,
  // This is one lower than the actual max value since 9223372036854775808 cannot be represented in Dart without using
  // a [BigInt].
  //
  // Since [Random]'s max is exclusive, this means we will never be able to generate 9223372036854775807, but in
  // practice this should not be a problem.
  max: 9223372036854775807,
);

Generator<double> positiveDouble({double shrinkInterval = .01}) =>
    double_(min: 0 + shrinkInterval, shrinkInterval: shrinkInterval);
Generator<double> nonNegativeDouble({double shrinkInterval = .01}) => double_(min: 0, shrinkInterval: shrinkInterval);
Generator<double> negativeDouble({double shrinkInterval = .01}) =>
    double_(max: 0 - shrinkInterval, shrinkInterval: shrinkInterval);
Generator<double> nonPositiveDouble({double shrinkInterval = .01}) => double_(max: 0, shrinkInterval: shrinkInterval);

Generator<num> number({num? min, num? max, num? shrinkInterval}) => boolean.flatMap(
  (v) =>
      v
          ? integer(min: min?.toInt(), max: max?.toInt(), shrinkInterval: shrinkInterval?.toInt())
          : double_(min: min?.toDouble(), max: max?.toDouble(), shrinkInterval: shrinkInterval?.toDouble()),
);

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

/// Chooses between the given values. Values further at the front of the list are considered less complex.
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

Generator<List<T>> listOf<T>(Generator<T> item, {int minSize = 0, int? maxSize}) => (random, size) {
  assert(minSize >= 0, 'minSize must be non-negative');
  assert(maxSize == null || maxSize >= minSize, 'maxSize must be greater than or equal to minSize');
  final actualMax = maxSize ?? size;

  if (actualMax == 0 || actualMax < minSize) {
    return Shrinkable([]);
  }

  final length = minSize + random.nextInt(actualMax - minSize + 1);
  final shrinkables = List.generate(length, (_) => item(random, size));
  final values = shrinkables.map((i) => i.value).toList();

  return Shrinkable(values, (v) sync* {
    if (shrinkables.isEmpty) {
      return;
    }
    yield Shrinkable(values.take(minSize).toList());

    for (var i = values.length; i > 1; i--) {
      yield Shrinkable(values.sublist(1, i));
    }

    for (var i = shrinkables.length - 1; i >= 0; i--) {
      yield* shrinkables[i].map((v) => values..[i] = v).shrunk;
    }
  });
};
