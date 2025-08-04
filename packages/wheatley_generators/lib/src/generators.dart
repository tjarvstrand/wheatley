part of '../generators.dart';

/// A constant generator that always returns `null`.
final empty = constant<Null>(null);

final boolean = generator(generate: (random, _) => random.nextBool());

Generator<core.int> integer({core.int? min, core.int? max, core.int? shrinkInterval}) {
  assert(min == null || max == null || min < max, 'min must be less than max');
  return generator(
    generate: (random, size) {
      final actualMin = min ?? -size;
      final actualMax = max ?? size;
      final r = random.nextInt(actualMax - actualMin);
      return actualMin + r;
    },
    shrink: (input) sync* {
      if (input > 0 && input > (min ?? 0)) yield input - (shrinkInterval ?? 1);
      if (input < 0 && input < (max ?? 0)) yield input + (shrinkInterval ?? 1);
    },
  );
}
