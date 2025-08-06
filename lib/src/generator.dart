import 'dart:async';
import 'dart:math';

import 'package:wheatley/src/explore_config.dart';
import 'package:wheatley/src/shrinkable.dart';

/// A [Generator] makes it possible to use Wheatley to test type [T].
/// Generates a new [Shrinkable] of type [T], using [size] as a rough
/// complexity estimate. The [random] instance should be used as a source for
/// all pseudo-randomness.
typedef Generator<T> = Shrinkable<T> Function(Random random, int size);

/// Useful methods on [Generator]s.
extension GeneratorExtensions<T> on Generator<T> {
  Generator<T2> map<T2>(T2 Function(T value) mapper) => (random, size) => this(random, size).map(mapper);

  Generator<T2> flatMap<T2>(Generator<T2> Function(T) mapper) =>
      (random, size) => mapper(this(random, size).value)(random, size);

  Generator<R> bind<R>(Generator<R> Function(T value) mapper) =>
      (random, size) => map(mapper)(random, size).value(random, size);

  Generator<T?> get nullable => (random, size) => this(random, size).nullable;

  Generator<(T, T2)> zip<T2>(Generator<T2> other) => (random, size) => this(random, size).zip(other(random, size));

  /// Explores the input space for inputs that break the property. This works by gradually increasing the size.
  ///
  /// Returns the first value where the property is broken, if any.
  Future<(int, Shrinkable<T>, Object, StackTrace)?> explore(
    ExploreConfig config,
    FutureOr<void> Function(T) body,
  ) async {
    final inputs =
        Iterable<(int, int)>.generate(config.runs, (i) => (i, config.initialSize + i * config.sizeIncrement));

    for (final (index, input) in inputs) {
      final shrinkable = this(config.random, input);
      try {
        await body(shrinkable.value);
      } catch (error, stackTrace) {
        return (index + 1, shrinkable, error, stackTrace);
      }
    }
    return null;
  }
}

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

extension Tuple5GeneratorExtension<T1, T2, T3, T4, T5> on (
  Generator<T1>,
  Generator<T2>,
  Generator<T3>,
  Generator<T4>,
  Generator<T5>
) {
  Generator<(T1, T2, T3, T4, T5)> get zip => (random, size) {
        return $1(random, size)
            .zip($2(random, size))
            .zip($3(random, size))
            .zip($4(random, size))
            .zip($5(random, size))
            .map((tuple) {
          final ((((first, second), third), fourth), fifth) = tuple;
          return (first, second, third, fourth, fifth);
        });
      };
}

extension Tuple6GeneratorExtension<T1, T2, T3, T4, T5, T6> on (
  Generator<T1>,
  Generator<T2>,
  Generator<T3>,
  Generator<T4>,
  Generator<T5>,
  Generator<T6>
) {
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

extension Tuple7GeneratorExtension<T1, T2, T3, T4, T5, T6, T7> on (
  Generator<T1>,
  Generator<T2>,
  Generator<T3>,
  Generator<T4>,
  Generator<T5>,
  Generator<T6>,
  Generator<T7>,
) {
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

extension Tuple8GeneratorExtension<T1, T2, T3, T4, T5, T6, T7, T8> on (
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

/// Creates a new, simple [Generator] that produces values and knows how to
/// simplify them.
Generator<T> generator<T>({
  required T Function(Random random, int size) generate,
  Iterable<T> Function(T input)? shrink,
}) {
  Shrinkable<T> generateShrinkable(T value) =>
      Shrinkable(value, () => shrink?.call(value).map(generateShrinkable) ?? []);
  return (random, size) => generateShrinkable(generate(random, size));
}
