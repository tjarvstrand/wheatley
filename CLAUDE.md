# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Wheatley is a Dart library for property-based testing (PBT), inspired by QuickCheck and Glados. It's a framework-agnostic library that generates test inputs and attempts to find the smallest failing case through shrinking.

## Common Commands

**Testing:**
```bash
dart test                    # Run all tests
dart test test/specific_test.dart  # Run a specific test file
dart test --coverage         # Run tests with coverage
```

**Code Quality:**
```bash
dart analyze                 # Static analysis
dart format .                # Format code
dart fix --apply             # Apply linting fixes
```

**Dependencies:**
```bash
dart pub get                 # Install dependencies
dart pub deps                # Show dependency tree
dart pub outdated            # Check for outdated packages
```

**Publishing:**
```bash
dart pub publish --dry-run   # Validate package for publishing
dart pub publish             # Publish to pub.dev
```

## Architecture

### Core Components

- **`lib/wheatley.dart`**: Main entry point exporting the public API, including `forAll` functions for 1-8 parameters
- **`lib/src/generator.dart`**: Core `Generator<T>` type and generator combinators
- **`lib/src/candidate.dart`**: `Candidate<T>` represents generated values with shrinking capability
- **`lib/src/explore_config.dart`**: Configuration for test exploration (iterations, size scaling, random seed)
- **`lib/src/generators.dart`**: Built-in generators for primitive types and collections

### Key Concepts

**Generator**: Function `(Random, int) -> Candidate<T>` that produces test values of increasing complexity
**Candidate**: Wrapper around generated values that knows how to shrink itself to simpler forms
**Shrinking**: Process of finding the minimal failing input when a property test fails
**forAll**: Main testing function that runs property checks with generated inputs

### Test Structure

- Tests use standard Dart `test` package
- Property tests written with `forAll(generator)((value) => expect(...))`
- Custom generators can be created by combining existing ones or implementing from scratch
- Shrinking automatically finds minimal failing cases for better debugging

## Development Notes

- The library is designed to be framework-agnostic (works with `test`, `flutter_test`, etc.)
- Coverage is tracked and tests should maintain high coverage
- Generator extensions provide convenient combinators (`.zip`, `.map`, etc.)
- Support for up to 8 combined generators via `forAll2` through `forAll8`