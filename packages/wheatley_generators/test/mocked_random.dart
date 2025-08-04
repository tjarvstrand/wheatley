import 'dart:math';

class MockedRandom implements Random {
  MockedRandom({this.booleans = const [], this.doubles = const [], this.integers = const []});

  final Iterable<bool> booleans;
  var nextBooleanIndex = 0;

  final Iterable<int> integers;
  var nextIntegerIndex = 0;

  final Iterable<double> doubles;
  var nextDoubleIndex = 0;

  @override
  bool nextBool() => booleans.elementAt(nextBooleanIndex++ % booleans.length);

  @override
  double nextDouble() => doubles.elementAt(nextDoubleIndex++ % doubles.length);

  @override
  int nextInt(int max) => integers.elementAt(nextIntegerIndex++ % integers.length);
}
