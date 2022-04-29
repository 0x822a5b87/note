"".main STEXT size=40 args=0x0 locals=0x8 funcid=0x0 align=0x0
	0x0000 00000 (hello.go:4)	TEXT	"".main(SB), ABIInternal, $8-0
	0x0000 00000 (hello.go:4)	CMPQ	SP, 16(R14)
	0x0004 00004 (hello.go:4)	PCDATA	$0, $-2
	0x0004 00004 (hello.go:4)	JLS	33
	0x0006 00006 (hello.go:4)	PCDATA	$0, $-1
	0x0006 00006 (hello.go:4)	SUBQ	$8, SP
	0x000a 00010 (hello.go:4)	MOVQ	BP, (SP)
	0x000e 00014 (hello.go:4)	LEAQ	(SP), BP
	0x0012 00018 (hello.go:4)	FUNCDATA	$0, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0012 00018 (hello.go:4)	FUNCDATA	$1, gclocals·33cdeccccebe80329f1fdbee7f5874cb(SB)
	0x0012 00018 (hello.go:5)	PCDATA	$1, $0
	0x0012 00018 (hello.go:5)	CALL	"".hello(SB)
	0x0017 00023 (hello.go:6)	MOVQ	(SP), BP
	0x001b 00027 (hello.go:6)	ADDQ	$8, SP
	0x001f 00031 (hello.go:6)	NOP
	0x0020 00032 (hello.go:6)	RET
	0x0021 00033 (hello.go:6)	NOP
	0x0021 00033 (hello.go:4)	PCDATA	$1, $-1
	0x0021 00033 (hello.go:4)	PCDATA	$0, $-2
	0x0021 00033 (hello.go:4)	CALL	runtime.morestack_noctxt(SB)
	0x0026 00038 (hello.go:4)	PCDATA	$0, $-1
	0x0026 00038 (hello.go:4)	JMP	0
	0x0000 49 3b 66 10 76 1b 48 83 ec 08 48 89 2c 24 48 8d  I;f.v.H...H.,$H.
	0x0010 2c 24 e8 00 00 00 00 48 8b 2c 24 48 83 c4 08 90  ,$.....H.,$H....
	0x0020 c3 e8 00 00 00 00 eb d8                          ........
	rel 19+4 t=7 "".hello+0
	rel 34+4 t=7 runtime.morestack_noctxt+0
go.cuinfo.packagename. SDWARFCUINFO dupok size=0
	0x0000 6d 61 69 6e                                      main
""..inittask SNOPTRDATA size=32
	0x0000 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00  ................
	0x0010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  ................
	rel 24+8 t=1 fmt..inittask+0
"".hello.args_stackmap SRODATA size=8
	0x0000 01 00 00 00 00 00 00 00                          ........
type..importpath.fmt. SRODATA dupok size=5
	0x0000 00 03 66 6d 74                                   ..fmt
gclocals·33cdeccccebe80329f1fdbee7f5874cb SRODATA dupok size=8
	0x0000 01 00 00 00 00 00 00 00                          ........
