import 'dart:async';

import 'package:meta/meta.dart';

/// Represents a value that is a candidate that could possibly falsify a property. [Candidate]s can be shrunk to make
/// them "simpler", in order to find the simplest possible input that still falsifies the property.
class Candidate<T> {
  Candidate(this.value, [Iterable<Candidate<T>> Function(T)? shrink]) : _shrink = shrink ?? ((_) => const []);

  /// The value of this [Candidate].
  final T value;

  Candidate<T> withValue(T newValue) => Candidate(newValue, _shrink);

  /// Generates an [Iterable] of [Candidate]s that fulfill the following criteria:
  ///
  /// - They are _similar_ to this: They only differ in little ways.
  /// - They are _simpler_ than this: The transitive hull is finite acyclic. If you would call [shrunk] on all returned
  ///   values and on the values returned by them etc., this process must terminate at some point, known as the
  ///   fixpoint.
  ///
  /// Since there are often multiple valid ways to simplify a failing test case, providing a list rather than a single
  /// value allows the property-based testing framework to explore different simplifications in parallel. This allows
  /// more thorough minimization, increasing the chance of finding the smallest or simplest failing case and decreasing
  /// the risk of getting stuck in local minima.
  Iterable<Candidate<T>> Function(T) _shrink;
  Iterable<Candidate<T>> get shrunk => _shrink(value);

  /// Shrinks this [Candidate] input until it can no longer be shrunk or until test no longer throws an error when
  /// using the shrunken value as input.
  Future<(int, T)> shrinkUntilDone(FutureOr<void> Function(T) test) async {
    var shrinks = 0;
    var currentInput = this;

    outer:
    while (true) {
      for (final shrunkInput in currentInput.shrunk) {
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

  /// Returns a new [Candidate] where [mapper] is applied to the value of this [Candidate].
  Candidate<T2> map<T2>(T2 Function(T value) mapper) =>
      Candidate(mapper(value), (_) => shrunk.map((candidate) => candidate.map(mapper)));

  /// Returns a new [Candidate] where [mapper] is applied to the value of this [Candidate].
  Candidate<T2> flatMap<T2>(Candidate<T2> Function(T value) mapper) =>
      Candidate(mapper(value).value, (_) => shrunk.map((s) => mapper(s.value)));

  /// Returns a new [Candidate] that can be shrunk to `null` in addition to this [Candidate]s shrink candidates.
  Candidate<T?> get nullable =>
      Candidate<T?>(value, (_) => shrunk.cast<Candidate<T?>>().followedBy([Candidate<T?>(null, (_) => [])]));

  /// Returns a new [Candidate] that combines the result of this [Candidate] with [other] in a tuple.
  ///
  /// The shrink candidates of the resulting [Candidate] is the Cartesian product of the shrink candidates of this
  /// and [other].
  Candidate<(T, T2)> zip<T2>(Candidate<T2> other) => Candidate<(T, T2)>((value, other.value), (_) {
    final thisShrink = shrunk;
    if (thisShrink.isNotEmpty) {
      return thisShrink.map((shrunk) => shrunk.zip(other));
    }
    final otherShrink = other.shrunk;
    return otherShrink.map((shrunk) => shrunk.map((otherValue) => (value, otherValue)));
  });

  /// Returns an [Iterable] of this [Candidate]s value and all values that it can shrink to.
  ///
  /// Useful for testing generators.
  @visibleForTesting
  Iterable<T> get allValues sync* {
    yield value;
    for (final candidate in shrunk) {
      yield* candidate.allValues;
    }
  }

  @override
  String toString() => 'Candidate<$T>($value)';
}
