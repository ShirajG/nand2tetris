// Sys.asm
(Sys_Sys.init)
// push constant 4
@4
D=A;
@SP
A=M
M=D
@SP
M=M+1
// call Main.fibonacci 1
@ReturnAddress0
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
@Sys_Main.fibonacci
0;JMP
(ReturnAddress0)
// Label
(Sys_WHILE)

// Goto WHILE
@Sys_WHILE
0;JMP
