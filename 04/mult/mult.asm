// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)

// Put your code here.

// @Number = RAM[0]
// @Sum = 0
// @Multiplier = RAM[1]
//  While @Multiplier > 0
//    @Sum = Sum + Number
//    @Multiplier = @Multiplier - 1
// END

@Sum
M=0
@R0
D=M
@Number
M=D
@R1
D=M
@Multiplier
M=D
@Loop
@End


(Loop)



(End)
@11
0;JMP

