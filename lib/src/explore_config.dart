import 'dart:math';

final _defaultRandom = Random();

/// Configuration for several parameters used during the exploration phase.
class ExploreConfig {
  const ExploreConfig({
    this.runs = 100,
    this.initialSize = 10,
    this.sizeIncrement = 1,
    Random? random,
  })  : assert(runs > 0, 'Number of runs must be greater than 0'),
        assert(initialSize > 0, 'Initial size must be greater than 0'),
        assert(sizeIncrement >= 0, 'Speed must be greater than or equal to 0'),
        _random = random;

  /// The number of runs after which to stop trying to break the property.
  final int runs;

  /// The initial size.
  final int initialSize;

  /// The amount by which the size will be increased each run.
  final int sizeIncrement;

  /// The [Random] used for generating all randomness.
  final Random? _random;
  Random get random => _random ?? _defaultRandom;
}
