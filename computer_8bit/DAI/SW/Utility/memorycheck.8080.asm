;******************************************************************************
;
; http://bruno.vivien.pagesperso-orange.fr/DAI/reparation/testmem.htm
;
;******************************************************************************
;
; compile with RetroAssembler
; Tab Size = 10
;
	.target	"8080"
	.format	"prg"

	.setting "OmitUnusedFunctions", true


ADDEB	.equ $02EC
ADFIN	.equ $BFFF

	.org	$F800

START	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH 	H
	DI
	MVI	B, $00
SUIV	LXI	H, ADFIN
	XCHG
	LXI	H, ADDEB
@ECR1	MOV	M, B
	CALL	TESTFI
	INX	H
	JNZ	@ECR1
	LXI	H, ADDEB
@CTRL	MOV	A, B
	XRA	M
	JNZ	ERREUR
	CALL	TESTFI
	INX	H
	JNZ	@CTRL
	INR	B
	MVI	A, $FF
	XRA	B
	JNZ	SUIV
	CALL	CLS
	LXI	H, OK
	CALL	$DB32
FIN	POP	H
	POP	D
	POP	B
	POP	PSW
	EI
	RET
ERREUR	CALL	CLS
	PUSH	H
	LXI	H, PB
	CALL	$DB32
	POP	H
	MVI	A, $0
	MVI	B, 0
	MOV	C, H
	MOV	D, L
	RST	4
	.byte	$12
	CALL	$C653
	LXI	H, $E3
	CALL	$DB32
	JMP	FIN
CLS	MVI	A, $FF
	RST	5
	.byte	$18
	MVI	A, $0C
	CALL	$D695
	MVI	A, $0D
	CALL	$D695
	RET
TESTFI	MOV	A, D
	XRA	H
	RNZ
	MOV	A, E
	XRA	L
	RET

OK	.byte	2
	.ascii	"OK"

PB	.byte	13
	.ascii	"PB ADRESSE : "
