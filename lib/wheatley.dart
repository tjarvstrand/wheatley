import 'dart:async';
import 'dart:io';

import 'package:wheatley/src/explore_config.dart';
import 'package:wheatley/src/generator.dart';

export 'package:wheatley/src/generator.dart';
export 'package:wheatley/src/generators.dart';
export 'package:wheatley/src/shrinkable.dart';

void _defaultErrorLogger(String message) => stderr.writeln(message);

/// Executes the given body with a bunch of parameters, trying to break it.
Future<void> Function(FutureOr<void> Function(T)) forAll<T>(
  Generator<T> generator, {
  ExploreConfig config = const ExploreConfig(),
}) =>
    (body) async {
      final failure = await generator.explore(config, body);
      if (failure == null) {
        return;
      }

      final (sampleCount, input, error, stackTrace) = failure;
      final (shrinkCount, shrunkInput) = await input.shrink(body);
      _defaultErrorLogger('Tested $sampleCount inputs, shrunk $shrinkCount times\nFailing for input: $shrunkInput\n');
      Error.throwWithStackTrace(error, stackTrace);
    };

Future<void> Function(FutureOr<void> Function(T1, T2)) forAll2<T1, T2>(
  Generator<T1> generator1,
  Generator<T2> generator2, {
  ExploreConfig config = const ExploreConfig(),
}) =>
    (body) => forAll(generator1.zip(generator2), config: config)(body.tupled);

Future<void> Function(FutureOr<void> Function(T1, T2, T3)) forAll3<T1, T2, T3>(
  Generator<T1> generator1,
  Generator<T2> generator2,
  Generator<T3> generator3, {
  ExploreConfig config = const ExploreConfig(),
}) =>
    (body) => forAll((generator1, generator2, generator3).zip, config: config)(body.tupled);

Future<void> Function(FutureOr<void> Function(T1, T2, T3, T4)) forAll4<T1, T2, T3, T4>(
  Generator<T1> generator1,
  Generator<T2> generator2,
  Generator<T3> generator3,
  Generator<T4> generator4, {
  ExploreConfig config = const ExploreConfig(),
}) =>
    (body) => forAll((generator1, generator2, generator3, generator4).zip, config: config)(body.tupled);

Future<void> Function(FutureOr<void> Function(T1, T2, T3, T4, T5)) forAll5<T1, T2, T3, T4, T5>(
  Generator<T1> generator1,
  Generator<T2> generator2,
  Generator<T3> generator3,
  Generator<T4> generator4,
  Generator<T5> generator5, {
  ExploreConfig config = const ExploreConfig(),
}) =>
    (body) => forAll((generator1, generator2, generator3, generator4, generator5).zip, config: config)(body.tupled);

Future<void> Function(FutureOr<void> Function(T1, T2, T3, T4, T5, T6)) forAll6<T1, T2, T3, T4, T5, T6>(
  Generator<T1> generator1,
  Generator<T2> generator2,
  Generator<T3> generator3,
  Generator<T4> generator4,
  Generator<T5> generator5,
  Generator<T6> generator6, {
  ExploreConfig config = const ExploreConfig(),
}) =>
    (body) => forAll((generator1, generator2, generator3, generator4, generator5, generator6).zip, config: config)(
        body.tupled);

Future<void> Function(FutureOr<void> Function(T1, T2, T3, T4, T5, T6, T7)) forAll7<T1, T2, T3, T4, T5, T6, T7>(
  Generator<T1> generator1,
  Generator<T2> generator2,
  Generator<T3> generator3,
  Generator<T4> generator4,
  Generator<T5> generator5,
  Generator<T6> generator6,
  Generator<T7> generator7, {
  ExploreConfig config = const ExploreConfig(),
}) =>
    (body) => forAll((generator1, generator2, generator3, generator4, generator5, generator6, generator7).zip,
        config: config)(body.tupled);

Future<void> Function(FutureOr<void> Function(T1, T2, T3, T4, T5, T6, T7, T8)) forAll8<T1, T2, T3, T4, T5, T6, T7, T8>(
  Generator<T1> generator1,
  Generator<T2> generator2,
  Generator<T3> generator3,
  Generator<T4> generator4,
  Generator<T5> generator5,
  Generator<T6> generator6,
  Generator<T7> generator7,
  Generator<T8> generator8, {
  ExploreConfig config = const ExploreConfig(),
}) =>
    (body) => forAll(
        (generator1, generator2, generator3, generator4, generator5, generator6, generator7, generator8).zip,
        config: config)(body.tupled);

extension Function2Ext<In1, In2, Out> on Out Function(In1, In2) {
  Out Function((In1, In2) input) get tupled => (input) => this(input.$1, input.$2);
}

extension Function3Ext<In1, In2, In3, Out> on Out Function(In1, In2, In3) {
  Out Function((In1, In2, In3) input) get tupled => (input) => this(input.$1, input.$2, input.$3);
}

extension Function4Ext<In1, In2, In3, In4, Out> on Out Function(In1, In2, In3, In4) {
  Out Function((In1, In2, In3, In4) input) get tupled => (input) => this(input.$1, input.$2, input.$3, input.$4);
}

extension Function5Ext<In1, In2, In3, In4, In5, Out> on Out Function(In1, In2, In3, In4, In5) {
  Out Function((In1, In2, In3, In4, In5) input) get tupled =>
      (input) => this(input.$1, input.$2, input.$3, input.$4, input.$5);
}

extension Function6Ext<In1, In2, In3, In4, In5, In6, Out> on Out Function(In1, In2, In3, In4, In5, In6) {
  Out Function((In1, In2, In3, In4, In5, In6) input) get tupled =>
      (input) => this(input.$1, input.$2, input.$3, input.$4, input.$5, input.$6);
}

extension Function7Ext<In1, In2, In3, In4, In5, In6, In7, Out> on Out Function(In1, In2, In3, In4, In5, In6, In7) {
  Out Function((In1, In2, In3, In4, In5, In6, In7) input) get tupled =>
      (input) => this(input.$1, input.$2, input.$3, input.$4, input.$5, input.$6, input.$7);
}

extension Function8Ext<In1, In2, In3, In4, In5, In6, In7, In8, Out> on Out Function(
    In1, In2, In3, In4, In5, In6, In7, In8) {
  Out Function((In1, In2, In3, In4, In5, In6, In7, In8) input) get tupled =>
      (input) => this(input.$1, input.$2, input.$3, input.$4, input.$5, input.$6, input.$7, input.$8);
}
