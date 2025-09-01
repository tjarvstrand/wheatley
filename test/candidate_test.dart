import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart';

void main() {
  late final Iterable<Candidate<int>> Function(int) shrinkInt;
  shrinkInt = (s) => s > 0 ? [Candidate(s - 1, shrink: shrinkInt)] : [];

  group('Candidate', () {
    group('nullable', () {
      test('adds a null candidate value', () {
        expect(Candidate(1, shrink: shrinkInt).nullable.allValues, [1, 0, null]);
      });
    });
    group('flatMap', () {
      test('should apply the mapper to the value', () {
        final candidate1 = Candidate(4, shrink: shrinkInt);
        final candidate2 = candidate1.flatMap((value) => Candidate(value * 2, shrink: shrinkInt));

        expect(candidate1.allValues.toList(), [4, 3, 2, 1, 0]);
        // Steps down from the first shrunk value of candidate1 mapped with mapper, 3 * 2 = 6
        expect(candidate2.allValues.toList(), [8, 6, 5, 4, 3, 2, 1, 0]);
      });
    });
    group('shrinkUntilDone', () {
      test('shrinks', () {
        expect(Candidate(4, shrink: shrinkInt).allValues, [4, 3, 2, 1, 0]);
      });
      test('calls dispose on each candidate except the last one', () async {
        final disposedValues = <int>[];
        late final Iterable<Candidate<int>> Function(int) shrinkInt;
        shrinkInt = (s) => s > 0 ? [Candidate(s - 1, shrink: shrinkInt, dispose: disposedValues.add)] : [];

        final candidate = Candidate(4, shrink: shrinkInt, dispose: disposedValues.add);
        await candidate.shrinkUntilDone((_) => throw Exception());
        expect(disposedValues, [4, 3, 2, 1]);
      });
      test(
        'calls dispose on each candidate except the last (null) one on a candidate from Candidate.nullable',
        () async {
          final disposedValues = <int>[];

          late final Iterable<Candidate<int>> Function(int) shrinkInt;
          shrinkInt = (s) => s > 0 ? [Candidate(s - 1, shrink: shrinkInt, dispose: disposedValues.add)] : [];

          final candidate = Candidate(4, shrink: shrinkInt, dispose: disposedValues.add).nullable;
          await candidate.shrinkUntilDone((v) => throw Exception());

          expect(disposedValues, [4, 3, 2, 1]);
        },
      );
      test('Does not shrink more than maxShrink times', () async {
        final (shrinks, candidate) = await Candidate(4, shrink: shrinkInt).shrinkUntilDone((_) => throw Exception(), 2);
        expect(shrinks, 2);
        expect(candidate.value, 2);
      });
    });
  });
}
