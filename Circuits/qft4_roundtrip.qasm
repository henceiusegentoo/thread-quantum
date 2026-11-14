// 4-Qubit QFT Round-Trip on |1101>
OPENQASM 2.0;
include "qelib1.inc";

qreg q[4];
creg c[4];

// Prepare |1101> (state index 13)
x q[0];
x q[2];
x q[3];
barrier q;

// Forward 4-Qubit QFT
h q[3];
cp(pi/2) q[2], q[3];
cp(pi/4) q[1], q[3];
cp(pi/8) q[0], q[3];

h q[2];
cp(pi/2) q[1], q[2];
cp(pi/4) q[0], q[2];

h q[1];
cp(pi/2) q[0], q[1];

h q[0];

swap q[0], q[3];
swap q[1], q[2];
barrier q;

// Inverse 4-Qubit QFT
swap q[0], q[3];
swap q[1], q[2];

h q[0];

cp(-pi/2) q[0], q[1];
h q[1];

cp(-pi/4) q[0], q[2];
cp(-pi/2) q[1], q[2];
h q[2];

cp(-pi/8) q[0], q[3];
cp(-pi/4) q[1], q[3];
cp(-pi/2) q[2], q[3];
h q[3];

measure q -> c;
