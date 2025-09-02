# Wheatley

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![pub package](https://img.shields.io/pub/v/wheatley.svg?label=wheatley&color=blue)](https://pub.dev/packages/wheatley)
[![likes](https://img.shields.io/pub/likes/wheatley?logo=dart)](https://pub.dev/packages/wheatley/score)
[![pub points](https://img.shields.io/pub/points/wheatley?logo=dart)](https://pub.dev/packages/wheatley/score)
![building](https://github.com/tjarvstrand/wheatley/workflows/wheatley/badge.svg)

Let your code generate your test cases for you!

Wheatley is a no frills, framework agnostic, property based testing (PBT) library for Dart. It is a
spiritual successor to [Glados](https://pub.dev/packages/glados).

# Background

Explaining the basics and virtues of property based testing is beyond the scope of this README, but
if you are new to it, or just want to learn more, here are some resources to get you started:

 - QuickCheck for Haskell is the OG PBT library. Check out the [the official manual](https://www.cse.chalmers.se/~rjmh/QuickCheck/manual.html). 
   Even though the code snippets are all in Haskell, it still contains a lot of information that is relevant for PBT in general.  
 - F# for Fun and Profit, [The "Property Based Testing" series](https://fsharpforfunandprofit.com/series/property-based-testing/)
 - [Property based testing #1: What is it anyway?](https://getcode.substack.com/p/property-based-testing-1-what-is)

If you're like me, you're now thinking "that's great, but it all seems very mathematical and not 
applicable to my situation or code base". Initially getting started with PBT can feel daunting. 
[Here](https://youtu.be/wHJZ0icwSkc?si=xGv88gLZBo0Evx7F)'s a great video about how to think about 
PBT when first setting out in any code base.

# Install

Just add wheatley to your dev dependencies in `pubspec.yaml`:
```yaml
dev_dependencies:
  wheatley: <current version>
```

You'll also need your test frame work of choice, e.g. `test`, `flutter_test`, `patrol_test`, etc. 

# Usage

For a list of included generators, see `generators.dart`.

import `wheatley.dart` and use `forAll` to verify that your properties hold true for all generated 
inputs, e.g.:
```dart
import 'package:test/test.dart';
import 'package:wheatley/wheatley.dart';

void main() {
  test('My property is always true', () {
    forAll(myGenerator)((value) => expect(value.myProperty, isTrue));
  });
}
```

You can configure `forAll` with an `Explore` config to control how many iterations to run, how fast 
to to scale the size of generated value, and even which `Random` instance to use.

## Using generators for non-property based testing

Randomly generating test input is often frowned upon because when the test fails, it is usually 
complicated to figure out which input caused the failure. With wheatley however, you will get logs
telling you exactly how to reproduces the failure.

Generators can easily be used to generate test input data for traditional example based tests that.
Just pass `ExploreConfig.single()` to `forAll` and Wheatley will only test your code with a single
example and not try to shrink the input if the test fails.

### Using more than one generator

Generating a new value from two or more other generated values can be done in two different ways.

The first option is to use the provided convenience versions of `forAll` (`forAll2`, `forAll3`, etc.), e.g.:
```dart
void main() {
  test('My property is always true', () {
    forAll3(g1, g2, g3)((v1, v2, v3) => expect(MyClass(v1, v2, v3).myProperty, isTrue));
  });
}
```

You can also use `zip`, to create a new generator from existing ones on-the fly:
```dart
void main() {
  test('My property is always true', () {
    forAll((g1, g2, g3).zip)((value) => expect(MyClass(value.$1, value.$2, value.$3).myProperty, isTrue));
  });
}
```

## Custom generators.

### Combining existing generators

`GeneratorExtensions` defines a number of utilities to make it more convenient to create new custom 
generators based on 
the already existing default ones. Arguably the most important one being `zip`, to combine two 
existing generators into one, e.g.:
```dart
Generator<MyClass> myClass = (g1, g2, g3).zip.map((values) => MyClass(values.$1, values.$2, values.$3));
```

**Note**: `forAllX` and `zip` are currently only implemented for up to 8 values. Please open an 
issue if have need of more than that.

### Creating a generator from scratch

A generator for a type `T` (`Generator<T>`) is just a function that receives a `Random` instance and
a size, and returns a `Candidate`. A `Candidate` is essentially just a value, but a value that also
knows how to make itself less "complex", if possible. What complex means for a particular value is
really up to the author of the generator.

So, to create a brand new generator, just define such a function:

```dart
Candidate<MyClass> myClassGenerator(Random random, int Size) {
  // ... do some fun stuff here
  return Candidate(
    MyClass(), // The candidate value
    shrink: (size) { ... }, // Only needed if MyClass can be shrunk
    dispose: (myClass) { ... }, // Only needed if this generator allocates any resources that need to be disposed.
  );
}
```

Or, more conveniently, use the provided`generator` function:

```dart
Generator<MyClass> myClassGenerator = generator(
    (random, size) {
      // ... do some fun stuff here
      return MyClass(); 
    },
    shrink: (size) { ... }, // Only needed if MyClass can be shrunk
    dispose: (myClass) { ... }, // Only needed if this generator allocates any resources that need to be disposed.
  );
```

# Thanks

Huge thanks to [Marcel Garus](https://github.com/MarcelGarus) for creating the original Glados 
library, which Wheatley has drawn a lot of inspiration from.

# Contributing

Contributions welcome! Please open a PR or an issue if you have any suggestions or improvements.