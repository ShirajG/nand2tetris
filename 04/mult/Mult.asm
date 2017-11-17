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

@R2
M=0
@R0
D=M
@Number
M=D
@R1
D=M
@Multiplier
M=D

(Loop)
@Multiplier
D=M

// End if Multiplier 0
// Either we're multiplying by 0 or we're done
@End
D;JEQ

// Decrement Mutliplier
@Multiplier
D=D-1
M=D

// Add To Sum
@R2
D=M
@Number
D=D+M

// Update Sum
@R2
M=D

@Loop
0;JMP

(End)
@End
0;JMP

