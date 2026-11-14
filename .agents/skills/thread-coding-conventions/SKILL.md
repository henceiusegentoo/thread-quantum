---
name: thread-coding-conventions
description: >-
  Project-specific OOP architecture, Java-style one-file-per-type layout, and
  naming conventions (PascalCase types/traits, camelCase variables/methods) for
  the thread-quantum repository. Activate before creating or modifying source
  files under Sources/.
---

# ThreadQuantum Coding Conventions

Strictly follow these four project rules for every `.tr` file in `Sources/`:

1. **`PascalCase` for Types and Traits**
   - Every user-defined `struct`, `enum`, and `trait` name MUST be `PascalCase` (e.g., `Complex`, `GateKind`, `QuantumGate`, `GateFactory`, `QuantumState`, `QuantumCircuit`, `MeasurementResult`, `QuantumSimulator`).
   - Built-in primitive scalars stay `lowerCamelCase` (`int`, `uInt`, `double`, `bool`, `char`, `void`) and built-in generics stay `PascalCase` (`Array`, `String`, `Optional`).

2. **`camelCase` for Variables, Fields, Cases, Parameters, and Methods**
   - All local variables (`let`, `var`), struct fields, enum cases (`case pauliX`), method names (`applyUnitary`, `normSquared`, `buildBellCircuit`), and parameters (`targetQubit`, `stateIndex`) MUST be `camelCase`.

3. **OOP-Oriented Design (Methods Encapsulated in Structs/Enums)**
   - Encapsulate domain logic inside `implementation TypeName { ... }` and `implementation TraitName for TypeName { ... }`.
   - Since Thread does not have `static fn`, group construction helpers either in `init(...)` on the target type or on a dedicated factory struct (`GateFactory`).
   - Avoid top-level free functions in `Sources/` except `fn main()` in `Sources/main.tr` (and `@test` functions if added).

4. **One File Per Type (Java-Style)**
   - Every `struct`, `enum`, or `trait` MUST reside in its own file under `Sources/` whose filename exactly matches the type name with the `.tr` extension:
     - `Sources/Complex.tr` -> `struct Complex`
     - `Sources/GateKind.tr` -> `enum GateKind`
     - `Sources/QuantumGate.tr` -> `struct QuantumGate`
     - `Sources/GateFactory.tr` -> `struct GateFactory`
     - `Sources/QuantumState.tr` -> `struct QuantumState`
     - `Sources/MeasurementResult.tr` -> `struct MeasurementResult`
     - `Sources/QuantumCircuit.tr` -> `struct QuantumCircuit`
     - `Sources/QuantumSimulator.tr` -> `struct QuantumSimulator`
     - `Sources/CircuitLoader.tr` -> `struct CircuitLoader`
     - `Sources/main.tr` -> `fn main()` entry point
   - Never declare multiple structs, enums, or traits in the same `.tr` file.

5. **Package-Internal Visibility (Omit `public`)**
   - Because every `.tr` file under `Sources/` is compiled into the same `ThreadQuantum` package automatically, omit unnecessary `public` visibility modifiers on package-internal structs, enums, traits, fields, and methods.
