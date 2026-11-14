---
name: thread-language
description: >-
  Essential language syntax, type system, ownership, automatic parallelization
  rules, and WSL compiler workflow for the Thread (.tr) programming language.
  Activate whenever reading, writing, editing, or compiling Thread code in this
  repository so compiler constraints and parallelization rules are never forgotten.
---

# Thread Language Rules & Parallelization Guide

Thread is a compiled language whose syntax is Swift-inspired, with **automatic compiler-proven parallelization** and **deterministic work-stealing execution**. Write clean sequential value-semantics code; `trc` proves loop independence and parallelizes safe loops and reductions automatically.

## 1. Compiler Location & WSL Workflow

In this environment on Windows, the Thread compiler (`trc`) runs inside WSL at `/home/leander/.local/bin/trc`.

- Always run `wsl` commands with simple command shapes (avoid chaining with `&&` / `;` or `$(...)`).
- Verify types and ownership:
  `wsl /home/leander/.local/bin/trc check`
- Build with full Release Tier-2 dependence analysis and inspect loop classification (`PARALLEL` vs `serial`):
  `wsl /home/leander/.local/bin/trc build --release --report`
- Run the optimized parallel binary:
  `wsl /home/leander/.local/bin/trc run --release`
- Update differential test snapshot and run tests (compares parallel build vs serial oracle):
  `wsl /home/leander/.local/bin/trc test --update-snapshot`
  `wsl /home/leander/.local/bin/trc test`

## 2. Core Lexical & Grammar Rules

- **No semicolons (`;`)**: Newlines terminate statements. Never end lines with `;`.
- **Parenthesized lists (`(...)`) and newlines**: Do NOT put the closing `)` of a function parameter list or argument list on its own line (`trc` treats newlines before `)` as `end of statement`). Keep parameter lists and function/constructor calls on single lines (or end the last argument with `)` on the same line).
- **Opening brace `{` on the same line**: `{` MUST appear on the same line as `fn`, `struct`, `enum`, `trait`, `implementation`, `if`, `else`, `for`, `while`, `match`, and `init` headers.
- **`for` loop pattern**: Thread v0.1 requires a bare identifier as the `for` loop variable (`for i in 0..<n`), not `_` (`for _ in ...` fails with `E0239`).
- **No intra-package imports**: `trc` automatically discovers and compiles all `.tr` files under `Sources/` (including subdirectories) together as one package. Never write `import` for your own project files. Only external/stdlib packages use `import` (e.g., `import Math`, `import IO`, `import Time`).
- **No mutable global state**: Top-level bindings must use `let` (never `var` at file scope).
- **No `class`, `extension`, `protocol`, `::`, `fallthrough`, `async`/`await`, locks, atomics, or threads**: Thread uses `struct`, `enum`, `trait`, `implementation`, and `.` for all member/path access.
- **No `static fn`**: Type-level static functions (`D354`) are not supported. Use `init(...)`, memberwise initializers `TypeName(field: value)`, free factory structs, or `EnumName.caseName(args)`.
- **No postfix `!` or `as!`**: Use `if let`, `guard let`, `??`, or `as?`.
- **`if` and `match` are expressions**: The final expression in a block is its value when not terminated by `return`.

## 3. Types, Operators & Methods

- **Primitive types (`lowerCamelCase`)**: `int` (i64), `uInt` (u64), `int8`..`int64`, `uInt8`..`uInt64`, `float` (f32), `double` (f64), `bool`, `char`, `void` / `()`.
- **Built-in generic/composite types (`PascalCase`)**: `String`, `Array<T>`, `Slice<T>`, `Dictionary<K, V>`, `Set<T>`, `Optional<T>` (`T?`), `Box<T>`, `Range`, `ClosedRange`.
- **Tuple types & destructuring (`E0274` / `E0083`)**: In type position, an unlabeled `(A, B)` parses as a function `(A, B) -> void`; label at least the first element (`(_0: A, _1: B)` or `(index: A, value: B)`) to write a tuple type. Read tuple values with destructuring `let (a, b) = pair` (tuples are not structs and do not support `.label` field access).
- **Explicit casts**: Use `as` for numeric conversions, e.g., `(index as double)`, `(x as int)`. Integer and float literals do not implicitly convert across types.
- **Numeric & binary operators**:
  - Arithmetic: `+`, `-`, `*`, `/`, `%`, compound `+=`, `-=`, `*=`, `/=`, `%=`, wrapping `&+`, `&-`, `&*` (for `int` hashing/RNG).
  - Bitwise: `&`, `|`, `^`, `~`, `<<`, `>>` and compound `&=`, `|=`, `^=`, `<<=`, `>>=`.
- **Ownership & `Array`/`String` growth (`E0259` / `E0125`)**:
  - `Array<T>.append`/`insert`/`remove` and `String.append` are only legal on an **owned** binding (a local `var` or a `consuming` parameter), NEVER through a borrowed `self` inside `mutating fn` or through an `exclusive` parameter (`V1-D5`). Inside `mutating fn`, construct a new local `Array` and assign `self.field = nextArray`, or use `consuming self -> Self`.
  - Borrowed parameters (`_ x: T`) cannot be assigned directly to a local `var` if `T` is non-`Copy` (`E0125`). Either accept `_ x: consuming T`, read elements individually, or provide a `.duplicate()` method on `T`.
- **Method receivers & labels**:
  - Non-mutating method: `fn normSquared(self) -> double`
  - Mutating method (MUST include `self` as first parameter): `mutating fn applyGate(self, _ gate: QuantumGate)`
  - Consuming method: `fn intoState(consuming self) -> QuantumState`
  - Argument labels follow Swift rules: `_ name: Type` omits the label at call sites; `name: Type` requires `name:` at call sites; `label name: Type` separates external label from internal name.
- **Initializers**:
  - A `struct` with NO explicit `init` and NO field default expressions gets an automatic memberwise initializer `TypeName(field1: v1, field2: v2)`.
  - Adding field defaults makes those parameters optional; adding a custom `init(...)` suppresses the automatic memberwise initializer.
  - Custom `init(...)` can be written directly inside `struct { ... }` or inside `implementation StructName { ... }`.
- **Operator traits**:
  - `Add`: `fn add(self, other: Self) -> Self`
  - `Sub`: `fn sub(self, other: Self) -> Self`
  - `Mul`: `fn mul(self, other: Self) -> Self`
  - `Div`: `fn div(self, other: Self) -> Self`
  - `Neg`: `fn neg(self) -> Self`
  - `Equatable`: `fn equals(self, other: Self) -> bool` (or empty `implementation Equatable for MyType {}` to auto-derive)
  - `Describable`: `fn describe(self) -> String` (used by `"\(val)"` interpolation and `print(val)`)
- **Formatting & Assertions (Prelude — no import needed)**:
  - `double.formatted(decimals: uInt) -> String` (e.g., `prob.formatted(decimals: 4)`)
  - `print(_ value)`, `assert(_ condition, _ message)`, `precondition(_ condition, _ message)`, `fatalError(_ message)`
  - `Array<T>(repeating: value, count: n)`, `arr.count`, `arr.append(item)`
- **Math Stdlib (`import Math`)**:
  - `sqrt`, `sin`, `cos`, `tan`, `exp`, `log`, `pow`, `floor`, `ceil`, `round`
  - Counter-based deterministic parallel RNG: `mix(_ seed: int, _ counter: int) -> int`, `randomInt(_ seed: int, _ counter: int, _ range: Range) -> int`, `randomBool(_ seed: int, _ counter: int) -> bool`

## 4. Automatic Parallelization Rules (`trc build --release --report`)

To ensure `trc` classifies simulation loops as **`PARALLEL`**:

1. **Always analyze/build in Release mode**: `trc build` (without `--release`) skips Tier-2 array subscript analysis (`tier2::subscript_conflict`) and only parallelizes folds. Always verify parallelism with `trc build --release --report`.
2. **Disjoint Array Writes (Out-of-place Map / Gather)**:
   - Write exclusively to `nextArray[i] = ...` where `nextArray` is a distinct array from any array being read (`self.amplitudes[partner]`).
   - Do **not** mutate an array in-place while reading arbitrary partner indices inside the same `for` loop. Allocate `var nextAmplitudes = Array<Complex>(repeating: zero, count: count)`, fill `nextAmplitudes[stateIndex]` in parallel, then swap `self.amplitudes = nextAmplitudes` after the loop.
3. **Scalar Folds**:
   - Standard reductions like `var total = 0.0; for i in 0..<n { total += expr }` or `total = total + expr` over `int` or `double` are recognized automatically as `PARALLEL` reduction trees.
4. **Componentwise Struct Folds (e.g. `Complex` sums)**:
   - For `sum = sum + items[i]` to classify as a `PARALLEL` `FoldKind::Componentwise` on a struct `S`:
     - `S` MUST declare only compatible numeric fields (`var real: double`, `var imag: double`), with **NO custom `init` and NO field default values**.
     - `implementation Add for S` MUST return `S(real: self.real + other.real, imag: self.imag + other.imag)` combining each field with its matching field via `+`.
5. **No `break`, `continue`, or early `return` in parallel `for` loops**:
   - Any `break`, `continue`, or early `return` inside a `for` loop forces `Serial` classification. Use pure conditional expressions or branchless accumulation inside the loop body instead.
6. **Inner loop bounds inside parallel `for` loops (`rustc E0434`)**:
   - When an inner `for` loop inside a `PARALLEL` outer loop indexes an array `arr[k]`, bound the inner loop directly by `0..<arr.count` (not a computed expression like `0..<(n - 1)`), so `trc` proves bounds safety statically without emitting a hoisted runtime guard that references outer SSA temporaries inside `fn __split`.
7. **Parallel Random Sampling (`Math.mix`)**:
   - Never share mutable RNG state across loop iterations. Pass the loop variable `shotIndex` as the counter to `mix(seed, shotIndex)` so each iteration computes its sample independently.
