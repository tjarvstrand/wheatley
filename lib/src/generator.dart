import 'dart:async';
import 'dart:math' as math;

import 'package:wheatley/src/candidate.dart';
import 'package:wheatley/src/explore_config.dart';

/// A [Generator] makes it possible to use Wheatley to test type [T].
/// Generates a new [Candidate] of type [T], using [size] as a rough
/// complexity estimate. The [random] instance should be used as a source for
/// all pseudo-randomness.
typedef Generator<T> = Candidate<T> Function(math.Random random, int size);

/// Creates a new, simple [Generator] that produces values and knows how to
/// simplify them.
Generator<T> generator<T>({
  required T Function(math.Random random, int size) generate,
  Iterable<T> Function(T input)? shrink,
  void Function(T value)? dispose,
}) {
  Candidate<T> generateCandidate(T value) =>
      Candidate(value, shrink: (v) => shrink?.call(v).map(generateCandidate) ?? [], dispose: dispose);
  return (random, size) => generateCandidate(generate(random, size));
}

/// Useful methods on [Generator]s.
extension GeneratorExtensions<T> on Generator<T> {
  /// Transforms this [Generator] into a new [Generator] that produces values of type [T2] by applying [mapper] to its
  /// values.
  Generator<T2> map<T2>(T2 Function(T value) mapper, {void Function(T2)? dispose}) =>
      (random, size) => this(random, size).map(mapper, dispose: dispose);

  /// Transforms this [Generator] into a new [Generator] that produces values of type [T2] by applying [mapper] to its
  /// values.
  Generator<T2> flatMap<T2>(Generator<T2> Function(T) mapper) => (random, size) {
    final candidate = this(random, size);
    final mapped = mapper(candidate.value)(random, size);
    return Candidate(
      mapped.value,
      shrink: (_) => mapped.shrunk,
      dispose: (v) {
        candidate.dispose();
        mapped.dispose();
      },
    );
  };

  /// Returns a new generator with candidates that can be shrunk to `null` in addition to this [Generator]'s candidates
  /// shrink candidates.
  Generator<T?> get nullable => (random, size) => this(random, size).nullable;

  /// Returns a new [Generator] that combines the resulting candidates of this [Generator] with candidates from [other]
  /// in a tuple.
  ///
  /// The shrink candidates of the resulting [Candidate] is the Cartesian product of the shrink candidates of this
  /// and [other].
  Generator<(T, T2)> zip<T2>(Generator<T2> other) => (random, size) => this(random, size).zip(other(random, size));

  /// Returns a new [Generator] that will only produce values that satisfy the [test] function.
  ///
  /// Fails if it cannot produce a new value after [maxTests] attempts.
  Generator<T> where(bool Function(T) test, {int maxTests = 1000}) =>
      (random, size) => Iterable.generate(maxTests, (_) => this(random, size)).firstWhere(
        (s) => test(s.value),
        orElse: () => throw ArgumentError('Failed to generate a valid ${T} input in $maxTests iterations'),
      );

  /// Returns a new [Generator] stateful generator that will not produce the same value twice.
  ///
  /// Fails if it cannot produce a new value after [maxTests] attempts.
  Generator<T> distinct({int maxTests = 1000}) {
    final seen = <T>{};
    return where(seen.add, maxTests: maxTests);
  }

  /// Explores the input space for inputs that break the property. This works by gradually increasing the size.
  ///
  /// Returns the first value where the property is broken, if any.
  Future<(int, Candidate<T>, Object, StackTrace)?> explore(
    ExploreConfig config,
    FutureOr<void> Function(T) body,
  ) async {
    final sizes = Iterable<(int, int)>.generate(config.runs, (i) => (i, config.initialSize + i * config.sizeIncrement));

    for (final (index, size) in sizes) {
      final candidate = this(config.random, size);
      try {
        await body(candidate.value);
      } catch (error, stackTrace) {
        return (index + 1, candidate, error, stackTrace);
      } finally {
        candidate.dispose();
      }
    }
    return null;
  }
}

// coverage:ignore-start

extension Tuple2GeneratorExtension<T1, T2> on (Generator<T1>, Generator<T2>) {
  Generator<(T1, T2)> get zip => (random, size) {
    return $1(random, size).zip($2(random, size));
  };
}

extension Tuple3GeneratorExtension<T1, T2, T3> on (Generator<T1>, Generator<T2>, Generator<T3>) {
  Generator<(T1, T2, T3)> get zip => (random, size) {
    return $1(random, size).zip($2(random, size)).zip($3(random, size)).map((tuple) {
      final ((first, second), third) = tuple;
      return (first, second, third);
    });
  };
}

extension Tuple4GeneratorExtension<T1, T2, T3, T4> on (Generator<T1>, Generator<T2>, Generator<T3>, Generator<T4>) {
  Generator<(T1, T2, T3, T4)> get zip => (random, size) {
    return $1(random, size).zip($2(random, size)).zip($3(random, size)).zip($4(random, size)).map((tuple) {
      final (((first, second), third), fourth) = tuple;
      return (first, second, third, fourth);
    });
  };
}

extension Tuple5GeneratorExtension<T1, T2, T3, T4, T5>
    on (Generator<T1>, Generator<T2>, Generator<T3>, Generator<T4>, Generator<T5>) {
  Generator<(T1, T2, T3, T4, T5)> get zip => (random, size) {
    return $1(random, size).zip($2(random, size)).zip($3(random, size)).zip($4(random, size)).zip($5(random, size)).map(
      (tuple) {
        final ((((first, second), third), fourth), fifth) = tuple;
        return (first, second, third, fourth, fifth);
      },
    );
  };
}

extension Tuple6GeneratorExtension<T1, T2, T3, T4, T5, T6>
    on (Generator<T1>, Generator<T2>, Generator<T3>, Generator<T4>, Generator<T5>, Generator<T6>) {
  Generator<(T1, T2, T3, T4, T5, T6)> get zip => (random, size) {
    return $1(random, size)
        .zip($2(random, size))
        .zip($3(random, size))
        .zip($4(random, size))
        .zip($5(random, size))
        .zip($6(random, size))
        .map((tuple) {
          final (((((first, second), third), fourth), fifth), sixth) = tuple;
          return (first, second, third, fourth, fifth, sixth);
        });
  };
}

extension Tuple7GeneratorExtension<T1, T2, T3, T4, T5, T6, T7>
    on (Generator<T1>, Generator<T2>, Generator<T3>, Generator<T4>, Generator<T5>, Generator<T6>, Generator<T7>) {
  Generator<(T1, T2, T3, T4, T5, T6, T7)> get zip => (random, size) {
    return $1(random, size)
        .zip($2(random, size))
        .zip($3(random, size))
        .zip($4(random, size))
        .zip($5(random, size))
        .zip($6(random, size))
        .zip($7(random, size))
        .map((tuple) {
          final ((((((first, second), third), fourth), fifth), sixth), seventh) = tuple;
          return (first, second, third, fourth, fifth, sixth, seventh);
        });
  };
}

extension Tuple8GeneratorExtension<T1, T2, T3, T4, T5, T6, T7, T8>
    on
        (
          Generator<T1>,
          Generator<T2>,
          Generator<T3>,
          Generator<T4>,
          Generator<T5>,
          Generator<T6>,
          Generator<T7>,
          Generator<T8>,
        ) {
  Generator<(T1, T2, T3, T4, T5, T6, T7, T8)> get zip => (random, size) {
    return $1(random, size)
        .zip($2(random, size))
        .zip($3(random, size))
        .zip($4(random, size))
        .zip($5(random, size))
        .zip($6(random, size))
        .zip($7(random, size))
        .zip($8(random, size))
        .map((tuple) {
          final (((((((first, second), third), fourth), fifth), sixth), seventh), eighth) = tuple;
          return (first, second, third, fourth, fifth, sixth, seventh, eighth);
        });
  };
}

// coverage:ignore-end
