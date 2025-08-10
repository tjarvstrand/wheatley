import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart';

void main() {
  test('My property is always true', () {
    forAll(positiveInteger())((value) => expect(value, greaterThan(0)));
  });
}
