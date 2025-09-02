import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart';

void main() {
  late final Iterable<int> Function(int) shrinkInt;
  shrinkInt = (s) => s > 0 ? [s - 1] : [];

  group('Candidate', () {
    group('nullable', () {
      test('adds a null candidate value', () {
        expect(Candidate(1, shrink: shrinkInt).nullable.allValues, [1, 0, null]);
      });
    });
    group('map', () {
      test('should apply the mapper to the value', () {
        final candidate1 = Candidate(4, shrink: shrinkInt);
        final candidate2 = candidate1.map((value) => value * 2);

        expect(candidate1.allValues.toList(), [4, 3, 2, 1, 0]);
        expect(candidate2.allValues.toList(), [8, 6, 4, 2, 0]);
      });
      test('creates a candidate that disposes both the original and the mapped value', () {
        final disposedValues = <int>[];
        final candidate1 = Candidate(4, shrink: shrinkInt, dispose: disposedValues.add);
        final candidate2 = candidate1.map((value) => value * 2, dispose: disposedValues.add);

        candidate2.dispose();
        expect(disposedValues, [4, 8]);
      });
    });
    group('flatMap', () {
      test('should apply the mapper to the value', () {
        final candidate1 = Candidate(4, shrink: shrinkInt);
        final candidate2 = candidate1.flatMap((value) => Candidate(value * 2, shrink: shrinkInt));

        expect(candidate1.allValues.toList(), [4, 3, 2, 1, 0]);
        expect(candidate2.allValues.toList(), [8, 7, 6, 5, 4, 3, 2, 1, 0]);
      });
      test('creates a candidate that disposes both the original and the mapped value', () {
        final disposedValues = <int>[];
        final candidate1 = Candidate(4, shrink: shrinkInt, dispose: disposedValues.add);
        final candidate2 = candidate1.flatMap(
          (value) => Candidate(value * 2, shrink: shrinkInt, dispose: disposedValues.add),
        );

        candidate2.dispose();
        expect(disposedValues, [4, 8]);
      });
    });
    group('zip', () {
      test('creates a candidate that disposes both original candidates', () {
        final disposedValues = <int>[];
        final candidate1 = Candidate(4, shrink: shrinkInt, dispose: disposedValues.add);
        final candidate2 = Candidate(5, shrink: shrinkInt, dispose: disposedValues.add);
        final zippedCandidate = candidate1.zip(candidate2);

        zippedCandidate.dispose();
        expect(disposedValues, [4, 5]);
      });
    });
    group('shrinkUntilDone', () {
      test('shrinks', () {
        expect(Candidate(4, shrink: shrinkInt).allValues, [4, 3, 2, 1, 0]);
      });
      test('calls dispose on each candidate except the last one', () async {
        final disposedValues = <int>[];
        final candidate = Candidate(4, shrink: shrinkInt, dispose: disposedValues.add);
        await candidate.shrinkUntilDone((_) => throw Exception());
        expect(disposedValues, [4, 3, 2, 1]);
      });
      test(
        'calls dispose on each candidate except the last (null) one on a candidate from Candidate.nullable',
        () async {
          final disposedValues = <int>[];

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
