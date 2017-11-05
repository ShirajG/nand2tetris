// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/08/FunctionCalls/SimpleFunction/SimpleFunction.tst

load SimpleFunction.asm,
output-file SimpleFunction.out,
compare-to SimpleFunction.cmp,
output-list RAM[0]%D1.6.1 RAM[1]%D1.6.1 RAM[2]%D1.6.1
            RAM[3]%D1.6.1 RAM[4]%D1.6.1 RAM[310]%D1.6.1;

// Stack @317
set RAM[0] 317,
// LCL @317
set RAM[1] 317,
// ARG @310
set RAM[2] 310,
// THIS @3000
set RAM[3] 3000,
// THAT @4000
set RAM[4] 4000,
// ARG1 = 1234
set RAM[310] 1234,
// ARG2 = 37
set RAM[311] 37,
// ARG3 = 1000
set RAM[312] 1000,
// ARG4 = 305
set RAM[313] 305,
// ARG5 = 300
set RAM[314] 300,
// ARG6 = 3010
set RAM[315] 3010,
// ARG7 = 4010
set RAM[316] 4010,

repeat 300 {
  ticktock;
}

output;
