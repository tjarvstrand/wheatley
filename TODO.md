# Wheatley TODO - Missing PBT Features

This document outlines missing features compared to mature property-based testing libraries like QuickCheck, Hypothesis, fast-check, and FsCheck.

## High Priority (Core Functionality)

### Recursive Generators
- [ ] **Size-aware recursion**: Generators that reduce size parameter to prevent infinite recursion
- [ ] **Lazy evaluation**: `lazy()` combinator to delay recursive generator evaluation
- [ ] **Built-in recursive types**: Binary trees, general trees, graphs, nested lists
- [ ] **JSON generators**: Arbitrary nested JSON objects and arrays
- [ ] **AST generators**: For testing parsers and compilers

**Example use case**: Testing tree algorithms, parsers, serialization of nested data structures

### Integrated Shrinking
- [ ] **Generator-aware shrinking**: Shrinking logic built into generator creation, not post-hoc
- [ ] **Invariant preservation**: Shrinking maintains data relationships and constraints
- [ ] **Structural shrinking**: Understands data structure relationships during shrinking
- [ ] **Targeted shrinking**: Shrinking toward "interesting" values (edge cases, nulls, empty strings)
- [ ] **Efficient exploration**: Better shrinking strategies that understand data semantics

**Current problem**: Shrinking happens after generation, leading to invalid intermediate states and inefficient exploration.

### Statistical Analysis
- [ ] **Test case distribution reporting**: Show what kinds of inputs were generated
- [ ] **Coverage analysis**: What portion of input space was exercised
- [ ] **Bias detection**: Identify when generators favor certain values unexpectedly
- [ ] **Edge case tracking**: Automatic identification and reporting of boundary conditions
- [ ] **Quality metrics**: Measure generator effectiveness and input diversity

**Example output**: "Generated 67% positive numbers, 23% zeros, 10% negative. Covered number ranges: [-1000, 2000]"

### Specialized Generators
- [ ] **Network types**: IP addresses, URLs, email addresses, domain names
- [ ] **Identifiers**: UUIDs, tokens, hashes, API keys
- [ ] **File system**: File paths, directory structures, MIME types
- [ ] **Geographic**: Coordinates, addresses, postal codes  
- [ ] **Text patterns**: Phone numbers, credit cards, social security numbers
- [ ] **Binary data**: Byte arrays, Base64 encoded data
- [ ] **Time patterns**: Cron expressions, time ranges, recurring schedules

## Medium Priority (Enhanced Usability)

### Model-Based Testing
- [ ] **State machine testing**: Generate sequences of valid state transitions
- [ ] **Stateful property testing**: Test sequences of operations on stateful objects
- [ ] **Command generators**: Generate sequences of method calls/API requests
- [ ] **Invariant checking**: Verify invariants hold throughout state sequences
- [ ] **Parallel execution**: Test concurrent operations on shared state

**Example**: Testing a bank account with deposit/withdraw/transfer operations maintaining balance invariants.

### Advanced Configuration
- [ ] **Distribution control**: Specify probability distributions for generators
- [ ] **Edge case bias**: Control how often edge cases (nulls, zeros, empty collections) appear
- [ ] **Reproducible seeds**: Better seed management for deterministic test replay
- [ ] **Progressive complexity**: More sophisticated size scaling strategies
- [ ] **Conditional generation**: Different strategies based on previously generated values
- [ ] **Performance tuning**: Timeout controls, memory limits

### Property Combinators
- [ ] **Logical operators**: `property.and(other)`, `property.or(other)`, `property.implies(condition)`
- [ ] **Assumption handling**: `assume(condition)` to skip invalid test cases
- [ ] **Property composition**: Combine multiple properties into test suites
- [ ] **Conditional properties**: Properties that only apply under certain conditions

**Example**: `property1.and(property2).implies(precondition)`

### Test Case Persistence
- [ ] **Failure database**: Store and replay previous failing test cases
- [ ] **Regression testing**: Automatically re-run known failing cases
- [ ] **Example databases**: Collect interesting test cases for future runs
- [ ] **Seed history**: Track which seeds produced failures

## Lower Priority (Nice to Have)

### Schema Integration
- [ ] **JSON Schema**: Generate data from JSON Schema definitions
- [ ] **Protocol Buffers**: Generate protobuf messages
- [ ] **OpenAPI**: Generate API requests/responses from OpenAPI specs
- [ ] **Database schemas**: Generate database-compatible data
- [ ] **XML Schema**: Generate valid XML documents

### Advanced Testing Patterns
- [ ] **Metamorphic testing**: Test relationships between function outputs
- [ ] **Differential testing**: Compare multiple implementations
- [ ] **Performance properties**: Test performance characteristics (time, memory)
- [ ] **Contract testing**: Pre/post condition verification
- [ ] **Round-trip testing**: Built-in serialize/deserialize testing

### Performance and Scalability
- [ ] **Parallel test execution**: Run property tests in parallel
- [ ] **Streaming generators**: Handle large datasets without memory limits  
- [ ] **Memory efficiency**: Better memory management for large test suites
- [ ] **Incremental testing**: Only re-run tests affected by code changes
- [ ] **Lazy evaluation**: Generate values on-demand

### Developer Experience
- [ ] **Better error messages**: More informative failure reporting
- [ ] **IDE integration**: Better debugging and visualization tools
- [ ] **Test case classification**: Automatic categorization of generated inputs
- [ ] **Progress reporting**: Show test progress for long-running property tests
- [ ] **Interactive debugging**: Step through shrinking process

## Implementation Notes

### Recursive Generators Implementation
```dart
// Potential API for recursive generators
Generator<BinaryTree<T>> binaryTree<T>(Generator<T> valueGen) {
  return sized((size) {
    if (size <= 0) {
      return valueGen.map((v) => Leaf(v));
    } else {
      return oneOf([
        valueGen.map((v) => Leaf(v)),
        (valueGen, 
         binaryTree(valueGen).resize(size ~/ 2), 
         binaryTree(valueGen).resize(size ~/ 2)
        ).zip.map((tuple) => Branch(tuple.$1, tuple.$2, tuple.$3))
      ]);
    }
  });
}
```

### Integrated Shrinking Implementation
```dart
// Potential API for integrated shrinking
Generator<Person> person() {
  return generate((context) {
    final age = context.draw(intRange(0, 100));
    final validPermissions = age >= 18 
        ? ["user", "guest", "admin"]
        : ["user", "guest"];
    final permissions = context.draw(oneOf(validPermissions));
    
    return Person(age: age, permissions: permissions);
    // Shrinking automatically maintains age/permission relationships
  });
}
```

### Statistical Reporting Implementation
```dart
// Potential API for statistics
final stats = forAll(myGenerator, config: ExploreConfig(
  collectStats: true,
  runs: 1000,
))((value) => myProperty(value));

print(stats.distribution); // Shows value distribution
print(stats.coverage);     // Shows input space coverage  
print(stats.edgeCases);    // Lists detected edge cases
```

## References

- **QuickCheck**: Original Haskell PBT library - [manual](https://www.cse.chalmers.se/~rjmh/QuickCheck/manual.html)
- **Hypothesis**: Python PBT with advanced shrinking - [docs](https://hypothesis.readthedocs.io/)
- **fast-check**: JavaScript PBT library - [docs](https://fast-check.dev/)
- **FsCheck**: F# PBT library - [docs](https://fscheck.github.io/FsCheck/)
- **ScalaCheck**: Scala PBT library - [docs](https://scalacheck.org/)
- **Glados**: Predecessor Dart PBT library - [pub.dev](https://pub.dev/packages/glados)