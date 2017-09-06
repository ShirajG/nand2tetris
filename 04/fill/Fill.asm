// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed.
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.

// 8k Screen space
@8192
D=A
@screenSize
M=D
@SCREEN
D=D+A
@screenEnd
M=D

(Loop)
  @KBD
  D=M
  @Blackout
  D;JGT
  @Whiteout

(Whiteout)
  D=0
  @Toggle

(Blackout)
  D=-1
  @Toggle

(Toggle)
  @color
  M=D

  @SCREEN
  D=A
  @i
  M=D

(ScreenLoop)
  // Jump if index is 8k
  @i
  D=M
  @screenEnd
  D=M-D
  @Loop
  D;JEQ

  @color
  D=M

  @i
  A=M
  M=D
  D=A+1
  @i
  M=M+1

  @ScreenLoop
  0;JMP


