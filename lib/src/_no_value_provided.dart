// coverage:ignore-file

import 'package:meta/meta.dart';

@internal
final class NoDateTimeProvided implements DateTime {
  const NoDateTimeProvided();

  @override
  DateTime add(Duration duration) => throw UnimplementedError();

  @override
  int compareTo(DateTime other) => throw UnimplementedError();

  @override
  int get day => throw UnimplementedError();

  @override
  Duration difference(DateTime other) => throw UnimplementedError();

  @override
  int get hour => throw UnimplementedError();

  @override
  bool isAfter(DateTime other) => throw UnimplementedError();

  @override
  bool isAtSameMomentAs(DateTime other) => throw UnimplementedError();

  @override
  bool isBefore(DateTime other) => throw UnimplementedError();

  @override
  bool get isUtc => throw UnimplementedError();

  @override
  int get microsecond => throw UnimplementedError();

  @override
  int get microsecondsSinceEpoch => throw UnimplementedError();

  @override
  int get millisecond => throw UnimplementedError();

  @override
  int get millisecondsSinceEpoch => throw UnimplementedError();

  @override
  int get minute => throw UnimplementedError();

  @override
  int get month => throw UnimplementedError();

  @override
  int get second => throw UnimplementedError();

  @override
  DateTime subtract(Duration duration) => throw UnimplementedError();

  @override
  String get timeZoneName => throw UnimplementedError();

  @override
  Duration get timeZoneOffset => throw UnimplementedError();

  @override
  String toIso8601String() => throw UnimplementedError();

  @override
  DateTime toLocal() => throw UnimplementedError();

  @override
  DateTime toUtc() => throw UnimplementedError();

  @override
  int get weekday => throw UnimplementedError();

  @override
  int get year => throw UnimplementedError();
}

@internal
final class NoDurationProvided implements Duration {
  const NoDurationProvided();

  @override
  Duration operator *(num factor) => throw UnimplementedError();

  @override
  Duration operator +(Duration other) => throw UnimplementedError();

  @override
  Duration operator -(Duration other) => throw UnimplementedError();

  @override
  bool operator <(Duration other) => throw UnimplementedError();

  @override
  bool operator <=(Duration other) => throw UnimplementedError();

  @override
  bool operator >(Duration other) => throw UnimplementedError();

  @override
  bool operator >=(Duration other) => throw UnimplementedError();

  @override
  Duration abs() => throw UnimplementedError();

  @override
  int compareTo(Duration other) => throw UnimplementedError();

  @override
  int get inDays => throw UnimplementedError();

  @override
  int get inHours => throw UnimplementedError();

  @override
  int get inMicroseconds => throw UnimplementedError();

  @override
  int get inMilliseconds => throw UnimplementedError();

  @override
  int get inMinutes => throw UnimplementedError();

  @override
  int get inSeconds => throw UnimplementedError();

  @override
  bool get isNegative => throw UnimplementedError();

  @override
  Duration operator -() => throw UnimplementedError();

  @override
  Duration operator ~/(int quotient) => throw UnimplementedError();
}
