// Grover Search (6 qubits, target=43)
OPENQASM 2.0;
include "qelib1.inc";

qreg q[6];
creg c[6];

h q;

// Iteration 1
x q[2];
x q[4];
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q[2];
x q[4];
h q;
x q;
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q;
h q;

// Iteration 2
x q[2];
x q[4];
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q[2];
x q[4];
h q;
x q;
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q;
h q;

// Iteration 3
x q[2];
x q[4];
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q[2];
x q[4];
h q;
x q;
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q;
h q;

// Iteration 4
x q[2];
x q[4];
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q[2];
x q[4];
h q;
x q;
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q;
h q;

// Iteration 5
x q[2];
x q[4];
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q[2];
x q[4];
h q;
x q;
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q;
h q;

// Iteration 6
x q[2];
x q[4];
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q[2];
x q[4];
h q;
x q;
c5z q[0], q[1], q[2], q[3], q[4], q[5];
x q;
h q;

measure q -> c;
