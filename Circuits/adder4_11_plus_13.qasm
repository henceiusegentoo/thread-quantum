// 4-Bit Quantum Ripple-Carry Adder (11 + 13 = 24)
OPENQASM 2.0;
include "qelib1.inc";

qreg q[10];
creg c[10];

// Encode A = 11 (0b1011) on q[0..3]
x q[0];
x q[1];
x q[3];

// Encode B = 13 (0b1101) on q[4..7]
x q[4];
x q[6];
x q[7];
barrier q;

// Forward MAJ ripple: MAJ(c_in, b_i, a_i)
// Bit 0: MAJ(q[9], q[4], q[0])
cx q[0], q[4];
cx q[0], q[9];
ccx q[9], q[4], q[0];

// Bit 1: MAJ(q[0], q[5], q[1])
cx q[1], q[5];
cx q[1], q[0];
ccx q[0], q[5], q[1];

// Bit 2: MAJ(q[1], q[6], q[2])
cx q[2], q[6];
cx q[2], q[1];
ccx q[1], q[6], q[2];

// Bit 3: MAJ(q[2], q[7], q[3])
cx q[3], q[7];
cx q[3], q[2];
ccx q[2], q[7], q[3];

// Copy carry-out into q[8]
cx q[3], q[8];

// Reverse UMA ripple: UMA(c_in, b_i, a_i)
// Bit 3: UMA(q[2], q[7], q[3])
ccx q[2], q[7], q[3];
cx q[3], q[2];
cx q[2], q[7];

// Bit 2: UMA(q[1], q[6], q[2])
ccx q[1], q[6], q[2];
cx q[2], q[1];
cx q[1], q[6];

// Bit 1: UMA(q[0], q[5], q[1])
ccx q[0], q[5], q[1];
cx q[1], q[0];
cx q[0], q[5];

// Bit 0: UMA(q[9], q[4], q[0])
ccx q[9], q[4], q[0];
cx q[0], q[9];
cx q[9], q[4];

measure q -> c;
