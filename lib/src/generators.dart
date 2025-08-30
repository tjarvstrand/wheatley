import 'dart:math';

import 'package:characters/characters.dart';
import 'package:wheatley/src/_no_value_provided.dart';
import 'package:wheatley/src/candidate.dart';
import 'package:wheatley/src/generator.dart';

export 'package:wheatley/src/generator.dart';

const generatorMax = 4294967296; // 1 << 32
int _nextInt(Random random, int maxValue) =>
    maxValue > generatorMax
        ? (random.nextInt(maxValue >> 32) << 32) + random.nextInt(generatorMax)
        : random.nextInt(maxValue);

/// Always generates the same value.
Generator<T> always<T>(T value) => (random, size) => Candidate(value, (_) => []);

/// A constant generator that always returns `null`.
final empty = always<Null>(null);

final boolean = generator(generate: (random, _) => random.nextBool());

/// Generates a random integer uniformly distributed in the range from [min], inclusive, to [max], exclusive.
///
/// If [min] is not provided, it defaults to `-size`, and if [max] is not provided, it defaults to `size`.
///
/// [shrinkInterval] decides how fast the values are shrunk. If not provided, it defaults to `1.0`.
///
/// See also [Random.nextInt]
Generator<int> integer({int? min, int? max, int shrinkInterval = 1}) {
  assert(min == null || max == null || min < max, 'min must be less than max');
  return generator(
    generate: (random, size) {
      final actualMin = min ?? -size;
      final actualMax = max ?? size;
      return actualMin + _nextInt(random, (actualMax - actualMin).abs());
    },
    // TODO: Try smallest input first
    shrink: (input) sync* {
      if (input > 0) {
        final next = input - shrinkInterval;
        if (next >= (min ?? 0)) {
          yield next;
        }
      }
      if (input < 0) {
        final next = input + shrinkInterval;
        if (next < (max ?? 0)) {
          yield next;
        }
      }
    },
  );
}

/// Generates a random floating point value uniformly distributed in the range from [min], inclusive, to [max],
/// exclusive.
///
/// If [min] is not provided, it defaults to `-size`, and if [max] is not provided, it defaults to `size`.
///
/// [shrinkInterval] decides how fast the values are shrunk. If not provided, it defaults to `1`.
///
/// See also [Random.nextDouble].
Generator<double> double_({double? min, double? max, double shrinkInterval = 1}) {
  assert(min == null || max == null || min < max, 'min must be less than max');
  return generator(
    generate: (random, size) {
      final actualMin = min ?? -size;
      final actualMax = max ?? size;
      return actualMin + random.nextDouble() * (actualMax - actualMin).abs();
    },
    // TODO: Try smallest input first
    shrink: (input) sync* {
      if (input > .0) {
        final next = input - shrinkInterval;
        if (next >= (min ?? 0)) {
          yield next;
        }
      }
      if (input < .0) {
        final next = input + shrinkInterval;
        if (next < (max ?? 0)) {
          yield next;
        }
      }
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

Generator<double> positiveDouble({double shrinkInterval = 1}) =>
    double_(min: 0 + shrinkInterval, shrinkInterval: shrinkInterval);
Generator<double> nonNegativeDouble({double shrinkInterval = 1}) => double_(min: 0, shrinkInterval: shrinkInterval);
Generator<double> negativeDouble({double shrinkInterval = 1}) =>
    double_(max: 0 - shrinkInterval, shrinkInterval: shrinkInterval);
Generator<double> nonPositiveDouble({double shrinkInterval = 1}) => double_(max: 0, shrinkInterval: shrinkInterval);

/// Generates a random number uniformly distributed in the range from [min], inclusive, to [max], exclusive.
///
/// If [min] is not provided, it defaults to `-size`, and if [max] is not provided, it defaults to `size`.
///
/// [shrinkInterval] decides how fast the values are shrunk. If not provided, it defaults to `1`.
Generator<num> number({num? min, num? max, num shrinkInterval = 1.0}) => boolean.flatMap(
  (v) =>
      v
          ? integer(min: min?.toInt(), max: max?.toInt(), shrinkInterval: shrinkInterval.toInt())
          : double_(min: min?.toDouble(), max: max?.toDouble(), shrinkInterval: shrinkInterval.toDouble()),
);

/// Generates a random [BigInt] value uniformly distributed in the range from [min], inclusive, to [max],
/// exclusive.
///
/// If [min] is not provided, it defaults to `-size`, and if [max] is not provided, it defaults to `size`.
///
/// [shrinkInterval] decides how fast the values are shrunk. If not provided, it defaults to `BigInt.one`.
Generator<BigInt> bigInt({BigInt? min, BigInt? max, BigInt? shrinkInterval}) => generator(
  generate: (random, size) {
    final actualMin = min ?? BigInt.from(-size);
    final actualMax = max ?? BigInt.from(size);
    assert(actualMax > actualMin, 'min must be less than max');
    if (actualMax == actualMin) {
      return actualMin;
    }

    final valueRange = actualMax - actualMin;

    var result = BigInt.zero;
    for (var i = 0; i < valueRange.bitLength; i++) {
      final nextResult = (result << 1) + (random.nextBool() ? BigInt.one : BigInt.zero);
      if (actualMin + nextResult >= actualMax) {
        break;
      }
      result = nextResult;
    }
    return actualMin + result;
  },
  shrink: (input) sync* {
    if (input > BigInt.zero) {
      yield input - (shrinkInterval ?? BigInt.one);
    } else if (input < BigInt.zero) {
      yield input + (shrinkInterval ?? BigInt.one);
    }
  },
);

/// Chooses between the given values. Values further at the front of the list are considered less complex.
Generator<T> oneOf<T>(Iterable<T> values) {
  final strictValues = <T>[];
  final index = <T, int>{};

  for (final (i, value) in values.indexed) {
    strictValues.add(value);
    index[value] ??= i;
  }

  return generator(
    generate: (random, size) => strictValues[_nextInt(random, size.clamp(0, strictValues.length))],
    shrink: (option) sync* {
      final previousIndex = index[option];
      if (previousIndex != null) {
        yield strictValues[previousIndex];
      }
    },
  );
}

/// Generates a list of random length, containing items from the provided [item] generator.
///
/// The length of the list is at least [minSize] and at most [maxSize]. If [maxSize] is not provided, it
/// defaults `size`.
Generator<List<T>> listOf<T>(Generator<T> item, {int minSize = 0, int? maxSize}) {
  assert(minSize >= 0, 'minSize must be non-negative');
  assert(maxSize == null || maxSize >= minSize, 'maxSize must be greater than or equal to minSize');
  return (random, size) {
    final actualMax = maxSize ?? size;

    if (actualMax == 0 || actualMax < minSize) {
      return Candidate([]);
    }

    final length = minSize + _nextInt(random, actualMax - minSize + 1);
    final candidates = List.generate(length, (_) => item(random, size));
    final values = candidates.map((i) => i.value).toList();

    return Candidate(values, (v) sync* {
      if (candidates.isEmpty) {
        return;
      }
      yield Candidate(values.take(minSize).toList());

      for (var i = values.length; i > 1; i--) {
        yield Candidate(values.sublist(1, i));
      }

      for (var i = candidates.length - 1; i >= 0; i--) {
        yield* candidates[i].map((v) => values..[i] = v).shrunk;
      }
    });
  };
}

/// Generates a set of random length, containing items from the provided set of items [items].items
///
/// The length of the set is at least [minSize] and at most [maxSize]. If [maxSize] cannot be larger than the size of
/// [items], and if not provided, it defaults to `size` or `items.length`, whichever is smaller.
Generator<Set<T>> setOf<T>(Set<T> items, {int minSize = 0, int? maxSize}) {
  assert(minSize >= 0, 'minSize must not be negative');
  assert(maxSize == null || maxSize >= 0, 'maxSize must not be negative');

  assert(
    maxSize == null || maxSize <= items.length,
    'maxSize must be less than or equal to the number of distinct elements in items',
  );

  return (random, size) {
    final actualMax = maxSize ?? size;
    if (actualMax == 0 || actualMax < minSize) {
      return Candidate({});
    }

    final indices = List.generate(items.length, (i) => i)..shuffle(random);
    final length = minSize + _nextInt(random, actualMax - minSize + 1);
    final candidates = indices.take(length).map((i) => Candidate(items.elementAt(i), (_) => [])).toList();
    final values = candidates.map((i) => i.value).toList();

    return Candidate(values.toSet(), (v) sync* {
      if (candidates.isEmpty) {
        return;
      }
      yield Candidate(values.take(minSize).toSet());

      for (var i = values.length; i > 1; i--) {
        yield Candidate(values.sublist(1, i).toSet());
      }

      for (var i = candidates.length - 1; i >= 0; i--) {
        yield* candidates[i].map((v) => Set.of(values..[i] = v)).shrunk;
      }
    });
  };
}

/// Generates a map of random size, containing items from the provided [key], and [value] generators.
///
/// The size of the map is at least [minSize] and at most [maxSize]. If [maxSize] is not provided, it defaults `size`.
Generator<Map<K, V>> mapOf<K, V>(Generator<K> key, Generator<V> value, {int minSize = 0, int? maxSize}) => listOf(
  key.distinct().zip(value).map((kv) => MapEntry(kv.$1, kv.$2)),
  minSize: minSize,
  maxSize: maxSize,
).map(Map.fromEntries);

/// A generator that returns [DateTime]s.
///
/// By default, it does not generate values before the UNIX epoch (1970-01-01T00:00:00Z).
///
/// [min] is inclusive, and [max] is exclusive on the scale of one microsecond.
Generator<DateTime> dateTime({DateTime? min = const NoDateTimeProvided(), DateTime? max}) => integer(
  min: min is NoDateTimeProvided ? 0 : min?.millisecondsSinceEpoch,
  max: max?.microsecondsSinceEpoch,
).map(DateTime.fromMicrosecondsSinceEpoch);

/// A generator that returns [Duration]s.
///
/// By default, it does not generate negative values
///
/// [min] is inclusive, and [max] is exclusive on the scale of one microsecond.
Generator<Duration> duration({Duration? min = const NoDurationProvided(), Duration? max}) => integer(
  min: min is NoDurationProvided ? 0 : min?.inMicroseconds,
  max: max?.inMicroseconds,
).map((int) => Duration(microseconds: int));

const asciiLetters = 'abcdefghijklmnopqrstuvwxyz';
const digits = '0123456789';
const asciiAlphaNumeric = '$asciiLetters$digits';

/// A generator that returns [String]s.
///
/// By default it generates ASCII alphanumeric strings.
Generator<String> string({String chars = asciiAlphaNumeric, int minSize = 0, int? maxSize}) => listOf(
  oneOf(chars.characters.toList()),
  minSize: minSize,
  maxSize: maxSize,
).map((listOfChars) => listOfChars.join());

extension StringGeneratorExtension on Generator<String> {
  /// Returns a new [Generator] that produces only lower case strings.
  Generator<String> get lowerCase => map((s) => s.toLowerCase());

  /// Returns a new [Generator] that produces only upper case strings.
  Generator<String> get upperCase => map((s) => s.toUpperCase());
}
