"".add STEXT nosplit size=52 args=0x10 locals=0x10 funcid=0x0 align=0x0
	0x0000 00000 (assembler.go:5)	TEXT	"".add(SB), NOSPLIT|ABIInternal, $16-16
	0x0000 00000 (assembler.go:5)	SUBQ	$16, SP
	0x0004 00004 (assembler.go:5)	MOVQ	BP, 8(SP)
	0x0009 00009 (assembler.go:5)	LEAQ	8(SP), BP
	0x000e 00014 (assembler.go:5)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x000e 00014 (assembler.go:5)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x000e 00014 (assembler.go:5)	FUNCDATA	$5, "".add.arginfo1(SB)
	0x000e 00014 (assembler.go:5)	MOVQ	AX, "".x+24(SP)
	0x0013 00019 (assembler.go:5)	MOVQ	BX, "".y+32(SP)
	0x0018 00024 (assembler.go:5)	MOVQ	$0, "".~r0(SP)
	0x0020 00032 (assembler.go:6)	MOVQ	$0, "".~r0(SP)
	0x0028 00040 (assembler.go:6)	XORL	AX, AX
	0x002a 00042 (assembler.go:6)	MOVQ	8(SP), BP
	0x002f 00047 (assembler.go:6)	ADDQ	$16, SP
	0x0033 00051 (assembler.go:6)	RET
	0x0000 48 83 ec 10 48 89 6c 24 08 48 8d 6c 24 08 48 89  H...H.l$.H.l$.H.
	0x0010 44 24 18 48 89 5c 24 20 48 c7 04 24 00 00 00 00  D$.H.\$ H..$....
	0x0020 48 c7 04 24 00 00 00 00 31 c0 48 8b 6c 24 08 48  H..$....1.H.l$.H
	0x0030 83 c4 10 c3                                      ....
"".main STEXT size=186 args=0x0 locals=0x60 funcid=0x0 align=0x0
	0x0000 00000 (assembler.go:9)	TEXT	"".main(SB), ABIInternal, $96-0
	0x0000 00000 (assembler.go:9)	CMPQ	SP, 16(R14)
	0x0004 00004 (assembler.go:9)	PCDATA	$0, $-2
	0x0004 00004 (assembler.go:9)	JLS	176
	0x000a 00010 (assembler.go:9)	PCDATA	$0, $-1
	0x000a 00010 (assembler.go:9)	SUBQ	$96, SP
	0x000e 00014 (assembler.go:9)	MOVQ	BP, 88(SP)
	0x0013 00019 (assembler.go:9)	LEAQ	88(SP), BP
	0x0018 00024 (assembler.go:9)	FUNCDATA	$0, gclocals·69c1753bd5f81501d95132d08af04464(SB)
	0x0018 00024 (assembler.go:9)	FUNCDATA	$1, gclocals·ce02aabaa73fa33b1b70f5cfd490303f(SB)
	0x0018 00024 (assembler.go:9)	FUNCDATA	$2, "".main.stkobj(SB)
	0x0018 00024 (assembler.go:10)	MOVL	$2, AX
	0x001d 00029 (assembler.go:10)	MOVL	$3, BX
	0x0022 00034 (assembler.go:10)	PCDATA	$1, $0
	0x0022 00034 (assembler.go:10)	CALL	"".add(SB)
	0x0027 00039 (assembler.go:10)	MOVQ	AX, ""..autotmp_0+24(SP)
	0x002c 00044 (assembler.go:10)	MOVUPS	X15, ""..autotmp_1+48(SP)
	0x0032 00050 (assembler.go:10)	LEAQ	""..autotmp_1+48(SP), CX
	0x0037 00055 (assembler.go:10)	MOVQ	CX, ""..autotmp_3+40(SP)
	0x003c 00060 (assembler.go:10)	MOVQ	""..autotmp_0+24(SP), AX
	0x0041 00065 (assembler.go:10)	PCDATA	$1, $1
	0x0041 00065 (assembler.go:10)	CALL	runtime.convT64(SB)
	0x0046 00070 (assembler.go:10)	MOVQ	AX, ""..autotmp_4+32(SP)
	0x004b 00075 (assembler.go:10)	MOVQ	""..autotmp_3+40(SP), CX
	0x0050 00080 (assembler.go:10)	TESTB	AL, (CX)
	0x0052 00082 (assembler.go:10)	LEAQ	type.int64(SB), DX
	0x0059 00089 (assembler.go:10)	MOVQ	DX, (CX)
	0x005c 00092 (assembler.go:10)	LEAQ	8(CX), DI
	0x0060 00096 (assembler.go:10)	PCDATA	$0, $-2
	0x0060 00096 (assembler.go:10)	CMPL	runtime.writeBarrier(SB), $0
	0x0067 00103 (assembler.go:10)	JEQ	107
	0x0069 00105 (assembler.go:10)	JMP	113
	0x006b 00107 (assembler.go:10)	MOVQ	AX, 8(CX)
	0x006f 00111 (assembler.go:10)	JMP	120
	0x0071 00113 (assembler.go:10)	CALL	runtime.gcWriteBarrier(SB)
	0x0076 00118 (assembler.go:10)	JMP	120
	0x0078 00120 (assembler.go:10)	PCDATA	$0, $-1
	0x0078 00120 (assembler.go:10)	MOVQ	""..autotmp_3+40(SP), AX
	0x007d 00125 (assembler.go:10)	TESTB	AL, (AX)
	0x007f 00127 (assembler.go:10)	NOP
	0x0080 00128 (assembler.go:10)	JMP	130
	0x0082 00130 (assembler.go:10)	MOVQ	AX, ""..autotmp_2+64(SP)
	0x0087 00135 (assembler.go:10)	MOVQ	$1, ""..autotmp_2+72(SP)
	0x0090 00144 (assembler.go:10)	MOVQ	$1, ""..autotmp_2+80(SP)
	0x0099 00153 (assembler.go:10)	MOVL	$1, BX
	0x009e 00158 (assembler.go:10)	MOVQ	BX, CX
	0x00a1 00161 (assembler.go:10)	PCDATA	$1, $0
	0x00a1 00161 (assembler.go:10)	CALL	fmt.Println(SB)
	0x00a6 00166 (assembler.go:11)	MOVQ	88(SP), BP
	0x00ab 00171 (assembler.go:11)	ADDQ	$96, SP
	0x00af 00175 (assembler.go:11)	RET
	0x00b0 00176 (assembler.go:11)	NOP
	0x00b0 00176 (assembler.go:9)	PCDATA	$1, $-1
	0x00b0 00176 (assembler.go:9)	PCDATA	$0, $-2
	0x00b0 00176 (assembler.go:9)	CALL	runtime.morestack_noctxt(SB)
	0x00b5 00181 (assembler.go:9)	PCDATA	$0, $-1
	0x00b5 00181 (assembler.go:9)	JMP	0
	0x0000 49 3b 66 10 0f 86 a6 00 00 00 48 83 ec 60 48 89  I;f.......H..`H.
	0x0010 6c 24 58 48 8d 6c 24 58 b8 02 00 00 00 bb 03 00  l$XH.l$X........
	0x0020 00 00 e8 00 00 00 00 48 89 44 24 18 44 0f 11 7c  .......H.D$.D..|
	0x0030 24 30 48 8d 4c 24 30 48 89 4c 24 28 48 8b 44 24  $0H.L$0H.L$(H.D$
	0x0040 18 e8 00 00 00 00 48 89 44 24 20 48 8b 4c 24 28  ......H.D$ H.L$(
	0x0050 84 01 48 8d 15 00 00 00 00 48 89 11 48 8d 79 08  ..H......H..H.y.
	0x0060 83 3d 00 00 00 00 00 74 02 eb 06 48 89 41 08 eb  .=.....t...H.A..
	0x0070 07 e8 00 00 00 00 eb 00 48 8b 44 24 28 84 00 90  ........H.D$(...
	0x0080 eb 00 48 89 44 24 40 48 c7 44 24 48 01 00 00 00  ..H.D$@H.D$H....
	0x0090 48 c7 44 24 50 01 00 00 00 bb 01 00 00 00 48 89  H.D$P.........H.
	0x00a0 d9 e8 00 00 00 00 48 8b 6c 24 58 48 83 c4 60 c3  ......H.l$XH..`.
	0x00b0 e8 00 00 00 00 e9 46 ff ff ff                    ......F...
	rel 3+0 t=23 type.int64+0
	rel 35+4 t=7 "".add+0
	rel 66+4 t=7 runtime.convT64+0
	rel 85+4 t=14 type.int64+0
	rel 98+4 t=14 runtime.writeBarrier+-1
	rel 114+4 t=7 runtime.gcWriteBarrier+0
	rel 162+4 t=7 fmt.Println+0
	rel 177+4 t=7 runtime.morestack_noctxt+0
go.cuinfo.packagename. SDWARFCUINFO dupok size=0
	0x0000 6d 61 69 6e                                      main
""..inittask SNOPTRDATA size=32
	0x0000 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00  ................
	0x0010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
	rel 24+8 t=1 fmt..inittask+0
runtime.gcbits.02 SRODATA dupok size=1
	0x0000 02                                               .
type..importpath.fmt. SRODATA dupok size=5
	0x0000 00 03 66 6d 74                                   ..fmt
gclocals·33cdeccccebe80329f1fdbee7f5874cb SRODATA dupok size=8
	0x0000 01 00 00 00 00 00 00 00                          ........
"".add.arginfo1 SRODATA static dupok size=5
	0x0000 00 08 08 08 ff                                   .....
gclocals·69c1753bd5f81501d95132d08af04464 SRODATA dupok size=8
	0x0000 02 00 00 00 00 00 00 00                          ........
gclocals·ce02aabaa73fa33b1b70f5cfd490303f SRODATA dupok size=10
	0x0000 02 00 00 00 07 00 00 00 00 02                    ..........
"".main.stkobj SRODATA static size=24
	0x0000 01 00 00 00 00 00 00 00 d8 ff ff ff 10 00 00 00  ................
	0x0010 10 00 00 00 00 00 00 00                          ........
	rel 20+4 t=5 runtime.gcbits.02+0
