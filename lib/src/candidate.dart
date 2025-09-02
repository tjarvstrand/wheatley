import 'dart:async';

import 'package:meta/meta.dart';

/// Represents a value that is a candidate that could possibly falsify a property. [Candidate]s can be shrunk to make
/// them "simpler", in order to find the simplest possible input that still falsifies the property.
class Candidate<T> {
  /// Creates a new candidate value.
  ///
  /// [shrink] and [dispose] take the candidates current value as input. This is so that they can be passed on when
  /// creating new candidates from this one.
  Candidate(this.value, {Iterable<Candidate<T>> Function(T)? shrink, void Function(T)? dispose})
    : _shrink = shrink ?? ((_) => const []),
      _dispose = dispose ?? ((_) {});

  /// The value of this [Candidate].
  final T value;

  /// Called to clean up resources when this [Candidate] is no longer needed.

  final void Function(T) _dispose;
  void dispose() => _dispose(value);

  Candidate<T> withValue(T newValue) => Candidate(newValue, shrink: _shrink, dispose: _dispose);

  Candidate<T> get unshrinkable => Candidate(value, dispose: _dispose);

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
  ///
  /// Note that the returned [Candidate] is not disposed, it is the callers responsibility to do so, if necessary.
  Future<(int, Candidate<T>)> shrinkUntilDone(FutureOr<void> Function(T) test, [int? maxShrinks]) async {
    var shrinks = 0;
    var currentInput = this;

    while (maxShrinks == null || shrinks < maxShrinks) {
      final candidates = currentInput.shrunk;
      if (candidates.isEmpty) {
        return (shrinks, currentInput);
      }
      shrinks++;
      final falsifyingCandidate = await _firstFalsifyingCandidate(test, candidates);
      if (falsifyingCandidate == null) {
        break;
      }
      currentInput.dispose();
      currentInput = falsifyingCandidate;
    }
    return (shrinks, currentInput);
  }

  Future<Candidate<T>?> _firstFalsifyingCandidate(
    FutureOr<void> Function(T) test,
    Iterable<Candidate<T>> candidates,
  ) async {
    var falsified = false;
    Candidate<T>? result = null;
    for (final candidate in candidates) {
      if (falsified) {
        candidate.dispose();
      } else {
        try {
          await test(candidate.value);
          candidate.dispose();
        } catch (_) {
          if (result != null) {
            result.dispose();
          }
          falsified = true;
          result = candidate;
        }
      }
    }
    return result;
  }

  /// Returns a new [Candidate] where [mapper] is applied to the value of this [Candidate].
  Candidate<T2> map<T2>(T2 Function(T value) mapper, {void Function(T2)? dispose}) => Candidate(
    mapper(value),
    shrink:
        (_) => shrunk.map(
          (candidate) => candidate.map(
            mapper,
            dispose: (v) {
              candidate.dispose();
              dispose?.call(v);
            },
          ),
        ),
    dispose: (v) {
      this.dispose();
      dispose?.call(v);
    },
  );

  /// Returns a new [Candidate] where [mapper] is applied to the value of this [Candidate].
  Candidate<T2> flatMap<T2>(Candidate<T2> Function(T value) mapper, {void Function(T2)? dispose}) =>
      Candidate(mapper(value).value, shrink: (v) => shrunk.map((s) => mapper(s.value)), dispose: dispose);

  /// Returns a new [Candidate] that can be shrunk to `null` in addition to this [Candidate]s shrink candidates.
  Candidate<T?> get nullable => Candidate<T?>(
    value,
    shrink: (_) => shrunk.cast<Candidate<T?>>().followedBy([Candidate<T?>(null, shrink: (_) => [])]),
    dispose: (v) {
      if (v != null) {
        _dispose(v);
      }
    },
  );

  /// Returns a new [Candidate] that combines the result of this [Candidate] with [other] in a tuple.
  ///
  /// The shrink candidates of the resulting [Candidate] is the Cartesian product of the shrink candidates of this
  /// and [other].
  Candidate<(T, T2)> zip<T2>(Candidate<T2> other) => Candidate<(T, T2)>(
    (value, other.value),
    shrink: (_) {
      final thisShrink = shrunk;
      if (thisShrink.isNotEmpty) {
        return thisShrink.map((shrunk) => shrunk.zip(other));
      }
      final otherShrink = other.shrunk;
      return otherShrink.map((shrunk) => shrunk.map((otherValue) => (value, otherValue)));
    },
    dispose: (_) {
      dispose();
      other.dispose();
    },
  );

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
