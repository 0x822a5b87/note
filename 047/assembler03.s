"".add STEXT nosplit size=66 args=0x0 locals=0x20 funcid=0x0 align=0x0
	0x0000 00000 (assembler03.go:3)	TEXT	"".add(SB), NOSPLIT|ABIInternal, $32-0
	0x0000 00000 (assembler03.go:3)	SUBQ	$32, SP
	0x0004 00004 (assembler03.go:3)	MOVQ	BP, 24(SP)
	0x0009 00009 (assembler03.go:3)	LEAQ	24(SP), BP
	0x000e 00014 (assembler03.go:3)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x000e 00014 (assembler03.go:3)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x000e 00014 (assembler03.go:3)	MOVQ	$0, "".~r0(SP)
	0x0016 00022 (assembler03.go:4)	MOVQ	$100, "".a+16(SP)
	0x001f 00031 (assembler03.go:5)	MOVQ	$200, "".b+8(SP)
	0x0028 00040 (assembler03.go:6)	MOVQ	"".a+16(SP), CX
	0x002d 00045 (assembler03.go:6)	LEAQ	500(CX), AX
	0x0034 00052 (assembler03.go:6)	MOVQ	AX, "".~r0(SP)
	0x0038 00056 (assembler03.go:6)	MOVQ	24(SP), BP
	0x003d 00061 (assembler03.go:6)	ADDQ	$32, SP
	0x0041 00065 (assembler03.go:6)	RET
	0x0000 48 83 ec 20 48 89 6c 24 18 48 8d 6c 24 18 48 c7  H.. H.l$.H.l$.H.
	0x0010 04 24 00 00 00 00 48 c7 44 24 10 64 00 00 00 48  .$....H.D$.d...H
	0x0020 c7 44 24 08 c8 00 00 00 48 8b 4c 24 10 48 8d 81  .D$.....H.L$.H..
	0x0030 f4 01 00 00 48 89 04 24 48 8b 6c 24 18 48 83 c4  ....H..$H.l$.H..
	0x0040 20 c3                                             .
go.cuinfo.packagename. SDWARFCUINFO dupok size=0
	0x0000 6d 61 69 6e                                      main
""..inittask SNOPTRDATA size=24
	0x0000 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
	0x0010 00 00 00 00 00 00 00 00                          ........
gclocals·33cdeccccebe80329f1fdbee7f5874cb SRODATA dupok size=8
	0x0000 01 00 00 00 00 00 00 00                          ........
