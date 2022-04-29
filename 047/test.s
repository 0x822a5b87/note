"".add STEXT size=126 args=0x20 locals=0x10 funcid=0x0 align=0x0
	0x0000 00000 (test.go:3)	TEXT	"".add(SB), ABIInternal, $16-32
	0x0000 00000 (test.go:3)	CMPQ	SP, 16(R14)
	0x0004 00004 (test.go:3)	PCDATA	$0, $-2
	0x0004 00004 (test.go:3)	JLS	79
	0x0006 00006 (test.go:3)	PCDATA	$0, $-1
	0x0006 00006 (test.go:3)	SUBQ	$16, SP
	0x000a 00010 (test.go:3)	MOVQ	BP, 8(SP)
	0x000f 00015 (test.go:3)	LEAQ	8(SP), BP
	0x0014 00020 (test.go:3)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0014 00020 (test.go:3)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0014 00020 (test.go:3)	FUNCDATA	$5, "".add.arginfo1(SB)
	0x0014 00020 (test.go:3)	MOVQ	AX, "".a+24(SP)
	0x0019 00025 (test.go:3)	MOVQ	BX, "".b+32(SP)
	0x001e 00030 (test.go:3)	MOVQ	CX, "".c+40(SP)
	0x0023 00035 (test.go:3)	MOVQ	DI, "".d+48(SP)
	0x0028 00040 (test.go:4)	PCDATA	$1, $0
	0x0028 00040 (test.go:4)	CALL	runtime.printlock(SB)
	0x002d 00045 (test.go:4)	MOVL	$10, AX
	0x0032 00050 (test.go:4)	CALL	runtime.printint(SB)
	0x0037 00055 (test.go:4)	CALL	runtime.printnl(SB)
	0x003c 00060 (test.go:4)	NOP
	0x0040 00064 (test.go:4)	CALL	runtime.printunlock(SB)
	0x0045 00069 (test.go:5)	MOVQ	8(SP), BP
	0x004a 00074 (test.go:5)	ADDQ	$16, SP
	0x004e 00078 (test.go:5)	RET
	0x004f 00079 (test.go:5)	NOP
	0x004f 00079 (test.go:3)	PCDATA	$1, $-1
	0x004f 00079 (test.go:3)	PCDATA	$0, $-2
	0x004f 00079 (test.go:3)	MOVQ	AX, 8(SP)
	0x0054 00084 (test.go:3)	MOVQ	BX, 16(SP)
	0x0059 00089 (test.go:3)	MOVQ	CX, 24(SP)
	0x005e 00094 (test.go:3)	MOVQ	DI, 32(SP)
	0x0063 00099 (test.go:3)	CALL	runtime.morestack_noctxt(SB)
	0x0068 00104 (test.go:3)	MOVQ	8(SP), AX
	0x006d 00109 (test.go:3)	MOVQ	16(SP), BX
	0x0072 00114 (test.go:3)	MOVQ	24(SP), CX
	0x0077 00119 (test.go:3)	MOVQ	32(SP), DI
	0x007c 00124 (test.go:3)	PCDATA	$0, $-1
	0x007c 00124 (test.go:3)	JMP	0
	0x0000 49 3b 66 10 76 49 48 83 ec 10 48 89 6c 24 08 48  I;f.vIH...H.l$.H
	0x0010 8d 6c 24 08 48 89 44 24 18 48 89 5c 24 20 48 89  .l$.H.D$.H.\$ H.
	0x0020 4c 24 28 48 89 7c 24 30 e8 00 00 00 00 b8 0a 00  L$(H.|$0........
	0x0030 00 00 e8 00 00 00 00 e8 00 00 00 00 0f 1f 40 00  ..............@.
	0x0040 e8 00 00 00 00 48 8b 6c 24 08 48 83 c4 10 c3 48  .....H.l$.H....H
	0x0050 89 44 24 08 48 89 5c 24 10 48 89 4c 24 18 48 89  .D$.H.\$.H.L$.H.
	0x0060 7c 24 20 e8 00 00 00 00 48 8b 44 24 08 48 8b 5c  |$ .....H.D$.H.\
	0x0070 24 10 48 8b 4c 24 18 48 8b 7c 24 20 eb 82        $.H.L$.H.|$ ..
	rel 41+4 t=7 runtime.printlock+0
	rel 51+4 t=7 runtime.printint+0
	rel 56+4 t=7 runtime.printnl+0
	rel 65+4 t=7 runtime.printunlock+0
	rel 100+4 t=7 runtime.morestack_noctxt+0
go.cuinfo.packagename. SDWARFCUINFO dupok size=0
	0x0000 6d 61 69 6e                                      main
""..inittask SNOPTRDATA size=24
	0x0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
	0x0010 00 00 00 00 00 00 00 00                          ........
gclocals·33cdeccccebe80329f1fdbee7f5874cb SRODATA dupok size=8
	0x0000 01 00 00 00 00 00 00 00                          ........
"".add.arginfo1 SRODATA static dupok size=9
	0x0000 00 08 08 08 10 08 18 08 ff                       .........
