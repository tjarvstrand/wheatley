import 'dart:async';

import 'package:meta/meta.dart';

/// A wrapper for a value that knows how to shrink itself.
class Shrinkable<T> {
  factory Shrinkable(T value, [Iterable<Shrinkable<T>> Function()? shrink]) => Shrinkable._(() => value, shrink);

  Shrinkable._(this._value, Iterable<Shrinkable<T>> Function()? shrink) : _shrink = shrink ?? (() => const []);

  final T Function() _value;

  /// The actual value itself.
  late T value = _value();

  /// Generates an [Iterable] of [Shrinkable]s that fulfill the following criteria:
  ///
  /// - They are _similar_ to this: They only differ in little ways.
  /// - They are _simpler_ than this: The transitive hull is finite acyclic. If you would call [shrunken] on all returned
  ///   values and on the values returned by them etc., this process must terminate at some point, known as the
  ///   fixpoint.
  ///
  /// Since there are often multiple valid ways to simplify a failing test case, providing a list rather than a single
  /// value allows the property-based testing framework to explore different simplifications in parallel. This allows
  /// more thorough minimization, increasing the chance of finding the smallest or simplest failing case and decreasing
  /// the risk of getting stuck in local minima.
  Iterable<Shrinkable<T>> Function() _shrink;
  Iterable<Shrinkable<T>> get shrunken => _shrink();

  /// Shrinks this [Shrinkable] input until it can no longer be shrunk or until test no longer throws an error when
  /// using the shrunken value as input.
  Future<(int, T)> shrink(FutureOr<void> Function(T) test) async {
    var shrinks = 0;
    var currentInput = this;

    outer:
    while (true) {
      for (final shrunkInput in currentInput.shrunken) {
        shrinks++;
        try {
          await test(shrunkInput.value);
        } catch (_) {
          currentInput = shrunkInput;
          shrinks++;
          continue outer;
        }
      }
      break;
    }
    return (shrinks, currentInput.value);
  }

  /// Returns a new [Shrinkable] where [mapper] is applied to the value of this [Shrinkable].
  Shrinkable<T2> map<T2>(T2 Function(T value) mapper) => Shrinkable(
        mapper(value),
        () => shrunken.map((shrinkable) => shrinkable.map(mapper)),
      );

  /// Returns a new [Shrinkable] where [mapper] is applied to the value of this [Shrinkable].
  Shrinkable<T2> flatMap<T2>(Shrinkable<T2> Function(T value) mapper) => Shrinkable(
        mapper(value).value,
        () => shrunken.map((s) => mapper(s.value)),
      );

  /// Returns a new [Shrinkable] that can be shrunk to `null` in addition to this [Shrinkable]s shrink candidates.
  Shrinkable<T?> get nullable => Shrinkable<T?>(
        value,
        () => shrunken.cast<Shrinkable<T?>>().followedBy([Shrinkable<T?>(null, () => [])]),
      );

  /// Returns a new [Shrinkable] that combines the result of this [Shrinkable] with [other] in a tuple.
  ///
  /// The shrink candidates of the resulting [Shrinkable] is the Cartesian product of the shrink candidates of this
  /// and [other].
  Shrinkable<(T, T2)> zip<T2>(Shrinkable<T2> other) => Shrinkable<(T, T2)>(
        (value, other.value),
        () {
          final thisShrink = shrunken;
          if (thisShrink.isNotEmpty) {
            return thisShrink.map((shrunk) => shrunk.zip(other));
          }
          final otherShrink = other.shrunken;
          return otherShrink.map((shrunk) => shrunk.map((otherValue) => (value, otherValue)));
        },
      );

  /// Returns an [Iterable] of this [Shrinkable]s value and all values that it can shrink to.
  ///
  /// Useful for testing generators.
  @visibleForTesting
  Iterable<T> get values sync* {
    yield value;
    for (final shrinkable in shrunken) {
      yield* shrinkable.values;
    }
  }
}
