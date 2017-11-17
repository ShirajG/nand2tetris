// Main.asm
(Main_Main.fibonacci)
// push argument 0
@ARG
D=M
@0
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push constant 2
@2
D=A;
@SP
A=M
M=D
@SP
M=M+1
// lt
@SP
M=M-1
A=M
D=M
@R13
M=D
@SP
A=M-1
D=M
@R13
D=D-M
@GtTrueJump1
D;JLT
@GtFalseJump1
0;JMP
(GtTrueJump1)
@SP
A=M-1
M=-1
@GtEndJump1
0;JMP
(GtFalseJump1)
@SP
A=M-1
M=0
@GtEndJump1
0;JMP
(GtEndJump1)
// If-goto IF_TRUE
@SP
M=M-1
A=M
D=M
@Main_IF_TRUE
D;JNE
// Goto IF_FALSE
@Main_IF_FALSE
0;JMP
// Label
(Main_IF_TRUE)

// push argument 0
@ARG
D=M
@0
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// return
@LCL
D=M
@R7
M=D
@R6
M=D
M=M-1
M=M-1
M=M-1
M=M-1
M=M-1
A=M
D=M
@R6
M=D
@SP
M=M-1
A=M
D=M
@ARG
A=M
M=D
@ARG
D=M
@SP
M=D+1
@R7
D=M
D=D-1
A=D
D=M
@THAT
M=D
@R7
D=M
D=D-1
D=D-1
A=D
D=M
@THIS
M=D
@R7
D=M
D=D-1
D=D-1
D=D-1
A=D
D=M
@ARG
M=D
@R7
D=M
D=D-1
D=D-1
D=D-1
D=D-1
A=D
D=M
@LCL
M=D
@R6
A=M
0;JMP
// Label
(Main_IF_FALSE)

// push argument 0
@ARG
D=M
@0
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push constant 2
@2
D=A;
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
//Sub
@SP
A=M;
D=M;
A=A-1;
D=M-D;
M=D;
// call Main.fibonacci 1
@ReturnAddress1
D=A
@SP
A=M
M=D
@SP
M=M+1
@LCL
D=M
@SP
A=M
M=D
@SP
M=M+1
@ARG
D=M
@SP
A=M
M=D
@SP
M=M+1
@THIS
D=M
@SP
A=M
M=D
@SP
M=M+1
@THAT
D=M
@SP
A=M
M=D
@SP
M=M+1
D=M
D=D-1
D=D-1
D=D-1
D=D-1
D=D-1
D=D-1
@ARG
M=D
@SP
D=M
@LCL
M=D
@Main_Main.fibonacci
0;JMP
(ReturnAddress1)
// push argument 0
@ARG
D=M
@0
D=D+A
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
// push constant 1
@1
D=A;
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
//Sub
@SP
A=M;
D=M;
A=A-1;
D=M-D;
M=D;
// call Main.fibonacci 1
@ReturnAddress2
D=A
@SP
A=M
M=D
@SP
M=M+1
@LCL
D=M
@SP
A=M
M=D
@SP
M=M+1
@ARG
D=M
@SP
A=M
M=D
@SP
M=M+1
@THIS
D=M
@SP
A=M
M=D
@SP
M=M+1
@THAT
D=M
@SP
A=M
M=D
@SP
M=M+1
D=M
D=D-1
D=D-1
D=D-1
D=D-1
D=D-1
D=D-1
@ARG
M=D
@SP
D=M
@LCL
M=D
@Main_Main.fibonacci
0;JMP
(ReturnAddress2)
@SP
M=M-1
//Add
@SP
A=M;
D=M;
A=A-1;
D=D+M;
M=D;
// return
@LCL
D=M
@R7
M=D
@R6
M=D
M=M-1
M=M-1
M=M-1
M=M-1
M=M-1
A=M
D=M
@R6
M=D
@SP
M=M-1
A=M
D=M
@ARG
A=M
M=D
@ARG
D=M
@SP
M=D+1
@R7
D=M
D=D-1
A=D
D=M
@THAT
M=D
@R7
D=M
D=D-1
D=D-1
A=D
D=M
@THIS
M=D
@R7
D=M
D=D-1
D=D-1
D=D-1
A=D
D=M
@ARG
M=D
@R7
D=M
D=D-1
D=D-1
D=D-1
D=D-1
A=D
D=M
@LCL
M=D
@R6
A=M
0;JMP
