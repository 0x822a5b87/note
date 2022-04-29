"".add STEXT nosplit size=71 args=0x8 locals=0x10 funcid=0x0 align=0x0
	0x0000 00000 (assembler02.go:4)	TEXT	"".add(SB), NOSPLIT|ABIInternal, $16-8
	0x0000 00000 (assembler02.go:4)	SUBQ	$16, SP
	0x0004 00004 (assembler02.go:4)	MOVQ	BP, 8(SP)
	0x0009 00009 (assembler02.go:4)	LEAQ	8(SP), BP
	0x000e 00014 (assembler02.go:4)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x000e 00014 (assembler02.go:4)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x000e 00014 (assembler02.go:4)	FUNCDATA	$5, "".add.arginfo1(SB)
	0x000e 00014 (assembler02.go:4)	MOVL	AX, "".a+24(SP)
	0x0012 00018 (assembler02.go:4)	MOVL	BX, "".b+28(SP)
	0x0016 00022 (assembler02.go:4)	MOVL	$0, "".~r0+4(SP)
	0x001e 00030 (assembler02.go:4)	MOVB	$0, "".~r1+3(SP)
	0x0023 00035 (assembler02.go:5)	MOVL	"".a+24(SP), CX
	0x0027 00039 (assembler02.go:5)	ADDL	"".b+28(SP), CX
	0x002b 00043 (assembler02.go:5)	MOVL	CX, "".~r0+4(SP)
	0x002f 00047 (assembler02.go:5)	MOVB	$1, "".~r1+3(SP)
	0x0034 00052 (assembler02.go:5)	MOVL	"".~r0+4(SP), AX
	0x0038 00056 (assembler02.go:5)	MOVL	$1, BX
	0x003d 00061 (assembler02.go:5)	MOVQ	8(SP), BP
	0x0042 00066 (assembler02.go:5)	ADDQ	$16, SP
	0x0046 00070 (assembler02.go:5)	RET
	0x0000 48 83 ec 10 48 89 6c 24 08 48 8d 6c 24 08 89 44  H...H.l$.H.l$..D
	0x0010 24 18 89 5c 24 1c c7 44 24 04 00 00 00 00 c6 44  $..\$..D$......D
	0x0020 24 03 00 8b 4c 24 18 03 4c 24 1c 89 4c 24 04 c6  $...L$..L$..L$..
	0x0030 44 24 03 01 8b 44 24 04 bb 01 00 00 00 48 8b 6c  D$...D$......H.l
	0x0040 24 08 48 83 c4 10 c3                             $.H....
"".callAdd STEXT size=76 args=0x0 locals=0x20 funcid=0x0 align=0x0
	0x0000 00000 (assembler02.go:8)	TEXT	"".callAdd(SB), ABIInternal, $32-0
	0x0000 00000 (assembler02.go:8)	CMPQ	SP, 16(R14)
	0x0004 00004 (assembler02.go:8)	PCDATA	$0, $-2
	0x0004 00004 (assembler02.go:8)	JLS	69
	0x0006 00006 (assembler02.go:8)	PCDATA	$0, $-1
	0x0006 00006 (assembler02.go:8)	SUBQ	$32, SP
	0x000a 00010 (assembler02.go:8)	MOVQ	BP, 24(SP)
	0x000f 00015 (assembler02.go:8)	LEAQ	24(SP), BP
	0x0014 00020 (assembler02.go:8)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0014 00020 (assembler02.go:8)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0014 00020 (assembler02.go:8)	MOVL	$0, "".~r0+12(SP)
	0x001c 00028 (assembler02.go:9)	MOVL	$10, AX
	0x0021 00033 (assembler02.go:9)	MOVL	$20, BX
	0x0026 00038 (assembler02.go:9)	PCDATA	$1, $0
	0x0026 00038 (assembler02.go:9)	CALL	"".add(SB)
	0x002b 00043 (assembler02.go:9)	MOVL	AX, ""..autotmp_2+20(SP)
	0x002f 00047 (assembler02.go:9)	MOVL	AX, "".a+16(SP)
	0x0033 00051 (assembler02.go:10)	MOVL	"".a+16(SP), AX
	0x0037 00055 (assembler02.go:10)	MOVL	AX, "".~r0+12(SP)
	0x003b 00059 (assembler02.go:10)	MOVQ	24(SP), BP
	0x0040 00064 (assembler02.go:10)	ADDQ	$32, SP
	0x0044 00068 (assembler02.go:10)	RET
	0x0045 00069 (assembler02.go:10)	NOP
	0x0045 00069 (assembler02.go:8)	PCDATA	$1, $-1
	0x0045 00069 (assembler02.go:8)	PCDATA	$0, $-2
	0x0045 00069 (assembler02.go:8)	CALL	runtime.morestack_noctxt(SB)
	0x004a 00074 (assembler02.go:8)	PCDATA	$0, $-1
	0x004a 00074 (assembler02.go:8)	JMP	0
	0x0000 49 3b 66 10 76 3f 48 83 ec 20 48 89 6c 24 18 48  I;f.v?H.. H.l$.H
	0x0010 8d 6c 24 18 c7 44 24 0c 00 00 00 00 b8 0a 00 00  .l$..D$.........
	0x0020 00 bb 14 00 00 00 e8 00 00 00 00 89 44 24 14 89  ............D$..
	0x0030 44 24 10 8b 44 24 10 89 44 24 0c 48 8b 6c 24 18  D$..D$..D$.H.l$.
	0x0040 48 83 c4 20 c3 e8 00 00 00 00 eb b4              H.. ........
	rel 39+4 t=7 "".add+0
	rel 70+4 t=7 runtime.morestack_noctxt+0
"".main STEXT size=40 args=0x0 locals=0x8 funcid=0x0 align=0x0
	0x0000 00000 (assembler02.go:12)	TEXT	"".main(SB), ABIInternal, $8-0
	0x0000 00000 (assembler02.go:12)	CMPQ	SP, 16(R14)
	0x0004 00004 (assembler02.go:12)	PCDATA	$0, $-2
	0x0004 00004 (assembler02.go:12)	JLS	33
	0x0006 00006 (assembler02.go:12)	PCDATA	$0, $-1
	0x0006 00006 (assembler02.go:12)	SUBQ	$8, SP
	0x000a 00010 (assembler02.go:12)	MOVQ	BP, (SP)
	0x000e 00014 (assembler02.go:12)	LEAQ	(SP), BP
	0x0012 00018 (assembler02.go:12)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0012 00018 (assembler02.go:12)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0012 00018 (assembler02.go:13)	PCDATA	$1, $0
	0x0012 00018 (assembler02.go:13)	CALL	"".callAdd(SB)
	0x0017 00023 (assembler02.go:14)	MOVQ	(SP), BP
	0x001b 00027 (assembler02.go:14)	ADDQ	$8, SP
	0x001f 00031 (assembler02.go:14)	NOP
	0x0020 00032 (assembler02.go:14)	RET
	0x0021 00033 (assembler02.go:14)	NOP
	0x0021 00033 (assembler02.go:12)	PCDATA	$1, $-1
	0x0021 00033 (assembler02.go:12)	PCDATA	$0, $-2
	0x0021 00033 (assembler02.go:12)	CALL	runtime.morestack_noctxt(SB)
	0x0026 00038 (assembler02.go:12)	PCDATA	$0, $-1
	0x0026 00038 (assembler02.go:12)	JMP	0
	0x0000 49 3b 66 10 76 1b 48 83 ec 08 48 89 2c 24 48 8d  I;f.v.H...H.,$H.
	0x0010 2c 24 e8 00 00 00 00 48 8b 2c 24 48 83 c4 08 90  ,$.....H.,$H....
	0x0020 c3 e8 00 00 00 00 eb d8                          ........
	rel 19+4 t=7 "".callAdd+0
	rel 34+4 t=7 runtime.morestack_noctxt+0
go.cuinfo.packagename. SDWARFCUINFO dupok size=0
	0x0000 6d 61 69 6e                                      main
""..inittask SNOPTRDATA size=24
	0x0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
	0x0010 00 00 00 00 00 00 00 00                          ........
gclocals·33cdeccccebe80329f1fdbee7f5874cb SRODATA dupok size=8
	0x0000 01 00 00 00 00 00 00 00                          ........
"".add.arginfo1 SRODATA static dupok size=5
	0x0000 00 04 04 04 ff                                   .....
