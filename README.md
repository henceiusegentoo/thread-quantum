# ThreadQuantum

### All code of this project was created using generative AI

A parallel **state-vector quantum computing simulator** implemented in the **Thread** programming language using object-oriented value-semantics design and automatic compiler-proven parallelization which reads .qasm.

---

## 1. How Quantum Computing Simulators Work in General

Classical computers store $n$ bits in one definite state at a time (e.g., `010`). A quantum register of $n$ **qubits** can exist in a linear **superposition** of all $2^n$ classical bitstrings simultaneously.

### 1.1 State Vectors ($2^n$ Simultaneous Basis States)

An $n$-qubit quantum state $|\psi\rangle$ is represented in software as an array of $2^n$ complex numbers called **probability amplitudes**:

$$
|\psi\rangle = \sum_{k=0}^{2^n - 1} \alpha_k |k\rangle, \qquad \alpha_k = a_k + i b_k \in \mathbb{C}, \qquad \sum_{k=0}^{2^n - 1} |\alpha_k|^2 = 1
$$

- Each index $k \in \{0, \dots, 2^n - 1\}$ corresponds to one classical basis state $|b_{n-1}\dots b_1 b_0\rangle$ (for 2 qubits: $|00\rangle, |01\rangle, |10\rangle, |11\rangle$).
- Simulation always starts in the ground state $|\psi\rangle = |00\dots 0\rangle$, meaning amplitude $\alpha_0 = 1 + 0i$ and $\alpha_k = 0$ for all $k > 0$.
- The squared magnitude $|\alpha_k|^2 = \alpha_k \overline{\alpha_k} = a_k^2 + b_k^2$ is the probability of observing basis state $|k\rangle$ when measured (the **Born rule**). Because complex amplitudes carry phase as well as magnitude, distinct computation paths can **constructively** or **destructively interfere** before measurement.

### 1.2 Quantum Gates as Parallel State-Vector Transforms

A single-qubit quantum gate is a $2 \times 2$ **unitary** matrix $U$ ($U^\dagger U = I$, preserving total probability $1.0$). Instead of allocating an enormous $2^n \times 2^n$ dense matrix, a state-vector simulator applies gates **matrix-free** across all $2^n$ amplitudes:

- Pick target qubit bit $t$ (mask $2^t$) and optional control bitmask $M$.
- Every computational basis index $k$ that has bit $t = 0$ pairs with a unique partner $k_1 = k \mid 2^t$ whose bit $t = 1$ and all other bits match.
- For every index where all control bits in $M$ are `1` (`(k & M) == M`), the simulator transforms the 2-element amplitude pair $(\alpha_k, \alpha_{k_1})^T$ into $U (\alpha_k, \alpha_{k_1})^T$:

$$
\begin{pmatrix} \alpha'_k \\ \alpha'_{k_1} \end{pmatrix} =
\begin{pmatrix} u_{00} & u_{01} \\ u_{10} & u_{11} \end{pmatrix}
\begin{pmatrix} \alpha_k \\ \alpha_{k_1} \end{pmatrix}
$$

- All $2^{n-1}$ butterfly pairs are **mutually disjoint**—updating index $k$ and its partner $k_1$ never collides with another pair, making state-vector gate application naturally data-parallel across all $2^n$ basis states at once.

### 1.3 Common Gates & Quantum Effects

| Gate / Operation | Effect |
| --- | --- |
| **Hadamard (`H`)** | Maps $\|0\rangle \mapsto \frac{\|0\rangle + \|1\rangle}{\sqrt{2}}$, placing a qubit into an equal superposition of $0$ and $1$. |
| **Pauli (`X`, `Y`, `Z`)** | `X` flips bit $\|0\rangle \leftrightarrow \|1\rangle$; `Z` flips the phase of $\|1\rangle \mapsto -\|1\rangle$; `Y = iXZ`. |
| **Phase & Rotations (`S`, `T`, `P`, `RX`, `RY`, `RZ`)** | Rotate state phase or Bloch sphere orientation by angle $\theta$. |
| **Controlled Gates (`CNOT`/`CX`, `CZ`, `CP`, `CCX`/Toffoli, `MCZ`)** | Apply a gate only on basis states where all control qubits equal `1`, creating **entanglement** across qubits. |
| **Permutation (`SWAP`, `CSWAP`/Fredkin)** | Exchanges two target qubit bits in every basis index (optionally controlled). |
| **Phase Oracle** | Flips the sign of a marked target basis state $\alpha_m \mapsto -\alpha_m$ in one superposition step. |

### 1.4 Measurement & Collapse

When a quantum register is measured, a classical basis state $|k\rangle$ is sampled according to the probability distribution $P(k) = |\alpha_k|^2$ (via the cumulative distribution function over $0 \dots 2^n - 1$). In projective collapse, the state vector resets to $\alpha_k = 1$ and $\alpha_{j \neq k} = 0$. Repeated independent executions (**shots**) produce an empirical histogram approximating the quantum probability distribution.

---

## 2. Automatic Parallelization in Thread

`ThreadQuantum` is written in ordinary value-semantics Thread code with **no manual threads, locks, or atomics**. When built with `--release`, the Thread compiler (`trc`) statically proves loop independence and automatically parallelizes the core quantum kernels over `__shuttle` worker tasks:

- **Out-of-place state-vector evolution**: `QuantumState.applyUnitary`, `QuantumState.applySwap`, and `QuantumState.applyPhaseOracle` read from `self.amplitudes` while writing disjoint indices into a fresh `nextAmplitudes` array before swapping `self.amplitudes = nextAmplitudes`.
- **Parallel reductions (`Complex` & `double`)**: `QuantumState.innerProduct` uses componentwise `Complex` addition (`implementation Add for Complex` on bare numeric fields) for parallel reduction trees; `totalProbability`, `qubitProbabilityOne`, `expectationZ`, and `probabilities` reduce and map across all $2^n$ basis states in parallel.
- **Parallel shot sampling**: `QuantumSimulator.buildCdf`, `sampleShots`, `aggregateHistogram`, and `collapseProjective` classify as `PARALLEL` by using stateless counter-based hashing (`Math.mix(seed, shotIndex)`) rather than mutable shared RNG state.

Verified `PARALLEL` loops in `trc build --release --report`:
- `QuantumState`: `applyUnitary`, `applySwap`, `applyPhaseOracle`, `probabilities`, `totalProbability`, `qubitProbabilityOne`, `expectationZ`, `innerProduct` (both loops), `mostLikelyState`, `duplicate`, `formatBasisKet`, `describeSignificantStates`
- `QuantumSimulator`: `buildCdf`, `sampleShots` (outer & inner loops), `aggregateHistogram`, `collapseProjective`
- `MeasurementResult`: `dominantStateIndex`, `formatBasisKet`, `formatHistogram`
- `QuantumCircuit`: `addGate`

---

## 3. OOP Architecture (One File Per Type)

Every type lives in its own matching `.tr` file under `Sources/` with `PascalCase` types/traits, `camelCase` methods/variables/cases, encapsulated methods inside `implementation` blocks, and package-internal visibility:

| File | Type | Responsibility |
| --- | --- | --- |
| [`Sources/Complex.tr`](Sources/Complex.tr) | `struct Complex` | Complex arithmetic (`+`, `-`, `*`, unary `-`), conjugate, squared magnitude, approximate equality, `Describable`. |
| [`Sources/GateKind.tr`](Sources/GateKind.tr) | `enum GateKind` | Gate taxonomy (`identity`, `hadamard`, `pauliX`, `pauliY`, `pauliZ`, `phaseS`, `phaseT`, `phaseShift`, `rotateX`, `rotateY`, `rotateZ`, `swap`, `phaseOracle`) and $2 \times 2$ unitary matrix coefficients. |
| [`Sources/QuantumGate.tr`](Sources/QuantumGate.tr) | `struct QuantumGate` | Represents a single, controlled, multi-controlled, swap, or oracle gate (`controlMask`, target qubits, angle). |
| [`Sources/GateFactory.tr`](Sources/GateFactory.tr) | `struct GateFactory` | Factory methods constructing gates cleanly (`hadamard`, `cnot`, `toffoli`, `multiControlledX`, `multiControlledZ`, `fredkin`, `phaseOracle`, etc.). |
| [`Sources/QuantumState.tr`](Sources/QuantumState.tr) | `struct QuantumState` | Holds the $2^n$ complex state vector and parallel evolution, inner-product/fidelity, marginal probability, and ket formatting methods. |
| [`Sources/MeasurementResult.tr`](Sources/MeasurementResult.tr) | `struct MeasurementResult` | Stores single-shot collapse outcome and multi-shot histogram counts (`countForState`, `empiricalProbability`, `dominantStateIndex`, `formatHistogram`). |
| [`Sources/QuantumCircuit.tr`](Sources/QuantumCircuit.tr) | `struct QuantumCircuit` | Mutable gate sequence builder (`hadamard`, `cnot`, `applyQft`, `applyInverseQft`, `applyGroverDiffusion`, `applyMaj`, `applyUma`, `applyRippleCarryAdder`, etc.) and `execute()` / `executeOn()`. |
| [`Sources/QuantumSimulator.tr`](Sources/QuantumSimulator.tr) | `struct QuantumSimulator` | Parallel Born-rule measurement, projective collapse, and built-in algorithms (Bell, GHZ, QFT, Deutsch-Jozsa, Grover, Cuccaro quantum adder). |
| [`Sources/CircuitLoader.tr`](Sources/CircuitLoader.tr) | `struct CircuitLoader` | OpenQASM 2.0 (`.qasm`) parser reading circuit files via `IO.readFile` into `QuantumCircuit` instances. |
| [`Sources/main.tr`](Sources/main.tr) | `fn main(args: Array<String>)` | Runs CLI `.qasm` file(s) if provided, or runs all 5 quantum algorithm benchmarks and verifies `Circuits/*.qasm` when invoked with no arguments. |

Project-local Thread language and style skills live in:
- [`.agents/skills/thread-language/SKILL.md`](.agents/skills/thread-language/SKILL.md)
- [`.agents/skills/thread-coding-conventions/SKILL.md`](.agents/skills/thread-coding-conventions/SKILL.md)

---

## 4. OpenQASM 2.0 (`.qasm`) Support

`CircuitLoader` reads standard OpenQASM 2.0 circuit files:

- **Header & declarations**: `OPENQASM 2.0;`, `include "qelib1.inc";`, `qreg q[n];` ($1 \le n \le 20$), `creg c[n];`, `//` or `#` comments (a leading comment line becomes the circuit display name).
- **Single-qubit gates** (indexed `q[i];` or register-broadcast `q;`): `i` / `id`, `h`, `x`, `y`, `z`, `s`, `sdg`, `t`, `tdg`, `p(theta)` / `u1(theta)`, `rx(theta)`, `ry(theta)`, `rz(theta)`, `u2(phi, lambda)`, `u3(theta, phi, lambda)` / `u(theta, phi, lambda)`.
- **Angle expressions**: Floating-point literals as well as symbolic `pi` expressions (`pi/2`, `-pi/4`, `3*pi/8`).
- **Controlled & multi-qubit gates**: `cx` / `cnot`, `cz`, `cp(theta)` / `cu1(theta)`, `ccx` / `toffoli`, `ccz`, `c3z`, `c4z`, `c5z`, `mcx`, `mcz`, `swap`, `cswap` / `fredkin`.
- **Execution directives & conveniences**: `barrier ...;`, `measure ... -> ...;`, plus optional macro helpers `qft q;`, `iqft q;`, `diffusion q;`, `oracle(k) q;`.

### Included OpenQASM Sample Circuits (`Circuits/`)

1. [`Circuits/bell.qasm`](Circuits/bell.qasm) — 2-qubit Bell state $|\Phi^+\rangle = \frac{|00\rangle + |11\rangle}{\sqrt{2}}$.
2. [`Circuits/ghz5.qasm`](Circuits/ghz5.qasm) — 5-qubit GHZ cat state across 32 basis states.
3. [`Circuits/qft4_roundtrip.qasm`](Circuits/qft4_roundtrip.qasm) — 4-qubit Quantum Fourier Transform + Inverse QFT round-trip restoring $|1101\rangle$ ($|13\rangle$).
4. [`Circuits/deutsch_jozsa_balanced.qasm`](Circuits/deutsch_jozsa_balanced.qasm) — 5-qubit (4-bit parity oracle + ancilla) Deutsch-Jozsa algorithm.
5. [`Circuits/grover6_target43.qasm`](Circuits/grover6_target43.qasm) — 6-qubit Grover search (64 states, 6 iterations) amplifying $|101011\rangle$ (state `43`) to `99.66%` probability.
6. [`Circuits/adder4_11_plus_13.qasm`](Circuits/adder4_11_plus_13.qasm) — 10-qubit ($1024$-state) Cuccaro et al. (2004) in-place ripple-carry quantum adder (`MAJ` + `UMA`) computing $11 + 13 = 24$.

---

## 5. Comparison with IBM Qiskit

- **1:1 mathematical parity with Qiskit `Statevector`**: `ThreadQuantum` uses Qiskit's little-endian qubit convention (`q[0]` is the least-significant bit in $|q_{n-1}\dots q_0\rangle$) and computes exact complex unitary amplitudes, Born-rule probabilities $|\alpha_k|^2$, marginal probabilities, $\langle Z_q\rangle$, and state fidelities $|\langle\psi|\phi\rangle|^2$ matching Qiskit's noiseless `Statevector` simulator.
- **Scope differences vs. the full Qiskit SDK / Aer**: `ThreadQuantum` focuses on pure state-vector simulation (up to 20 qubits) with flat single-`qreg` OpenQASM 2.0 input and end-of-circuit projective measurement; it does not implement density matrices, hardware noise models, Clifford stabilizer or MPS backends, mid-circuit `measure`/`reset`/classical conditionals, custom OpenQASM `gate` subroutine definitions, or hardware transpiler routing.

---

## 6. Building, Running & Testing (WSL)

In WSL from `/mnt/d/Programmieren/Thread/thread-quantum`:

```bash
# 1. Type-check and ownership-check all files
trc check

# 2. Build the release binary and print the compiler parallelism report
trc build --release --report

# 3. Run the built-in algorithm benchmarks & OpenQASM verification suite
trc run --release

# 4. Execute any custom OpenQASM 2.0 (.qasm) file with the compiled binary
.build/ThreadQuantum_0.1.0_release Circuits/adder4_11_plus_13.qasm

# 5. Run differential tests (compares parallel analysis build against serial oracle) & snapshot checks
trc test
```
