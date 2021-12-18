"".add STEXT nosplit size=71 args=0x8 locals=0x10 funcid=0x0
	0x0000 00000 (tutorial01.go:3)	TEXT	"".add(SB), NOSPLIT|ABIInternal, $16-8
	0x0000 00000 (tutorial01.go:3)	SUBQ	$16, SP
	0x0004 00004 (tutorial01.go:3)	MOVQ	BP, 8(SP)
	0x0009 00009 (tutorial01.go:3)	LEAQ	8(SP), BP
	0x000e 00014 (tutorial01.go:3)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x000e 00014 (tutorial01.go:3)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x000e 00014 (tutorial01.go:3)	FUNCDATA	$5, "".add.arginfo1(SB)
	0x000e 00014 (tutorial01.go:3)	MOVL	AX, "".a+24(SP)
	0x0012 00018 (tutorial01.go:3)	MOVL	BX, "".b+28(SP)
	0x0016 00022 (tutorial01.go:3)	MOVL	$0, "".~r2+4(SP)
	0x001e 00030 (tutorial01.go:3)	MOVB	$0, "".~r3+3(SP)
	0x0023 00035 (tutorial01.go:4)	MOVL	"".a+24(SP), CX
	0x0027 00039 (tutorial01.go:4)	ADDL	"".b+28(SP), CX
	0x002b 00043 (tutorial01.go:4)	MOVL	CX, "".~r2+4(SP)
	0x002f 00047 (tutorial01.go:4)	MOVB	$1, "".~r3+3(SP)
	0x0034 00052 (tutorial01.go:4)	MOVL	"".~r2+4(SP), AX
	0x0038 00056 (tutorial01.go:4)	MOVL	$1, BX
	0x003d 00061 (tutorial01.go:4)	MOVQ	8(SP), BP
	0x0042 00066 (tutorial01.go:4)	ADDQ	$16, SP
	0x0046 00070 (tutorial01.go:4)	RET
	0x0000 48 83 ec 10 48 89 6c 24 08 48 8d 6c 24 08 89 44  H...H.l$.H.l$..D
	0x0010 24 18 89 5c 24 1c c7 44 24 04 00 00 00 00 c6 44  $..\$..D$......D
	0x0020 24 03 00 8b 4c 24 18 03 4c 24 1c 89 4c 24 04 c6  $...L$..L$..L$..
	0x0030 44 24 03 01 8b 44 24 04 bb 01 00 00 00 48 8b 6c  D$...D$......H.l
	0x0040 24 08 48 83 c4 10 c3                             $.H....
"".main STEXT size=54 args=0x0 locals=0x10 funcid=0x0
	0x0000 00000 (tutorial01.go:6)	TEXT	"".main(SB), ABIInternal, $16-0
	0x0000 00000 (tutorial01.go:6)	CMPQ	SP, 16(R14)
	0x0004 00004 (tutorial01.go:6)	PCDATA	$0, $-2
	0x0004 00004 (tutorial01.go:6)	JLS	47
	0x0006 00006 (tutorial01.go:6)	PCDATA	$0, $-1
	0x0006 00006 (tutorial01.go:6)	SUBQ	$16, SP
	0x000a 00010 (tutorial01.go:6)	MOVQ	BP, 8(SP)
	0x000f 00015 (tutorial01.go:6)	LEAQ	8(SP), BP
	0x0014 00020 (tutorial01.go:6)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0014 00020 (tutorial01.go:6)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0014 00020 (tutorial01.go:7)	MOVL	$10, AX
	0x0019 00025 (tutorial01.go:7)	MOVL	$32, BX
	0x001e 00030 (tutorial01.go:7)	PCDATA	$1, $0
	0x001e 00030 (tutorial01.go:7)	NOP
	0x0020 00032 (tutorial01.go:7)	CALL	"".add(SB)
	0x0025 00037 (tutorial01.go:8)	MOVQ	8(SP), BP
	0x002a 00042 (tutorial01.go:8)	ADDQ	$16, SP
	0x002e 00046 (tutorial01.go:8)	RET
	0x002f 00047 (tutorial01.go:8)	NOP
	0x002f 00047 (tutorial01.go:6)	PCDATA	$1, $-1
	0x002f 00047 (tutorial01.go:6)	PCDATA	$0, $-2
	0x002f 00047 (tutorial01.go:6)	CALL	runtime.morestack_noctxt(SB)
	0x0034 00052 (tutorial01.go:6)	PCDATA	$0, $-1
	0x0034 00052 (tutorial01.go:6)	JMP	0
	0x0000 49 3b 66 10 76 29 48 83 ec 10 48 89 6c 24 08 48  I;f.v)H...H.l$.H
	0x0010 8d 6c 24 08 b8 0a 00 00 00 bb 20 00 00 00 66 90  .l$....... ...f.
	0x0020 e8 00 00 00 00 48 8b 6c 24 08 48 83 c4 10 c3 e8  .....H.l$.H.....
	0x0030 00 00 00 00 eb ca                                ......
	rel 33+4 t=7 "".add+0
	rel 48+4 t=7 runtime.morestack_noctxt+0
go.cuinfo.packagename. SDWARFCUINFO dupok size=0
	0x0000 6d 61 69 6e                                      main
""..inittask SNOPTRDATA size=24
	0x0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
	0x0010 00 00 00 00 00 00 00 00                          ........
gclocals·33cdeccccebe80329f1fdbee7f5874cb SRODATA dupok size=8
	0x0000 01 00 00 00 00 00 00 00                          ........
"".add.arginfo1 SRODATA static dupok size=5
	0x0000 00 04 04 04 ff                                   .....
