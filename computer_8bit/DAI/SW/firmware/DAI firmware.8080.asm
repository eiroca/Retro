;
; DAI FIRMWARE
;
.target	"8080"
.format	"bin"
.setting	"OutputSaveIndividualSegments", true
;
;ROMVERS	.equ	10	; 11 = BASIC v1.0
ROMVERS	.equ	11	; 11 = BASIC v1.1
;
.include	"DAI FW macro.8080.asm"
.include	"DAI FW RAM.8080.asm"
;
; ROM Core - 8KB starting $C000 (not banked)
.bank 0, 8, $C000
.segment "ROM", 0
.org	$C000
;
bgn_rom	.equ	*
;
;     ===============
; *** MATH. UTILITIES ***
;     ===============
;
; ***************
; * ENTRYPOINTS *
; ***************
;
BASE	JMP	INIT	; Reset entry on hardware reset
XINIT	JMP	MINIT	; Math. package initialisation
XEINM	JMP	FINM	; Incr. FPT number in memory
XFDCM	JMP	FDCM	; Decr. FPT number in memory	(not used)
XFCOMP	JMP	FCOMP	; FPT Compare
XIINM	JMP	IINM	; Incr. INT number in memory
XIDCM	JMP	IDCM	; Decr. INT number in menory	(not used)
XICOMP	JMP	ICOMP	; INT Compare
XPLISH	JMP	PLISH	; Save MACC on stack
XPOF	JMP	POF	; Retrieve MACC from Stack
XFCB	JMP	FCB	; Input FPT number to MACC
XFEC	JMP	FEC	; Conv. FPT number for Output
XICB	JMP	ICB	; Input INT number to MACC
XIBC	JMP	IBC	; Conv. INT number for Output
XHCB	JMP	HCB	; Input Hex number to MACC
XHBC	JMP	HBC	; Conv. MACC to Hex for output
XPRTY	JMP	PRTY	; Pretties up FPT/INT number
;
PDECBUF	.word	DECBUF	; Location output buffer
;
; ********************************
; * MATH. PACKAGE INITIALISAT1ON *
; ********************************
;
; Entry: HL: Address input encoding routine ($DDE0)
;        DE: Base address error routines ($C7F2)
; Exit:  AFDEHL corrupted, BC preserved.
;
MINIT	SHLD	AGETC	; Init. (AGETC) = $DDE0
	XCHG
	SHLD	EVECT	; Init. (EVECT) = $C7F2
	LDA	MSTATUS	; Get math. chip status
	ORA	A	; Check if math. chip present
	MVI	A, $00	; Flag = 0 if not
	JM	@C047
	MVI	A, $7B	; Flag = $7B if present
@C047	STA	MVECA	; Set math.chip flag
	RET
;
; **************************
; * OVERFLOW ERRDR ROUTINE *
; **************************
;
; (From LC04F common part for various entries).
;
; Jump to (EVECT/1) = Address 'overflow error' routine ($C7F2)
;
; Entry: If start at LC04F: offset in HL.
; Exit:  AFBCDEHL preserved.
;        On stack original return address.
;
FPEOV	PUSH	H
	LXI	H, $0000	; Init offset = 0
;
LC04F	PUSH	PSW
	PUSH	D
	XCHG		; Offset in DE
	LHLD	EVECT	; Get addr pointer
	DAD	D	; Add offset
	MOV	A, M
	INX	H
	MOV	H,M
	MOV	L,A	; Get addr routine in HL
	POP	D
	POP	PSW
	XTHL		; New addr on stack
	RET		; Continue with new address
;
; ******************
; * ARGUMENT ERROR *
; ******************
;
; Jump to (EVECT/1)+2 = Address 'number out of range' routine ($C7F4)
;
; Entry/Exit: See FPEOV.
;
FPEAE	PUSH	H
	LXI	H, $002	; Init. offset
	JMP	LC04F	; Calc. new addr, go to it
;
; *******************
; * UNDERFLOW ERROR *
; *******************
;
; * Jump to (EVECT/1)+4 = Return ($C7F6).
; * Underflow gives 0 as result of operation.
;
; * Entry/Exit: See FPEOV.
;
FPEUN	PUSH	H
	LXI	H, $C45E	; Addr. FPT (0)
	JMP	$D20C	; Copy '0' into MACC
;
; ************************
; * DIVIDE BY ZERO ERROR *
; ************************
;
; Jump to (EVECT/1)+6 Address 'divide by zero' routine (LC7FB)
;
; Entry/exit: See FPEOV.
;
FPEDO	PUSH	H
	LXI	H, $0006	; Init. offset
	JMP	LC04F	; Calc. new addr, go to it
;
; ***************************
; * GET CHARACTER FROM LINE *
; ***************************
;
; Entry: None.
; Exit:  All registers preserved.
;        Address to continue on stack.
;
LC073	PUSH	H
	LHLD	AGETC	; Get addr 'Get char' routine
	XTHL		; on stack restore HL
	RET		; Goto EVECT/1)+2
;
; **************************
; * FLOATING POINT COMPARE *
; **************************
;
; Compares normalised FPT numbers in MACC and in M.
;
; Exit:  ABCDEHL preserved.
;        Flags: CY=1,S=0,Z=1: both nrs. 0
;               CY=0,S=0,Z=1: both nrs. identical
;               CY=0,S=0,Z=0: MACC > M
;               CY=0,S=1,Z=0: MACC < M
; $C079
FCOMP	PUSH	B
	PUSH	PSW
	PUSH	D
	PUSH	H
	ROMCALL(4, $15)	; Copy MACC to reg A,B,C,D
	MOV	E, A	; Exp. byte in E
	XRA	M	; XOR both exp. bytes
	JM	LC0B7	; Jump if different signs
;
; If equal signs
;
	JMP	LD1E8	; Goto $D1E8, return to $C087
LC087	RAL
	JNZ	LC0A3
LC08B	MOV	A, E
LC08C	SUB	M	; Comp. exp. bytes
	JNZ	LC0A2	; Jump if not equal
	INX	H
	MOV	A, B
	SUB	M	; Comp. 1st bytes mantissa's
	JNZ	LC0A2	; Jump if not equal
	INX	H
	MOV	A, C
	SUB	M	; Comp. 2nd bytes mantissa's
	JNZ	LC0A2	; Jump if not equal
	INX	H
	MOV	A, D
	SUB	M	; Comp. 3rd bytes mantissa's
LC09F	JZ	LC0A6	; Jump if not equal
LC0A2	RAR		;  Set flags for output
LC0A3	XRA	E
LC0A4	ORI	$01	; Clear CY-f1ag
LC0A6	POP	H
	POP	D
	POP	B
	MOV	A, B	; Restore A
	POP	B
	RET
;
; *******************
; * INTEGER COMPARE *
; *******************
;
; Compares INT numbers in MACC and M.
; REMARK: Routine is incorrect when both numbers are negative! Then result
; is if MACC > M due to LC0A2/LC0A3.
;
; Exit: ABCDEHL preserved. CY=0
;       Flags: S=0, Z=1: Both numbers equal
;              S=0, Z=0: MACC > M
;              S=1, Z=0: MACC < M
; $C0AC
ICOMP	PUSH	B
	PUSH	PSW
	PUSH	D
	PUSH	H
	ROMCALL(4, $15)	; Copy MACC to reg. A,B,C,D
	MOV	E, A	; Sign byte in E
	XRA	M	; XOR both sign bytes
.if ROMVERS == 11
; The temporary storage register E (sign byte) is cleared to avoid problems when using the combined
; FPT/INT exit LC27. This is done to remove a bug in comparing 2 relational numeric operations.
; The unitary operator '-' is now recognised correctly.
	JMP	XD1C8
.endif
.if ROMVERS == 10
	JP	LC08B	; If both nrs have same sign: compare
.endif
;
; If different signs:
;
LC0B7	XRA	M	; Find out which one is neg:
			; S=1: MEM pos; MACC neg
			; S=0: MEM neg; MACC pos
	JMP	LC0A4	; Abort
;
; ***************************************
; * INCREMENT INTEGER NUMEBER IN MEMORY *
; ***************************************
;
; Entry: HL points to 1st byte of INT number.
; Exit:  All registers preserved.
;
; $C0BB
IINM	PUSH	PSW
	PUSH	H
	INX	H
	INX	H
	INX	H	; HL pnts to last byte
	MVI	A, $03	; Nr of bytes for INT nr
@C0C2	INR	M	; Incr. INT nr
	JNZ	@C0D2	; Ready if no overflow
	DCX	H	; Goto next byte
	DCR	A	; 1st byte reached?
	JNZ	@C0C2	; Incr. next byte
	INR	M	; Incr 1st byte
	MOV	A, M	; Get it
	CPI	$80	; msb-1?
	CZ	FPEOV	; Then overflow error
@C0D2	POP	H	; Normal return
	POP	PSW
	RET
;
; *************************************************
; * DECREMENT INTEGER NUMBER IN MEMORY (not used) *
; *************************************************
;
; Entry: HL points to 1st byte of INT number.
; Exit:  All registers preserved.
;
; $C0D5
IDCM	PUSH	PSW
	PUSH	B
	PUSH	H
	INX	H
	INX	H
	INX	H	; HL pnts to 1ast bytte
	MVI	B, $03	; Nr of bytes of INT nr.
@C0DD	DCR	M	; Decr INT nr
	MOV	A, M
	INR	A	; Check for overflow
	JNZ	@C0EF	; Ready if no overflow
	DCX	H	; Goto next byte
	DCR	B	; Decr. byte count
	JNZ	@C0DD	; Next byte if not ready
	DCR	M	; Decr. hibyte
	MOV	A, M
	CPI	$7F	; Check for overflow
	CZ	FPEOV	; Then run over flow error
@C0EF	POP	H	; Normal return
	POP	B
	POP	PSW
	RET
;
; *********************************************
; * INCREMENT FLOATING POINT NUMBER IN MEMORY *
; *********************************************
;
; If number = 0, or exponent < 0, a '1' is added
; to the 1sb of the mantissa. Else, the position
; of the least significant '1' is looked up, and
; a '1' is added to this position.
; If the lsb of the mantissa is already a rounded
; value, no increment occours.
;
; Entry: HL points to ist byte of FPT number.
; Exit:  All registers preserved.
;
; $C0F3
FINM	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D, FP1	; Addr FPT(1)
	MOV	A, M	; Get exp. byte
	ANI	$7F	; Mask sign bit
	JZ	LC1AC	; If nr=0: add 1, abort
	CPI	$40	; Is exponent negative?
	JNC	LC1AC	; Then add 1, abort
	CPI	$19	; Lsb of mantissa is not 1sb of number?
	JNC	EXIT	; Then Popall, ret
	CMP	M	; Check if nr. is negative
	INX	H
	JNZ	LC152	; Then jump
; From LC10F al so used by XFDCM.
; Find 1sb of mantissa if nr is positive
LC10F	SUI	$09	; In 1st byte?
	CC	LC1EE	; Then SHL bit into A (A) time
	JC	@C136	; and jump
	INX	H
	SUI	$08	; In 2nd byte?
	CC	LC1EE	; Then SHL bit into A (A) time
	JC	@C12E	; and jump
	INX	H
	SUI	$08	; In 3rd byte?
	CALL	LC1EE	; Then SHL bit into A (A) time
	ADD	M
	MOV	M, A	; Add 1 to 3rd byte mantissa
	JNC	EXIT	; Ready if no overflow
	DCX	H
	MVI	A, $01	; Over flow: add 1 to 2nd byte
@C12E	ADD	M
	MOV	M, A	; Add 1 to 2nd byte mantissa
	JNC	EXIT	; Ready if no overflow
	DCX	H
	MVI	A, $01	; Overflow add 1 to 1st byte
@C136	ADD	M
	MOV	M, A	; Add 1 to 1st byte mantissa
	JNC	EXIT	; Ready if no overflow
;
; If overflow into exponent byte:
;
	RAR		; Shift all bits in
	MOV	M, A	; mantissa right one position
	INX	H
	MOV	A, M
	RAR
	MOV	M, A
	INX	H
	MOV	A, M
	RAR
	MOV	M, A
	DCX	H
	DCX	H
	DCX	H	; HL pnts to exp. byte
	MVI	A, $01
LC14A	CALL	LC1BA	; Add 1 to exponent
;
EXIT	POP	H
	POP	D
	POP	B
	POP	PSW
	RET
;
; Find 1sb of mantissa if nr is negative:
;
LC152	SUI	$09	; In 1st byte?
	CC	LC1EE	; Then SHL bit into A (A) time
	JC	@C17D	; and jmp
	INX	H
	SUI	$08	; In 2nd byte?
	CC	LC1EE	; Then SHL bit into A (A) time
	JC	@C173	; and jump
	INX	H
	SUI	$08	; In 3rd byte?
	CC	LC1EE	; Then SHL bit into A (A) ti me
	MOV	B, A
	MOV	A, M
	SUB	B	; Subtract from 3rd byte
	MOV	M, A
	JNC	EXIT	; Ready if no borrow
	DCX	H
	MVI	A, $01	; Subtract 1 from 2nd byte if borrow
@C173	MOV	B, A
	MOV	A, M
	SUB	B	; Subtract 1 from 2nd byte
	MOV	M, A
	JNC	EXIT	; Ready if no borrow
	DCX	H
	MVI	A, $01	; Subtract 1 from 1st byte if borrow
@C17D	MOV	B, A
	MOV	A, M
	SUB	B	; Subtract 1 from 1st byte
	MOV	M, A
	JM	EXIT	;  Ready if normalised
;
; If not normalised:
;
	MVI	B, $18	; Nr of mantissa bits
@C186	INX	H
	INX	H
	ORA	A
	MOV	A, M
	RAL
	MOV	M, A	; Shift all bits
	DCX	H	; of mantissa
	MOV	A, M	; left one position
	RAL
	MOV	M, A
	DCX	H
	MOV	A, M
	RAL
	MOV	M, A
	ORA	A
	JM	@C19F	; If normalized
	DCR	B	; Update exp. count
	JZ	@C1A6	; It exp. now zero
	JMP	@C186	; Cont. normalisation
;
; Normalisation done:
;
@C19F	DCX	H	; Pnts to exp. byte
	MOV	A, B	; Get exp. count
	SUI	$19	; Minus nr of bytes in mantissa
	JMP	LC14A	; Update exponent, quit
;
; If exponent is zero:
;
@C1A6	DCX	H
	MVI	M, $00	; Exp. byte is 0
	JMP	EXIT	; Papall, ret
;
; Simply add 1 (FINM) or add -1 (FDCM)
 LC1AC	ROMCALL(4, $0C)	; Copy number into MACC
	XCHG
	ROMCALL(4, $00)	; Add 1 or -1 (FPT)
	XCHG
	ROMCALL(4, $0F)	; Copy MACC into memory
	JMP	EXIT	;  Popall, ret
;
; *****************
; * ADD EXPONENTS *
; *****************
;
; LC1B7 for operand in MACC.
; LC1BA for operand in M.
;
; Entry: Byte to be added to exponent in A.
; Exit:  BCDEHL preserved.
;        CY=0: OK
;        CY=1: Overf1ow
;
LC1B7	LXI	H, FPAC	; Addr. MACC
;
LC1BA	PUSH	H
	PUSH	D
	PUSH	B
	MOV	C, A	; Byte to be added in C
	MOV	A, M	; Get exp. byte operand
	ANI	$80	; Sign bit mantissa only
	MOV	B, A	; in B
	MOV	A, M	; Get exp. byte
	CALL	SEXT	; Sign extend
	PUSH	PSW	; Save sign extended exp. byte
	XRA	C	; XOR with byte to be added
	CMA
	MOV	D, A
	POP	PSW	; Get sign extended exp. byte
	ADD	C	; Add byte to exponent
	MOV	C, A	; store result
	RAR
	XRA	C
	ANA	D
	JM	@C1E2	; If overflow into sign bit
	MOV	A, C	; Get new exp. byte
	RAL
	XRA	C
	JM	@C1E2	; If overflow into sign bit
	MOV	A, C	; Get new exp. byte
	ANI	$7F	; Exponent only
	ORA	B	; Add sign bit mantissa
	MOV	M, A	; Store it
@C1DE	POP	B
	POP	D
	POP	H
	RET		; CY=0
;
; If overf1ow into sign bit:
;
@C1E2	MOV	A, C	; Get new exp. byte
	RAL
	ORA	A
	STC
	JMP	@C1DE	; Abort with CY=1
;
; ***************
; * SIGN EXTEND *
; ***************
;
; Exponent byte is normalized.
;
; Entry: Exp. byte in A.
; Exit:  BCDEHL preserved
;        Normalized exp. byte in A: Exp. value in
;        bits 7-2, sign mantissa in bit 1, sign
;        exponent in bit 0.
;
SEXT	RLC
	RLC
	RRC
	RAR
	RET
;
; ************************************
; * MOVE A BIT INTO A LEFT (A) TIMES *
; ************************************
;
; Used to place a '1' in the correct position in
; a byte for adding/subtracting '1' to/from the
; least significant '1' of a FPT mantissa.
;
; Entry: A contains a neg. number indicating
;        how aften RAL has to be performed.
; Exit:  Result in A, B.
;        FCDEHL preserved.
;
LC1EE	PUSH	PSW
	MOV	B, A	; Save nr of shifts
	XRA	A	; Clear A
	STC		; Set CY
@C1F2	RAL		; SHL
	INR	B	; Update count
	JNZ	@C1F2	; Continue if not ready
	MOV	B, A	; Save result
	POP	PSW
	MOV	A, B	; Result in A
	RET
;
; *********************************************
; * DECREMENT FLOATING POINT NUMBER IN MEMORY *
; *****************^***************************
;
; Routine is not used.
;
; If the number is 0, or the exponent < 0, -1 is
; added to the mantissa. Else, a -1 is added/
; subtracted to/from the least significant '1' of
; the mantissa.
; If the 1sb of the mantissa is already a rounded
; value, no decrement occurs.
;
; Entry: HL points to FPT number in M.
; Exit:  All registers preserved.
;
FDCM	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D, FPM1	; Addr. FPT (-1)
	MOV	A, M	; Get exp. byte
	ANI	$7F	; Mask sign bit
	JZ	LC1AC	; If nr=0: add -1, abort
	CPI	$40	; Is exp. negative?
	JNC	LC1AC	; Then add -1, abort
	CPI	$18	; Max. nr of mantissa bits
	JNC	EXIT	; Abort if 1sb mantissa is not 1sb of number
	CMP	M	; Check if nr. is negative
	INX	H
	JZ	LC152	; Into FINM for neg. nr
	JMP	LC10F	; Idem for pos. nr.
;
; DATA - (not used)
;
FPM1	.byte $81, $80, $00, $00	; FPT (-1)
;
; **********************
; * SAVE MACC ON STACK *
; **********************
;
;  Contents MACC is placed on TOS. Return address is saved.
;
; Entry: None.
; Exit:  All registers preserved.
;        On stack: HL; return address; MACC.
;
PLISH	SHLD	XPHLS	; Save HL
	XTHL		; Get return address
	SHLD	XPRAS	; Save it
	PUSH	H	; and put it on stack again
	LXI	H, $0000
	DAD	SP	; SP in HL
	ROMCALL(4, $0F)	; Copy MACC to TOS
	LHLD	XPRAS	; Get return addr.
	PUSH	H	; on stack
LC230	LHLD	XPHLS	; Get original HL
	RET
;
; ****************************
; * RETRIEVE MACC FROM STACK *
; ****************************
;
; Gets data from TOS and place it in MACC.
;
;
; Entry: None.
; Exit:  All registers preserved.
;
POF	SHLD	XPHLS	; Save HL
	POP	H	; Get return address
	SHLD	XPRAS	; Save it
	LXI	H, $0000
	DAD	SP	; Get SP in HL
	ROMCALL(4, $0C)	; Copy TOS to MACC
	POP	H
	LHLD	XPRAS	; Get return address
	XTHL		; on stack
	JMP	LC230	; Restore HL, ret
;
; *****************************************
; * INPUT A FLOATING PDINT NUMBER TO MACC *
; *****************************************
;
; Converts a FPT number to binary into MACC.
; The input string is converted as a integer FPT
; number, then multiplied/divided by a power of
; 10, corresponding to the explicit exponent and
; placement of the decimal Point.
;
; Entry: C points to 1st digit of FPT nr in input.
; Exit:  CY=1: No error.
;        CY=0: Over/underflow error.
;        C points past FPT string in input.
;        ABDEHL, rest of F preserved.
;
FCB	STC		; CY=1
	PUSH	PSW
	PUSH	D
	PUSH	H
	CALL	LC2AE	; Clear MACC+DEH; L=2B
@C250	CALL	LC32F	; Get bin. value of input char
	CC	LC2BA	; Value found: Move digit into MACC
	JC	@C250	; and get next digit
	CPI	'.'	; '.'($2E)?
	JZ	@C26B	; Then jump
	DCR	E
	INR	E
	JZ	LC2A6	; If error
	CPI	'E'	; 'E'($45)?
	JZ	@C284	; Then jump
	JMP	@C29F	; Convert FPT exp; quit
; If digit is '.':
;
@C26B	CALL	LC2D5	; E=0, H=H+1
@C26E	CALL	LC32F	; Get bin. value of input char
	CC	LC2BA	; If found: Move digit into MACC
	JC	@C26E	; and get next digit
	DCR	E
	INR	E
	JZ	LC2A6	; If error
	CPI	'E'	; 'E'($45)?
	CNZ	LC2D9	; H=0 if not
	JNZ	@C29F	; If not: convert exp, quit
;
; If digit is 'E'
;
@C284	CALL	LC2D9	; H=0
	CALL	LC32F	; Get bin. value of input char
	CZ	LC2DC	; If '+' or '-': char in L
	CZ	LC32F	; Then get bin. value of next char
	JNC	LC2A6	; Error if no char found
	CALL	LC2DE	; H = 10 * H + A
	CALL	LC32F	; Get bin. value of input char
	CC	LC2DE	; If found: H = 10 * H + A
	CC	LC32F	; Get bin. value of input char
;
; If digit is number:
;
@C29F	CALL	LC2EB	; Convert FPT exponent
LC2A2	POP	H
	POP	D
	POP	PSW	; CY=1
	RET
;
; If error:
;
LC2A6	CALL	LC32D	; DCR C
LC2A9	POP	H
	POP	D
	POP	PSW
	CMC		; CY=0
	RET
;
; CLEAR MACC AND REGISTERS D, E AND H;
;
; Exit: ABC preserved.
;       L = $2B ('+')
;
LC2AE	LXI	H, FP0	; Addr. FPT (0)
	ROMCALL(4, $0C)	; Copy FPT (0) to MACC
	LXI	D, $0000	; Clear DE
	LXI	H, $002B	; Clear H, L='+'
	RET
;
; MOVE A DIGIT INTO THE MACC:
;
; MACC = MACC * 10 + A
;
; Entry: A: Digit 1 - 9
; Exit:  AFBCHL preserved.
;        D=D-H; E=E-1.
;
LC2BA	PUSH	PSW
	PUSH	H
	LXI	H, LC34D	; Addr FPT (10)
	ROMCALL(4, $06)	; MACC = MACC * 10 (FPT)
	PUSH	D
	ADD	A
	ADD	A	; DE =  4 * A
	MOV	E,A	; (calc offset to start addr)
	MVI	D, $00
	LXI	H, FP0	; Addr table FPT (1-9)
	DAD	D	; Calc. addr nr to be added
	POP	D
	ROMCALL(4, $00)	; MACC = MACC + (1-9) (FPT)
	POP	H
	MOV	A, D
	SUB	H
	MOV	D, A	; D = D - H
	DCR	E	; E = E - 1
	POP	PSW
	RET
;
LC2D5	MVI	E, $00
	INR	H
	RET
;
LC2D9	MVI	H, $00
	RET
;
LC2DC	MOV	L, A
	RET
;
; H = 10 * H + Ai
;
; Exit: AFBCDEL preserved.
LC2DE	PUSH	PSW
	MOV	A, H	; A=H
	ADD	A	; A=2*H
	ADD	A	; A=4*H
	ADD	H	; A=5*H
	ADD	A	; A=10*H
	MOV	H, A
	POP	PSW
	PUSH	PSW
	ADD	H	; A=10*H+A
	MOV	H, A
	POP	PSW
	RET
;
; CONVERT A FPT EXPONENT:
;
; The MACC is multiplied/divided by a power of 10
; corresponding to the 'E'-exponent minus the number
; of digits after the deci mal point.
;
; Entry: C:    Points beyond 1st non useable char of FPT number in input.
;        L:    Contains sign of exponent
;        H:    Contains 'E....' exponent (10).
;        MACC: Contains PFT conversion of string of digits.
;        D:    Contains nr of digits after '.'.
; Exit:  BE preserved, AHL corrupted.
;        C:    Decremented to after FPT nr in input.
;        D:    Contains effective exponent.
;
LC2EB	CALL	LC32D	; Decr C
	MOV	A, L	; Get exp. sign
	CPI	'-'	; '-'($2D)?
	MOV	A, H	; Get exponent
	JNZ	@C2F7	; If exp. positive
	CMA		; Else: make exponent positive
	INR	A
@C2F7	ADD	D	; Add nr of digits after '.'
	MOV	D, A	; Save result
	JP	@C2FE	; If result positive
	CMA		; Else: make it positive
	INR	A
@C2FE	PUSH	B
	MVI	B, $05	; Nr of times of multipl.
	LXI	H, LC34D	; Addr table powers of 10
@C304	ORA	A	; Flags on result @C2F7
	RAR		; 1sb in carry
	JNC	@C317	; If bit=0
	PUSH	PSW
	MOV	A, D	; Check if multipl/div
	ORA	A
	JM	@C311	; If division
	ROMCALL(4, $06)	; MACC = MACC * power of 10
@C311	JP	@C316	; If multiplication
	ROMCALL(4, $09)	; MACC = MACC / power of 10
@C316	POP	PSW	; Restore A
@C317	INX	H
	INX	H
	INX	H
	INX	H	; HL pnts to next ^10
	DCR	B
	JNZ	@C304	; Again if not ready
	ORA	A
	JZ	@C32B	; If result OK
;
; If error:
;
	MOV	A, D
	ORA	A	; Set flags for error type
	CP	FPEOV	; If overflow error
	CM	FPEUN	; If underflow error
@C32B	POP	B	; Normal return
	RET
;
LC32D	DCR	C
	RET
;
; GET BINARY VALUE OF INPUT CHARACTER IN A:
;
; Entry: C points to character in input.
; Exit:  C points to next character.
;        BDEHL preserved
;        CY=1, Z=0: Value in A.
;        CY=0, Z=1: Char is +/—.
;        CY=0, Z=0:	otherwise.
;
LC32F	CALL	LC073	; Get char from line
	INR	C	; Update pointer
	CPI	'+'	; $2B
	RZ		; Abort if '+'
	CPI	'-'	; $2D
	RZ		; Abort if '-'
	CPI	$30
	CMC
	RNC		; Abort if < $30
	CPI	$3A
	JNC	@C34B	; Abort if > $3A
	SUI	$30	; Convert ASCII to binary
	PUSH	D
	MOV	D, A
	INR	A	; Set Z-flag correctly for reqd output
	MOV	A, D
	POP	D
	STC		; CY=1: value in A
	RET
@C34B	ORA	A	; Set flags correctly
	RET
;
; **************************
; * TABLE FPT POWERS OF 10 *
; **************************
;
LC34D	.byte	$04, $A0, $00, $00	; FPT 10^1
	.byte	$07, $C8, $00, $00	; FPT 10^2
	.byte	$0E, $9C, $40, $00	; FPT 10^4
	.byte	$1B, $BE, $BC, $20	; FPT 10^8
	.byte	$36, $8E, $1B, $CA	; FPT 10^16
;
; **********************************************
; * CONVERT A FLOATING POINT NUMBER FOR OUTPUT *
; **********************************************
;
; A FPT number in MACC is converted to ASCII in
; outputbuffer in DECBUF. The sign is in DECBS, the
; decimal point in DECBD. The normalized value of
; the mantissa is in DECBF (7 digits). In DECBE
; is the 10's exponent in 2—complement binary
; signed format
;
; Exit: A=6 (number of significant digits).
;       BCDEHL, MACC preserved.
;
FEC	PUSH	B
	PUSH	D
	PUSH	H
	CALL	PLISH	; Save MACC on stack
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	PUSH	PSW	; Save exp. byte
	ORA	B
	ORA	C
	ORA	D
	JZ	@C3D4	; if FPT nr is zero
	POP	PSW	; Get exp. byte
	PUSH	PSW
	MVI	H, $00
	ANI	$7F	; Mask sign bit mantissa
	CPI	$40
	JC	@C380	; If exp is positive
	DCR	H
	CMA		; Else convert
	ANI	$7F	; exponent to
	INR	A	; positive
@C380	PUSH	PSW	; Save value exponent
	XRA	A
	ROMCALL(4, $12)	; Copy mantissa to MACC
	POP	PSW	; Get exp. value
	MOV	B, H	; B=$FF (exp.<0), $00 (exp.>0)
	LXI	H, LC437	; Addr table powers FPT (2)
	MVI	C, $00
	MVI	D, $07	; digits to be examined
@C38D	RRC		; Shift exp. into carry
	PUSH	PSW	; Save rest of exp.
	MOV	A, M	; Get 10's power byte
	INX	H	; Points to next
	JNC	@C3A2	; If n-th power of 2=0: go to next
	ADD	C
	MOV	C, A	; Total 10's power in C
	DCR	B
	INR	B
	JNZ	@C39D	; Jump if exp. negative
	ROMCALL(4, $06)	; Multipl. mantissa by (2^2^n)/10^m
@C39D	JZ	@C3A2
	ROMCALL(4, $09)	; Divide mantissa by (2^2^n)/10^m
@C3A2	INX	H
	INX	H
	INX	H
	INX	H	; Pnts to next in table
	POP	PSW	; Get rest exponent
	DCR	D	; Decr digit count
	JNZ	@C38D	; Again if not 7 digits done
	DCR	B
	INR	B
	LXI	H, LC45A	; Addr FPT (0.1)
	JNZ	@C3C4	; exp. negative
;
; If exponent positive:
;
@C3B3	PUSH	H
	LXI	H, FP1	; Addr FPT (1)
	CALL	FCOMP	; Compare with 1
	POP	H
	JM	@C3D4	; Jump if normalized
	ROMCALL(4, $06)	; MACC = MACC * 0.1 (FPT)
	INR	C	; Update 10's power
	JMP	@C3B3	; Cont. normalisation
;
; If exponent negative:
;
@C3C4	MOV	A, C
	CMA		; Change 10's power
	INR	A	; to neg. value
	MOV	C, A
@C3C8	CALL	FCOMP	; Compare with 0.1
	JP	@C3D4	; Jump if normalized
	ROMCALL(4, $09)	; MACC = MACC / 0.1 (FPT)
	DCR	C	; Update 10's power
	JMP	@C3C8	; Cont. normalisation
;
; Load output buffer:
;
@C3D4	MOV	A, C	; Get 10's power
	STA	DECBE	; In output buffer
	POP	PSW	; Get sign byte mantissa
	ORA	A	; Set flags on it
	LXI	H, DECBS	; Addr output buffer
	MVI	M, '+'	; '+'($2B) in buffer
	JP	@C3E4	; If mantissa is positive
	MVI	M, '-'	; Else: '-'($2D) in buffer
@C3E4	INX	H
	MVI	M, '.'	; '.'($2E) in DECBD
	INX	H
	PUSH	H
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	PUSH	PSW	; Save exp. byte
	XRA	A
	ROMCALL(4, $12)	; Copy mantissa to MACC
	POP	PSW	; Get exp. byte
	CMA
	INR	A	; 2—compl.
	ANI	$7F	; Mask sign bit mantissa
	LXI	H, I10	; Addr INT(10)
	ROMCALL(4, $54)	; MACC = MACC * 10 (INT)
	LXI	H, I1	; Addr. INT(1)
@C3FC	DCR	A
	JM	@C402	; If exp. converted
	ROMCALL(4, $72)	; Shift MACC right
@C402	JP	@C3FC	; If not ready
	POP	H
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	ADI	$30	; Exp. byte in ASCII
	MOV	M, A	; Into outputbuffer
	INX	H
	MVI	B, $06	; 6 sign. digits for mantissa
@C40E	CALL	LC424	; Convert one digit to ASCII
	MOV	M, A	; Into outputbuffer
	INX	H
	DCR	B
	JNZ	@C40E	; Next digit if not ready
	CALL	POF	; Retrive MACC form TOS
	POP	H
	POP	D
	POP	B
	MVI	A, $06
	RET
;
; DATA
;
I1	.byte	$00, $00, $00, $01	; 1 (INT)
;
; CONVERT A DIGIT FOR OUTPUT:
;
; Highest byte of MACC * 10 is made ASCII.
;
; Exit: A: Converted highest byte MACC
;       BCHL preserved.
;       DE corrupted.
LC424	PUSH	B
	PUSH	H
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	XRA	A	; Clear highest byte
	ROMCALL(4, $12)	; Copy reg A, B, C, D to MACC
	LXI	H, I10
	ROMCALL(4, $54)
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	ADI	'0'	; Make highest byte ASCII
	POP	H
	POP	B
	RET
;
; ************************
; * FPT NUMBER CONSTANTS *
; ************************
;
; For the first 7 numbers, the 1st byte is the power of 10 for division.
;
LC437	.byte	$00, $02, $80, $00, $00	; FPT (2^1)/10^0
	.byte	$00, $03, $80, $00, $00	; FPT (2^2)/10^0
	.byte	$01, $01, $CC, $CC, $CD	; FPT (2^4)/10^1
	.byte	$02, $02, $A3, $D7, $0A	; FPT (2^8)/10^2
	.byte	$04, $03, $D1, $B7, $17	; FPT (2^16)/10^4
	.byte	$09, $03, $89, $70, $5F	; FPT (2^32)/10^9
	.byte	$13, $01, $EC, $1E, $4A	; FPT (2^64)/10^19
;
LC45A	.byte	$7D, $CC, $CC, $CD	; FPT (0.1)
;
FP0	.byte	$00, $00, $00, $00	; FPT (0.0)
FP1	.byte	$01, $80, $00, $00	; FPT (1.0)
FP2	.byte	$02, $80, $00, $00	; FPT (2.0)
FP3	.byte	$02, $C0, $00, $00	; FPT (3.0)
FP4	.byte	$03, $80, $00, $00	; FPT (4.0)
FP5	.byte	$03, $A0, $00, $00	; FPT (5.0)
FP6	.byte	$03, $C0, $00, $00	; FPT (6.0)
FP7	.byte	$03, $E0, $00, $00	; FPT (7.0)
FP8	.byte	$04, $80, $00, $00	; FPT (8.0)
FP9	.byte	$04, $90, $00, $00	; FPT (9.0)
;
; *********************************
; * PRETTIES UP FPT OR INT NUMBER *
; *********************************
;
; Entry: B:         Fix/float flag (0=fix, 1=float).
;        A:         Nr. of useable digits in string in
;                   DECBUF (not counting additional digit for rounding).
;        DECBE:     Nr. of digits before '.' (exponent).
;        DECBUF:    Sign '+' or '-'
;        DECBD:     Decimal point
;        $E6—$F0:   Digits
; Exit:  All registers preserved.
;        DECBUF:    Length of string
;        $E4—$F0:   Output string
;
; Format: Sign in DECBUF is blank or '-'.
;         If exponent is 0:
;           real case: '0.digits'
;           int. case: no final '.'
;           real case if INT: '.0'
;         If exponent < -1: E-format
;         If exponent too 1arge: E-format
;         In E-format no '.0'
;
PRTY	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	H, DECBF	; Start addr digits
	MOV	C, A	; Save nr. useable digit
	PUSH	B
	MVI	B, $00
	DAD	B	; HL pnt to last useable digít
	MOV	A, M	; Get last digit
	CPI	'5'	; Check for rounding
	JC	@C4AF	; If < 5
@C498	DCX	H
	MOV	A, M	; Get digit before
	CPI	'9'
	JZ	@C4A3	; If it is 9
	INR	M	; Rounding upwards
	JMP	@C4AF	; Abort rounding
@C4A3	MVI	M, '0'	; Make digit before 0
	DCR	C	; Decr nr of digits
	JNZ	@C498	; Cont. check for rounding
	MVI	M, '1'	; Make nr=1 if all digits 9
	LXI	H, DECBE
	INR	M	; Incr nr of digits before '.'
@C4AF	POP	B
	INR	C	; Incr. nr useable digits
	LDA	DECBE	; Get nr of digits before '.'
	ORA	A
	JZ	@C4D8	; If 0
	JM	@C4E1	; If too many digits
	ADD	B	; Add fix/f1oat f1ag
	CMP	C
	JNC	@C4E1	; If too many digits
	CALL	LC69C	; Restore A, insert '.' after number string
@C4C3	MOV	A, C	; Length string in A
	CALL	LC54B	; Calc nr of digits for output
@C4C7	INR	A	; Add 1
	LXI	H, DECBUF
	MOV	M, A	; String length in outbuf
	INX	H
	MOV	A, M	; Get sign
	CPI	'+'	; '+'($2B)?
	JNZ	@C4D5	; Then abort
	MVI	M, ' '	; Replace '+' by blank
@C4D5	JMP	EXIT	; Popall, ret
;
; If format '0.digits':
;
@C4D8	CALL	LC51A	; Move string right 1 pos.
	MVI	M, '0'	; Insert 0 in DECBD
	INR	C	; Update nr of digits
	JMP	@C4C3	; Update string
;
; If too many digits:
;
@C4E1	MVI	A, $01
	CALL	LC531	; Move string left 1 pos.
			; Insert '.' after string
	MOV	A, C	; Get nr of digits
	MVI	B, $00
	CALL	LC54B	; Calc nr of digits for output
	MOV	B, A	; in B
	LDA	DECBE	; Get nr of digits before '.'
	DCR	A	; Minus 1
	MVI	M, 'E'	; 'E' in buf after 1ast digit
	INX	H
	INR	B	; Incr. nr of digits
	ORA	A	; Flags on exponent
	JP	@C4FF	; If exp. positive
;
; If exponent negative:
;
	MVI	M, '-'	; Store '-' in buffer
	INX	H
	INR	B	; Incr nr of digits
	CMA
	INR	A	; 2-compl of exponent
;
; Exponent to buffer:
;
@C4FF	LXI	D, $2F0A
@C502	SUB	E	; Exp.-10 (unit value)
	INR	D	; ASCII-count 10's-value
	JNC	@C502	; If rest exp. still > 10
	ADI	$3A	; Convert rest to Ascii
	MOV	E, A	; in E
	MOV	A, D	; Get 10's value
	CPI	$30
	JZ	@C513	; If exp. < 10
	MOV	M, A	; 10's value exp. in buf
	INX	H
	INR	b	; Incr nr of digits
@C513	MOV	M, E	; Unit value exp. in buf
	INX	H
	INR	B	; Incr nr of digits
	MOV	A, B	; into A
	JMP	@C4C7	; Prepare string for output
;
; MOVE STRING IN OUTPUTBUFFER RIGHT 1 POS.
;
; The contents of DECBF-1 is moved up one position to DECBF.
;
; Entry: No conditions.
; Exit:  ABCDEF preserved.
;        HL points to $00E5.
;
LC51A	PUSH	PSW
	PUSH	B
	PUSH	D
	LXI	H, DECBF+MAXSIG	; Highest destination address
	MOV	D, H
	MOV	E, L
	DCX	D		; Highest source address
	MVI	B, MAXSIG+1	; Number of bytes
@C525	LDAX	D		; Get byte
	MOV	M, A		; and move it
	DCX	D
	DCX	H
	DCR	B
	JNZ	@C525		; Next byte if not ready
	POP	D
	POP	B
	POP	PSW
	RET
;
; MOVE STRING IN OUTPUTBUFFER LEFT 1 POS.
;
; The string, beginning on DECBF, is moved one memory 1ocation downwards. A '.' is
; inserted after the string.
;
; Entry: A: number of bytes to be transferred.
; Exit:  All registers preserved.
;
LC531	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	MOV	B, A	; Store number of bytes
	LXI	H, DECBD	; Lowest destination address
	LXI	D, DECBF	; Lowest source address
@C53C	LDAX	D	; Get byte
	MOV	M, A	; and move it
	INX	D
	INX	H
	DCR	B
	JNZ	@C53C	; Next byte if not ready
	MVI	M, '.'	; Insert '.' after string
	POP	H
	POP	D
	POP	B
	POP	PSW
	RET
;
; CALCULATE NUMBER OF DIGITS FOR DUTPUT:
;
; Entry: Total nr of string digits in A and C.
;        B: Flag for INT (0) or FPT (1)
;        Digits in DECBUF+1 to DECBUF+1 + A
; Exit:  A:  Nr of bytes for output:
;            INT: excl. trailing '.0'
;            FPT: incl. trailing '.0'
;        HL: If 1ast non-zero byte is not '.':
;            points after 1ast byte.
;            Else: INT: points to '.'
;                  FPT: after '.0'
;
LC54B	PUSH	B
	PUSH	D
	LXI	H, DECBUF+1	; Start addr string
	MOV	E, A	; Total nr of digits in E
	MVI	D, $00
	DAD	D	; Calc end of string
@C554	MOV	A, M	; Get digit
	CPI	'0'
	JNZ	@C55F	; If non-zero
	DCX	H	; Points to previous digit
	DCR	C	; Decr nr of digits
	JMP	@C554	; Again till non-zero found
;
; If non-zero digit founds
;
@C55F	CPI	'.'	; '.'?
	INX	H
	JNZ	@C56F	; Abort if not
	DCX	H	; Pnts after 1ast non-zero, non-'.' digit
	DCR	C	; Excl. '.'
	DCR	B
	JNZ	@C56F	; If INT case
	INX	H	; If FPT Case: pnts
	INX	H	; after '.0'
	INR	C
	INR	C	; Incl. '.0'
@C56F	MOV	A, C	; Nr of digits for output
	POP	D
	POP	B
	RET
;
; ********************************
; * INPUT INTEGER NUMBER TO MACC *
; ********************************
;
; Read string of digits from line and convert it to binary in MACC.
;
; Entry: BC points to input character.
; Exit:  BC points after INT number.
;        ADEHL preserved.
;        CY=1: there were digits.
;        CY=0: No digits.
;
ICB	STC
	PUSH	PSW
	PUSH	D
	PUSH	H
	CALL	LC598	; Clear MACC and FPTWRK
@C57A	CALL	LC073	; Get digit from line
	SUI	$30	; Convert ASCII to binary
	JC	LC590	;
	CPI	$0A	; Abort if no number
	JNC	LC590	;
	LXI	H, I10	; Addr INT(10)
	CALL	LC5A5	; MACC = MACCH * 10 + digit
	JMP	@C57A	; Next digit
LC590	DCR	D
	INR	D
	JNZ	LC2A2	; If digits: Pop ret
	JMP	LC2A9	; If no digits: CY=0, Pop, ret
;
; CLEAR MACC AND FPTWRK
;
; Both MACC and registers FPTWRK are 1oaded with the value of FPT (0).
;
; Exit: ABCE preserved. D=0.
;
LC598	LXI	H, FP0	; Addr. FPT(0)
	ROMCALL(4, $0C)	; Copy FPT(0) to MACC
	LXI	H, FPTWRK
	ROMCALL(4, $0F)	; Copy FPT(0) to FPTWRK
	MVI	D, $00	; Clear D
	RET
;
; MACC = MACC 10 + DIGIT FROM LINE.
;
; Entry: HL: points to INT (10).
;        A:  digit to be added.
;
LC5A5	ROMCALL(4, $54)	; MACC = MACC * 10 (1NT)
LC5A7	INR	C
	DCR	D
	STA	FPTWRK+3	; Digit in 1obyte FPTWRK
	LXI	H, FPTWRK
	ROMCALL(4, $4E)	; Add (E3-E6) to MACC (INT)
	RET
;
; *************************************
; * CONVERT INTEGER NUMBER FOR OUTPUT *
; *************************************
;
; Places ASCII string from INT MACC contents in output buffer 00E4-F0.
; DECBUF is sign, DECBD is '.', DECBF is value, DECBE is nr of digits.
;
; Exit: A: Number of digits.
;       BCDEHL preserved.
;
IBC	PUSH	B
	PUSH	D
	PUSH	H
	CALL	PLISH	; Save MACC to TOS
	CALL	@C5E0	; Abs.val ue of MACC in regs A,B,C, D; Prepare 00E4-E6
@C5BB	CALL	PLISH	; Save MACC to TOS
	LXI	H, I10	; Addr INT (10)
	ROMCALL(4, $5A)	; MACC = remainder MACC/10
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	MOV	A, D	; Lobyte in A
	CALL	@C5FA	; Digit into $00E5-F0
	CALL	POF	; Retrieve MACC from T0S
	ROMCALL(4, $57)	; MACC = MACC/10 (INT)
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	ORA	B
	ORA	C
	ORA	D
	JNZ	@C5BB	; Again if <> 0
	CALL	@C606	; '.' in DECBD; length in DECBE
	CALL	POF	; Retrieve MACC from TOS
	POP	H
	POP	D
	POP	B
	RET
;
; PREPARE DECBUF+1
;
; DECBUF+1 is set to +00 or -00, depending on sign
; of contents MACC. In the MACC remains the absolute
; value. The registers A, B, C, D contain the original
; contents of the MACC.
;
; Exit: E=0. HL preserved. AFBCD corrupted.
;
@C5E0	PUSH H
	LXI	H, DECBS
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	ORA	A	; Set flags on sign
	MVI	M, '+'	; '+' in DECBS
	JP	@C5F0	; Jump if nr is positive
	MVI	M, '-'	; Else '-' in DECBS
	ROMCALL(4, $60)	; and make contents MACC pos.
@C5F0	INX	H
	MVI	M, '0'	; 0 in DECBD
	INX	H
	MVI	M, '0'	; 0 in DECBF
	MVI	E, $00	; Digit count is 0
	POP	H
	RET
;
; STORE DIGIT IN OUTPUT FUFFER $00E5-$00F0
;
; Entry: Digit in A.
; Exit:  Digit in $00E5-F0 as most sign. digit.
;        E: Count of digit in buffer.
;        BCDHL preserved. AF corrupted.
;
@C5FA	PUSH	H
	PUSH	PSW
	CALL	LC51A	; Move contents buffer right
	POP	PSW
	ADI	'0'	; Make digit ASCII
	MOV	M, A	; Digit in $00E5 inserted.
	INR	E	; Update digit count.
	POP	H
	RET
;
; ADD A '.' TO A DIGIT STRING IN OUTPUTBUFFER:
;
; A '.' is placed at the beginning of a digit string in the output buffer.
; The length of the string is stored in DECBE.
;
; Entry: E:  Digit count.
;        HL: Points to DECBD
; Exit:  A: Count.
;	BCDEHL preserved.
;
@C606	CALL	LC51A	; Move contents outbuf right one position
	MVI	M, '.'	; '.' at begin of string
	MOV	A, E	; Get digit count
	STA	DECBE	; Store it in buffer
	RET
;
; DATA
;
I10	.byte $00, $00, $00, $0A	; INT (10)
;
; ****************************
; * INPUT HEX NUMBER TO MACC *
; ****************************
;
; Reads a sequence of hex digits and converts them into MACC.
;
; Entry: C points to input.
; Exit:  CY=1: There was a digit.
;        CY=0: No digit.
;        C points to next input.
;        ABDEHL preserved.
;
HCB	STC
	PUSH	PSW
	PUSH	D
	PUSH	H
	CALL	LC598	; Clear MACC and FPTWRK
@C61B	CALL	LC073	; Get digit from line
	SUI	'0'
	JC	LC590
	CPI	$0A	; Check if hex number
	JC	@C634
	SUI	$07	; Abort via LC590 if not
	CPI	$0A
	JC	LC590
	CPI	$10
	JNC	LC590
@C634	LXI	H, I4	; Addr INT (4)
	CALL	LC641	; Insert digit at low end MACC
	JMP	@C61B	; Get next digit
;
; DATA:
;
I4	.byte $00, $00, $00, $04	; INT (4)
;
; ENTER HEX DIGIT AT LOW END MACC:
;
; Entry: HL points to a 4-byte number.
;        A  contains a digit.
; Exit:  HL = FPTWRK
;        C is incremented, D decremented.
;        ABE preserved.
;
LC641	PUSH	PSW
	PUSH	B
	PUSH	D
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	ANI	$F0	; Check if vale too high
	CNZ	FPEOV	; Then overflow error
	POP	D
	POP	B
	POP	PSW
	ROMCALL(4, $6F)	; Shift left
	JMP	LC5A7	; Add digit to MACC
;
; ****************************************
; * CONVERT HEX MACC TO ASCII FOR OUTPUT *
; ****************************************
;
; Converts a HEX number in MACC into its ASCII representation into the output buffer.
; Not significant leading zeroes are cancelled.
;
; Exit: BCDEHL preserved.
;       AF corrupted.
;       Length outpt string in DECBUF.
;       Output string starting from DECBUF+1
;
HBC	PUSH	B
	PUSH	D
	PUSH	H
	CALL	@C68D	; Get start addr DECBUF in HL
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	CALL	@C66A	; Convert A, B to ASCII into DECBUF
	MOV	A, C
	MOV	B, D
	CALL	@C66A	; Idem for C, D
	CALL	@C691	; Get string length in DECBUF
	POP	H
	POP	D
	POP	B
	RET
;
; Convert 2 hex digits:
;
@C66A	CALL	@C66E	; Convert 1st digit
	MOV	A, B	; Get 2nd one
@C66E	PUSH	PSW
	RAR
	RAR
	RAR
	RAR		; Shift high nibble in low
	CALL	@C677	; Convert it to ASCII
	POP	PSW	; Restore both nibbles
@C677	ANI	$0F	; Low nibble only
	CPI	$0A
	JC	@C680	; If 0 < digit < 9
	ADI	$07	; Add 7 for A < digit < F
@C680	ADI	'0'	; Convert to ASCIT
	MOV	M, A	; Into DECBUF
	INX	H	; Incr pointer
	CPI	'0'
	RNZ		; Abort if digit <> 0
;
; If 1st digit is zero:
;
	MOV	A, L	; Get 1st byte buffer pointer
	CPI	$E5	; 1st digit in buffer?
	RNZ		; Abort if not
	DCX	H	; Else: cancel non-sign. 0's
	RET
;
; Get start address output buffer:
;
@C68D	LXI	H, DECBUF+1	; Start addr in HL
	RET
;
; CALCULATE LENGTH OF STRING IN OUTPUT BUFFER
;
; Entry: L: 1obyte of address last digit in buffer.
; Exit:  BCDEHL preserved. AF corrupted.
;        Length is stored in DECBUF.
;
@C691	MOV	A, L	; Get 1obyte addr 1ast digit
	SUI	$E4	; Minus begin addr
	CPI	$01
	ACI	$00	; Length min. 1
	STA	DECBUF	; Store 1ength in DECRUF
	RET
;
; *****************************************
; * RESTORE A, ADD '.' AFTER DIGIT STRING *
; *****************************************
;
; Part of PRTY (LC486)
;
LC69C	SUB	B	; Restore A
	JMP	LC531	; Move string 1eft 1 pos, insert '.'
;
; **************************************
; * PRINT CHARACTER, INPUT A TEXT LINE *
; **************************************
;
; Part of Run 'INPUT' ($0E3D6)
;
; Entry: Character in A.
; Exit:  BC preserved.
;
PINPLN	PUSH	B
	CALL	INPLN	; Print char; input textline
	POP	B
	RET
;
	.byte	$FF, $FF
;
; *******************
; * DATA FOR RANDOM *
; *******************
;
RNDA	.byte	$00, $00, $00, $3B	; Random number constant A
RNDB	.byte	$07 ,$73, $59, $41	; Random number constant B
IROR	.byte	$01, $80, $00, $00	; OR mask (FPT (1))
;
; ******************************
; * part of READ BLOCK (LD340) *
; ******************************
;
; Exit if no 1oading errors.
;
LC6B4	XTHL
	STC	; CY=1: no error
LC6B6	POP	H
	POP	D
	POP	B
	RET
;
; *****************
; * part of 2E8DE *
; *****************
;
SPT02	CALL	LCE91	; Go and set screen bits for mode 1
	JMP	XRET	; (2) Pop all, ret.
;
;
;    ==============
;*** BANK SWITCHING ***
;    ==============
;
;
; ***** *******************
; * MATH. RESTART (RST 4) *
; *************************
;
; This, and the following routínes, switch the paged banks of ROM.
; They are entered via RST x; DATA xx instructions.
;
MARST	POP	H
	DI
	SHLD	RSWK2	; Save HL
	PUSH	PSW
	POP	H
	SHLD	RSWK1	; Save PSW
	MVI	H, $40	; ROM bank 1 select bits
	LDA	MVECA	; Offset of start HW/SW vector
;
; ROM BANK SWITCHING:
;
; This routine is generally used by all Restarts using ROM bank switching.
;
MRSIO	XTHL
	ADD	M	; Add entry number
	INX	H
	XTHL
	MOV	L, A	; Complete entry point address
	LDA	POROM	; O1d bank select port status
	PUSH	PSW	; Save it
	ANI	$3F	; Keep other bits
	ORA	H	; Add new select bits
	STA	POROM	; Update memory
	STA	PORO	; Update port
	MVI	H, $E0
	CALL	MRDCL	; Restore HL, PSW; Switch bank
;
; Return from switched bank:
LC6E6	XTHL		; Return to old bank
	PUSH	PSW
	MOV	A, H	; Get old bank
	STA	POROM	; Reinstate memory
	STA	PORO	; Re-instate port
	POP	PSW
	POP	H
	RET		; Return to caller
;
; SWITCH TO ROM BANK:
;
; HL and PSW are restored. On exit, the program switches to the selected ROM bank.
; After return from this bank, the program continues on LC6E6.
MRDCL	PUSH	H
	LHLD	RSWK1
	PUSH	H
	POP	PSW	; Restore A, F
	LHLD	RSWK2	; Restore H, L
	EI
	RET		; Switch to selected bank
;
; **************************
; * SCREEN RESTART (RST 5) *
; **************************
;
; From SRS10 also used by RST 1.
;
SCRST	POP	H
	DI
	SHLD	RSWK2	; Save HL
	PUSH	PSW
	MVI	A, $80	; ROM bank 2 select bits
SRS10	POP	H
	SHLD	RSWK1	; Save PSW
	MOV	H, A
	XRA	A
	JMP	MRSIO	; Switch to new bank
;
; **************************
; * UTILITY/ENCODE (RST 1) *
; **************************
;
UTRST	POP	H
	DI
	SHLD	RSWK2	; Save HL
	PUSH	PSW
	MVI	A, $C0	; ROM bank 3 select bits
	JMP	SRS10	; Switch to ROM bank 3
;
;
;     =============
; *** BASIC HANDLER ***
;     =============
;
;
; *********
; * RESET *
; *********
;
; BASIC entry point. Entry via hardware reset by means of a bootstrap on the
; address lines to $C000.
;
; This section is responsible for all 'once only' initialisation of the hardware and
; the sottware environment. It initialises pointers to all RAM areas required, the
; interrupt system and the software modules.
;
INIT	.equ	*
RESET	LXI	SP, $F900	; Init. stack pointer
	MVI	A, $30	; Cassette motors off;
	STA	POROM	; paddle enable off;
	STA	PORO	; select ROM bank 0
	CALL	INTINI	; Init. interrupt sytem
	LXI	H, $0000
	SHLD	STBUSE	; Set for no Basic
	XRA	A
	STA	RNDLY	; RNDLY=0
	NOP
	NOP
;
; Init. math package:
;
	LXI	D, $C7F2	; Addr table error vectors
	LXI	H, $DDE0	; Addr routine get char/line
	CALL	XINIT	; Package initialisation
;
; Init screen RAM:
;
	CALL	MEMCHK	; Check available RAM space
	DCX	H	; Highest RAM ddress
	LXI	D, $C7E0	; Addr screen default data
	ROMCALL(5, $00)	; Init. screen RAM
;
; Init I/O:
;
	XRA	A
	CALL	LEE8D	; (0) Init. I/O switching (input keyb; output screen + RS232)
	STA	EFSW	; Input from keyboard for encoding
	MVI	A, $C0
	STA	TIC_RR	; Init. TICC baud rate
;
; Init screen
;
	CALL_W(PMSGR, MSGHDR)	; Print 'DAI PERSONAL COMPUTER'
	LHLD	SCRBOT	; Get bottom screen RAM
	LXI	D, $097B
	DAD	D	; Get line mode byte of line with 'DAI PC'
	MVI	M, $5F	; Set for medium resolution
	LXI	D, $FFD0
	DAD	D	; Create new line mode byte for line with COMPUTER
	CALL	LCEF9	; Place 'COMPUTER' on new line
	MVI	D, $0F	; Nr of blanking lines
@C768	CALL	LCECF	; Blank next 15 lines
	DCR	D
	JNZ	@C768	; Next line
;
; Prepare BASIC:
;
	CALL	LD72D	; Init. Soundgen/DCEbus/transfer cassette data/
			; set start HEAP/get evt. DCE-inputs
	LXI	H, SYSBOT
	SHLD	HSIZE	; HEAP size default value
.if ROMVERS == 11
	CALL	RNEW	; Run 'NEW'
.endif
.if ROMVERS == 10
	CALL	RNEW	; Run 'NEW'
.endif
	MVI	A, $10
	STA	CASSL	; Select Cassette port 1
	LXI	H, KEYTU	; (3) Ptr. to ASCII table
	CALL	KBINIT	; Init keyboard pointers
	CALL	SHINIT	; Init string handler
.if ROMVERS == 11
; Now switches off the volume of sound channel 2 during initialisation. This is useless,
; because in C76C all sound is already switched off, just to keep same length of BASIC 1.0
	STA	SCB2+6	; Volume SCB2 = 0
	STA	IMPTYP
	LXI	D, IMPTAB
	LXI	H, IMPTAB+26
	CALL	FILL
	EI
	ROMCALL(1, $15)
.endif
.if ROMVERS == 10
	MVI	A, $00
	STA	IMPTYP	; Default number type FPT
	LXI	D, IMPTAB-$41	; Begin IMPTAB
	LXI	H, IMPTYP	; End IMPTAB
	CALL	FILLMEM	; Init. implicit type table with 0 (= FPT)
	EI
	ROMCALL(1, $15)	; Wait for input keybeard or RS232
	NOP
.endif
	LXI	H, STCOL	; Ptr. to mode colours
	ROMCALL(5, $06)	; Set text colours
;
; Entry from utility:
;
RINIT	CALL_W(SELB0, MSGIN)	; Select ROM bank 0 and print 'BASIC V1.0'
	JMP	$C818	; Into BASIC monitor
;
; INITIALISATION SCREEN DATA
;
MSGHDR	.byte	$0D, $0D, $0D, $0D, $0D, $0D	; Frigged screen header
	.ascii	" DAI PERSONAL              COMPUTER"
	.byte	$0D, $00
MSGIN	.byte	$0C
.if ROMVERS == 11
	.ascii	"BASIC V1.1"
.endif
.if ROMVERS == 10
	.ascii	"BASIC V1.0"
.endif
	.byte	$0D, $00
;
; SCREEN INITIALISATION PARAMETERS
;
SIPAR	.byte	$01	; Default cursor type
	.byte	$5F	; Default cursor ASCII value
;
	.byte	$05, $0F $0F, $05	; Colours COLORT during Reset
;
	.byte	$00, $05 $0A, $0F	; Default colours COLORG
;
	.word	ASKRM	; Addr. memory management routine
	.word	EMSTP	; Addr. emergency stop routine
;
STCOL	.byte	$08, $00, $00, $08 ; Default colours COLORT
;
; MATH. ERROR ROUTINE VECTORS
;
MEVEC	.word	ERROV	; Addr. Overflow error routine
	.word	ERRRA	; Addr. Number out of range error routine
	.word	MERET	; Addr. Return
	.word	ERRD0	; Addr. Error routine Division by zero
;
MERET	RET		; Return
;
;
; *********************************
; * CHECK FOR HIGHEST RAM ADDRESS *
; *********************************
;
; Entry: No conditions.
; EXit:	HL points after RAM.
;	BC preserved, ADEF corrupted.
;
MEMCHK	LXI	D, $1000
	LXI	H, $0000	; Start at $0000
@C801	DAD	D	; Incr. with #1000
	MOV	A, M	; Get what is in memory
	CMA		; Take its complement
	MOV	M, A	; and store it back
	CMP	M	; Then compare
	CMA
	MOV	M, A	; Restore original value
	JZ	@C801	; Next block if still RAM
	RET
;
; **********************
; * START FROM SCRATCH *
; **********************
;
; Entry to Basic monitor
; V1.1  Added is the reset of all keyboard pointers at various moments:
;        - when restarting the Basic interpreter.
;        - after command execution. Then also the output direction is reset to screen (to avoid a not useable keyboard
;        - idem before executing 'break'
;       Resetting the keyboard pointers clears the key input buffer in order to avoid keybounce.
;
; If out of a Hard BREAK:
;
RSTART	LXI	SP, $F900 ; Reset stack pointer
	CALL_W(SELB0, MSG07)	; Select ROM bank 0, print '*** BREAK'
;
; Re-enter Basic after run-time error, except on input:
;
START	XRA	A
	STA	EFSW	; Input from keyb/DINC
;
;
; Entry on reset, after encoding program line after END:
;
LC818	LXI	H, $F900
	SHLD	v_STACK	; Reset current base stack
	SPHL		; Reset stack pointer
	XRA	A
	STA	CONFL	; No suspended program
;
; Restart interpreter entry after end of program after direct command,
; after soft BREAK, after direct command error, after STOP:
;
LC823	LHLD	v_STACK	; Get saved stack pointeer
	SPHL		; Set it to saved value
.if ROMVERS == 11
	CALL	KLIRP	; Keyb. pntrs to default
	LXI	H, $0000
	SHLD	CURRNT
	SHLD	LOPVAR
	SHLD	STKGOS
	MOV	A, H
	STA	ERSFL
 .endif
.if ROMVERS == 10
	LXI	H, $0000
	SHLD	CURRNT	; Reset current line nr
	SHLD	LOPVAR	; No running 1oops
	SHLD	STKGOS	; No active subroutine cal1
	MOV	A, H
	STA	ERSFL	; No encoding of stored line
	NOP
	NOP
	NOP
.endif
	LXI	H, RDIPF
	MOV	M, A	; No running of inputs
	INX	H
	MOV	M,A	; No running of program
	CALL	KBEI	; Enable keyboard interrupt
	CALL	CLKEI	; Enable clock interruupt
 @C846	LDA	EFSW	; Get input direction
	CPI	$02
	CZ	LD879	; EFSW=2 input from editbuf .
	JNC	@C867	; encode TEXTLINE if EDITBUF is not empty
	MVI	A, $2A	;
	CALL	INPL0	; Print '*', scan keyboard and display characters
			; until Break or car. ret (If no input is given,
			; the DAI remains here in a endless 1oop).
	JC	@C846	; If BREAK: new inputs
	CALL	IGNB	; Get char from line, neglect TAB and space
	CPI	$0D
	JZ	@C846	; If car.ret: new inputs
	CALL	NUMBER	; Check if char is number
	JNC	@C86D	; If no leading nr: encode cmd
;
; Encode program line (if 1st char is number)
;
@C867	CALL	PROGI	; Encode program line update program
	JMP	LC818	; Get next input lines ki11 any suspended program
;
; Encode direct command (if 1st char is no number)
;
@C86D	MVI	D, $80	; Mask for direct command
	PUSH	H	; Pointer to RUNF
	LXI	H, EBUF+1	; Addr EBUF
	PUSH	H	; Save it on stack
	ROMCALL(1, $00)	; Encode immediate cmd line
	MVI	M, $00	; Dummy end of progran
	CALL	CRLF	; Print car.ret
	POP	B	; Get EBUF pntr
	POP	H	; Pntr to RUNF
	MVI	M, $FF	; Set flag running programs
;
; Run a Basic line:
;
LC87F	LDAX	B	; Get ist byte from EBUF:
			; <  #80: length,
			; >= #80: Token.
LC880	INX	B
	ADD	A	; Calc offset from $CF00
	JNC	LC8E5	; Jump if length byte
	MOV	L, A	; Get table address in HL
	MVI	H, $CF
	MOV	A, M	; Get addr Basic routine
	INX	H	; from table in HL
	MOV	H, M
	MOV	L, A
	CALL	DCALL	; Perform this routine
;
; Commands return here
;
ENDCOM	JC	LC8AA	; Jump 1f special action
;
; If suspended:
;
	MOV	H, B
	MOV	L, C
	SHLD	BRKPT	; Remember start next cmd
.if ROMVERS == 11
	LXI	H, KBRFL
	MOV	A, M	; Get break flag
	ORA	A
	JZ	LC87F
LC89F	CALL	KLIRP	; Keyb pntrs to default
	XRA	A
	STA	OTSW	; Output to screen
.endif
.if ROMVERS == 10
	LDA	KBRFL
	ORA	A	; BREAK flag set?
	JZ	LC87F	; Run Basic line if not
	NOP
	NOP
	NOP
	MVI	A, $FF
	STA	KBRFL	; Set BREAK f1ag 'serviced'
.endif
	JMP	LC8C0	; Handle break
;
; Run a BASIC line
;
DCALL	PCHL		; Addr Basic routine in PC
;
; If special end of action
;
;
LC8AA	CPI	$02
.if ROMVERS == 11
	JZ	LC89F	; Keyb.pntrs to default
.endif
.if ROMVERS == 10
	JZ	LC8C0	; If soft break (2)
.endif
	JNC	@C8B8	; If STOP (3)
	JPE	LC818	; If can't continue (1)
	JMP	LC908	; If after LOAD (0)
;
; If 'STOP'
;
@C8B8	MOV	H, B
	MOV	L, C
	SHLD	BRKPT	; Remember where next cmd
	JMP	LC8C5	; Print 'IN LINE ...' and handle a break
;
; If suspended (soft Break handling)
;
LC8C0	CALL_W(PMSGR, MSG09)	; Print car.ret; 'BREAK'.
LC8C5	CALL	MSGIL	; Print 'IN LINE ...' or car.ret
	JZ	LC823	; Jump if immediate cmd
;
; Only if 'break' in program
;
LC8CB	LXI	H, $FFEB	; Frame length
	DAD	SP	; New stack level
	MOV	B, H
	MOV	C, L
	SHLD	v_STACK	; Set new base stack
	SPHL		; Set stack pointer
	LXI	D, SYSBOT	; Boundaries frame
	LXI	H, SYSTOP
	CALL	MOVE	; Save program status (FRAME) on stack.
	LXI	H, CONFL
	INR	M	; Set f1ag existence saved program
	JMP	LC823	; Run again
;
; Length byte or end flag
;
LC8E5	JZ	LC823	; If end immediate cmd line or end program
	MOV	H, B
	MOV	L, C
	SHLD	SYSBOT	; Store start current line
	LHLD	STRFL	; Get trace + step flag
	MOV	A, H
	ORA	L
	JZ	@C900	; If no step/trace flag
;
; If step/trace flag set
;
	PUSH	H
	PUSH	B
	CALL	LCEA4	; List current line
	POP	B
	POP	PSW	; Get step flag
	ORA	A	; If set:
	CNZ	WSPACE	; Wait for spacebar pressed
@C900	INX	B
	INX	B	; Pnts after line nr
	JC	LC8CB	; If Break
	JMP	LC87F	; Run next BASIC line
;
; Special action after LOAD
;
LC908	LHLD	CURRNT	; Get start current line
	MOV	A, H
	ORA	L	; Direct Cmd?
	JZ	LC87F	; Then run Basic line
	LXI	SP, $F900 ; Else: reset stack pointer
	MVI	A, $87	; Similate Token 'RUN'
	JMP	LC880	; Pretend RUN Cmd
;
; PROGRAM INPUT
;
; Encodes a program line and updates the stored program.
;
; Entry: C: Input count / offset
; Exit:  C: Offset after line
;        AFBDEHL preserved
;
PROGI	LXI	H, EBUF+1	; Addr buf for encoded cmds
	ROMCALL(1, $03)	; Get line nr
	CALL	IGNB	; Get char from line; neglect TAB + space
	CPI	$0D	; Car.ret?
	CZ	LDEL	; Delete old version if only line nr given
	JZ	@C93B	; Jump if line nr only
	PUSH	D	; Remember line nr
	MVI	D, $40	; Mask for 'stored cmd'
	CALL	ELINA	; Encode a line
	MOV	A, L
	SUI	<EBUF + 1	; Length string in A 
	STA	EBUF	; Length in EBUF
	POP	D	; Get line nr
	CALL	LDEL	; Delete old line
	CALL	LINS	; Insert new line
@C93B	RET
;
; ENCODE A LINE
;
; Exit: DE restored.
;       HL points to 1st free byte in EBUF.
;        C points after car.ret in input
;        A=0, F corrupted.
;
ELINA	PUSH	D
	PUSH	B
	PUSH	H
	LXI	H, $0000
	DAD	SP	; Stack pointer in HL
	SHLD	ERSSP	; Save stack pointer
	POP	H
	PUSH	H
	MVI	A, $01
	STA	ERSFL	; Set encoding a stored line
	ROMCALL(1, $00)	; Encode inputs
	POP	D	; Cancel Push B, H
	POP	D
LC951	XRA	A
	STA	ERSFL	; No encoding stored line
	POP	D
	RET
;
; **************************************
; * ERROR WHILE ENCODING A STORED LINE *
; **************************************
;
; Restores stack pointer, adds '***' to begin of line, adds '?' to place of error.
; Line is entered into the encoded inputbuffer (EBUF).
;
; Entry: B: error code.
;        C: Place of error.
;        On stack: BC points to input.
;                  HL points to EBUF.
;
ELARS	LHLD	ERSSP	; Get ERSSP
	SPHL		; Restore stack pointer
	POP	H	; Get buffer pointer
	MOV	A, B	; Errorcode in A
	MOV	D, C	; Place of error in D
	POP	B	; Get input pointer
	MOV	B, A
	MVI	M, $B1	; Token for '***' in EBUF
	INX	H
	PUSH	H	; Save buf pointer
	INX	H
@C965	MOV	A, C	; Place of error
	CMP	D	; reached?
	MVI	A, '?'
	CZ	ELAIN	; Then insert '?'
	CALL	EFETCH	; Get char. from line
	INR	C	; Update input pointer
	CPI	$0D	; Line done?
	CNZ	ELAIN	; Insert char in EBUF if not
	JNZ	@C965	; Next char if not ready
	MOV	A, L	; Lobyte EBUF pntr in A
	POP	D	; Addr after '***'
	SUB	E
	DCR	A
	STAX	D	; Store length in EBUF
	MVI	M, $00	; after string
	PUSH	B	; Save error message pntr
	MOV	B, D	; EBUF pntr in BC
	MOV	C, E
	DCX	B
	DCX	B
	DCX	B
	DCX	B	; Pnts to begin EBUF
	CALL	CRLF	; Print car.ret
	CALL	SLINE	; (0) List current line
	POP	B	; Get error message pntr
	PUSH	H
	CALL	ERRMS	; Print error message
	POP	H
	JMP	LC951	; Store 0 in ERSFL, Pop D, and ret.
;
; INSERT CHARACTER IN ENCODED INPUT BUFFER:
;
; A character is inserted in the EBUF only if there is space available.
;
; Entry: HL: 1st free location in EBUF
;        A:  Character to be inserted
; Exit:  HL updated. AFBCDE preserved
;
ELAIN	PUSH	PSW
	MOV	A, L	; Get lobyte of EBUF pntr
	CPI	$BC	; Buffer full?
	JZ	@C9A0	; Then abort
	POP	PSW
	MOV	M, A	; Char into ERUF
	INX	H	; Update pntr
	RET
;
; If EBUF ful1
;
@C9A0	POP	PSW	; No action
	RET
;
; ********************************
; * DELETE OLD VERSION OF A LINE *
; ********************************
;
; A textline is deleted by moving the rest of thetextbuffer and the symbol
; table 'downwards'.
;
; Entry: DE: requested linenumber
; Exit:  DE points to line nr after deleted line
;        AFBCHL preserved.
;
LDEL	PUSH	PSW
	PUSH	B
	PUSH	H
	XCHG		; Linenr in HL
	CALL	FINDL	; Addr line in textbuf in HL
	JNC	@C9B8	; Abort if not found
	MOV	A, M	; Get line length
	CMA
	MOV	E, A	; Compl. value in E
	MVI	D, $FF
	CALL	DADM	; HL=HL - line length
	XCHG
	CALL	PROGM	; Move program buffers
@C9B8	XCHG
	POP	H
	POP	B
	POP	PSW
	RET
;
; *********************
; * INSERT A NEW LINE *
; *********************
;
; Inserts an encoded 11ne in the textbuffer.
; Required space for the textline is made by shifting the rest of the textbuffer and
; the symboltable 'upwards'.
;
; Entry: DE: Destination address in textbuffer
;        HL: Points after string in EBUF
;        A:  Length string in EBUF
;
LINS	PUSH	B
	PUSH	H
	MOV	L, A
	MVI	H, $00	; String length in HL
	INX	H	; Required space in HEAP
	PUSH	D
	CALL	PROGM	; Move program buffers
	POP	B
	POP	H
	LXI	D, EBUF	; Start addr. EBUF
	CALL	MOVE	; Transfer data from EBUF into textbuffer
	POP	B
	RET
;
; ************************
; * MOVE PROGRAM BUFFERS *
; ************************
;
; Moves a part (or the whole) textbuffer and the whole symboltable up or down.
; The start address of the textbuffer and the end of the symbal table are set
; depending on the heap size. The heap pointers are updated.
;
; Entry: DE: Address from where to update
;        HL: Length of area to be inserted/deleted
; Entry if running 'NEW' only:
;        BC: 0
;        DE: start address Heap
;        HL: Size Heap
;        At entry, the pointers for textbuf and symtab are as if HEAPsize is zero
; Exit:  AFBCDE preserved
;        HL: New start address
;
PROGM	PUSH	B
	PUSH	D
	MOV	B, D	; Addr from where to
	MOV	C ,E	; update in BC
	XCHG		; Length area in DE
	LHLD	STBUSE	; Get end symtab
	PUSH	H
	PUSH	D
	DAD	D	; New end symtab
	XCHG
	LHLD	SCRBOT	; Get bottom screen RAM
	CALL	COMP	; Check for overflow
	XCHG		; End symtab in HL
	JC	ERROM	; Evt. run 'OUT OF MEMORY'
	SHLD	STBUSE	; Store end synbol table
	POP	D
	PUSH	D
	LHLD	STBBGN	; Get begin symtab
	DAD	D	; New begin symtab
	SHLD	STBBGN	; Store begin symbol table
PRGM1	POP	H
	MOV	D, B
	MOV	E, C	; Startaddr in DE
	DAD	D	; New startaddr
	MOV	B, H
	MOV	C, L	; New startaddr in BC
	XTHL		; Get old end symtab
	CALL	MOVE	; Move textbuf +symtab from old to new addr.
	POP	H
	POP	D
	POP	B
	RET
;
;
;
; *****************************
; * MEMORY MANAGEMENT ROUTINE *
; *****************************
;
; This routine is used to obtain and release memory or its display, as the mode changes.
;
; Entry: HL: Lowest screen RAM byte required.
;        CY=1: Space to this point at least is now required. Additional space may not be released.
;        CY=0: Space is held to or below this point. Any space held below this point is no 1onger required
; Exit:  CY=1: OK
;        CY=0: No space available
;        AFBCDE preserved
;
ASKRM	NOP
	PUSH	PSW
	PUSH	D
	JNC	@CA1B	; If space not reqd anymore
	XCHG		; Lowest byte in DE
	LHLD	SCRBOT	; Get bottom screen RAM
	CALL	COMP	; Check for overflow
	JC	@CA1E	; If OK
	LHLD	STBUSE	; Get begin free RAM
	XCHG		; and store it in DE
	CALL	COMP	; Still free RAM available?
	JC	LCA21	; If not
@CA1B	SHLD	SCRBOT	; Update bottom screen RAM
@CA1E	JMP	LCEAD	; Return, set CY=1
;
; If no RAM space availables
;
LCA21	POP	D
	JMP	LCEB1	; Return, set CY=0
;
; *******************************************
; * EMERGENCY STOP ROUTINE (Graphics modes) *
; *******************************************
;
; This routine is used if no sufficient space for a A-mode is available.
;
EMSTP	.equ	*
.if ROMVERS == 11
	CALL	XDEB0+1	; Run NEW with default heap --- B1 in ROM WRONG???
.endif
.if ROMVERS == 10
	CALL	HRNEW	;Set up HEAPsize + buffers to default values
.endif
	MVI	A, $FF
	ROMCALL(5, $18)	; Change to mode 0
	CALL_W(SELB0, MSG03)	; Select ROM-bank 0, Run error 'OUT OF SPACE FOR MODE'
	JMP	LC818	; Return to BASIC monitor
;
; ******************************************
; * FIND STRING BASIC INSTRUCTION IN TABLE *
; ******************************************
;
; Looks for table entry whose name is the initial string of input, beginning at
; C'th position.
; REMARK: Variables, beginning with a reserved string are not allowed.
;
; Entry: HL: Startaddress table
;        C:  Position char on current line
;        E:  Number of info bytes - 1
; Exit:  If found: CY=1:
;          HL: Address in table where string can be found
;          C:  Position on current line after 1ast char
;          A:  Last byte of string typed in.
;          D:  0
;          BE preserved,
;        If not found: CY=0:
;          C:  Points to next char
;	 HL: Points after end of table
;          A:  0
;          D:  0
;          BE preserved
;
LOOKC	CALL	IGNB	; Get char from line neglect TAB and space
@CA37	MOV	D, M	; Get 1ength byte of string
	INX	H	; Points to 1st stringchar
	MOV	A, D
	ORA	A	; Is length zero?
	RZ		; Then abort
	PUSH	B	; Save position of 1st char
@CA3D	CALL	EFETCH	; Get char from line
	INR	C	; Points to next char on line
	CMP	M	; Is it identical to the one in table?
	INX	H	; Points to next char in table
	JNZ	@CA4E	; If not identical
	DCR	D	; Else: decr string 1ength
	JNZ	@CA3D	; Get evt. next byte to check
	XTHL		; cance1 PUSH B
	POP	H
	STC		; CY=1
	RET
;
; If strings not identical:
;
@CA4E	MOV	A, D	; Get string length
	ADD	E	; Add 2
	CALL	DADA	; Add A to HL; HL points now to next string in table
	POP	B	; Restore C=1
	JMP	@CA37	; Start check on next string
;
; *****************
; * TABLE LOOK UP *
; *****************
;
; Finds an entry in a 1ook-up table.
; LOOK used for symboltable, LOOKX for table of Basic functions (FUNTB).
;
; Table format:
; [type/1ength][name][type/length][info]
;
; Entry: B:  Points to start name in input
;        D:  Type/length of name in input high nibble: type; low nibble: length
;        HL: Startaddress look-up table
; Exit:  If not found: CY=0:
;            HL points to 0 byte at table end
;            ABCD preserved, E corrupted
;        If found CY=1:
;            HL points to T/L of entry found
;            E indicates how manyth entry
;            ABC preserved
;
LOOK	LHLD	STBBGN	; Get startaddr symtab
LOOKX	STC		; CY=1
	PUSH	PSW
	PUSH	B
	MVI	E, $FF
@CA5F	INR	E	; Entry Count
	MOV	A, M	; Get T/L name in table
	ORA	A
	JZ	@CA8B	; Abort if end table reached
	CMP	D	; Compare with wanted T/L
	JZ	@CA6F	; Jump if found
@CA69	CALL	DADD	; Calc addr next entry
	JMP	@CA5F	; Check next entry
;
; If T/L of name OK
;
@CA6F	POP	B
	PUSH	B
	MOV	C, B
	PUSH	D
	MOV	A, D	; Get wanted T/L of name
	ANI	$0F	; Length name only
	MOV	D, A	; in D
	PUSH	H	; Save begin table entry
@CA78	INX	H
	CALL	EFETCH	; Get char from line
	CMP	M	; Compare char of name
	JNZ	@CA8F	; If not correct namne
;
; If char. identical
;
	INR	C	; Points to next char
	DCR	D	; Decr length
	JNZ	@CA78	; Check next char if not ready
	INX	H	; Points after name in table
	POP	D
	POP	D
	POP	B
	POP	PSW	; CY=1: Entry found
	RET
;
; If end of 1ook-up table reached
;
@CA8B	POP	B
	POP	PSW
	CMC		; CY=0: No entry found
	RET
;
; If characters not identical
;
@CA8F	POP	H
	POP	D
	MOV	A, D	; Length in A
	JMP	@CA69	; Look further
;
; **************************************
; * FIND A VARIABLE IN THE SYMBOLTABLE *
; **************************************
;
; Routine skips through successive symtab entries from beginning till past the
; place pointed by HL
;
; Entry: HL points to 1st byte required variable
; Exit:  HL points to (if found) or past (if not found) address required in symbol table
;        AFBCDE preserved
;
FNAME	PUSH	PSW
	PUSH	D
	XCHG		; Reqd addr in DE
	LHLD	STBBGN	; Get startaddr symtab
@CA9B	PUSH	H
	CALL	DADD	; Calc addr next variable
	CALL	COMP	; Reqd variable reached?
	JNC	@CAAA	; Quit if true
	INX	SP	; Cancel PUSH H
	INX	SP
	JMP	@CA9B	; Skip next variable
@CAAA	POP	H
	POP	D
	POP	PSW
	RET
;
; **************************************************
; * CALCULATE ADDRESS NEXT VARIABLE IN SYMBOLTABLE *
; **************************************************
;
; Adds 1ength of nane of var1able + length of value of variable to beginaddress.
;
; DADD: variable = length/name/length/value
; DADR: variable = length/name
;
; Entry: HL points to 1st byte of current variable
; Exit:  HL points to next variable in symtab
;
DADD	CALL	DADR	; Add 1ength name to HL
DADR	MOV	A, M	; Get info T/L byte
	INX	H	; Add 1
	ANI	$0F	; Length only
	JMP	DADA	; Add length info to HL
;
; **********************************************
; * INSERT A VARIABLE NAME IN THE SYMBOL TABLE *
; **********************************************
;
; Entry: HL points to end symtab
;        B  points to start of name in input
;        E  number of bytes of info to reserve
;        D  T/L byte of name
; Exit:  HL points to info T/L byte
;        AFBCDE preserved
;
LOOKI	PUSH	PSW
	PUSH	B
	MOV	C, B	; Input pos. in C
	PUSH	D
	PUSH	D
	PUSH	H
	MOV	A, D	; T/L name in A
	ANI	$0F	; Name length only
	ADD	E	; Add length info
	INR	A
	INR	A	; +2 (1ength new entry)
	CALL	DADA	; Calc new end symtab -1
	XCHG
	LHLD	SCRBOT	; Get bottom screen RAM
	XCHG
	CALL	COMP	; Compare DE-HL
	MVI	A,$1B
	JNC	ERROR	; Run 'OUT OF MEMORY' if not sufficient free RAM
	MVI	M, $00	; New 'end table' f1ag
	INX	H	; HL is new end symtab
	SHLD	STBUSE	; Store end symtab
	POP	H	; Get old end symtab
	POP	D	; Get T/L info
	MOV	M, D	; Into syntab
	INX	H
	MOV	A, D
	ANI	$70	; Get type only
	ORA	E	; Set 1ow nibble for 1ength
	MOV	E, A
	MOV	A, D	; Get length name
	ANI	$0F	; Max. 15 bytes
	MOV	D, A	; Length in D for count
@CAE7	CALL	EFETCH	; Get char from line
	MOV	M, A	; Char into symtab
	INR	C	; Pnts to next char on line
	INX	H	; Next pos in symtab
	DCR	D	; Decr 1ength name
	JNZ	@CAE7	; Next char if not ready
	MOV	M, E	; Info T/L into symtab
	POP	D
	POP	B
	POP	PSW
	RET
;
; *********************************
; * FIND LINENUMBER IN TEXTBUFFER *
; *********************************
;
; Entry: HL: requested linenumber
; Exit:  ABCDE preserved. F corrupted.
;        CY=1: Linenr found
;              HL points to address textline
;        CY=0: Not found
;              Z=0: HL points to address textline with next higher linenumber
;              Z=1: End of textbuffer reached.
;
FINDL	PUSH	B
	PUSH	PSW
	PUSH	D
	MVI	B, $00
	XCHG		; Req. linenr in DE
	LHLD	TXTBGN	; Get startaddr textbuf
@CAFF	MOV	C, B	; Length prev. instr in C
	MVI	B, $00
	DAD	B	; Add this length to beginaddr
	MOV	B, M	; Get length current instr
	MOV	A, B	; in A
	ORA	A
	INX	H	; Pnts to hibyte linenr
	JZ	@CB1D	; Abort if at end textbuf
	MOV	A, D	; Get hibyte reqd linenr
	CMP	M	; Test high order bits
	JC	@CB1C	; Abort if regd nr 1ower than current one (nr > reqd)
	JNZ	@CAFF	; Next textline (nr < reqd)
	INX	H	; Pnts to lobyte linenr
	MOV	A, E	; Get 1obyte reqd linenr
	CMP	M
	DCX	H
	JC	@CB1C	; Abort if reqd nr 1ower than current one (nr > reqd)
	JNZ	@CAFF	; Next textline if not found (nr < reqd)
@CB1C	CMC		; Line found: CY=1
@CB1D	DCX	H
	POP	D
	POP	B
	MOV	A, B
	POP	B
	RET
;
; ******************************
; * EMPTY SYMBOLTABLE AND HEAP *
; ******************************
; Zeroes all variables, all pointers in the symtab, kill all arrays, strings or
; stringarrays (zero the pointers) referenced by the symtab by setting the msb of
; the sizebit =1. Basic program is moved to a location corresponding to the Heapsize.
;
; Exit: All registers preserved.
;
SCRATC	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	STBBGN	; Get startaddr symtab
@CB2A	MOV	A, M	; get name length
	ANI	$0F
	JZ	@CB53	; Abort if at end symtab
	CALL	DADR	; HL pnts to info length byte
	MOV	A, M	; Get type
	ANI	$F0
	CPI	$40
	JNC	@CB4D	; If array
	INX	H
	CPI	$20
	JZ	@CB47	; If string
;
; If numeric variable
;
	CALL	ZFPINT	; Set value is 0 (4 bytes)
	JMP	@CB2A	; Next entry
;
; If string variable
;
@CB47	CALL	RSVHL	; Erase string reference in symbtab and Heap
	JMP	@CB2A	;Next entry
;
; If arrays
;
@CB4D	CALL	EARRAY	; Erase array
	JMP	@CB2A	; Next entry
;
; If ready
;
@CB53	CALL	HRINIT	; Organise HEAP + buffers
LCB56	POP	H
	POP	D
	POP	B
	POP	PSW
	RET
;
; ***************
; * ERASE ARRAY *
; ***************
;
; The pointer is zeroed, the array size is erased (msb=1). For stringarrays: zeroes
; all pointers in the array and erase the string in the Heap.
;
; Entry: HL points to T/L byte of info after a symtab name of an array
; Exit:  HL points to next symtab entry
;        AFBCDE preserved
;
EARRAY	PUSH	D
	PUSH	B
	PUSH	PSW
	MOV	A, M	; Get type info
	ANI	$30
	PUSH	PSW	; Save type only
	CALL	LCE51	; Get addr of array in
	INX	H	; Heap in DE,
	MOV	D, M	; Kill pointer in the
	MVI	M, $00	; symboltable
	INX	H	; Pnts after symtab entry
	MOV	A, D
	ORA	E
	JZ	@CB99	; Abort if entry was already 0
	XCHG		; Arrayaddr in HL
	DCX	H
	DCX	H	; Pnts to 1st byte Heap entry
	MOV	B, M	; Get 1st byte
	CALL	HREL	; Clear heap entry by msb=i
	POP	PSW	; Get type info
	PUSH	PSW
	CPI	$20	; String?
	PUSH	D	; Save stringpointer
	JNZ	@CB98	; Abort if not string
;
; If string array!
;
	INX	H
	MOV	C, M	; Get 1ength Heap entry
	INX	H
	MOV	E, M	; Get dimension
	INR	E
	MOV	A, E
	CALL	DADA	; Calc beginaddr stringpntrs
	MOV	A, C
	SUB	E	; Calc length pntr area
	MOV	C, A	; in C
	JNC	@CB8E
	DCR	B
@CB8E	CALL	RSVHL	; Erase stringreferente in symtab and Heap
	DCX	B
	DCX	B	; Update 1ength pntr area
	MOV	A, B
	ORA	C
	JNZ	@CB8E	; Next string if not ready
;
;	If ready
;
@CB98	POP	H	; Get symtab pntr
@CB99	POP	PSW
	POP	PSW
	POP	B
	POP	D
	RET
;
; ************************************************
; * CLEAR A NUMERIC VARIABLE IN THE SYMBOL TABLE *
; ************************************************
;
; Loads '0' into 4 consecutive memory 1ocations.
;
; Entry: Startaddress in HL
; Exit:  A=0, HL points to next byte
;        BCDEF preserved
;
ZFPINT	XRA	A
	MOV	M, A
	INX	H
	MOV	M, A
	INX	H
	MOV	M, A
	INX	H
	MOV	M, A
	INX	H
	RET
;
; ********************************************
; * ERASE STRINGREFERENCE IN HEAP AND SYMTAB *
; ********************************************
;
; The pointer in the symtab is set to '0', the msb of the sizebyte of the Heap
; entry is set to 1.
;
; Entry: HL points to stringpointer in symtab
; Exit:  HL points after this pointer
;        DE stringpointer
;        BC preserved
;        AF corrupted
;
RSVHL	MOV	E, M	; Stringpointer
	MVI	M, $00	; in DE and then
	INX	H	; erased.
	MOV	D, M
	MVI	M, $00
	INX	H
	PUSH	H
	LHLD	TXTBGN	; Get startaddr textbuf
	XCHG		; in DE stringpntr in HL
	MOV	A, H
	ORA	L	; Stringpntr is already 0?
	CNZ	COMP	; If not: test if end of heap reached
	CC	SHREL	; If not: clear heap entry
	POP	H
	RET
;
;
; **************************
; * STRINGS BASIC COMMANDS *
; **************************
;
; The first byte of each string is a length byte.
;
; The first byte after the string is the 'type' byte.
; It ís used to compose the TOKEN of the particular Basic command:
;   type byte, ANI $3F, ORI $80, gives TOKEN.
;
; Commands with type bytes bit 7=1 can be executed during a program run.
; If bit 6=1, commands are valid as direct command.
;
; The address given is the 1ocation of the encoding routine for this particular comnand.
; These routines can be found in ROM bank 3.
;
BAS_CMD	.equ	*
SNEW	BCMD("NEW", $81, ENEW)
SCONT	BCMD("CONT", $82, ECONT)
SSTOP	BCMD("STOP", $43, ESTOP)
SEND	BCMD("END", $44, EEND)
SREST	BCMD("RESTORE", $C5, EREST)
SRET	BCMD("RETURN", $46, ERET)
SRUN	BCMD("RUN", $87, LE295)
SGOTO	BCMD("GOTO", $49, EGOTO)
SGOSUB	BCMD("GOSUB", $4A, EGOSUB)
SIMP	BCMD("IMP", $B5, EIMP)
SSAVA	BCMD("SAVEA", $F9, ESAVA)
SLODA	BCMD("LOADA", $FA, ELODA)
SOUT	BCMD("OUT", $CE, EOUT)
SPOKE	BCMD("POKE", $CF, EPOKE)
SWAIT	BCMD("WAIT", $D0, EWAIT)
SLIST	BCMD("LIST", $D3, ELIST)
SEDIT	BCMD("EDIT", $B6, EEDIT)
SSOUND	BCMD("SOUND", $D6, ESOUND)
SNOISE	BCMD("NOISE", $D7, ENOISE)
SENV	BCMD("ENVELOPE", $D8, EENV)
SCURS_	BCMD("CURSOR", $D9, ECURS)
SMODE_	BCMD("MODE", $DA, EMODE)
SDOT_	BCMD("DOT", $DB, EDOT)
SDRAW_	BCMD("DRAW", $DC, EDRAW)
SFILL_	BCMD("FILL", $DD, EFILL)
SCOLT_	BCMD("COLORT", $DE, ECOLT)
SCOLG_	BCMD("COLORG", $DF, ECOLG)
SINPUT	BCMD("INPUT", $60, EINPUT)
SDATA	BCMD("DATA", $62, EDATA)
SREAD	BCMD("READ", $63, EREAD)
SLET	BCMD("LET", $E4, ELET)
SIF	BCMD("IF", $66, EIF)
SREM	BCMD("REM", $69, EREM)
SFOR	BCMD("FOR", $EA, EFOR)
SNEXT	BCMD("NEXT", $EB, ENEXT)
SPRINT	BCMD("PRINT", $ED, EPRINT)
SPRINT2	BCMD("?", $ED, EPRINT)
SON	BCMD("ON", $6E, EON)
SDIM	BCMD("DIM", $F0, EDIM)
SAAA	BCMD("***", $71, EERR)
SUT	BCMD("UT", $B2, EUT)
SCALM	BCMD("CALLM", $F3, ECALM)
SCLEAR	BCMD("CLEAR", $F4, ECLEAR)
SLOAD	BCMD("LOAD", $CB, ELOAD)
SSAVE	BCMD("SAVE", $8C, ESAVE)
SCHECK	BCMD("CHECK", $8D, ECHECK)
.if ROMVERS == 11
	.byte	$05, $00
XCD36	XRA	A	; A=0
	JMP	XD55A
	.byte	$FF, $FF, $E8
.endif
.if ROMVERS == 10
	.byte	$05, $00, $52, $41, $53, $45, $FB
	.word	EERASE
.endif
SSTEP	BCMD("STEP", $BC, ESTEP)
STRON	BCMD("TRON", $FD, ETRON)
STROF	BCMD("TROFF", $FE, ETROF)
STALK	BCMD("TALK", $FB, ETALK)
	.byte	$00, $E5
	.word	ELET	; Assigment (= LET)
.if ROMVERS == 11
LCD62	PUSH	D
	RET
.endif
.if ROMVERS == 10
	.byte	$FF, $FF		; End of table
.endif
;
; *********************
; * RUN basiccmd TALK *
; *********************
;
RTALK	CALL	REXI2	; (0) Get addr parameter block in HL
LCD67	MOV	A, M	; Get code
	INX	H
	ORA	A
	RM		; Ready if code = FF (end)
	CPI	$05
	JC	LCE45	; Jump if freq code
	CPI	$0C
	JC	LEE94	; (0) Jump if volume code
	JMP	LEC6D	; (0) Continue
;
; ***************
; * STRING DATA *
; ***************
LCD78	PSTR("WAIT MEM")
LCD81	PSTR("WAIT TIME")
;
;
; *****************************************
; * POINTERS TO STRINGS OF BASIC COMMANDS *
; *****************************************
;
; This table, with base at LCC08, is used for printing the Basic
; instructions during a 1isting.
;
; From the TOKEN, the address in this table can be found by:
;    $CC08 + 3x TOKEN = address in table
; This is done by a routine on $0ECCC
;
; The address given points to the memory 1ocation on which the particular string
; can be found.
;
; The data byte after the address is an offset with base at $0ECF8. Therewith the
; instructions can be found about what to print after the Basic statement (when
; performing LIST).
;
CDTAB
	TBL1(SNEW,   $00)		; NEW
	TBL1(SCONT,  $00)		; CONT
	TBL1(SSTOP,  $00)		; STOP
	TBL1(SEND,   $00)		; END
	TBL1(SREST,  $00)		; RESTORE
	TBL1(SRET,   $00)		; RETURN
	TBL1(SRUN,   $00)		; RUN
	TBL1(SRUN,   $01)		; RUN
	TBL1(SGOTO,  $01)		; GOTO
	TBL1(SGOSUB, $01)		; GOSUB
	TBL1(SLOAD,  $04)		; LOAD
	TBL1(SSAVE,  $04)		; SAVE
	TBL1(SCHECK, $00)		; CHECK
	TBL1(SOUT,   $05)		; OUT
	TBL1(SPOKE,  $05)		; POKE
	TBL1(SWAIT,  $0A)		; WAIT
	TBL1(LCD78,  $0A)		; WAIT MEM
	TBL1(LCD81,  $04)		; WAIT TIME
	TBL1(SLIST,  $00)		; LIST
	TBL1(SLIST,  $01)		; LIST
	TBL1(SLIST,  $0B)		; LIST
	TBL1(SSOUND, $0C)		; SOUND
	TBL1(SNOISE, $0D)		; NOISE
	TBL1(SENV,   $0E)		; ENVELOPE
	TBL1(SCURS_, $05)		; CURSOR
	TBL1(SMODE_,  $0F)		; MODE
	TBL1(SDOT_,  $07)		; DOT
	TBL1(SDRAW_, $08)		; DRAW
	TBL1(SFILL_,  $08)		; FILL
	TBL1(SCOLT_, $09)		; COLORT
	TBL1(SCOLG_, $09)		; COLORG
	TBL1(SINPUT, $11)		; INPUT
	TBL1(SINPUT, $10)		; INPUT
	TBL1(SDATA,  $03)		; DATA
	TBL1(SREAD,  $11)		; READ
	TBL1(SLET,   $13)		; LET
	TBL1($0000,  $13)		; Assignment (= LET)
	TBL1(SIF,    $14)		; IF
	TBL1(SIF,    $15)		; IF
	TBL1(SIF,    $16)		; IF
	TBL1(SREM,   $03)		; REM
	TBL1(SFOR,   $17)		; FOR
	TBL1(SNEXT,  $00)		; NEXT
	TBL1(SNEXT,  $18)		; NEXT
	TBL1(SPRINT, $19)		; PRINT
	TBL1(SON,    $1A)		; ON
	TBL1(SON,    $1B)		; ON
	TBL1(SDIM,   $11)		; DIM
	TBL1(SAAA,   $03)		; '***'
	TBL1(SUT,    $00)		; UT
	TBL1(SCALM,  $1C)		; CALLM
	TBL1(SCLEAR, $04)		; CLEAR
	TBL1($0000,  $00)		; IMP
	TBL1(SLIST,  $00)		; LIST
	TBL1(SLIST,  $01)		; LIST
	TBL1(SLIST,  $0B)		; LIST
	TBL1(SSAVA,  $1E)		; SAVEA
	TBL1(SLODA,  $1E)		; LOADA
	TBL1(STALK,  $04)		; TALK
	TBL1(SSTEP,  $00)		; STEP
	TBL1(STRON,  $00)		; TRON
	TBL1(STROF,  $00)		; TROFF
;
;
; *****************************
; * part of Run 'TALK' (CD6D) *
; *****************************
;
; Set frequencies of channels 0, 1 or 2.
;
LCE45	MOV	E, A	; Code in E (=1obyte osc. addr)
	MVI	D, $FC
	MOV	A, M	; Get 1st byte freq. code
	STAX	D	; into osc.
	INX	H
	MOV	A, M	; Get 2nd byte freq. code
	STAX	D	; into osc.
	JMP	LEA47	; (0) Handle next code
;
	.byte	$FF
;
; ****************************
; * GET (M+1) IN E, ZERO M+1 *
; ****************************
;
; Part of EARRAY (EARRAY).
;
; Entry: HL points to M
; Exit:  HL points to M+1. (M+1) in E
;        AFBCD preserved
;
LCE51	INX	H
	MOV	E, M
	MVI	M, $00
	RET
;
; ***************
; * STRING DATA *
; ***************
MSPACE	PSTR("SPACE")
;
; ***************************
; * part of RUN DIM (0E639) *
; ***************************
;
LCE5C	DCX	H
	JMP	EARRAY	; Erase array if exists
;
; **********************************
; * GET TABNUMBER IN L, DOUTC IN A *
; **********************************
;
; Part of Run 'TAB'.
;
LCE60	CALL	REXI1	; (0) Get nr of tabs in A
	MOV	L, A	; Save it in L
	LDA	OTSW	; Get output direction
	RET
;
; ****************************************
; * PRINT EXPRESSION FOLLOWED BY A SPACE *
; ****************************************
;
; Entry SCHSP frequently used to print a space.
;
LCE68	CALL	SCEXP	; (0) Print expression
SCHSP	MVI	A, ' '
	JMP	OUTC	; Print space
;
; *************
; * PRINT ',' *
; *************
;
; Entry None.
; Exit: FBCDEHL preserved
;
SCHCO	MVI	A, ','
	JMP	OUTC	; Print ','
;
; *********************************
; * PRINT A STRING BETWEEN SPACES *
; *********************************
;
; Entry: Pointer to stringpointer on stack
; Exit:  BC preserved. AFDEHL corrupted
;
STXSS	CALL	SCHSP	; Print space
STXTS	XTHL		; Get stringpntr from stack
	MOV	E, M	; Store addr string in DE
	INX	H
	MOV	D, M
	INX	H
	XTHL		; Addr after pntr on stack
	XCHG		; Addr string in HL
	CALL	PSTR	; Print string pointed by HL
	JMP	SCHSP	; Print space
;
; *****************************
; * EDIT: PRINT TEXT COMPLETE *
; *****************************
;
LCE85	CALL	LEF17	; (2) Print text complete
	JMP	XRET	; (2) Popall, ret
;
; ********************************
; * LIST ARRAY NAME - (not used) *
; ********************************
LCE8B	PUSH	D
	CALL	SCARN	; (0) List array name
	POP	D
	RET
;
; ****************
; * part of C6BA *
; ****************
LCE91	PUSH	H
	JMP	LE92D	; (2) Now set up screen bits for mode 1
;
; **************
; * (not used) *
; **************
;
LCE95	LDA	v_EBUFR	; Get startaddr edit buffer
	JMP	$E97C	; (0)
;
; ***************************
; * CONVERT MACC FOR OUTPUT *
; ***************************
;
; The MACC contents is converted from FPT to ASCII.
;
; Exit: AF Corrupted, BCDEHL preserved
;
FBCP	CALL	XFEC	; Convert FPT nr for output
	PUSH	B
	MVI	B, $01	; Cannot trim 1ast dec. place
	JMP	BPP	; Tidy up into external form
;
; *********************
; * LIST CURRENT LINE *
; *********************
;
; Lists a program line if trace flag set.
; Part of C8F5
;
LCEA4	DCX	B
	CALL	COL0	; Cursor to begin next line
	JMP	SLINE	; (0) List current line
;
LCEAB	POP	D	; (Not used)
	RET
;
; ************************
; * part of SMKRM (CA01) *
; ************************
;
LCEAD	POP	D	; Return, CY=1
	POP	PSW
	STC
	RET
;
LCEB1	POP	PSW	; Return, CY=0
	STC
	CMC
	RET
;
; **********************
; * CHANGE SCREEN MODE *
; **********************
;
; Part of Run 'MODE' (0E5BB).
;
; Entry: New mode in A.
;
LCEB5	ROMCALL(5, $18)	; Change mode
	JC	ERROM	; If insufficient memory: error 'OUT OF MEMORY'
	RET
;
.if ROMVERS == 11
;
; Part of CLEAR
;
LCEBB	SHLD	CURRNT	; Update pntr
	CALL	RREST	; Run RESTORE
	PUSH	D	; Preserve differencee
	JMP	LD87F
;
; Part of RUN INT
;
LCEC5	CALL	XFCOMP	; FPT compare nrs in MACC and in WORKE
	LXI	H, FPM1B	;  Addr FPT (-1)
	RZ		; Ready if nr = 0
	ROMCALL(4, $00) 	; Add (-1) to MACC if nr < 0
	RET
 .endif
.if ROMVERS == 10
;
; *****************************
; * part of RUN CLEAR (0E6B5) *
; *****************************
;
; Checks if more than 4 bytes are cleared.
;
; Entry: HL: Number of bytes to be cieared
;         F: f1ags on hibyte HL.
;
LCEBB	LXI	D, $0004	; Must be at least 4 bytes
	CP	COMP	; Compare HL-DE if not >32k
	JC	ERRRA	;Run error 'NUMBER OUT OF RANGE' if < 4.
	RET
;
	.byte	$FF
;
; **********************************
; * SET HEAP SIZE TO DEFAULT VALUE *
; **********************************
;
; Part of emergency stop routine (CA25).
; Also runs a NEW command.
;
HRNEW	LXI	H, SYSBOT
	SHLD	HSIZE	; Store HEAP default value
	JMP	RNEW	; Run 'NEW'
.endif
;
; *************************************
; * RE-ORGANISE SCREEN AFTER 'DAI-PC' *
; *************************************
;
; Lines after 'DAI PERSONAL COMPUTER' are set in unit colour mode.
; Set line mode byte to 7F and first char.
; byte to 20, colour 00 during screen init.
;
; Entry: HL line mode byte of part. line.
;
LCECF	MVI	M, $7F	; Wide char line contr byte
	DCX	H
	DCX	H
	MVI	M, ' '	; Load space
	DCX	H
	MVI	M, $00	; Colour no change
	DCX	H
	RET
;
; ****************************************
; * part of RUN 'WAIT(TIME)' (DFD5/DFF7) *
; ****************************************
;
LCEDA	DCX	B
	JMP	REXI1	; (0) Get value of argument in A (max. $FF)
;
; ********************************************
; * EVALUATE ARGUMENTS IN NUMERIC EXPRESSION *
; ********************************************
;
; Not used
;
LCEDE	PUSH	PSW
	CALL	REXPN	; (0) Evaluate arguments
	POP	PSW
	RET
;
; ************************************
; * SELECT ROM BANK 0; PRINT MESSAGE *
; ************************************
;
; When SELB0 1s called, the 2 bytes following the CALL-instruction indicate
; the message to be printed by the routine PMSGR.
;
SELB0	LDA	POROM	; Get POROM
	ANI	$3F	; Select ROM bank 0
	STA	POROM	; Set POROM
	STA	PORO	; and PORO
	JMP	PMSGR	; Print message
;
; ****************************************
; * EDIT: RETURN FROM 'DELETE CHARACTER' *
; ****************************************
;
; Part of 2EFCC
;
LCEF2	POP	H
	CALL	CURSET	; (2) Put cursor on screen
	JMP	LEF95	; (2) Popall, ret, CY=1
;
; *****************************************
; * PRINT 'COMPUTER' UNDER 'DAI PERSONAL' *
; *****************************************
;
; Part of RESET (C751).
;
; During screen initialisation used to set a new line mode byte between
; both parts of the message. Line colour bytes are set for medium resolution.
;
; Entry: HL: line mode byte to be changed.
;        DE: offset for calculation next line mode byte
; Exit:  HL: next line mode byte
;
LCEF9	MVI	M, $5F	; Set line mode byte
	DCX	H
	MVI	M, $40	; Set line colour byte
	INX	H
	DAD	D	; Addr. next line mode byte
	RET
;
	.byte	$FF
;
;
;
; **************************************
; * POINTERS TO ROUTINES BASICCOMMANDS *
; **************************************
;
; This table, with base at CF00, gives the addresses of the routines for
; execution of the Basic statements.
; The offset from baseaddress CF00 can be found by adding 2x TOKEN to the base address.
; Address indicates begin subroutine (ROM bank 0).
;
; The number given between brackets is the TOKEN.
;
CITAB	.equ	*
	.word	RNEW	; (81) NEW
	.word	RCONT	; (82) CONT
	.word	RSTOP	; (83) STOP
	.word	REND	; (84) END
	.word	RREST	; (85) RESTORE
	.word	RRET	; (86) RETURN
	.word	RRUN	; (87) RUN
	.word	RRUNN	; (88) RUN <linenumber>
	.word	RGOTO	; (89) GOTO
	.word	RGOSUB	; (8A) G0SUB
	.word	RLOAD	; (8B) LOAD
	.word	RSAVE	; (8C) SAVE
	.word	RCHECK	; (8D) CHECK
	.word	ROUT	; (8E) OUT
	.word	RPOKE	; (8F) POKE
	.word	RWAIT	; (90) WAIT
	.word	RWTEM	; (91) WAIT MEM
	.word	RWTET	; (92) WAIT TIME
	.word	RLIST	; (93) LIST
	.word	RLIS1	; (94) LIST <linenumber>
	.word	RLIS2	; (95) LIST <part of progr>
	.word	RSOUND	; (96) SOUND
	.word	RNOISE	; (97) NOISE
	.word	RENV	; (98) ENVELOP
	.word	RCURS	; (99) CURSOR
	.word	RMODE	; (9A) MODE
	.word	RDOT	; (9B) DOT
	.word	RDRAW	; (9C) DRAW
	.word	RFILL	; (9D) FILL
	.word	RCOLT	; (9E) COLORT
	.word	RCOLG	; (9F) COLORG
	.word	RINPUT	; (A0) INPUT
	.word	RINPQ	; (A1) INPUT <with prompt>
	.word	RDATA	; (A2) DATA
	.word	RREAD	; (A3) READ
	.word	RLETX	; (A4) LET
	.word	RLETI	; (A5) assignment
	.word	RIFTC	; (A6) IF THEN <statement>
	.word	RIFG	; (A7) IF GOTO
	.word	RIFTL	; (AB) IF THEN <linenumber>
	.word	RREM	; (A9) REM
	.word	RFOR	; (AA) FOR .. TO
	.word	RNEXT	; (AB) NEXT
	.word	RNEXI	; (AC) NEXT <variable>
	.word	RPRINT	; (AD) PRINT
	.word	RONGT	; (AE) ON GOTO
	.word	RONGS	; (AF) ON GOSUB
	.word	RDIM	; (B0) DIM
	.word	ERREL	; (B1) *** (error line run)
	.word	RUT	; (B2) UT
	.word	RCALM	; (B3) CALLM
	.word	RCLEAR	; (B4) CLEAR
	.word	RIMP	; (B5) IMP
	.word	REDIT	; (B6) EDIT
	.word	REDI1	; (E7) EDIT <linenumber>
	.word	REDI2	; (B8) EDIT <part>
	.word	RSAVA	; (B9) SAVEA
	.word	RLODA	; (BA) LOADA
	.word	RTALK	; (BB) TALK
	.word	RSTEP	; (BC) STEP
	.word	RTRON	; (BD) TRON
	.word	RTROF	; (BE) TROFF
;
; ****************************
; * part of RUN 'ASC' 0EACF) *
; ****************************
;
LCF7E	ORA	A	; Null string?
	JZ	FR1BY	; (0)Then 0 into MACC
	INX	H	; E1se:
	JMP	LEAC7	; (0) Next byte from MEM into MACC
;
; *****************************************
; * TABLE PREFIXES FOR UNITARY OPERATIONS *
; *****************************************
;
; Only used by LIST for decoding.
; The prefix gives a code for unitary operators, which on encoding are directly
; determined, not 1ooked up in a table.
;
; Format: length of name / name / 5-bit opcode
;
OPTBB	.equ	*
	OPE('(', $1A)
	OPE('-', $1D)
	OPE('+', $1C)
	.byte	$00, $1F	; Fixed FPT conversion
;
; **************************
; * TABLE BINARY OPERATORS *
; **************************
;
; Format: 1 byte:  1ength of name
;         n bytes: name
;         1 byte:  code byte
;                  highest 3 bits: priority
;                  1owest 5 bits: opcode
;
OPTAB	.equ	*
SDIV	OPE("/",    $C2)
	OPE("*",    $C3)
	OPE("MOD",  $CF)
	OPE("^",    $E4)
	OPE("IAND", $69)
	OPE("IOR",  $6A)
	OPE("IXOR", $6C)
	OPE("SHL",  $8D)
	OPE("SHR",  $8E)
	OPE(">=",   $50)
	OPE(">",    $51)
	OPE("<>",   $52)
	OPE("<=",   $53)
	OPE("<",    $54)
	OPE("=",    $55)
	OPE("AND",  $38)
	OPE("OR",   $39)
;
; ***************************
; * TABLE UNITARY OPERATORS *
; ***************************
;
; Format: 1 byte:  1ength of name
;         n bytes: name
;         1 byte:  code byte
;                  highest 3 bits: priority
;                  1owest 5 bits: opcode
;
OPTBM	.equ	*
	OPE("INOT", $1E)
	OPE("+",    $A0)
	OPE("-",    $A1)
	.byte	$00, $00
;
; *********************************
; * TABLE STRINGS BASIC FUNCTIONS *
; *********************************
;
; Format: 1 byte:   length of name
;         n bytes:  name
;         1 byte:   high nibble: type of info
;                   low nibble:  nr of arguments
;         1 byte    high nibble: required type of variable expected: (0=FPT, 1=INT, 2=STR)
;
FUNTB	.equ	*
SABS	FNC("ABS",   $01,$00)	; ABS(f)
SALOG	FNC("ALOG",  $01,$00)	; ALOG(f)
SASC	FNC("ASC",   $11,$20)	; ASC($)
SCHR	FNC("CHR$",  $21,$10)	; CHR$(i)
SCURX	FNC("CURX",  $10)		; CURX
SCURY	FNC("CURY",  $10)		; CURY
SEXP	FNC("EXP",   $01,$00)	; EXP(f)
SFRAC	FNC("FRAC",  $01,$00)	; FRAC(f)
SFRE	FNC("FRE",   $10)		; FRE
SFREQ	FNC("FREQ",  $11,$00)	; FREQ(f)
SGETC	FNC("GETC",  $10)		; GETC(i)
SHEX	FNC("HEX$",  $21,$10)	; HEX$(i)
SINP	FNC("INP",   $11,$10)	; INP(i)
SINT	FNC("INT",   $01,$00)	; INT(f)
SLEFT	FNC("LEFT$", $22,$20,$10)	; LEFT$($,i,i)
SLEN	FNC("LEN",   $11,$20)	; LEN($)
SVPT	FNC("VARPTR",$11,$30)	; VARPTR(@)
SLOG	FNC("LOG",   $01,$00)	; LOG(f)
SLOGT	FNC("LOGT",  $01,$00)	; LOGT(f)
SXMAX	FNC("XMAX",  $10)		; XMAX(i)
SYMAX	FNC("YMAX",  $10)		; YMAX(i)
SMID	FNC("MID$",  $23,$20,$10,$10)	; MID$($,i,i)
SPDL	FNC("PDL",   $11,$10)	; PDL(i)
SPEEK	FNC("PEEK",  $11,$10)	; PEEK(i)
SPI	FNC("PI",    $00)		; PI
SRIGHT	FNC("RIGHT$",$22,$20,$10)	; RIGHT$($,i,i)
SRND	FNC("RND",   $01,$00)	; RND(i)
SSCRN_	FNC("SCRN",  $12,$10,$10)	; SCRN(i,i)
SSGN	FNC("SGN",   $01,$00)	; SGN(f)
SSPC	FNC("SPC",   $21,$10)	; SPC(i)
SSQR	FNC("SQR",   $01,$00)	; SQR(f)
SSTR	FNC("STR$",  $21,$00)	; STR$(f)
STAB	FNC("TAB",   $21,$10)	; TAB(i)
SVAL	FNC("VAL",   $01,$20)	; VAL($)
SSIN	FNC("SIN",   $01,$00)	; SIN(f)
SCOS	FNC("COS",   $01,$00)	; COS(f)
STAN	FNC("TAN",   $01,$00)	; TAN(f)
SASIN	FNC("ASIN",  $01,$00)	; ASIN(f)
SACOS	FNC("ACOS",  $01,$00)	; ACOS(f)
SATN	FNC("ATN",   $01,$00)	; ATN(f)
	.byte	$00
;
; ********
; * DATA *
; ********
ENDFT	.equ	*
FPOSC	.byte	$15,$F4,$24,$00	; Sound constant
FPM1b	.byte	$81,$80,$00,$00	; FPT (-1)
FPPI	.byte	$02,$C9,$0F,$DB	; FPT (PI)
I4b	.byte	$00,$00,$00,$04	; INT (4) (not used)
IRAND	.byte	$00,$FF,$FF,$FF	; AND mask
;
;
;
;
;     ==============
; *** STRING HANDLER ***
;     ==============
;
;
; *****************************
; * INITIALISE STRING HANDLER *
; *****************************
;
; Initialises a given size of string area.
; This routine is used once by RESET (LC719), but without purpose.
; It belongs to another BASIC package of the firm DAI.
;
; Entry: None
; Exit:  A=0, BCDEHL preserved. F corrupted.
;
SHINIT	XRA	A
	STA	RST0_BGN	; Zero $0000
	RET
;
; **********************
; * APPEND TWO STRINGS *
; **********************
;
; Appends two strings together to one new string by adding the 2nd string to the
; end of the 1st string.
;
; Entry: DE: Start address 1st string (1st byte is length byte)
;        HL: Start address 2nd string
; Exit:  AFBCDE preserved.
;        HL: Points to new string
;        Error if string too long
;
SHAPP	PUSH	PSW
	PUSH	D
	LDAX	D	; Get length 1st string
	ADD	M	; Calc 1ength new stri1ng
	JC	ERRLS	; Run error 'STRING TOO LONG' if length >255
	PUSH	H	; Save pntr 2nd string
	CALL	SHREQ	; Find place in Heap for new string
	PUSH	H	; Save pntr to new string
	INX	H
	CALL	SCOPF	; Move 1st string to new loc
	POP	D
	XTHL
	XCHG
	XTHL
	CALL	SCOPF	; Move 2nd string to new loc
	POP	H	; Get pntr to new string
	POP	D
	POP	PSW
	RET
;
; ***********************
; * COMPARE TWO STRINGS *
; ***********************
;
; Compares two string character by character.
; No characters >#80 are allowed.
;
; Entry: DE: begin addr. 1st string
;        HL: begin addr. 2nd string
; Exit:  ABCDEHL preserved.
;        Flags:   Z=1: Both strings ident.
;                 S=1,Z=0: 2nd string 1onger.
;                 S=0,Z=1: 1st string longer.
SHCOMP	PUSH	B
	PUSH	PSW
	PUSH	D
	PUSH	H
	LDAX	D	; Get length 1st string
	MOV	B, A	; Store it in B
	MOV	C, M	; Length 2nd string in C
@D128	INX	D
	INX	H
	MOV	A, B
	SUI	$01	; Check 1st string empty
	MOV	B, A	; Save rest of bytes
	JC	@D145	; 1f 1st string empty
	MOV	A, C
	SUI	$01	; Check 2nd string empty
	MOV	C, A	; Save rest of bytes
	INR	A
	INR	A
	JC	@D13F	; If 2nd string empty
	LDAX	D	; Get byte 1st string
	CMP	M	; and compare it with 2nd
	JZ	@D128	; If identical: cont. test
@D13F	POP	H
	POP	D
	POP	B
	MOV	A, B	; Restore A
	POP	B
	RET
;
; If 1st string empty
;
@D145	MOV	A, C	; Get 1ength 2nd string
	ORA	A
	JZ	@D13F	; If also empty? abort, Z=1
	XRA	A
	DCR	A	; Z=0
	JMP	@D13F
;
; *********************************************************
; * EXTRACT A SUBSTRING FROM THE MIDDLE OF ANOTHER STRING *
; *********************************************************
;
; Entry: HL points to string.
;        D  offset substring
;        E  length substring
; Exit:  If OK: HL points to substring
;        Else: Jump to error
;        AF corrupted. BCDE preserved.
;
SHMID	PUSH	B
	PUSH	D
	MOV	A, M	; Get length string
	SUB	D	; Minus offset substrinG
	JC	ERRRA	; Run error 'NUMBER OUT OF RANGE' if offset too big
	SUB	E	; Minus length substring
	JC	ERRRA	; Run error 'NUMBER OUT OF RANGE' if length too big
	MOV	A, D	; Get offset
	CALL	DADA	; Calc begin addr substring
	INX	H
	PUSH	H	; Save begin substring
	MOV	A, E	; Get length substring
	CALL	SHREQ	; Find place in Heap for substring
	POP	D	; Get begin substring
	PUSH	H
	CALL	SCOPT	; Move substring into Heap
	POP	H
	POP	D
	POP	B
	RET
;
; ***************************
; * TRANSFER OF STRING DATA *
; ***************************
;
; Copies strings from one place to another.
; Start at SCOPF: Transfer known string from DE to HL
; Start at sCOPT: Transfer string into 1imited space of HL
;
; Entry: DE: Start addr. string to be transferred
;        HL: Destination address
;            1st bytes are 1ength bytes
; Exit:  Both DE + HL point to byte after string
;        BC preserved; A=$FF, CY=1
;
SCOPF	LDAX	D	; Get length
	INX	D	; Pnt to 1st byte
	JMP	LD175
;
SHCOPY	INX	D	; Pnt to 1st byte of string
SCOPT	MOV	A, M	; Get available space
	INX	H	; Pnt to 1st place to store
LD175	PUSH	B
	MOV	B, A	; Available space/space reqd in B
@D177	MOV	A, B	; Get space still available
	SUI	$01	; Decr. space available
	MOV	B, A	; and save it
	JC	@D185	; Jump if ready
	LDAX	D	; Get byte to be transferred
	MOV	M, A	; and transfer it
	INX	D	; Prt to next byte
	INX	H	; Pnt to next place
	JMP	@D177	; Transfer next byte
@D185	POP	B
	RET
;
; *************************
; * RELINGUISH HEAP SPACE *
; *************************
;
; Clears a string in the heap
; Entry: HL points to 2nd length byte of string
; Exit:  HL points to 2nd 1ength byte of clared string
;        AFBCDE preserved
;
SHREL	DCX	H
	JMP	HREL	; Clear Heap entry
;
; **************************************
; * REQUEST SPACE IN HEAP FOR A STRING *
; **************************************
;
; Finds a p1ace in the heap for a new string.
;
; Entry: A: Required space
; Exit:  AFBCDE preserved
;        HL points to length of reserved area
;        Error if no space available
;
SHREQ	PUSH	D
	MVI	D, $00	; Required space in DE
	MOV	E, A
	CALL	HREQU	; Run Heap request
	INX	H
	POP	D
	RET
;
;     ============
; *** HEAP HANDLER ***
;     ============
;
; *************************************
; * INIT. HEAP SPACE TO ALL AVAILABLE *
; *************************************
;
; The pointers for textbuffer and symboltable are updated correctly according to
; the requested Heapsize. The Heap is cleared: It starts with
; HSIZE-4 IOR #8000 and ends with $7FFF
;
; Entry: DE: HEAP size (<32K).
; Exit:  BC preserved. AFDEHL corrupted
;        Error if insufficient space
;
HINIT	LHLD	TXTBGN	; Start text buffer in HL
	PUSH	D
	PUSH	H
	PUSH	D
	XCHG		; Start textbuf in DE
	LHLD	HEAP	; Start Heap in HL
	XCHG
	CALL	SUBDE	; Calc current heapsize
	XCHG		; Store it in DE
	POP	H	; Get new HEAP size
	CALL	SUBDE	; Calculate difference
	POP	D	; Get old start textbuf
	CALL	PROGM	; Move textbuf and symtab
	SHLD	TXTBGN	; Update start textbuf
	POP	D	; Get new HEAP size
	LHLD	HEAP	; Get startaddr HEAP
	DCX	D
	DCX	D
	DCX	D
	DCX	D	; HSIZE-4
	MOV	A, D
	ORI	$80	; Free space available
	MOV	M, A	; Set start Heap to
	INX	H	; HS1ZE-4 IOR $8000
	MOV	M, E
	INX	H
	DAD	D	; Get end HEAP-2
	MVI	M, $7F	; Set it to
	INX	H	; $7FFF
	MVI	M, $FF	; (end marker)
	RET
;
; ***************
; *HEAP REQUEST *
; ***************
;
HREQU	ROMCALL(1, $0F)	; Run heap request
	RET
;
.if ROMVERS == 11
;
; Part of Integer Compare
;
XD1C8	MOV	A, E	; Get signbyte in A
	MVI	E, $00	; Clear E
	JP	LC08C	; Compare if both nrs same sign
	JMP	LC0A4	; Else: abort
.endif
.if ROMVERS == 10
	.byte $FF ,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.endif
;
; ************************
; * part of EDIT (2EEC0) *
; ************************
;
; Prints a text line.
;
LD1D1	JZ	LEEEC	; (2) If char=0
	JP	LEEDE	; (2) Cont for char #01-7F
	INX	H	; Next pos in textbuf
	JMP	LEED2	; (2) Ignore char >= #80
;
; *******************************************
; * INPUT SCANNING: CHECK SOURCE AND INPUTS *
; *******************************************
;
; Part of D6BB.
; Checks if input from keyboard or from DINC.
; Checks also for any new inputs.
;
LD1DB	LDA	INSW	; Get input direction
	ORA	A
	JNZ	DINC	; Jump if input from DINC
;
; If input from keyboard
;
LD1E2	CALL	ASKKEY	; Check if new keys pressed
	JMP	LD6C1	; Into keyb. scanning
;
; *******************************
; * part af FPT COMPARE (LC079) *
; *******************************
;
; Entry: Contents MACC in ABCD, exp. byte in E
;        HL points to exp. byte MEM
;
LD1E8	MOV	A, B
	INX	H
	ANA	M	; AND 1st bytes both mantissas
	MOV	A, M
	DCX	H	; Pnts to exp. byte MEM
	JM	@D1F5	; Jump if both 1st mantissa bits are '1'
	CMP	B	; Comp both 1th mantissa bytes
	CMC		; CY=0 if mantissa MACC > mantissa MEM
	JMP	LC09F	; Quit
;
@D1F5	MOV	A, E	; Get exp. byte MACC
	XRA	M	; XOR both exponents
	ANI	$40	; Check if only 1 exp. neg.
	MOV	A, E	; Get exp. byte MACC
	JMP	LC087	; Back to main routine
;
; ************************
; * part of EDIT (2EE7B) *
; ************************
;
; Skip to B'th position on line.
;
LD1FD	MOV	A, M	; Get char in A
	ORA	A	; Set flags on it
	JM	LEE94	; (2) ignore char >= #80
	MOV	A, B	; Set pos. required
	CMP	C	; Reached?
	MOV	A, M	; Get char
	JMP	LEE82	; (2)
;
; ********
; * DATA *
; ********
;
MSG001	.byte	$0D
	.word	$6FDB	; 'SOME INPUT IGNORED'
	.byte	$00
;
; **********************************
; * part of UNDERFLOW ERROR (C065) *
; **********************************
;
LD20C	ROMCALL(4, $0C)	; Copy operand to MACC
	LXI	H, $0004
	JMP	LC04F	; Cont on (00D0/1)+4
.if ROMVERS == 11
;
; Part of RUN 'CLEAR'
;
LD214	CALL	SUBDE	; Calc difference old/new
	PUSH	H	; Preserve result
	CALL	SCRATC	; Empty heap and symtab move progra to after heap
	LHLD	CURRNT	; Get pntr to Current line
	MOV	A, H
	ORA	L
	POP	D	; Get difference
	RZ		; Abort if direct cmd
	DAD	D	; Add difference to pnt current line
	JMP	LCEBB
	.byte 	$FF
.endif
.if ROMVERS == 10
;
; ****************************************
; * part of RUN 'CLEAR' (cont. of 0E6B5) *
; ****************************************
;
LD214	SHLD	HSIZE	; Update HEAP size
	LHLD	CURRNT	; Get start current line
	MOV	A, H
	ORA	L	; Check if CURRNT=0
	POP	D
	RZ		; Abort if immediate cmd
	CALL	RREST	; (0) Run RESTORE
	DAD	B
	CALL	LE92D	; (0) Calc length of block Result in BC
	ORA	A
	RET
.endif
;
; ******************************
; part of HEAP REQUEST (3E9AD) *
; ******************************
;
; Checks if end of Heap reached.
;
LD227	CPI	$7F	; End marker?
	JNZ	LE9FA	; (3) Jump if not
	MOV	A, E	; Get 2nd byte in A
	INR	A
	JNZ	LE9FA	; (3) Jump if it was <> FF
	MVI	A, $07	; If end of Heap reached:
	JMP	ERROR	; Run error 'OUT OF STRING SPACE'
;
; **********************
; * CLEAR A HEAP ENTRY *
; **********************
;
; A Heap entry is erased by setting the msb of the first byte to 1.
;
; Entry: HL: Points to byte.
; Exit:  All registers preserved.
;
HREL	PUSH	PSW
	MOV	A, M	; Get byte
	ORI	$80	; Set msb=1
	MOV	M, A	; Store byte
	POP	PSW
	RET
;
;
;
;     ===========
; *** I/O HANDLER ***
;     ===========
;
;
; *********************
; * RUN basiccmd SAVE *
; *********************
;
; Valid as direct command and in program.
; Clears the Heap, zeroes all variables, evaluate an evt. program name and
; writes a file of type 0 (BASIC) on tape.
;
; Exit: HL: Points to end symboltable
;       DE: Length symboltable
;       BC: Updated
;
RSAVE	CALL	SCRATC	; Empty HEAP + symtab
	LHLD	STBBGN	; Get start symtab
	XCHG		; in DE
	LHLD	STBUSE	; End symtab in HL
	CALL	SUBDE	; Calculate length symtab
	PUSH	H	; Preserve length symtab
	LHLD	TXTBGN	; Get start textbuf
	XCHG		; in DE
	CALL	SUBDE	; Calculate length textbuf
	PUSH	H	; Preserve length textbuf
	PUSH	D	; Preserve start textbuf
	CALL	REXSR	; (0) Evaluate program name
.if ROMVERS == 11
	MVI	A, $30	; File type byte 0
	CALL	WOPEN	; Write fileleader, f1agbyte, file type byte, name 1ength and name
	POP	H	; Start textbuf in HL
	POP	D	; Length textbuf in DE
	CALL	WBLK	; Write length and contents textbuf
	POP	D	; Length symtab in DE
	JMP	LD7D8	; Write length and contents symtab + file trailer
;
; Part of READ BLOCK FROM TAPE
;
XD265	JNC	RLEAR	; Evt run 1oading error
	JMP	RCLOSE	; Stop cassette motors
;
; Part of WINDOW DOWN
XD26B	LHLD	v_ECURY	; Get Y-offset cursor in document
	CALL	SUBDE_	; HL=HL-DE
	DCR	L	; -1
	STC		; Set window changed flag
	RET
.endif
.if ROMVERS == 10
	NOP
	NOP
	NOP
	MVI	A, $30	; File type byte 0
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CALL	WOPEN	; Write fileleader, f1agbyte, file type byte, name 1ength and name
	POP	H	; Start textbuf in HL
	POP	D	; Length textbuf in DE
	CALL	WBLK	; Write length and contents textbuf
	POP	D	; Length symtab in DE
	JMP	LD7D8	; Write length and contents symtab + file trailer
;
	.byte	$FF
.endif
;
; *********************
; * RUN basiccmd LOAD *
; *********************
;
; Valid as direct comand and in program.
; Clears Heap and all variables. Evaluates name of program, updates BC. Required file type: 0.
; C is set to print type/name or not.
; A file (type 0: Basic) is read fron tape. When a file has been found, the textbuffer and
; the symbol table are 1oaded and the pointers updated.
; When 1oading during program run: the program continues with the program just loaded.
;
; Exit: No error: BC: Updated
;                 DE: Begin screen RAM
;                 HL: End symbol table
;
RLOAD	CALL	SCRATC	; Empty HEAP + symtab
	CALL	REXSR	; (0) Evaluate program name
	PUSH	B
.if ROMVERS == 10
	NOP
	NOP
	NOP
	NOP
.endif
	MVI	B, $30	; File type byte 0
	PUSH	H	; Preserve length name reqd
	LHLD	CURRNT	; Get CURRNT
	MOV	A, H
	ORA	L	; Load during run program?
	MVI	C, $00
	JNZ	@D289	; If during run; C=$00
	DCR	C	; Else C=$FF
@D289	POP	H
	CALL	ROPEN	; Switch on cassette motors; read header + name
	LHLD	SCRBOT	; Get end free RAM
	XCHG		; Max. RAM in DE
	LHLD	TXTBGN	; Start textbuf in HL
	CALL	RBLK	; Load textbuffer
	SHLD	TXTUSE	; Store end textbutfer
	CC	RBLK	; Load symboltable
	CALL	LD71A	; Store end symtab; stop Ccssette motors
	POP	B
	EI		; Enable interrupts
	JNC	RLERR	; If 1oading error
	MVI	A, $00	; No 1oading error
	RET
;
; *********************
; * RUN LOADING ERROR *
; *********************
;
; The program buffers are restored. A errar message is printed.
;
RLERR	PUSH	PSW
	CALL	RNEW	; Run 'NEW'
	POP	PSW
	LXI	H, $0000
	SHLD	CURRNT	; Set CURRNT=0
RLEAR	ADI	$0B
	JMP	ERROR	; Run 'LOADING ERROR..'
;
;
; ******************
; * OPEN TAPE FILE *
; ******************
;
; Entry: A:  File type
;        HL: Points to file name
; Exit:  HL: Points beyond file name
;        DE: Length of nane
;        BC: Preserved
;        A:  Checksum on name
;
CWOPEN	PUSH	PSW
	CALL	LD720	; Init. write file leader
	POP	PSW
	CALL	WBYTE	; Write file type byte
	JMP	LD7F8	; Get name 1ength, write it on tape, inc1. its c.s.
;
; **********************
; * RUN basiccmd CHECK *
; **********************
;
; Valid as direct command only.
; Checks on file type and name. For all files with type <3, a checksum on all data is done.
; This routine remains in a endless 1oop and can be aborted with BREAK only.
;
RCHECK	LXI	H, $0000	; No program name given
	LXI	B, $00FF	; Any file type
.if ROMVERS == 10
	NOP
	NOP
.endif
	CALL	ROPEN	; Read file header, file, type and name; print type and name
.if ROMVERS == 10
	NOP
.endif
	CPI	$33
	JNC	@D2EB	; If file type >=3 no check on checksum
;
; Test checksum
;
	INR	C	; BC=0
.if ROMVERS == 10
	CALL	AMBLK	; Set A=0, read + check a data block
.endif
.if ROMVERS == 11
	MVI	A, $00
	CALL	MBLK	; Read + check next block
	NOP
.endif
	CZ	MBLK	; Read + check next block
	JNZ	@D2E6	; If reading error
	CALL_W(PMSGR, MSG17)	; Print 'OK', car.ret
	JMP	RCHECK	; Wait fot next file
;
; If checksum error
;
@D2E6	CALL_W(PMSGR, MSG14)	; Print 'BAD'
@D2EB	CALL	CRLF	; Print car.ret
	JMP	RCHECK	; Wait for next file
;
;
; ***********************
; * WRITE BLOCK ON TAPE *
; ***********************
;
; Entry: HL: Start addres block
;        DE: Length block
; Exit:  HL: 1st byte after block
;        A:  Checksum on block contents
;        BCDE preserved
;
CWBLK	PUSH	B
	PUSH	D
	NOP
	CALL	LD316	; Write block length + c.s. on 1ength
	MVI	B, $56	; Initial checksum value
@D2F9	MOV	A, D
	ORA	E
	JZ	@D307	; If all bytes written
	DCX	D
	MOV	A, M	; Get byte of block
	INX	H	; Point to next byte
	CALL	LD30F	; Write byte, update checksum
	JMP	@D2F9	; Next byte
;
;	If a11 data written: write c.s. on block
;
@D307	MOV	A, B	; Get calculated checksum
	CALL	WBYTE	; Write checksum
	NOP
	POP	D
	POP	B
	RET
;
; *******************************
; * WRITE BYTE, UPDATE CHECKSUM *
; *******************************
;
; Entry: Byte to be written in A
;        Checksum in B
; Exit:  New checksum in B; A corrupted
;        CDEHL preserved
;
LD30F	CALL	WBYTE	; Write byte
	XRA	B
	RLC
	MOV	B, A	; Update checksum
	RET
;
; ***************************************
; * WRITE BLOCK LENGTH, UPDATE CHECKSUM *
; ***************************************
;
; Entry: DE: length block
; Exit:  DEHL preserved
;
LD316	MVI	B, $56	; Init checksum
	MOV	A, D	; Get highest length byte
	CALL	LD30F	; write it, update c.s.
	MOV	A, E	; Get 1owest length byte,
	CALL	LD30F	; write it, update c.s.
	MOV	A, B	; Get checksum
	CALL	WBYTE	; Write checksLim on length
	RET
;
; **********************
; * START FILE READING *
; **********************
;
; Entry: HL: Address 1ength byte of name requested.
;        B:  File type byte requested
;        C:  00 when reading during run program, else $FF
; Exit:  A:  File type byte
;        HL: Points to 1st byte of name requested
;        DE: Length namme requested
;        BC: preserved
;
CROPEN	PUSH	PSW
	CALL	LD7FF	; Switch cassette motors on, init. registers
LD329	NOP
	NOP
	NOP
	NOP
	NOP
	POP	PSW
	CALL	RHDR	; Read file header
	PUSH	PSW
	CALL	LD78A	; Display file type byte
	SUB	B
	CALL	CMBLK	; Read and check header, program name, file type byte
	ORA	A	; 0 if everything ok.
	JNZ	LD783	; If failure
	POP	PSW
	RET
;
; **************
; * READ BLOCK *
; **************
;
; Read 1ength, contents and checksum of a block
;
; Entry: HL: Addr. where to dump data read.
;        DE: End free space.
; Exit:  CY=1: No error:
;           HL: Next free address
;           BCDE preserved
;           AF corrupted
;        CY=0 Loading error:
;           BCDEHL preserved
;           A: Type of loading error
;
CRBLK	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LD790	; Calculate free RAM Space
	XCHG		; Free RAM in DE
	CALL	INLNG	; Read block length + c.s. 1ength in HL
	JC	@D37E	; If loading error 3
	ORA	A
	MVI	A, $00	; Loading error 0
	JNZ	LOERR	; If checksum error 0
	PUSH	H	; Save 1ength block
	DAD	D	; Calculate free RAM
	POP	D	; Get length block
	INR	A	; Loading error 1
	POP	H
	PUSH	H	; Restore begin addr.
	JC	LOERR	; If 1oading error 1
	MVI	B, $56	; Init checksum
@D35E	MOV	A, D
	ORA	E
	JZ	@D36F	; If whole block read
	DCX	D
	CALL	INSC	; Read next byte, update c.s
	JC	@D37E	; If 1oading error 3
	MOV	M, A	; store byte in buffer
	INX	H
	JMP	@D35E	; Next byte
;
; If whole block read
;
@D36F	CALL	RBYTE	; Read checksum block contents
	JC	@D37E	; If 1oading error 3
	CMP	B	; Check checksum
	MVI	A, $02	; Loading error 2
	JNZ	LOERR	; If loading error 2
	JMP	LC6B4	; CY=1, return: no error
;
; If loading error
;
@D37E	MVI	A, $03	; Loading error 3
LOERR	ORA	A
	JMP	LC6B6	; Return with CY=0; error
;
; *********************************
; * READ BYTE, CALCULATE CHECKSUM *
; *********************************
;
; Entry: B: Checksum
; Exit:  A: Byte read
;        B: Updated checksum
;        CDEHL preserved
;
INSC	CALL	RBYTE	; Read byte
RBUEX	PUSH	PSW
	XRA	B	; Calculate checksum
	RLC
	MOV	B, A	; Store new value
	POP	PSW
	RET
;
; ********************
; * READ NAME LENGTH *
; ********************
;
; Entry: No conditions.
; Exit:  HL: Length name read.
;        A:  Result checksum check (0 if OK).
;        BCDE: preserved
;        CY=0: OK
;        CY=1: Out of data
;
INLNG	PUSH	B
	MVI	B, $56	; Init. checksum
	CALL	INSC	; Read highest length byte and update checksum
	MOV	H, A
	CNC	INSC	; Read 1owest 1ength byte and update checksum
	MOV	L, A
	CNC	RBYTE	; Read checksun on length
RHLEX	PUSH	PSW
	SUB	B	; Check checksum
	MOV	B, A
	POP	PSW
	MOV	A, B
	POP	B
	RET
;
; *****************************************
; * READ CHECK PROGRAM NAME AND FILE TYPE *
; *****************************************
;
; Routine searches for proper file name by reading file name and compare it
; with name requested.
;
; Entry: A:  Evt. difference in file type byteread and requested.
;        B:  Requested file type
;        C:  00 during run program, else $FF
;        DE: Length requested
;        HL: Address 1st byte name requested
; Exit:  BCDEHL preserved
;        A=0: All OK
;        A=1: Loading error 1
;
CMBLK	PUSH	B	; Save file type + RUN flag
	PUSH	H	; Save addr reqd name
	MOV	B, A	; Store deviation file type
	PUSH	D	; Save reg. name length
	PUSH	H
	CALL	INLNG	; Read + check program name evt. c.s. failure in A
	JC	@D3ED	; If reading error
	ORA	A
	JNZ	@D3ED	; If checksum error
	PUSH	H	; Save length name on tape
	CALL	SUBDE	; Calculate difference name 1engths reqd and on tape
	MOV	A, H
	ORA	L
	MOV	H, A	; Difference in H
	MOV	L, B	; Difference file type in L
	POP	D	; Get 1ength name on tape
	MVI	B, $56	; Initiate checksum
@D3BC	XTHL		; Get byte reqd name
	MOV	A, D
	ORA	E	; Length name on tape = 0?
	JZ	@D3D8	; If length = 0, or whole name read
	DCX	D
	CALL	INSC	; Read bytes of name, update checksum
	JC	@D3ED	; If reading error
	DCR	C
	INR	C	; Load during run?
	PUSH	PSW	; Save 1ength name oh tape
	CNZ	WBCPUC	; Display program name
	POP	PSW	; Get byte of name on tape
	XRA	M	; Compare with name reqd
	INX	H
	XTHL		; Get 'difference flag'
	ORA	H	; Update it
	MOV	H, A	; and store it in H
	JMP	@D3BC	; Next byte
;
; If whole name read
;
@D3D8	CALL	RBYTE	; Read c.s. on name contents
	JC	@D3ED	; If reading error
	XRA	B	; Check checksum
	POP	H
	ORA	L	; Check file type
	MOV	L, A
	POP	D	; Get length req. nane
	MOV	A, D
	ORA	E	; No name requested?
	JZ	@D3E9	; If 1oad without name
	MOV	A, H	; Difference in names?
@D3E9	ORA	L	; Take also other checks in account
	POP	H
	POP	B
	RET
;
; If error
;
@D3ED	POP	H
	POP	D
	MVI	A, $01	; Loading error 1
	JMP	@D3E9
;
;
;
; ********************
; * READ FILE HEADER *
; ********************
;
; Locates a file on tape and reads leader.
; Exit: Interrupts are disabled
;       BCDEHL preserved
;
RHDR	CALL	SNDDI	; Disable sound interrupt
	CALL	RLEAD	; Find sync pattern
	CALL	RBYTE	; Read flag type byte
	JC	RHDR	; Again if reading error
	CPI	$55
	JNZ	RHDR	; Again if not flag byte
	CALL	RBYTE	; Read file type byte
	JC	RHDR	; Again if reading error
	RET
;
; *********************
; * WRITE FILE LEADER *
; *********************
;
; Writes a leader for program or data block on tape.
; Disables interrupts which could cause problems.
;
; Entry: at WHDR:   Entry if not during run program
;        at WHD20:  If during run of program.
; Exit:  BCDEHL preserved
;
WHDR	CALL_W(PMSGR, MSG15)	; Print 'SET RECORD, START TAPE, TYPE SPACE'
	CALL	WPT	; Wait for spacebar pressed
LD414	CALL	CASST	; Switch on cassette motors
	DI		; Disable interrupts
	NOP
	NOP
	CALL	WLEAD	; Write leader
	MVI	A, $55	; Get flag byte
	JMP	WBYTE	; Write f1ag byte
;
; **************
; * (Not used) *
; **************
LD422	CALL	CWBLK	; Write block on tape
	NOP
	NOP
;
; **********************
; * WRITE FILE TRAILER *
; **********************
;
; Write a trailer for program or datablock.
;
; Entry: Length of trailer in C
; Exit:  A=0, BCDEHL preserved
;
WTRL	.equ	*
CWCLOS	CALL	WTRLX	; Write trailer bytes
	EI		; Enable interrupts
	JMP	CASSP	; Stop cassette motors
;
; *************************
; * START CASSETTE MOTORS *
; *************************
;
; Turns on motor of selected cassettedeck and waits 665 msec.
;
; Exit: All registers preserved
;
CASST	PUSH	PSW
	LDA	POROM	; Load POROM
	ORI	$30	; Disable cassette motors
	PUSH	H
	LXI	H, CASSL	; Addr CASSL
	XRA	M	; Get selected cassette
	POP	H
	STA	POROM	; Remember POROM
	STA	PORO	; Switch cassette motor on
	CALL	DELAY	; Delay
	POP	PSW
	RET
;
; ************************
; * STOP CASSETTE MOTORS *
; ************************
;  Switches off cassette motors.
;
; Exit: All registers preserved
;
CRCLOS	.equ	*
CASSP	PUSH	PSW
	LDA	POROM	; Load POROM
	ORI	$30	; Disable cassette motors
	STA	POROM	; Remember POROM
	STA	PORO	; Switch cassette motors off
	POP	PSW
	RET
;
; ************
; * READ BIT *
; ************
;
; Reads one bit from tape.
;
; Entry: Address input port in HL. Input 1ow state.
; Ex1t:  CY=0: sign bit of A is bit read
;        CY=1: reading error
;        EHL preserved
;
RBIT	XRA	A
	MOV	D, A
	MOV	B, A
	MOV	C, A
;
; 1st impulse
;
@D457	DCR	B
	JZ	@D47E	; Too long low
	ORA	M
	JP	@D457	; Wait for high
@D45F	DCR	C
	JZ	@D47E	; Too 1ong high
	DCR	D
	ANA	M
	JM	@D45F	; Wait low
	LXI	B, $0000
;
; 2nd impulse
;
@D46B	DCR	B
	JZ	@D47E	; Too long 1ow
	ORA	M
	JP	@D46B	; Wait high again
@D473	DCR	C
	JZ	@D47E	; Too 1ong high
	INR	D
	ANA	M
	JM	@D473	; Wait low
	MOV	A, D
	RET
;
; * If error
;
@D47E	STC		; Set CY if error
	RET
;
; ***************
; * READ LEADER *
; ***************
;
; Finds a section of leader on the tape.
;
; Entry: No conditions
; Exit:  BCDEHL preserved, interrupts disabled
;
RLEAD	PUSH	B
	PUSH	D
	PUSH	H
	MVI	B, $28	; Estimate of impulse length
	LXI	H, PORI	; address input port
@D488	MVI	A, $FF
@D48A	EI		; Enable interrupts
	NOP		; interrupts slot (here cursor flashes)
	DI		; Disable interrupts
	ANA	M
	JM	@D48A	; Wait low
	MOV	C, B	; Estimated length in C
	MVI	D, $14	; Needs this many cycles for synchronisation.
			; Must be	more than trailer length
@D494	MVI	E, $00
	XRA	A
@D497	DCR	E
	JZ	@D488	; Too long low; start again
	ORA	M
	JP	@D497	; Wait high
	MVI	B, $00
@D4A1	INR	B
	JZ	@D488	; Too long high; start again
	ANA	M
	JM	@D4A1	; Wait 1ow
	MOV	A, B
	SUB	C	; Compare impulse length with estimate
	JP	@D4B0
	CMA
	INR	A	; 2-complement if < 0
@D4B0	MOV	E, A	; Store difference in E
	MOV	A, C	; Calculate margin
	ANI	$F0
	RAR
	RAR
	RAR		; Margin: 1/8th of estimate
	CMP	E	; Compare with difference
	JC	@D4C3	; Not within margin
;
; If sync archieved
;
	DCR	D
	JNZ	@D494	; Next impulse until D=0
	INR	D
	JMP	@D494	; Next impulse until out of margin
;
; If out of margin
;
@D4C3	DCR	D
	JNZ	@D488	; Not synchronised again
	XRA	A
@D4C8	ORA	M
	JP	@D4C8	; Wait high
@D4CC	ANA	M
	JM	@D4CC	; Wait 1ow
	POP	H
	POP	D
	POP	B
	RET
;
; *************
; * READ BYTE *
; *************
;
; Reads one byte from tape.
;
; Entry: No conditions
; Exit:  CY=0: Byte read in A
;        CY=1: Some error
;        BCDEHL preserved
;
RBYTE	PUSH	B
	PUSH	D
	PUSH	H
	LXI	H, PORI	; Address input port
	MVI	E, $FE
@D4DC	CALL	RBIT	; Read bit
	JC	@D4E9	; If reading error; CY=1;
	RAL
	MOV	A, E
	RAL
	MOV	E, A	; Shift bit into E
	JC	@D4DC	; Next bit
@D4E9	POP	H	; 8 bits read, no error
	POP	D
	POP	B
	RET
;
; ****************
; * WRITE LEADER *
; ****************
;
; Writes a leader on the tape. From LD4F6 also used to write a trailer.
;
; Entry: No conditions
; Exit:  A=0, BCDEHL preserved
;
WLEAD	NOP
	PUSH	B
	PUSH	H
	LHLD	TAPSL	; Get 1eader impulse length
	LXI	B, $07E8	; Period for synchr.
LD4F6	CALL	WBIT	; Write bit
	DCX	B
	MOV	A, B
	ORA	C
	JNZ	LD4F6	; Write many bits
	LHLD	$02E8	; Get impulse 1ength data bit
	CALL	WBIT	; Write a data '1' bit to end
	POP	H
	POP	B
	NOP
	RET
;
;
; **************
; * WRITE BYTE *
; **************
;
; Write a byte to tape.
;
; Entry: Byte to be written in A
; Exit:  All registers preserved
;
WBYTE	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	$02E8	; Get impulse length bit '1'
	MOV	E, H
	MOV	D, L	; DE: inpulse length bit '0*
	MVI	B, $08	; 8 bits to write
@D514	RAL		; Set/reset CY for kind of bit
	CC	WBIT	; Write data '1' bit
	XCHG
	CNC	WBIT	; Write data '0' bit
	XCHG
	DCR	B
	JNZ	@D514	; Next bit
	JMP	LCB56	; Pop all, ret
;
; *************
; * WRITE BIT *
; *************
;
; Write 2 impulses on tape, one long, one short.
;
; Entry: H: Half count first cycle
;        L: Half count second cycle
; Exit:  All registers preserved
;
WBIT	PUSH	PSW
	PUSH	D
	PUSH	H
	MOV	L, H
	LXI	D, PORO	; Address output port
	CALL	WCYC	; Write 1st impulse
	POP	H
	PUSH	H
	MOV	H, L
	MOV	A, L	; Allow for return to WBYTE
	SUI	$08
	MOV	L, A
	CALL	WCYC	; Write 2nd impulse
	POP	H
	POP	D
	POP	PSW
	RET
;
; **************
; WRITE CYCLE *
; **************
;
; Writes one impulse (hi/lo) on tape. Two cycles are required for one bit.
;
; Entry: DE: Address output port
;        HL: Impulse 1ength constants
; Exit:  HL = 0
;        BCDE preserved
;
WCYC	LDA	POROM	; POROM in A
	ORI	$01	; 1sb = 1
	STAX	D	; Output port is made '1'
@D542	DCR	H
	JNZ	@D542	; Write 1 until H=O
	DCR	L
	DCR	L
	DCR	L	; Allow for return to WBIT
	DCR	A
	STAX	D	; Output port is made '0'
@D54B	DCR	L
	JNZ	@D54B	; Write '0' until L=0
	RET
;
; **********************
; * WRITE TRAILER BITS *
; **********************
;
; writes trailer bits after a block on tape.
;
; Entry: Number of trailer bits in C
; Exit:  A=0, other registers preserved
;        F corrupted
;
WTRLX	PUSH	B
	PUSH	H
	LHLD	$02EA	; Trailer impulse length
	MVI	B, $00
	JMP	LD4F6	; Write trailer bits
;
.if ROMVERS == 11
;
; Part of Input Text Line
;
XD55A
	STA	OTSW	; Output to screen
	JMP	LDD49	; Ignore line if break pressed
.endif
.if ROMVERS == 10
	.byte $FF, $FF, $FF, $FF, $FF, $FF
.endif
;
; ********************************
; * INITIALISE KEYBOARD POINTERS *
; ********************************
;
; Set all keyboard pointers to default valuess.
;
; Entry: Address ASCII-table in HL (KEYTU)
; Exit:  BCDE preserved
;
KLIRS	.equ	*
KBINIT	SHLD	KBTPT	; Load pointer ASCII-table
KLIRP	XRA	A
	STA	KNSCAN	; Allow complete scan routine
	STA	SHLK	; CTRL not pressed
	LXI	H, KLIND
	SHLD	KLIIN	; Set KLIIN ) Ignore
	SHLD	KLIOU	; Set KLIOU ) previous inputs
	CMA
	STA	KBRFL	; BREAK pointer = FF
	RET
;
; ****************************i*********
; * KEYEOARD INTERRUPT SERVICE (RST 6) *
; ****************************i*********
;
; Current interrupt mask is saved. Only stack and clock interrupts are allowed.
; Keyboard timer 4 is re-loaded.
; KBXCT is counted down: abort if not 0
; Else: scan keyboard and store result.
;
; Entry: None
; Exit:  Al1 registers + int. mask preserved
;
KBINT	PUSH	PSW
	PUSH	B
	PUSH	D
	LDA	TICIM
	PUSH	PSW	; Preserve current int. mask
	MVI	A, $84
	STA	TIC_IM	; Allow stack and clock
	STA	TICIM	; interrupts only
	EI
	CALL	KBIS	; Reload keyboard timer
	LXI	H, KBXCT
	DCR	M	; Decr. keyb. scan time count
	JNZ	INTRM	; No scanning if <> 0
;
; if KBXCT = 0
;
	MVI	M, $02	; Set keyb. scan time counter
	CALL	KBSCAN	; Scan keyboard store result
	JMP	INTRM	; Restore int. mask; ret.
;
; *******************************
; * SCAN KEYBOARD, STORE RESULT *
; *******************************
;
; Exit: All registers corrupted
;
KBSCAN	LXI	D, TIC_KI	; Input port from keyboard
	LXI	H, TIC_KO	; Output port to keyboard
	LXI	B, KBRFL	; BREAK pointer
	DI
	MVI	M, $40	; Scan row 6
	LDAX	D	; and get result
	EI
	ADD	A	; Check for BREAK pressed
	JM	@D606	; If BREAK pressed
	CALL	LD750	; Update BREAK pointer
	LDA	KNSCAN	; Get BREAK pointer
	ORA	A	; Scan for BREAK only?
	JNZ	@D605	; Then abort
;
; Scan all rows and store result in MAP1
;
	LXI	B, MAP1	; MAP1 for currently pressed key
	PUSH	B	; Preserve MAP1 addr
	INR	A	; Determine row
@D5BB	PUSH	PSW
	DI
	MOV	M, A	; Scan row
	LDAX	D	; Get result
	EI
	STAX	B	; Store result in MAP1
	INX	B
	POP	PSW
	ADD	A	; Determine next row
	JNC	@D5BB	; Scan next row if not ready
;
; REPT handling
;
	LDA	RPLOC
	ANI	$20	; Check if REPT pressed
	MOV	B, A	; Store result
	LXI	H, RPCNT	; Addr. REPT counter
	MOV	A, M	; Get contents
	MVI	M, $01	; Update it for immediate scan
	JZ	@D5DF	; If REPT not pressed
	DCR	A	; Else
	MOV	M, A	; Decr. REPT counter
	JNZ	@D604	; If <> 0, abort scan
	MVI	M, $02	; Else RPCNT=2
	MVI	B, $FF	; Set B=FF for REPT pressed
;
; ASCII-value of key pressed into KLIND
;
@D5DF	POP	H	; Get addr MAP1
	PUSH	H	; Save addr. MAP1
	LXI	D, MAP2	; Get addr. MAP2
	MVI	C, $00
@D5E6	MOV	A, M	; Get result scan current row in A
	DCR	B
	INR	B	; REPT pressed?
	JNZ	@D5F0	; If REPT pressed
	XCHG
	XRA	M	; Check if new input
	XCHG
	ANA	M
@D5F0	ORA	A
	CNZ	TKEY	; If new Get ASCII-code and store it in KLIND
	INX	D
	INX	H	; Next row
	INR	C
	MOV	A, C
	CPI	$08	; All rows checked?
	JNZ	@D5E6	; Next row if not
	POP	D	; Get MAP1 addr in DE
	PUSH	D
	MOV	B, H	; Get MAP2 addr in HL
	MOV	C, L
	CALL	MOVE	; Transfer (MAP1) into MAP2
@D604	POP	D	; Scrap
@D605	RET
;
; BREAK pressed
;
@D606	PUSH	B	; Save Breakpntr
	CALL	SNDINI	; All sound off
	POP	B
	NOP
	CALL	CASSP	; Stop cassette motors
	LDAX	B	; Get KBRFL
	INR	A
	JZ	@D605	; If KBRFL=FF: break acknowledged already
	STAX	B	; Else: store new KBRFL
	CPI	$20
	JNZ	@D605	; If new KBRFL<>20: wait for soft-break to be accepted
	CALL	KLIRP	; Else: init keyb. pointers
	JMP	RSTART	; Print 'BREAK' return to monitor
;
;
;
; **************************
; * COMPLETE KEYBOARD SCAN *
; **************************
;
; Initialises a complete keyboard scan, independent of the KNSCAN flag, and performs it.
;
; Exit:	All registers preserved
;
KFSCAN	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	H, KNSCAN	; Addr KNSCAN pointer
	MVI	M, $00	; Enable complete scan
	PUSH	H
	CALL	KBSCAN	; Scan keyboard and store result in circ. buffer
	POP	H
	DCR	M	; Scan for BREAK only
	JMP	LCB56	; Popall ; return
;
; **********************************
; * GET ASCII VALUE OF KEY PRESSED *
; **********************************
;
; Calculates address in ASCII table in ROM and gets ASCII value of the key pressed.
; The result is stored in the 4—byte circular buffer KLIND.
;
; Entry: A:  Keycode of scanned row (7 bits only)
;        B:  FF when REPT pressed; else 00
;        C:  Number of row
;        DE: Address in MAP2
;        HL: Address in MAP1
; Exit:  BCDEHL preserved
;        AF corrupted
TKEY	PUSH	B
	MVI	B, $07	; Check which key in row is
@D635	RAR		; pressed; calculate offset
	CC	SINKEY	; Get ASCII value; store it in KLIND
	DCR	B
	JNZ	@D635	; Next column
	POP	B
	RET
;
; GET KEY-ASCII VALUE AND STORE IT
;
SINKEY	ROMCALL(1, $12)	; Get ASCII-va1ue from ROM—table and store it in KLIND
	RET
;
; *******************************
; * OUTPUT TO RS232 IF REQUIRED *
; *******************************
;
; Checks if output is to RS232. If positive, output is performed.
;
; Entry: Byte to be transmitted in A
;
TOUTSE	PUSH	PSW
	LDA	OTSW	; Get output direction
	ORA	A	; Check if RS232 output
	JNZ	LDD8C	; Abort if not
	POP	PSW
	JMP	OUTSE	; Output to RS232
;
; ******************************************
; * GET ASCII—VALUE OF CHARACTER IN BUFFER *
; ******************************************
;
; Routine is not used.
;
; The Ascii—vaiue of a character is stored in KLIND. Afterwards, Bank select is restored.
;
LD64E	CALL	INKEY
	POP	PSW	; A contains POROM
	CALL	LD808	; Update PORO and POROM
	POP	PSW
	POP	H
	RET
;
; ************************************
; * parts of RON 'RANDOMISE' (RRAND) *
; ************************************
;
LD658	DCR	A
	JNZ	LD658	; Again till A=0
	MOV	A, M	;  Get contents FD00
	XRA	E
	RET
;
; Entry: L = 0
;
LD65F	LDA	KBXCT	; Get keyb. scan time count (0, 1 or 2)
	RRC
	RRC		; A= 0, $40 or $80
	MOV	E, A	; in E
	MOV	B, L
	MOV	C, L	; BC = 0
	RET
;
; ************************************
; * WRITE 2 BLOCKS + TRAILER ON TAPE *
; ************************************
;
; * Entry: HL:    Start address 1st block
;          Stack: Length 2nd block
;                 Start address 2nd block
;
LD668	LXI	D, $0001	; Length 1st block = 1
	CALL	WBLK	; Write 1st block
	POP	D	; Get length 2nd block
	POP	H	; Gee start addr. 2nd block
	CALL	WBLK	; Write 2nd block
	CALL	WCLOSE	; write trailer
	ORA	A
	RET
;
; ********************************
; * LOADA: EVALUATE PROGRAM NAME *
; ********************************
;
; The program name is evaluated. Selection of ROM bank 1 is prepared.
;
LD678	CALL	LD687	; Evaluate program name
	LDA	POROM	; Get POROM
	ORI	$40	; Prepare selection ROM bank 1
	RET
;
; ******************
; * OPEN READ FILE *
; ******************
;
LD681	PUSH	D
	CALL	ROPEN	; Open READ file
	POP	D
	RET
;
; ********************************
; * EVALUATE A STRING EXPRESSION *
; ********************************
;
; A string expression is evaluated. Eventually, the Heap entry is cleared if the string
; was temporarily on Heap.
;
; Exit:  DE preserved
;       BC updated
;       HL points after string
;
LD687	PUSH	D
	CALL	REXSR	; (0) Eval. string expr. evt. clear Heap entry
	POP	D
	RET
;
; *******************
; * CURSOR HANDLING *
; *******************
;
; Load the cursor pointers with the address, the colour and the contents of a new
; cursor address.
;
; Entry:  HL: New cursor address
;         D:  The colour byte of this location
;         E:  The contents of this 1ocation
; Exit:  HL and DE exchanged
;         ABCF preserved
;
LD68D	SHLD CURSOR	; Store cursor address
	XCHG
	SHLD CURSV	; Store cursor addr. contents
	RET
;
; ************************
; * OUTPUT ONE CHARACTER *
; ************************
;
; Output direction depending on OTSW.
; This routine is useable for all data output functions in machine language programs.
;
; Entry: Character for output in A
; Exit:  All registers preserved
;
LD695	PUSH	PSW
	CALL	OUTC	; Output character in A
	POP	PSW
	RET
;
	.byte	$FF
;
; ************************************************
; * KEYB. SCANNING: UPDATE POINTER OUTPUT BUFFER *
; ************************************************
;
; Updates the pointer to the circular output buffer KLIND-$02BD.
;
; Entry: HL: KLIOU
; Exit:  HL: Updated KLIOU
;        AF corupted
;        BCDE preserved
;
KPTRU	INX	H	; Incr KLIOU
	MOV	A, L	; Lobyte into A
	CPI	$BE	; Buffer full?
	RNZ		; Quit if not
	LXI	H, KLIND	; Else: wrap around
	RET
;
; ******************************************
; * KEYBOARD SCANNING: CHECK IF NEW INPUTS *
; ******************************************
;
; Returns a flag if BREAK has been pressed or if there is a character available.
;
; Entry: No conditions
; Exit:  BCDEHL preserved
;        A: Diference KLIIN and KLIOU
;        CY=1: Break pressed
;        CY=0, Z=1: No inputs
;        CY-0, Z=0: New input available
;
ASKKEY	.equ	*
BREAK	PUSH	H
;
; If suspended
;
	LXI	H, KBRFL	; Addr break pntr
	MOV	A, M
	DCR	A
	CPI	$FE	; Test if not 0 or FF
	JC	@D6B9	; Abort if break: CY=1
	LHLD	KLIOU	; Get KLIOU
	LDA	KLIIN	; Get KLIIN
	SUB	L	; New keys pressed?
	STC
	CMC		; CY=0
@D6B9	POP	H
	RET
;
; ******************
; * INPUT SCANNING *
; ******************
;
; Gets input from keyboard or DINC, depending on INSW (INSW).
;
; FGETC: Gets a character, even if keyboard scanning is turned off
;  GETC: Returns a flag if break and sets break accepted. Returns also a flag if a character is available
;
; Exit:  CY=1: Break pressed
;         Z=1: No inputs. Then A=0
;	Else: Character in A
;
FGETC	CALL	KFSCAN	; Complete keyboard scan
GETC	JMP	LD1DB	; Check input keyb/DINC; scan for new keys pressed
LD6C1	JC	@D6D4	; Jump if Break pressed
	RZ		; No new 1nput or buffer full
;
; If inputs
;
	PUSH	H
	LHLD	KLIOU	; Get addr pntr output buffer
	MOV	A, M	; Get ASCII char in A
	PUSH	PSW
	CALL	KPTRU	; Update pntr
	POP	PSW
	SHLD	KLIOU	; Re-instate KLIOU
	POP	H
	RET		; CY=0
;
; If Break pressed
;
@D6D4	MVI	A, $FF	; Flag 'break accepted'
	STA	KBRFL	; Scan for break only
	RET		; CY=1
;
; *********************
; * WAIT FOR SPACEBAR *
; *********************
;
; Wait until spacebar (or break) is pressed.
; Entry: None
; Exit:  CY=1: Break pressed
;        CY=0: Space in A
;        BCDEHL preserved
;
WSPACE	CALL	FGETC	; Input scanning
	RC		; Abort if BREAK pressed
	CPI	' '	; Check if spacebar
	JNZ	WSPACE	; Wait for space bar
	ORA	A
	RET
;
; *************************
; * part of LOADA (1EE0F) *
; *************************
;
LD6E5	XTHL		; Orig. DE in HL free RAM pntr on stack
	CALL	COMP	; Compare DE-HL
	JNC	@D6ED	; If DE<=HL
	XCHG
@D6ED	MOV	B, D	; Lowest value in BC
	MOV	C, E
	POP	D
	POP	H
	XTHL
	JMP	LEE4C	; (1) Continue
;
; ************************************************************************
; * CHECK SUFFICIENT SCREEN RAM AVAILABLE - PREPARE SELECTION SPLIT MODE *
; ************************************************************************
;
LD6F5	STC		; CY=1
	LHLD	GTE	; Get end area splitting mode
	CALL	SMKRM	; (2) Ask for temporary area
	LXI	H, TABMA	; (2) Start addr table screen parameters split modes
	RET
;
; ******************************************
; * CHANGE FROM SPLIT TO FULL GRAPHIC MODE *
; ******************************************
;
LD700	CALL	LD6F5	; Check suff. screen RAM
	JMP	LE485	; (2) Change split to full
; **********************************************************************
; * CHECK SUFFICIENT SCREEN RAM AVAILABLE - PREPARE FULL GRAPHICS MODE *
; **********************************************************************
;
LD706	CALL	LD6F5	; Check suff. screen RAM
	LXI	H, TABM	; (2) Startaddr table screen parameters full graph. modes
	RET
;
; ******************************
; * SET UP CURRENT SCREEN MODE *
; ******************************
;
LD70D	POP	D
	POP	PSW
LD70F	LDA	SMODE	; Get current screen mode
	ORA	A
	RAR		; Sp1it or all-graph mode?
	CALL	TABP	; (2) Set up screen mode
	JMP	LE43C	; (2) Pop PSW, ret
;
; *************************
; * STOP LOADING PROGRAMS *
; *************************
;
; Entry: HL: New end symbol table
; Exit:  All registers preserved
;
LD71A	SHLD	STBUSE	; Store end symtab
	JMP	RCLOSE	; Stop 1oading
;
; *****************************
; * INIT. WRITING FILE LEADER *
; *****************************
;
; Procedure depends on saving in program or not.
;
LD720	PUSH	H
	LHLD	CURRNT	; Get start current line
	MOV	A, H
	ORA	L	; 0 if not during run
	POP	H
	JNZ	LD414	; if SAVE during run
	JMP	WHDR	; Write file leader
;
; *********************************************************************************
; * INIT. SOUND GENERATOR, GIC, START HEAP, MOVE CASSETTE VECTORS, GET DCE INPUTS *
; *********************************************************************************
;
LD72D	CALL	SNDINI	; Init. sound generator
	CALL	CASIN	; Transer cassette vectors
	LXI	H, RAMSTRT
	ROMCALL(1, $0C)	; Init. GIC; get evt. inputs from DCE-bus (bootstrap)
	SHLD	HEAP	; Set HEAP start
	RET
;
	.byte	$02	; (not used)
;
; ********************************************
; * part of RUN A VARIARLE REFERENCE (RARRN) *
; ********************** *********************
;
LD73D	CALL	RVR05	; (0) Run VARPTR
	POP	D
	RET
;
	.byte	$DD	; (not used)
;
; *************************************************
; * SET INPUT DIRECTION, LOAD SOUND + KEYB TIMERS *
; *************************************************
;
; Part of 'stack interrupt' (D9E2)
;
LD743	STA	EFSW	; Set input direction
	CALL	KBIS	; Reload keyboard timer
	JMP	SNDIS	; Reload sound timer, ret
;
; *******************************
; * DATA OUTPUT ROUTINE 'DOUTC' *
; *******************************
;
; Part of DD70.
; On DOUTC, an jump to an user determined output routine can be written.
; As default, a RET is on this address.
;
LD74C	POP	PSW	; Output char in A
	JMP	DOUTC	; Goto user DOUTC
;
; ********************
; * CHECK BREAK FLAG *
; ********************
;
; Part of 'scan keyboard' (D59A).
;
; Entry: Address 'break' flag in BC
; Exit:  BCDEHL preserved
;        AF corrupted
;
LD750	LDAX	B	; Get KBRFL
	INR	A
	RNZ		; Quit if it was <> FF
	STAX	B	; KBRFL=0: No recent break
	RET
;
; ***************************
; * SOUND INTERRUPT (RST 3) *
; ***************************
;
; Called periodically every few milliseconds.
; Adjust the volume for the sound channels and approaches the correct frequency if necessary.
;
; Saves all registers + interrupt mask.
; Enables only clock and sound interrupts.
; Sound interrupt timer is re-loaded and sound control blocks are executed.
;
; Entry: HL must already be saved on stack
; Exit:  All registers preserved
;        Bank select is restored
;
SNTMP	PUSH	PSW
	PUSH	B
	PUSH	D
	LDA	TICIM	; Get current int. mask
	PUSH	PSW	; and save it
	MVI	A, $84
	STA	TICIM	; Enable clock and sound
	STA	TIC_IM	; interrupts only
	EI
	CALL	SNDIS	; Reload sound timer
	LDA	POROM	; Get POROM
	PUSH	PSW	; and save it
	ANI	$3F
	ORI	$40	; Select ROM bank 1
	STA	POROM	; Set POROM
	STA	PORO	; and PORO
	CALL	TEMPO	; (1) Execute SCB('s)
	POP	PSW
	STA	POROM	; Re-instate old ROM bank
	STA	PORO	; and save it
	JMP	INTRM	; Restore int. mask ret
;
; ************************
; * FAILURE DURING ROPEN *
; ************************
;
LD783	DCR	B
	INR	B
	JNZ	LD7DE	; If file type byte <> 0 run error
	POP	PSW
	RET
;
; ************************************
; * CHECK IF LOAD DURING RUN PROGRAM *
; ************************************
;
; Entry: C: 00: if 1oad during run, else it is FF
;        A: File type byte
; Exit:  ABCDEHL preserved
;
LD78A	DCR	C
	INR	C	; Check C
	RZ		; Abort if during run
	JMP	WBCPUC	; Display file type byte
;
;
;
; ************************
; * CHECK FREE RAM SPACE *
; ************************
;
; Entry: DE: Start address
;        HL: 1st not useable address
; Exit:  HL: Useable RAM space
;        ABCDE preserved
;
LD790	CALL	SUBDE	; Calculate free space
	DCX	H
	RET
;
; **********************************
; * TRANSFER DATA/CASSETTE VECTORS *
; **********************************
;
; Transfer data/cassette switching vectors from ROM to RAM vector area.
;
; Exit:  AFBC preserved
;        DEHL corrupted
;
CASIN	PUSH	B
	LXI	H, CINTE	; Highest source address
	LXI	D, CINTB	; Lowest source address
	LXI	B, IOVEC	; Lowest destination address
	CALL	MOVE	; Transfer cassette vectors
	POP	B
	RET
;
; ***********************************
; * DATA/CASSETTE SWITCHING VECTORS *
; ***********************************
;
; This data block is moved into the RAM area WOPEN-$02EB during system initialisation.
;
CINTB	JMP	CWOPEN	; WOPEN
	JMP	CWBLK	; WBLK
	JMP	CWCLOS	; WCLOSE
	JMP	CROPEN	; ROPEN
	JMP	CRBLK	; RBLK
	JMP	CRCLOS	; RCLOSE
	JMP	CMBLK	; MBLK
	RET		; RESET
	NOP
	NOP
	RET		; DOUTC
	NOP
	NOP
	JMP	CINC	; DINC
	RET
	NOP
	NOP
	.byte	$24, $24	; TAPSL
	.byte	$24, $3C	; TAPSD
	.byte	$24, $18	; TAPS
CINTE	.equ	*
;
; ************************************
; * WAIT FOR SPACEBAR, PRINT CAR.RET *
; ************************************
;
; Exit: BCDEHL preserved
;       CY=1: Break pressed
;
WPT	CALL	WSPACE	; Wait for spacebar
	JC	RSTART	; If BREAK pressed: into Basic monitor
	JMP	CRLF	; Print car.ret; ret
;
	.byte	$FF, $FF, $FF, $FF
;
; *********************************
; * WRITE BLOCK + TRAILER ON TAFE *
; *********************************
;
; Entry: DE: Length block
;        HL: Start address block
; Exit:  A=0
;        BCDE preserved
;        HL points past block written
;
LD7D8	CALL	WBLK	; Write block
	JMP	WCLOSE	; Write trailer
;
; ************************
; * FAILURE DURING ROPEN *
; ************************
;
LD7DE	DCR	C
	INR	C	; Load during program?
	CNZ	CRLF	; Print car.ret if not
	JMP	LD329	; Back to read file 1eader
.if ROMVERS == 11
;
; *****************************
; * PRINT MESSAGE ON NEW LINE *
; *****************************
;
; New routine. It moves the cursor to a new line before a message is printed.
; Used for printing	'STOPPED IN LINE ...' and 'END PROGRAM'.
;
XD7E6	CALL	COL0	; Cursor to column 0
 	JMP	PMSGR	; Print message
.endif
.if ROMVERS == 10
;
; **************************
; * CHECK FILE OF ANY TYPE *
; **************************
;
AMBLK	MVI	A, $00	; File type correct
	JMP	MBLK	; Read and check program name
.endif
;
; *****************************************
; * WRITE BYTE ON CURSOR POSITION ADDRESS *
; * AND UPDATE CURSOR P0SITION            *
; *****************************************
;
; This routine is a fast printing routine: the data byte is poked directly into the
; screen RAM.
;
; Entry: Byte to be written on screen in A
; Exit:  All registers preserved
;
WBCPUC	PUSH	H
.if ROMVERS == 10
	NOP
.endif
	LHLD	CURSOR	; Get cursor position address
	MOV	M, A	; Write byte on screen
	DCX	H	; Update cursor addr
	DCX	H
	SHLD	CURSOR	; Save new cursor address
	POP	H
	RET
;
; ***************************
; * SAVE: WRITE NAME LENGTH *
; ***************************
;
; Entry: HL: Addr. length byte of name
; Exit:  DE: Length of name
;        HL: Points past string
;        BC: Preserved
;        A:  Checksum on string
;
LD7F8	MOV	E, M	; Get name length
	MVI	D, $00	; in DE
	INX	H	; HL to 1st byte of name
	JMP	CWBLK	; Write name 1ength
;
; ********************************
; * INITIALISE LOADING FROM TAPE *
; ********************************
;
; Entry: HL: Points to 1ength byte of name requested
; Exit:  DE: Length requested name
;        HL: Points to first byte of name
;        AFBC preserved
;
LD7FF	MOV	E, M	; Get 1ength requested name
	MVI	D, $00	; in DE
	INX	H	; HL points to 1st byte name
	JMP	CASST	; Cassette motors on; ret
;
; *********************
; * UPDATE POROM/PORO *
; *********************
;
; Entry: LD806: Byte for ROM/cassette select in A
;        LD808: New POROM byte
;
LD806	ANI	$F0	; Enable ROM/cassette select
LD808	STA	POROM	; Load POROM
	STA	PORO	; and PORO
	RET
;
; *****************
; * part of 2EAC1 *
; *****************
;
; If pointer is off top visible screen:
;
LD80F	MOV	A, D
	CPI	$D0
	JC	LEAEF	; (2) if <= CF (no overflow below 0)
	PUSH	H	; if > CF:
	PUSH	B	; Exchange BC and HL
	POP	H
	POP	B
	JMP	LEAEF
;
	.byte	$FF
;
; **********************
; * RUN basiccmd SAVEA *
; **********************
;
RSAVA	CALL	RLSAS	; Evaluate array type to be saved
	PUSH	PSW	; Save type array
	JNZ	@D826	; Jump if INT/FPT array
	ROMCALL(4, $75)	; Move stringarray into one string in free RAM
@D826	POP	PSW	; Get type array
	PUSH	H
	PUSH	D
	PUSH	PSW
	CALL	REXSR	; (0) Evaluate program name
	MVI	A, $32	; File type byte '2'
	CALL	WOPEN	; WOPEN
	POP	PSW	; Get type array
	LXI	H, EBUF	; Start addr EBUF
	MOV	M, A	; Type into EBUF
	JMP	LD668	; Write 2 blocks + trailer
;
	NOP
;
; ******************************************
; * EVALUATE ARRAY TYPE TO BE SAVED/LOADED *
; ******************************************
;
; Exit: A:  Array type
;       DE: Length all array elements
;       HL: Beginaddr. 1st array element
;       Z=1: String array
;       Z=0: INT/FPT array
;
RLSAS	CALL	RARRN	; (0) Get array addr in HL
	ANI	$30	; Allow any type array
	PUSH	PSW	; Save type
	MOV	E, M	; Get array pntr in DE
	INX	H
	MOV	D, M
	MOV	A, E
	ORA	D
	JZ	ERRUA	; (0) Undef. array if no addr
	XCHG		; Pointer to array in HL
	DCX	H
	DCX	H
	MOV	D, M	; Get 1st 1ength byte
	INX	H
	MOV	A, M	; Get 2nd length byte
	INX	H	; Minus nr of dim. bytes
	SUB	M
	MOV	E, A
	MOV	A, D
	SBI	$00	; Update hibyte if borrow
	MOV	D, A
	DCX	D	; DE is length all array elem.
	CALL	DADM	; HL is begin addr 1st element
	POP	PSW	; Get type in A
	CPI	$20	; Set Z-flag on type
	RET
;
; **********************
; * RUN basiccmd LOADA *
; **********************
;
;
RLODA	CALL	RLSAS	; Evaluate array type to be 1oaded
	PUSH	H	; Save start addr array elem.
	PUSH	PSW	; Save type
	CALL	LD678	; Evaluate requested program name; prep. select ROM bank 1
	CALL	LD808	; Select ROM bank 1
	POP	PSW	; Get type
	JMP	LEE0F	; (1) Read block from tape and store it in array
;
; ************************************
; * INITIALISE 'EDIT': EMPTY HEAP,   *
; * CLEAR SYMBOL TABLE, MOVE PROGRAM *
; ************************************
;
; Part of 'Init. EDIT' (REDIN).
;
; Entry: CY=1: Not sufficient memory available.
;
LD86D	JC	ERROM	; Evt. run error 'OUT OF MEMORY'
	JMP	SCRATC	; Empty heap, move program, clear symtab
;
; ******************************************
; * LIST CURRENT LINE IF LINENR IS CORRECT *
; ******************************************
;
; Part of 'run LIST <range>' (0E1B6).
;
; Entry: CY=0 if linenr. <= 0 or > $FFFF
;
LD873	JNC	ERRRA	; Evt. run error 'NUMBER OUT OF RANGE'
	JMP	SLINE	; (0) List current line
;
; **************************
; * INPUT FROM EDIT BUFFER *
; **************************
;
; Part of 'restart interpreter' (C823)
;
LD879	PUSH	H
	CALL	IFBNL	; (0) Input from editbuffer
	POP	H
	RET
.if ROMVERS == 11
; Part of RUN CLEAR
LD87F	POP	H	; Get difference
	DAD	B	; Add textpntr
	MOV	B, H	; New textpntr in BC
	MOV	C, L
	ORA	A	; No special action
	RET
	.byte	$FF
.endif
.if ROMVERS == 10
;
; *******************************
; * Part of RUN 'CLEAR' (0E6B5) *
; *******************************
;
; Checks for heap too big.
;
LD87F	CALL	REXI2	; (0) Get space req. in HL
	MOV	A, H
	ORA	A	; Set flags on hibyte
	STC		; CY=1 if > 32K
	RET
.endif
;
; ************************************
; * EVT. INITIALISE 4 COLOUR ANIMATE *
; ************************************
;
; Part of 2E9C3
;
LD886	CPI	$14
	RNC		; Abort if A >= $14
	STA	ANIM	; Set for 4-colour animate
	RET
;
; ********
; * DATA *
; ********
;
LD88D	.byte	' '	; Space
	REF_STR($8, SMODE_)	; Pntr. to MODE
	.byte	$00
;
; ******************************
; * part of 1EE0B - (not used) *
; ******************************
;
LD891	PUSH	PSW
	CALL	REXSR	; (1)
	POP	PSW
	RET
;
; *******************************************
; * READ BLOCK FROM TAPE, EVT. ERROR REPORT *
; *******************************************
;
; Part of LOADA (1EE0F)
LD897	CALL	RBLK	; Read block from tape
.if ROMVERS == 11
 	JMP	XD265
.endif
.if ROMVERS == 10
	JNC	RLEAR	; Evt. run 'LOADING ERROR'
.endif
	RET
;
; **************************************
; * LIST ARRAY NAME, SPACE, EXPRESSION *
; **************************************
;
; Used in listing 'Savea/Loada' textlines.
;
LD89E	CALL	SCARN	; (0) List array name
	JMP	SCSEX	; (0) List space, expression
;
	.byte	$FF, $FF
;
; ******************************
; * INITIALISE SOUND GENERATOR *
; ******************************
;
; All sound channels are switched off.
;
; Exit: AB preserved
;       CDEHLF corrupted
;
SNDINI	LXI	H, SNDC	; Load 3 timers
	MVI	M, $36
	MVI	M, $76
	MVI	M, $B6
	LXI	H, $0000
	SHLD	POR0	; Volume 4 channels off
	SHLD	POR0M	; and remember it
	LXI	H, SCBAREA	; Start 1st SCB
	LXI	D, $000E	; Length SCB
	MVI	C, $04	; 4 blocks (3 SCB, 1 NCB)
@D8C0	MVI	M, $FF	; FF in 1st byte SCB (= off)
	DAD	D	; Calc start next block
	DCR	C
	JNZ	@D8C0	; Next block if not ready
	RET
;
; *********************
; * OUTPUT TO DCE-BUS *
; *********************
;
; 'Real World' output. Writes a byte to a given Real World address.
;
; Entry: D: Bus address
;        E: Data for output
;
RWOP	PUSH	PSW
	PUSH	H
	LXI	H, GIC_CM	; GIC control address
	MVI	M, $80	; All ports output
	DCX	H	; Port C addr. in HL
	MVI	M, $FE	; Clear bus expand signal
	XCHG		; Data in L busaddr. in H
	SHLD	GIC_A	; Data in PA, busaddr. in PB
	XCHG		; Address PC in HL
	INR	M	; Set bus expand signal
	MVI	M, $FD	; Set write strobe true (Now data exchange done)
	MVI	M, $FF	; Reset strobe
	DCR	M	; Clear bus expand signal
	POP	H
	POP	PSW
	RET
;
; **********************
; * INPUT FROM DCE-BUS *
; **********************
;
; Real World input. Reads a byte from a given Real World address.
;
; Entry: D: Bus address
; Exit:  E: Data received
;
RWIP	PUSH	PSW
	PUSH	H
	LXI	H, GIC_CM	; GIC control addr. in HL
	MVI	M, $90	; PA input, rest output
	DCX	H	; Address PC in HL
	MVI	M, $FE	; Clear bus expand sigal
	MOV	A, D	; Busaddress in A
	STA	GIC_B	; Store busaddress in PB
	INR	M	; Set bus expand signal
	MVI	M, $FB	; Set read strobe true (Now data exchange)
	LDA	GIC_A	; Data to A
	MOV	E, A	; Data in E
	MVI	M, $FF	; Reset strobe
	DCR	M
	POP	H
	POP	PSW
	RET
;
;
;
;     =================
; *** INTERRUPT HANDLER ***
;     =================
;
;
; *******************************
; * INITIALISE INTERRUPT SYSTEM *
; *******************************
;
; Initialises the interrupt system of the machine.
;
; Entry: No conditions
; Exit:  All registers corrupted
;
INTINI	LXI	H, TIC_IM	; Address int.mask register
	MVI	A, $04
	MOV	M, A	; Only stack interrupt
	STA	TICIM	; Remember int. mask
	MVI	L, $F4
	MVI	A, $0C
	MOV	M, A	; Select ext.int. and INTA
	INR	A
	MOV	M, A	; Reset
	MVI	A, $0C
	STA	CTIMR	; Init. cursor timer
	MVI	A, $02
	STA	KBXCT	; Init. keyboard scan counter
	CALL	SNDIS	; Reload sound timer
	CALL	KBIS	; Reload keyboard timer
	CALL	VECSU	; Set up int. entry points
;
; Set-up interrupt vectors (also entry from utility)
;
INTSU	LXI	H, CLKINT
	SHLD	I7USA	; Clock int. vector (7)
	LXI	H, KBINT
	SHLD	I6USA	; Keyboard int. vector (6)
	LXI	H, SCRST
	SHLD	I5USA	; Screen restart vector (5)
	LXI	H, MARST
	SHLD	I4USA	; Math. restartt vector (4)
	LXI	H, SNTMP
	SHLD	I3USA	; Sound int. vector (3)
	LXI	H, SPINT
	SHLD	I2USA	; Stack int. vector (2)
	LXI	H, UTRST
	SHLD	I1USA	; Utility/encode vector (1)
	RET
;
; SET UP INTERRUPT VECTOR AREA
;
; Sets up the vector area $0000-$003F.
;
; Entry: No conditions.
; Exit:  All registers corrupted.
;
VECSU	LXI	B, $0000	; Start at zero
@D94C	LXI	D, ITMPL	; Start addr. int. routine
	LXI	H, ITMPLE	; End address
	CALL	MOVE	; Transfer int. routinne
	MOV	A, C
	CPI	$40	; 8 routines done?
	JNZ	@D94C	; Next one if not ready
	LXI	H, $003B	; Addr. highest int. vector
	LXI	B, TIC_IM
	MVI	D, $70
@D963	MOV	M, D	; Load vector addr.
	DCR	D
	DCR	D
	DAD	B	; Calculate next addr
	JC	@D963	; Next one if not ready
	RET
;
; INTERRUPT VECTOR ROUTINE
;
; During initialisation loaded into RAM on the restart routine 1ocations of the CPU.
; The address after LHLD is 1ater changed into the appropriate vector address by INTINI.
;
ITMPL	NOP
	PUSH	H
	LHLD	I7USA
	PCHL
	NOP
	NOP
ITMPLE	.equ	*
;
; *******************************
; * DISABLE KEYBOARD INTERRUPTS *
; *******************************
;
; Disables keyboard interrupts only.
;
; Entry can be different. From INTCH common part to disable/enable sound, clock and
; keyboard interrupts.
;
; Entry: None
; Exit:  All registers preserved
;
KBDI	PUSH	B
	LXI	B, $BF00	; Disable keyboard interrupts
INTCH	PUSH	PSW
	DI		; Disable interrupts
	LDA	TICIM	; Get current int.mask
	ANA	B	; Calculate new one
	ORA	C
	STA	TICIM	; Remember new mask
	STA	TIC_IM	; and set mask
	EI		; Enable interrupts again
	POP	PSW
	POP	B
	RET
;
; ******************************
; * ENABLE KEYBOARD INTERRUPTS *
; ******************************
;
; Enable keyboard interrupts only
;
KBEI	PUSH	B
	LXI	B, $FF40	; Enable keyboard interrupts
	JMP	INTCH	; Update int. mask
;
; ****************************
; * DISABLE SOUND INTERRUPTS *
; ****************************
;
; Disables sound interrupts only.
;
SNDDI	PUSH	B
	LXI	B, $F700	; Disable sound interrupts
	JMP	INTCH	; Update int. mask
;
; ***************************
; * ENABLE SOUND INTERRUPTS *
; ***************************
;
; &Enables sound interrupts only.
;
SNDEI	PUSH	B
	LXI	B, $FF08	; Enable sound interrupts
	JMP	INTCH	; Update int. mask
;
; ***********************
; * LOAD KEYBOARD TIMER *
; ***********************
;
; Starts a keyboard interrupt.
;
KBIS	MVI	A, $FF	; Init. 16.32 msec
	STA	KEIAD	; Load timer 4 (keyboard)
	RET
;
; ********************
; * LOAD SOUND TIMER *
; ********************
;
; Starts a sound interrupt.
;
SNDIS	MVI	A, $50	; Init. 5.12 msec
	STA	SNDIAD	; Load timer 3 (sound)
	RET
;
; ***************************
; * CLOCK INTERRUPT (RST 7) *
; ***************************
;
; Triggered every 20 msec by the TV page blanking signal.
; Decrements timer TIMER until 0.
; Checks also the contents of cursor clock timer 01C0. It is decrementeds if it becomes 0,
; the timer is re1oaded and the cursor is flashed.
;
; Exit: All registers preserved.
;
CLKINT	PUSH	PSW
	PUSH	B
	PUSH	D
	LDA	TICIM	; Get current int. mask and remember it
	PUSH	PSW
	MVI	A, $04
	STA	TIC_IM	; Set stack interrupt oniy
	EI
	LHLD	TIMER	; Get timer contents
	MOV	A, H
	ORA	L
	JZ	@D9C2	; If timer = 0
	DCX	H
	SHLD	TIMER	; decrement timer
@D9C2	LXI	H, CTIMR	; Addr cursor clock
	DCR	M	; Decr. clock
	JNZ	INTRM	; Return if <> 0
	MVI	M, $0F	; Load 20 ms flash time
	ROMCALL(5, $12)	; F1ash cursor
;
; GENERAL INTERRUPT RETURN
;
; Restores interrupt mask and all registers.
;
; Entry: Interrupt mask and all registers on stack.
;
INTRM	POP	PSW	;Get old int mask
	DI
	STA	TIC_IM	; Restore int. mask
	STA	TICIM	; and remember it.
	EI
	POP	D
	POP	B
	POP	PSW
	POP	H
	RET
;
; **************************
; * ENABLE CLOCK INTERRUPT *
; **************************
;
CLKEI	PUSH	B
	LXI	B, $FF80	; Enable clock interrupt
	JMP	INTCH	; Update int.mask
;
; **************************
; * STACK INTERRUPT (RST2) *
; **************************
;
; This routine handles an interrupt caused by the stack overflow hardware 1ogic.
;
SPINT	LXI	SP, $F900 ; Reset stackpointer
	XRA	A
	STA	RDIPF	; No running inputs
	STA	ERSFL	; No encoding of stored line
	CALL	LD743	; Input rom keyboard, reload timers sound/keyb
	EI
	MVI	A, $16
	JMP	ERROR	; Run error 'STACK OVERFLOW'
;
;
;
;     =============
; *** ERROR HANDLER ***
;     =============
;
;
; ******************
; * ERROR HANDLING *
; ******************
;
; Produces an error message and other information about errors
;
; Entry: A:  Error message number
;        BC: Latest position in EBUF or textbuffer
; Exit:  If during input: Restart input statement
;        If during encoding: Back to ELINA (LC93C) for handling.
;        Else: Restart Basic (direct mode)
;
ERROR	MOV	B, A	; Save error pointer
	XRA	A
	STA	OTSW	; Set output screen/RS232
	CALL_W(SELB0, $0000)	; Select ROM bank 0
	NOP
	NOP
	LDA	RUNF	; Get RUNF
	ORA	A
	JNZ	ERRRU	; If run-time error
	JMP	ERRCO	; If compile-time error
;
; ENTRYPOINTS TO ERROR ROUTINES
;
ERRSN	MVI	A, $17
	JMP	ERROR	; Run 'SYNTAX ERROR'
ERROM	MVI	A, $13
	JMP	ERROR	; Run 'OUT OF MEMORY'
ERRRA	MVI	A, $09
	JMP	ERROR	; Run 'NUMBER OUT OF RANGE'
ERRTM	MVI	A, $14
	JMP	ERROR	; Run 'TYPE MISMATCH'
ERROV	MVI	A, $03
	JMP	ERROR	; Run 'OVERFLOW'
ERRD0	MVI	A, $06
	JMP	ERROR	; Run 'DIVISION BY ZERO'
ERRBS	MVI	A, $05
	JMP	ERROR	; Run 'SUBSCRIPT ERROR'
ERRNF	MVI	A, $00
	JMP	ERROR	; Run 'NEXT WITHOUT FOR'
ERREL	MVI	A, $12
	JMP	ERROR	; Run 'ERROR LINE RUN'
ERRLS	MVI	A, $08
	JMP	ERROR	; Run 'STRING TOO LONG'
;
; ******************
; * RUN-TIME ERROR *
; ******************
;
ERRRU	CALL	ERRMS	; Print error message
	LDA	RDIPF	; Get RDIPL
	ORA	A
	JNZ	@DA4D	; Jump if running inputs
	CALL	MSGIL	; else: Print 'IN LINE <nr>'
	JMP	START	; Re-enter BASIC
;
; If error in input
;
@DA4D	JMP	INPRS	; (0) Back to restart input
;
; ***********************
; * PRINT ERROR MESSAGE *
; ***********************
;
; Entry: B: Error message number
; Exit:  BC preserved
;        AFDEHL corrupted
;
ERRMS	CALL	COL0	; Cursor to begin (next) line
	MOV	A, B	; Get error nmber
	LXI	H, ERITB	; Base of 1ist error messages
	ADD	A	; Multiply error nr * 2
	MOV	E, A	; and save offset
	MVI	D, $00
	DAD	D	; Calculate table addr
	MOV	E, M	; Get addr of message
	INX	H	; in DE
	MOV	D, M
	XCHG		; and in HL
	CALL	PMSG	; Print error message
	RET
;
; **********************
; * COMPILE-TIME ERROR *
; **********************
;
; Handles errors in direct mode. Only an error message is printed.
; Control is passed back to ELINA (LC93C) except if it is an error during encoding of a
; stored line.
;
; Entry: A: Error number
;        C: Points to 1ast read char acter on input line
; Exit:  To Basic interpreter
;
ERRCO	LDA	ERSFL	; Get ERSFL
	CPI	$01	; Error during encoding?
	JZ	ELARS	; Then handle error
;
; Error in direct command
;
	CALL	ERRMS	; Print error messagee
	CALL	CRLF	; Print car.ret
	JMP	LC823	; Restart intepreter
;
; ******************************************
; PRINT LINE NUMBER IN WHICH ERROR OCCURED *
; ******************************************
;
; Prints car.ret if current line is a direct command else, prints ' IN LINE <linenr>'
; and car. ret.
;
; Entry: None
; Exit:  ABCDEHL preserved
;        F corrupted
;        Z=1: direct command
;
MSGIL	PUSH	H
	PUSH	PSW
	LHLD	CURRNT	; Get start current line
	MOV	A, H
	ORA	L	; Check if 0
	PUSH	PSW
	JZ	@DA8C	; If direct, print car.ret
	CALL_W(PMSGR, MSG02)	; Else, print 'IN LINE'
	MOV	A, M	; Get line nr in HL
	INX	H
	MOV	L, M
	MOV	H, A
	CALL	LEFB4	; (0) Print line number
@DA8C	CALL	CRLF	; Print car. ret
	POP	PSW
	POP	H
	MOV	A, H
	POP	H
	RET
;
; ************************************
; * ERROR MESSAGES INDIRECTION TABLE *
; ************************************
;
; The address points to the location where the string with the error messages can be found.
; Between brackets the error number.
;
; Run-time errors:
;
ERITB
E_NF	.word	ERMNF	; (00) NEXT WITHOUT FOR
E_RG	.word	ERMRG	; (01) RETURN WITHOUT GOSUB
E_OD	.word	ERMOD	; (02) OUT OF DATA
E_OV	.word	ERMOV	; (03) OVERFLOW
E_US	.word	ERMUS	; (04) UNDEFINED LINE NUMBER
E_BS	.word	ERMBS	; (05) SUBSCRIPT ERROR
E_D0	.word	ERMD0	; (06) DIVISION BY ZERO
E_OS	.word	ERMOS	; (07) OUT OF STRING SPACE
E_LS	.word	ERMLS	; (08) STRING TOO LONG
E_RA	.word	ERMNA	; (09) NUMBER OUT OF RANGE
E_IN	.word	ERMIN	; (0A) INVALID NUMBER
E_LO0	.word	ERML0	; (0B) LOADING ERROR 0
E_LO1	.word	ERML1	; (0C) LOADING ERROR 1
E_LO2	.word	ERML2	; (0D) LOADING ERROR 2
E_LO3	.word	ERML3	; (0E) LOADING ERROR 3
E_UA	.word	ERMUA	; (0F) UNDEFINED ARRAY
E_NC	.word	ERMNC	; (10) COLOUR NOT AVAILABLE
E_OF	.word	ERMOF	; (11) OFF SCREEN
E_EL	.word	ERMEL	; (12) ERROR LINE RUN
;
; Compile/Run-time errors
;
E_OM	.word	ERMOM	; (13) OUT OF MEMORY
E_TM	.word	ERMTM	; (14) TYPE MISMATCH
E_LN	.word	ERMLN	; (15) LINE NUMBER OUT OF RANGE
E_SO	.word	ERMSO	; (16) STACK OVERFLOW
;
; Compile-time errors
;
E_SN	.word	ERMSN	; (17) SYNTAX ERROR
E_ID	.word	ERMID	; (18) COMMAND INVALID
E_CN	.word	ERMCN	; (19) CAN'T CONT
E_TC	.word	ERMTC	; (1A) LINE TOO COMPLEX
E_ST	.word	ERMOM	; (1B) OUT OF MEMORY
;
; *******************************
; * WAIT: part of RTALK (0EC6D) *
; *******************************
;
; Entry: HL: Wait time
;
.if ROMVERS == 11
; If wait:
; As old routine, but HL replaced by DE
;
LDACC	DCX	D
	MOV	A, D
	ORA	E
	JNZ	LDACC	; Wait for DE=0
	RET
	.byte	$FF
.endif
.if ROMVERS == 10
LDACC	DCX	H	; Wait time -1
	MOV	A, H
	ORA	L
	JNZ	LDACC	; If not ready
	XCHG		; Parameter pntr in HL
	RET
.endif
;
;
;
;     ==============
; *** PRINT ROUTINES ***
;     ==============
;
;
; *****************
; * PRINT MESSAGE *
; *****************
;
; Prints a message, which may include internal references to other submessages.
;
; Entry: Pointer to message in HL
; Exit:  Pointer after string in HL
;        Other registers preserved
;
; Message format: A series of bytes:
;                 00 End of string.
;                 01-7F Printed character
;                 >= 80 bit 14 set:
;                       bits 0-13 are offset in program of a message (char terminated by a 0).
;                       bit 14 unset:
;                       bits 0-13 are offset in program of a string (1 byte length + char.)
;
PMSG	PUSH	PSW
@DAD5	MOV	A, M	; Get character
	INX	H	; Points to next char.
	ORA	A	; Check char.
	JZ	@DAE4	; If end message
	JM	@DAE6	; If submessage reference
	CALL	OUTC	; Print character in A
	JMP	@DAD5	; Next
@DAE4	POP	PSW	; End message
	RET
;
; Submessage reference
;
@DAE6	CPI	$C0
	PUSH	H
	MOV	L, M	; Lobyte in L
	JC	@DAF6	; If reference to string
	MOV	H, A	; BASE is at location C000
	CALL	PMSG	; Print submessage
@DAF1	POP	H
	INX	H
	JMP	@DAD5	; Next character
;
; String reference:
;
@DAF6	ADI	$40	; (BASE SHR 8)- $80
	MOV	H, A	; Hibyte in H
	CALL	PSTR	; Print substring pntd by HL
	JMP	@DAF1	; Next character
;
;
; ********************************************
; * PRINT MESSAGE POINTED TO BY NEXT 2 BYTES *
; ********************************************
;
; Entry: Top of stack points to the address where the address of the message can be found.
; Exit:  AFBCDEHL preserved
;        Return address on stack
;
PMSGR	XTHL		; Get pntr from stack
	PUSH	D
	MOV	E, M	; Get 1obyte address
	INX	H
	MOV	D, M	; Get hibyte address
	INX	H
	XCHG		; Addr message in HL
	CALL	PMSG	; Print nessage
	XCHG		; HL pnts after message pntr
	POP	D
	XTHL		; Restore stack
	RET
;
; ************************
; * CURSOR TO NEXT FIELD *
; ************************
;
; Part of 'run PRINT' (RPRINT).
; Moves the cursor to a new number output field.
; The field size is 12 character positions field positions: 0, 12, 24, 36, 48
;
PSKP	ROMCALL(5, $0C)	; Ask cursor position and size character screen
	MOV	A, L	; X-coord in L
	CPI	$30	; Already past last field?
	JNC	LDB27	; Then print car.ret, abort
@DB15	SUI	$0C	; Minus 12 untill underf1ow
	JNC	@DB15
LDB1A	CMA		; Restore pos. value
	INR	A
;
; Entry from SPC function
;
LDB1C	MOV	D, A	; Store nr of spaces required
LDB1D	MVI	A, ' '
	CALL	OUTC	; Print space
	DCR	D	; Ready?
	JNZ	LDB1D	; Next space if not
	RET
;
LDB27	JMP	CRLF	; Print car.ret
;
; *********************
; * CURSOR TO TAB (8) *
; *********************
;
; Part of 'List current line' (0ECB3)
; Moves cursor to column 8 after linenumber.
;
; Exit:  BC preserved
;        AFDEHL corrupted
;
SCTAB	.equ	*
TAB	ROMCALL(5, $0C)	; Ask cursor position and size character screen
	MOV	A, L	; X-coord after linenr in A
	SUI	$06	; Tab must be 8
	JMP	LDB1A	; Print additional spaces
;
; ****************
; * PRINT STRING *
; ****************
;
; Prints a string of characters pointed to by HL.
;
; Entry: HL points to string
; Exit:  HL points after string
;        Other registers preserved
;
; String format:
;    1 byte length (0 = no data).
;    N bytes data
;
SCSTR	.equ	*
PSTR	PUSH	PSW
	PUSH	B
	MOV	B, M	; String length in B
LDB35	INX	H
LDB36	MOv	A, B	; Get length
	SUI	$01	; Minus 1
	MOV	B, A	; Nr. char stil1 to be printed
	MOV	A, M	; Get char
	CNC	LD695	; Print charactter if not ready
	JNC	LDB35	; Next one if not ready
	POP	B
	POP	PSW
	RET
;
; ************************
; * PRINT STRING MESSAGE *
; ************************
;
; Prints a string of characters, pointed to by HL 1ength in A.
;
; Entry: HL: Points to string
;        A:  Number of characters
; Exit:  HL: Points after string
;        AFBCDE preserved
;
SCSTM	.equ	*
PSTRM	PUSH	PSW
	PUSH	B
	MOV	B, A	; String length in B
	JMP	LDB36	; Print string
;
; **********************
; * PRINT A HEX NUMBER *
; **********************
;
; Converts MACC to hex in DECBUF and print it.
;
; Exit: HL points after string in DECBUF
;       BCDE preserved
;       AF corrupted
;
PHEX	CALL	XHBC	; Convert MACC for hex output
PGP	LHLD	PDECBUF	; Get addr DECBUF
	JMP	PSTR	; Print string in DECBUF
;
; **************************
; * PRINT A INTEGER NUMBER *
; **************************
;
; Prints an integer number from MACC
;
PINT	CALL	IBCP	; Convert MACC for output
	JMP	PGP	; Print contents DECBUF
;
; *********************************
; * PRINT A FLOATING POINT NUMBER *
; *********************************
;
; Prints a FPT number from MACC.
;
PFPT	CALL	FBCP	; Convert MACC for output
	JMP	PGP	; Print contents DECBUF
;
; ***************************************
; * CONVERT MACC FOR FIXED POINT OUTPUT *
; ***************************************
;
; Places ASCII-eqivalent to DECBUF+1, digits before decimal point in DECBE, length in DECBUF.
;
; Exit: A: Number of digits
;       BCDEHL preserved
;
IBCP	CALL	XIBC	; Convert INT for output
	PUSH	B
	MVI	B, $00	; Can trim last dec. placee
BPP	CALL	XPRTY	; Tidy up into external form
	POP	B
	RET
;
; *********************************
; * (Not used, replaced by FBCP) *
; *********************************
LDB6A	MVI	B, $01	; Part of a previous version
	JMP	$DB64
;
;
;
;
; ********************************
; * STRINGS FOR MACHINE MESSAGES *
; ********************************
;
; The machine messages exist partly from strings, partly from subreferences to other strings.
; The subreferences can be:
;  - An address where another string can be fOund.
;  - An offset with base at $C0000 to the other string.
; The messages are ended with 00.
; 20 is space, $0D is carriage return.
;
RMS01	.equ	*
MSG01	.ascii	"SOME "
	REF_STR($8, SINPUT)	; INPUT
	.ascii	" IGNORED"
	.byte	$00
MSG02	.ascii	" IN "
MLINE	.ascii	"LINE "
	.byte	$00
MSG03	REF_STR($D, MOUTOF)	; OUT OF
	REF_STR($8, MSPACE) ; SPACE
	.ascii	" "
	REF_STR($8, SFOR)	; FOR
	REF_STR($D, LD88D)	; MODE
	.byte	$00
MSG04	.ascii	" RE"
	REF_STR($D, MTYPE)	; TYPE
MLINR	REF_STR($D, MLINE)	; LINE
	.byte	$0D
	.byte	$00
MSG15	.byte	$0D
	.ascii	"SET RECORD,"
MSB05	REF_STR($D, msg06)	; START TAPE
	.ascii	","
	REF_STR($D, MTYPE)	; TYPE
	REF_STR($8, MSPACE)	; SPACE
	.byte	$00
MSG06	.ascii	"START"
	REF_STR($D, MTAPE)	; TAPE
	.byte	$00
MSG07	.byte	$0D
	.ascii	"***"
	REF_STR($D, MBREAK)	; BREAK
	.byte	$0D
	.byte	$00
MSG17	.ascii	" OK"
	.byte	$0D
	.byte	$00
MSG09	.byte	$0D
	REF_STR($D, MBREAK)	; BREAK
	.byte	$00
MSG10	REF_STR($8, SSTOP)	; STOP
	.ascii	"PED"
	.byte	$00
MSG11	REF_STR($8, SEND)	; END
	.ascii	" PROGRAM"
	.byte	$0D
	.byte	$00
MSG14	.ascii	" BAD"
	.byte	$00
MBREAK	.ascii	"BREAK"
	.byte	$00
MWITHO	.ascii	" WITHOUT "
	.byte	$00
MSTRIN	.ascii	"STR"
MING	.ascii	"ING"
	.byte	$00
MTYPE	.ascii	"TYPE "
	.byte	$00
MTAPE	.ascii	" TAPE"
	.byte	$00
MUNDF	.ascii	"UNDEFINED"
	.byte	$00
MOUTOF	.ascii	"OUT OF "
	.byte	$00
MERROR	.ascii	" ERROR"
	.byte	$00
;
; **************************
; * STRINGS ERROR MESSAGES *
; **************************
;
; Comments: See strings machine messages (DB6F)
;
ERMNF	REF_STR($8, SNEXT)	; NEXT
	REF_STR($D, MWITHO)	; WITHOT
	REF_STR($8, SFOR)	; FOR
	.byte	$00
ERMSN	.ascii	"SYNTAX"
	REF_STR($D, MERROR)	; ERROR
	.byte	$00
ERMRG	REF_STR($8, SRET)	; RETURN
	REF_STR($D, MWITHO)	; WITHOUT
	REF_STR($8, SGOSUB)	; GOSUB
	.byte	$00
ERMOD	REF_STR($D, MOUTOF)	; OUT OF
	REF_STR($8, SDATA)	; DATA
	.byte	$00
ERMSO	.ascii	"STACK "
ERMOV	.ascii	"OVERFLOW"
	.byte	$00
ERMOM	REF_STR($D, MOUTOF)	; OUT OF
	.ascii	"MEMORY"
	.byte	$00
ERMUS	REF_STR($D,MUNDF)	; UNDEFINED
	.ascii	" "
MLINN	REF_STR($D, MLINE)	; LINE
MNUMBE	.ascii	"NUMBER"
	.byte	$00
ERMBS	.ascii	"SUBSCRIPT"
	REF_STR($D, MERROR)	; ERROR
	.byte	$00
ERMD0	.ascii	"DIVISION BY ZERO"
	.byte	$00
ERMID	.ascii	"COMMAND "
MINVAL	.ascii	"INVALID "
	.byte	$00
ERMTM	REF_STR($D, MTYPE)	; TYPE
	.ascii	"MISMATCH"
	.byte	$00
ERMOS	REF_STR($D, MOUTOF)	; OUT OF
	REF_STR($D, MSTRIN)	; STRING
	.ascii	" "
	REF_STR($8, MSPACE)	; SPACE
	.byte	$00
ERMLS	REF_STR($D, MSTRIN)	; STRING
	.ascii	" TOO LONG"
	.byte	$00
ERMCN	.ascii	"CAN'T "
	REF_STR($8, SCONT)	; CONT
	.byte	$00
ERMIN	REF_STR($D, MINVAL)	; INVALID
	REF_STR($D, MNUMBE)	; NUMBER
	.byte	$00
ERMOF	.ascii	"OFF SCREEN"
	.byte	$00
ERMNC	.ascii	"COLOR NOT AVAILABLE"
	.byte	$00
ERMLN	REF_STR($D, MLINE)	; LINE
ERMNA	REF_STR($D, MNUMBE)	; NUMBER
	.ascii	" "
MSGOR	REF_STR($D, MOUTOF)	; OUT OF
	.ascii	"RANGE"
	.byte	$00
ERMTC	REF_STR($D, MLINE)	; LINE
	.ascii	"TOO COMPLEX"
	.byte	$00
ERMUA	REF_STR($D, MUNDF)	; UNDEFINED
	.ascii	" ARRAY"
	.byte	$00
ERML0	REF_STR($D, MSGL)	; LOADING ERROR
	.ascii	"0"
	.byte	$00
ERML1	REF_STR($D, MSGL)	; LOADING ERROR
	.ascii	"1"
	.byte	$00
ERML2	REF_STR($D, MSGL)	; LOADING ERROR
	.ascii	"2"
	.byte	$00
ERML3	REF_STR($D, MSGL)	; LOADING ERROR
	.ascii	"3"
	.byte	$00
MSGL	REF_STR($8, SLOAD)	; LOAD
	REF_STR($D, MING)	; ING
	REF_STR($D, MERROR)	; ERROR
	.ascii	" "
	.byte	$00
ERMEL	REF_STR($D, MERROR)	; ERROR
	.ascii	" "
	REF_STR($D, MLINE)	; LINE
	REF_STR($8, SRUN)	; RUN
	.byte 00
;
;
;
; *******************
; * INPUT TEXT LINE *
; *******************
;
; Part of 'restart interpreter' (C853).
; Scans keyboard and reads in a line on the current screen line, up until car.ret.
; First prints car.ret. and a prompt ('*').
; The routine can be aborted on car.ret or Break only.
;
; Entry: A: Contains prompt
; Exit:  CY=1: Break pressed
;        CY=0: HL:  Address 1st character on line
;              C=1: Offset 1st significant character
;        ABDEHL preserved
;
INPL0	PUSH	PSW
	CALL	COL0	; Cursor to column 0
	POP	PSW	;Get prompt
INPLN	STC		; CY=1
	PUSH	PSW
	PUSH	H	; Save cursor coord 1st char
@DD22	CALL	COUTC	; Print prompt
	LXI	H, KNSCAN
	MVI	M, $00	; Enable complete keyb. scan
@DD2A	CALL	GETC	; Get keyb. input
.if ROMVERS == 11
	JC	XCD36	; Jump if break pressed
.endif
.if ROMVERS == 10
	JC	LDD49	; Ignore line if break pressed
.endif
	JZ	@DD2A	; Wait for input
	CPI	' '	; Printable character?
	JNC	@DD22	; Print it and get next one
	CPI	$08	; Backspace
	JZ	@DD22	; Print it get next char
	CPI	$0D	; Car.ret?
	JNZ	@DD2A	; Get next char if not
;
; Exit on car.ret
;
	DCR	M	; Set KBRFL for BREAK only
	MVI	C, $01
EXIT1	POP	H	; Get cursor coord 1st char
	POP	PSW	; Get prompt
	CMC		; CY=0
	RET
;
; Exit on Break
;
LDD49	DCR	M	; Set KBRFL for BREAK on1y
	MVI	A, $21
	CALL	OUTC	; Print '!'
	CALL	CRLF	; Print car.ret
	POP	H
	POP	PSW	; Set prompt, CY=1
	RET
;
; **********************
; * CURSOR TO COLUMN 0 *
; **********************
;
; The X-coordinate of the cursor is checked.
; If not 0, a car.ret is printed.
;
; Entry: None
; Exit:  AF corrupted
;        BCDEHL preserved.
;
COL0	PUSH	D
	PUSH	H
	ROMCALL(5, $0C)	; Get cursor pos (HL) and size char screen (DE)
	MOV	A, L	; X-coord cursor in A
	POP	H
	POP	D
	ORA	A
	RZ		; Abort if cursor in column 0
CRLF	MVI	A, $0D	; Else: print CR
;
; GENERAL OUTPUT ROUTINE:
;
; Outputs a character in a direction depending on OTSW (OTSW).
;
; Entry: A: Character to be transmitted.
; Exit:  AF corrupted
;
SCCHR	.equ	*
OUTC	PUSH	PSW	; Preserve char
	LDA	OTSW
	CPI	$02	; Check output direction
	JNC	LDD70	; If to edit buf/DOUTC
;
; To screen/RS232 - OTSW=0/1
;
	POP	PSW	; Get char
COUTC	ROMCALL(5, $03)	; Character to screen
	CNC	TOUTSE	; Output to RS232 if reqd
	RET
;
; To DOUTC - OTSW = 3
;
LDD70	NOP
	JNZ	LD74C	; Character to DOUTC
;
; To editbuffer - OTSW = 2
;
	POP	PSW	; Get char
OTBIN	PUSH	PSW
	PUSH	H
	PUSH	D
	LHLD	v_EBUFN	; Get edit input pointer
	MOV	M, A	; 3Byte in edit buffer
	INX	H
	SHLD	v_EBUFN	; Update edit input pointer
	XCHG		; in DE
	LHLD	v_EBUFS	; Get end edit buffer
	CALL	COMP	; Calculate free buffer space
	JC	LDD8E	; If edit buffer full
	POP	D
	POP	H
LDD8C	POP	PSW
	RET
;
; If edit buffer full
;
LDD8E	CALL	HRINIT	; Heap back to right size
	JMP	ERROM	; Run error 'OUT OF MEMORY'
;
; *******************
; * OUTPUT TO RS232 *
; *******************
;
; Transmits a character to the RS232 interface via the TICC if the interface is ready for it.
; In case of a car.ret, also a line feed is send.
;
; Entry: A: Character to be transmitted
; Exit:  ABCDEHL preserved
;        F corrupted
OUTSE	PUSH	PSW	; Preserve char
@DD95	LDA	PORI
	ANI	$08	; Check peripheral ready
	JZ	@DD95	; Wait until ready
@DD9D	LDA	TIC_ST
	ANI	$10	; Check TICC buffer enpty
	JZ	@DD9D	; Wait until empty
	POP	PSW
	STA	TIC_SO	; Load serial output buffer
	CPI	$0D	; Carriage return?
	RNZ		; Ready if not
;
; If car.ret
;
	PUSH	PSW
	MVI	A, $0A
	CALL	OUTSE	; Send line feed too
	POP	PSW
	RET
;
; ********************
; * INPUT FROM RS232 *
; ********************
;
; Gets inputs from RS232 via TICC. Only 7-bit Ascii-code is accepted.
;
; Entry: No conditions
; Exit:  A: character received (O if nothing)
;        BCDEHL preserved
;
CINC	.equ	*
INSER	LDA	TIC_ST
	ANI	$08	; Check if something received
	RZ		; Abort if no reception
	LDA	TIC_SI	; Received char in A
	ANI	$7F	; Mask bit 7
	RET
;
; **********************************
; * RS232 FRAME ERROR - (not used) *
; **********************************
;
; Break test for serial input line.
;
BRSER	LDA	TIC_ST
	RAR
	RNC		; Abort if no break
@DDC5	LDA	TIC_ST	; If break: check again
	RAR
	JC	@DDC5	; Wait until end of break
	LDA	TIC_SI	; Load received character
	CMC		; Set CY=1
	RET
;
;
;     =========================
; *** ENCODING SERVICE ROUTINES ***
;     =========================
;
;
; The following routines are used both in 'main' and 'decode' modules.
;
; ************************************************
; * GET CHARACTER FROM LINE, NEGLECT TAB + SPACE *
; ************************************************
;
; Entry: C: Position on currentt line
; Exit:  Character in A; tab and space neglected
;        C: Points to next character
;        BDEHL preserved
;
IGNBR	INR	C	; Pnts to next char
IGNB	CALL	EFETCH	; Get char from line
	CPI	' '	; Space?
	JZ	IGNBR	; Then get next char
	CPI	$09	; Tab? Then get next char
	JZ	IGNBR
	RET
;
; ***************************
; * GET CHARACTER TO ENCODE *
; ***************************
;
; Returns a character from some position on the current line.
; The source is determined by EFSW.
;
; Entry: C: Position on current line (max. 219)
; Exit:  EFSW=0  - Keyboard: Char on line pos in A
;        EFSW>=2 - Edit buf: Char on EFEPT + line pos in A
;        EFSW=1  - String: Idem. If COUNT=line pos then char is car.ret.
;        F corrupted
;        BCDEHL preserved
;
EFETCH	LDA	EFSW
	CPI	$01	; Check input direction
	JC	@DDFF	; If from keyb/RS232
	JNZ	@DDF4	; If from edit buffer
;
; If from string
;
	LDA	EFECT	; If string: Get COUNT
	CMP	C	; COUNT=pos. on curr.line?
	MVI	A, $0D	; Then char is car.ret.
	JZ	@DDFE	; And abort
;
; Entry if from edit buffer
;
@DDF4	PUSH	H
	LHLD	EFEPT	; Get EFEPT
	MOV	A, C
	CALL	DADA	; Add curr.line pos to EFEFT
	MOV	A, M	; Get character
	POP	H
@DDFE	RET
;
; If from screen
;
@DDFF	ROMCALL(5, $15)	; Get character from line
	RET
;
;
;     ================================
; *** SINGLE AND DOUBLE BYTE UTILITIES ***
;     ================================
;
;
; *********************************
; * CHECK IF UPPER CASE CHARACTER *
; ********** **********************
;
; Entry: A: Character to be checked
; Exit:  CY=0: Not upper case
;        CY=1: Upper case.
;        ABCDEHL preserved
;       F corrupted
ALPHA	CPI	$41	; Lowest upper case char
	CMC
	RNC
	CPI	$5B	; First 1ower case char
	RET
;
; **********************************************
; * CHECK IF CHARACTER IS NUMBER OR UPPER CASE *
; **********************************************
;
; Entry: A: Character to be checked
; Exit:  CY=0: Not number, not upper case
;        CY=1: Number or upper case.
;        ABCDEHL preserved
;        F corrupted
;
ALNUM	CALL	ALPHA	; Check if upper casee
	RC
NUMBER	CPI	'0'	; Lowest number
	CMC
	RNC
	CPI	'9'+1	; No number anymore
	RET
;
; *********************
; * COMPARE HL AND DE *
; *********************
;
; Compares HL with DE (HL-DE)
;
; Exit:  DE=HL: Z=1, CY=0
;        DE<HL: Z=0, CY=0
;        DE>HL: Z=0, CY=1
;        BCDEHL preserved
;        AF corrupted
;
COMP	MOV	A, H
	CMP	D
	RNZ
	MOV	A, L
	CMP	E
	RET
; *****************************
; * CALCULATE LENGTH OF BLDCK *
; *****************************
;
; Sets HL=HL-DE.
;
; Entry: Start address in DE, 1st address after block in HL
; Exit:  Length in HL, Start address in DE
;        If DE>HL, length in 2-complement
;        ABCDE preserved
;        F as in COMP
;
SUBDE	PUSH	B
	PUSH	PSW
	MOV	A, L
	SUB	E	; Calc. difference 1owest byte
	MOV	L, A
	MOV	A, H
	SBB	D	; Calc. diff. highest byte
	MOV	H, A
	POP	B
	MOV	A, B
	POP	B
	RET
;
; ******************************
; * DOUBLE BYTE TWO COMPLEMENT *
; ******************************
;
; Sets HL = -HL.
;
; Entry: Double byte to be converted in HL
; Exit:  Two complement in HL
;        ABCDEF preserved
;
CMPHL	PUSH	PSW
	MOV	A, H
	CMA		; Complement H
	MOV	H, A
	MOV	A, L
	CMA		; Complement L
	MOV	L, A
	INX	H	; Add 1
	POP	PSW
	RET
;
; **************************
; * ADD OFF-SET TO ADDRESS *
; **************************
;
; Adds a given offset to a base address (HL = HL + A).
;
; Entry: Base in HL, offset in A
; Exit:  HL=HL+A
;        ABCDE preserved
;        F corrupted
DADA	PUSH	PSW
	ADD	L
	MOV	L, A	; L = L + A
	MOV	A, H
	ACI	$00	; Add carry if overflow
	MOV	H, A
	POP	PSW
	RET
;
; **********************************
; * CALCULATE ADDRESS AFTER STRING *
; **********************************
;
; Sets HL = HL + M + 1.
;
; Entry: HL points to 1st byte of string (length byte)
; Exit:  HL points to first byte after string
;        AFBCDE preserved
;
DADM	PUSH	PSW
	MOV	A, M	; Get length of string
	INX	H	; HL: addr. 1st char. byte
	CALL	DADA	; Calc addr after string
	POP	PSW
	RET
;
; *****************
; * DELAY ROUTINE *
; ***** ***********
;
; RunS a fixed delay 1oop of 665 msec. If interrupts are enabled, the delay will be
; approx 730 msec.
; HL is 1oaded with FFFF and then decremented.
;
; Exit:  ABCDEHL preserved
;        F corrupted
;
DELAY	PUSH	H
	PUSH	D
	LXI	H, $FFFF	; Init. delay value
	MOV	D, H
	MOV	E, L
@DE48	DAD	D
	JC	@DE48	; Repeat if not ready
	POP	D
	POP	H
	RET
;
; ***********************
; * DATA BLOCK TRANSFER *
; ***********************
;
; Moves a block of data starting at (DE) and ending at (HL)-1 to (BC).
;
; Entry: DE: start addr. source bank
;        BC: start addr. destination bank
;        HL: Points after end source bank
; Exit:  AF preserved
;        BCDEHL corrupted
;
MOVE	PUSH	PSW
	PUSH	H
	CALL	SUBDE	; Calc. length source bank
	MOV	A, C
	SUB	E
	MOV	A, B
	SBB	D
	JC	@DE6C	; If destination addr. is lower than source addr
;
;  Destination address > source address
;
	MOV	D, H
	MOV	E, L	; Save 1ength in DE
	DAD	B	; Highest dest.addr. in HL
	POP	B
@DE5F	MOV	A, D	; Check 1f ready
	ORA	E
	JZ	@DE7A	; Then abort
	DCX	D
	DCX	H
	DCX	B
	LDAX	B	; Get byte to be transferred
	MOV	M, A	; Transter it
	JMP	@DE5F	; Next one
;
; Destination address < source address
;
@DE6C	MOV	A, H
	ORA	L
	JZ	@DE79	; Abort if ready
	DCX	H
	LDAX	D	; Get byte to be transferred
	STAX	B	; Transfer it
	INX	D
	INX	B
	JMP	@DE6C	; Next byte
;
; If ready
;
@DE79	POP	H
@DE7A	POP	PSW
	RET
;
; *********************************
; * FILL BANK WITH IDENT1CAL DATA *
; *********************************
;
; Fills an area of memory with a constant.
;
; Entry: DE: Start addr. of bank
;        HL: Points after bank
;        A:  Data to be loaded into bank
; Exit:  DE: Points after bank
;        BCHL preserved
;        AF corrupted
;
FILL	PUSH	B
	MOV	B, A	; Save data in B
@DE7E	CALL	COMP	; Check if bank full
	JZ	@DE8D	; Abort if ready
	JC	@DE8D	; Abort if DE>HL
	MOV	A, B	; Get data
	STAX	D	; and store it
	INX	D
	JMP	@DE7E	; Next addr
@DE8D	POP	B
	RET
;
; ********************
; * MULTIPLY HL BY A *
; ********************
;
; Multiplies a 16-bit value by a 8-bit value.
;
; Entry: HL: 16-bit value
;        A:  8-bit value.
; Exut:  CY=0: Result in HL
;        CY=1: Overflow
;        ABCDE preserved
;
HLMUL	STC
	PUSH	PSW
	PUSH	D
	XCHG
	LXI	H, $0000	; Init. result
@DE96	ORA	A
	RAR		; Next bit of multiplier
	JNC	@DE9F	; Jump if bit is 0
	DAD	D	; Add 1 * HL if bit is 1
	JC	@DEAD	; Abort if overflow
@DE9F	ORA	A
	JZ	@DEB1	; Abort if ready
	XCHG
	DAD	H	; Multiply * 2
	XCHG
	JNC	@DE96	; Again if no overflow
.if ROMVERS == 10
	NOP
	NOP
	NOP
	NOP
	NOP
.endif
@DEAD	POP	D
	POP	PSW	; Error exit if overflow
	RET
@DEB1	POP	D
	POP	PSW
	CMC		; No error exit
	RET
;
;
;
;     =================================
; *** BASIC EXECUTION / RUN-TIME MODULE ***
;     =================================
;
; Generally, BC is used as entry pointer to the textbuffer.
;
; ********************
; * RUN basiccmd NEW *
; ********************
;
; Sets up heap, empty textbuffer and symboltable, sets pointers of textbuffer and
; symboltable correctly. O1d buffer contents is not destroyed (except 4 1ocations),
; but not useable.
; Valid as direct command only.
;
; Exit: A=1, CY=1
;
.if ROMVERS == 11
; An additiornal entry is made for run NEW with returning the heapsize to its default value.
; In BASIC V1.O, this entry was available on $CEC6.
;  All jumps/calls to RNEW with other heapsizes are updated
XDEB0	LXI	H, $0100
	SHLD	HSIZE	; Set heap to default size
	NOP
	NOP		; Into RNEW
.endif
RNEW	.equ	*
.if ROMVERS == 10
	NOP
	NOP
	NOP
.endif
	LHLD	HEAP	; Get start addr heap
	SHLD	TXTBGN	; Set start textbuf=start heap
	MVI	M, $00	; Store 00 in 1st addr.
	INX	H
	SHLD	STBBGN	; Set start symtab
	MVI	M, $00	; 00 in 1st addr.
	INX	H
	SHLD	STBUSE	; Set end symtab
;
; Entry from scratch/edit
;
HRINIT	LHLD	HSIZE	; Get heap size
	XCHG		; in DE
	CALL	HINIT	; Init heap to all available
	MVI	A, $01	; Code for 'buffer crunched'
	STC
	RET
;
; *********************
; * RUN basiccmd CONT *
; *********************
;
; Resets step flag, decr. CONFL (error if it was 0), restores FRAME from stack, restores
; stack pointer and continues program execution.
; Valid as direct command only.
;
RCONT	XRA	A
LDED6	STA	STEPF	; Reset step f1ag
	LXI	H, CONFL	; Set pntr suspended program
	DCR	M	; Update it
	MVI	A, $19
	JM	ERROR	; Evt. run error 'CAN'T CONT'
	LHLD	v_STACK	; Get current base stack level
	XCHG		; in DE
	LXI	H, $0015	; FRAME length
	DAD	D	; Top of FRAME in stack
	PUSH	H	; Save it
	LXI	B, SYSBOT	; Addr SYSBOT
	CALL	MOVE	; Load FRAME from stack
	POP	H	; Get addr FRAME top in stack
	SHLD	v_STACK	; Update current base stack 1evel
	SPHL		; Update stackpointer
	LHLD	BRKPT	; Get start current command
	MOV	B, H
	MOV	C, L	; Store it in BC
	JMP	LC87F	; Run BASIC line
;
; *********************
; * RUN basiccmd STEP *
; *********************
;
RSTEP	MVI	A, $FF	; Init valUe STEP flag
	JMP	LDED6	; Set STEP F1ag and continue
;
; *********************
; * RUN basiccmd STOP *
; *********************
;
; Entry: No conditions
; Exit:  A=03, CY=1. HL points after string.
;
RSTOP	.equ	*
.if ROMVERS == 11
	CALL_W(XD7E6, MSG10)
.endif
.if ROMVERS == 10
	CALL_W(PMSGR, MSG10)	; Print 'STOPPED'
.endif
	MVI	A, $03	; Code for 'susp. execution'
	STC
	RET
;
; ********************
; * RUN basiccmd END *
; ********************
;
; Entry:  No conditions
; Exit:   A=1, CY=1
;         HL points after string
;
REND	.equ	*
.if ROMVERS == 11
	CALL_W(XD7E6, MSG11)
.endif
.if ROMVERS == 10
	CALL_W(PMSGR, MSG11)	; Print 'END PROGRAM'
.endif
	MVI	A, $01	; Code for 'stop execution'
	STC
	RET
;
; *******************
; * RUN basiccmd IF *
; *******************
;
; Used for IF .. GOTO <linenr> and for IF .. THEN <linenr>.
;
RIFG	.equ	*
RIFTL	CALL	REXPL	; (0) Run 1ogical expression
	INR	A
	JZ	RGOTO	; Run GOTO if condition true
;
; If condition false
;
	INX	B
	INX	B	; Skip linenr
	ORA	A	; No special action
	RET
;
; ***************************************
; * RUN basiccmd IF .. THEN <statement> *
; ***************************************
;
RIFTC	CALL	REXPL	; (0) Run 1ogical expression
	INR	A
	JNZ	RREM	; (0) Ignore rest if false
;
; If condition true
;
	INX	B	; Skip length line
	ORA	A	; No special action
	RET		; Execute rest of line
;
; ******************
; * basiccmd GOSUB *
; ******************
;
; Saves current program state on the interpreter stack and branches to a named line.
; The running FOR loop (if any) is saved in order to avoid problens if any unpaired NEXT
; is encountered.
; The stackpointer at the subroutine-entry is held to enable breaking out of a FOR-NEXT 1oop.
;
RGOSUB	CALL	RLNFI	; (0) Get linenr and find it
;
; Entry from ON .. GOSUB
;
LDF2D	POP	D	; Kill return addr
	SHLD	GSNWK	; Save new PC
	CALL	PUSHF	; (0) Save FOR 1oop contents
	PUSH	B	; Save program position
	LHLD	GSNWK	; Get new PC
	MOV	B, H	; Is new text position
	MOV	C, L
	LHLD	STKGOS	; Get stack 1evel last GOSUB
	PUSH	H	; Save evt link to previous subroutine entry
	LXI	H, $0000
	SHLD	LOPVAR	; No running loop
	DAD	SP	; SP in HL
	SHLD	STKGOS	; SP in STKGOS for return
;
; Entry on return
;
LDF48	ORA	A	; No special action
	JMP	ENDCOM	; Into Basic monitor
;
; ***********************
; * RUN basiccmd RETURN *
; ***********************
;
; Reverses the effect of a previous 'GOSUB'.
;
RRET	POP	D	; Kill returnaddr
	LHLD	STKGOS	; Set stack level last GOSUB
	MOV	A, H
	ORA	L	; 0 if no active cal1
	MVI	A, $01
	JZ	ERROR	; Then run error 'RETURN WITHOUT GOSUB'
	SPHL		; Else re-instate old stack
	POP	H
	SHLD	STKGOS	; Link back to previouus GOSUB
	POP	B	;  Restore text pntr
	CALL	POPF	; (0) Pop FRAME
	JMP	LDF48	; Back to Basic monítor
;
; *********************
; * RUN basiccmd GOTO *
; *********************
;
; Simply transfers control to a named line.
;
; Entry from IF .. GOTO
;
RGOTO	CALL	RLNFI	; (0) Get linenr and find it
;
; Entry from ON .. GOTO
;
LDF66	MOV	B, H	; Set textpointer to line
	MOV	C, L
	ORA	A	; No special action
	RET
;
; ***************************
; * RUN basiccmd ON .. GOTO *
; ***************************
;
RONGT	CALL	RONFN	; Process command
	JC	LDF66	; Use GOTO if OK
	RET		; If outside list
;
; ****************************
; * RUN basiccmd ON .. GOSUB *
; ****************************
;
RONGS	CALL	RONFN	; Process command
	JC	LDF2D	; Use GOSUB if OK
	RET		; If outside list
;
; ***********************
; * COMMON 'ON ..' CODE *
; ***********************
;
; Exit:  CY=1: OK
;        CY=0: Outside 1ist.
;
RONFN	CALL	REXI1	; (0) Get index of number
	MOV	E, A	; in 1ist in E
	LDAX	B	; Get nr of linenrs in 1ist
	INX	B
	MOV	L, A
	MVI	H, $00
	DAD	H
	DAD	B	; Pointer after 1ist
	PUSH	H	; Save pointer
	DCR	E
	INR	E
	JZ	@DF9B	; Index of 0: outside list
	CMP	E
	JC	@DF9B	; If index too 1arge
	MVI	D, $00
	DCX	D
	XCHG
	DAD	H
	DAD	B	; Pntr to reqd linenr
	MOV	B, H	; in BC
	MOV	C, L
	CALL	RLNFI	; (0) Find reqd line
	POP	B
	STC		; CY=1: OK
	RET
;
; If outside 1ist
;
@DF9B	POP	B
	ORA	A	; CY=0: outside 1ist
	RET
;
; ********************
; * RUN basiccmd RUN *
; ********************
;
; No linenumber is given.
;
.if ROMVERS == 11
;
; The Sequence of the instructions is modified.
; This enables RUN <linenr> to be used without destroying the contents of heap and symtab.
;
RRUN	CALL	SCRATC	; Empty heap and symtab
	LHLD	TXTBGN	; Get start textbuf
LDFA4	MOV	B, H	; in BC
	MOV	C, L
	CALL	RREST	; Run RESTORE
	LXI	H, $0000
	SHLD	STRFL	; Reset step/trace flag
	XRA	A
	STA	CONFL	; No suspended p.endif program
 	LXI	SP, STKEND	; Reset SP
.endif
.if ROMVERS == 10
RRUN	LXI	H, $0000
	SHLD	STRFL	; Reset trace/step flag
	LHLD	TXTBGN	; Get start textbuf
LDFA7	MOV	B, H
	MOV	C, L	; Store it in BC
	CALL	RREST	; (0) Run RESTORE; Set data pntr to start program
	LXI	SP, STKEND	; Reset stackpointer
	XRA	A
	STA	CONFL	; No suspended program
	CALL	SCRATC	; Empty HEAP + symtab
.endif
	ORA	A	; No special action
	JMP	ENDCOM	; Run program
;
; *****************************
; * RUN basiccmd RUN <linenr> *
; *****************************
;
; After RUN, a line number is given.
;
RRUNN	CALL	RLNFI	; (0) Read linenr and find it in textbufF
.if ROMVERS == 11
	JMP	LDFA4	; Process RUN
.endif
.if ROMVERS == 10
	JMP	LDFA7	; Process RUN
.endif
;
; *********************
; * RUN basiccmd POKE *
; *********************
;
RPOKE	CALL	REXI2	; (0) Get addr in HL
;
; Entry for other modules
;
RPEN	CALL	REXI1	; (0) Get argument in A
	MOV	M, A	; Store it
	ORA	A	; No special action
	RET
;
; ********************
; * RUN basiccmd OUT *
; ********************
;
ROUT	CALL	REXI1	; (0) Get portnr in A
	MOV	D, A	; and in D
	CALL	REXI1	; (0) Get data in A
	MOV	E, A	; and in E
	ORA	A
	JMP	RWOP	; Output to DCE-bus
;
; *********************
; * RUN basiccmd WAIT *
; *********************
;
; WAIT I, J, K reads the status of Real World port I, EXOR's it with K and AND's it
; with J until a result equal to J is obtained.
;
RWAIT	CALL	REXI1	; (0) Get portnr
	MOV	D, A	; in D
	CALL	REXI1	; (0) Get bits needed high
	MOV	H, A	; in H
	LDAX	B	; Get next byte from text
	INX	B
	SUI	$FF	; Check if ony 2 arguments
	NOP
	CNZ	LCEDA	; If 3 arg: Get XOR mask
	MOV	L, A	; in L
@DFE6	CALL	RWIP	; Input fron DCE-bus
	MOV	A, E	; into A
	XRA	L	; XOR with mask
	ANA	H	; AND with bits needed high
	CMP	H	; Correct value reached?
	RZ		; Then abort
	CALL	ASKKEY	; Check keyb for new inputs
	JNC	@DFE6	; Next DCE-input if no Break
;
; If suspended:
;
	JMP	LE012	; (0) Quit: 'cmd broken in'
;
; *************************
; * RUN basiccmd WAIT MEM *
; *************************
;
; As WAIT, but with I is a memory 1ocation.
;
RWTEM	CALL	REXI2	; (0) Get memory addr in HL
	CALL	REXI1	; (0) Get bit mask
	MOV	D, A	; in D
	LDAX	B	; Get next byte from text
	INX	B
;
end_rom	.equ	*
; ROM Bank 0 - 4KB starting $E000
.bank 0, 4, $E000
.segment "ROM0", 0
.org	$E000
;
bgn_rom0	.equ	*
;
	SUI	$FF	; Check if only 2 arguments
	NOP
	CNZ	LCEDA	; If 3 arg: Get XOR mask
	MOV	E, A	; in E
@E007	MOV	A, E	; XOR mask in A
	XRA	M	; XOR with memory
	ANA	D	; AND with bit mask
	CMP	D	; Correct value reached?
	RZ		; Then abort
	CALL	ASKKEY	; Check keyb for inpts
	JNC	@E007	; Cont if no Break pressed
;
; If suspended
;
LE012	MVI	A, $02	; Code 'command broken in'
	STC
	RET
;
;
;
; **************************
; * RUN basiccmd WAIT TIME *
; **************************
;
; Timer TIMER is decremented by clock interrupt RST7.
;
RWTET	CALL	REXI2	; Get time to wait
	SHLD	TIMER	; Load timer
@E01C	LHLD	TIMER	; Get timer
	MOV	A, H
	ORA	L
	RZ		; Abort if (timer)=0
	CALL	ASKKEY	; Check keyb for new inputs
	JNC	@E01C	; Again if no break pressed
;
; If suspended
;
	JMP	LE012	; Abort, 'command broken in'
;
; ***************************************
; * RUN basiccmd FOR .. TO .. (STEP ..) *
; ***************************************
;
RFOR	POP	D	; Kil1 return addr
	CALL	PUSHF	; Save old FRAME on stack
	CALL	RLETI	; Init variable
	SHLD	LOPVAR	; Remember 1ocation variable
	ANI	$30
	SUI	$10	; Set flags for var. type
	CALL	REXNA	; Eval TO expr, result in MACC
	JZ	LE0A2	; If INT variable
;
; If FPT variable
;
	ROMCALL(4, $03)	; Subtract 'FROM'
	LXI	H, LSTPF	; Get addr. LSTPF
	MVI	M, $00	; Default STEP implicit
	LDAX	B	; Get evt. STEP val. from text
	INX	B
	CPI	$FF
	JZ	@E05F	; Jump if no STEP
;
; If STEP
;
	CALL	XPLISH	; Save 'to-from' on stack
	INR	M	; Stepflag explicit
	DCX	B
	CALL	REXNA	; Stepvalue in MACC
	LXI	H, LSTEP	; Addr. LSTEP
	ROMCALL(4, $0F)	; Stepvalue in LSTEP
	CALL	XPOF	; 'to-from' range in MACC
	ROMCALL(4, $09)	; Find nr of iterations
@E05F	ROMCALL(4, $48)	; Make it INT
LE061	LXI	H, LCOUNT	; Addr. LCOUNT
	ROMCALL(4, $0F)	; Iterations in LCOUNT
	MOV	A, M
	ORA	A
	CM	ZFPINT	; Clear LCOUNT if 1oop in wrong direction
	MOV	H, B	; Current pos in start of loop in HL
	MOV	L, C
	SHLD	LOPPT	; Set pointer to start loop
;
; Now delete any previous use of the loop
;
	LXI	B, $0010	; Size of 1 'FOR' stackframe
	LHLD	LOPVAR	; Get current 1oop variablLe
	XCHG		; in DE
	LXI	H, $0000	;
	DAD	SP	; Stack start
	JMP	@E07F	; Into loop
;
; Loop
;
@E07E	DAD	B	; Up 1 frame
@E07F	MOV	A, M
	INX	H
	ORA	M
	JZ	@E09F	; Jump if top of stack
	MOV	A, M
	DCX	H
	CMP	D	; Comp top byte variable addr
	JNZ	@E07E	; Again if not the same
	MOV	A, M
	SUB	E
	JNZ	@E07E	; Cont if bottom byte different
	PUSH	H	; Frame bottom to be removed
	LXI	H, $0002
	DAD	SP	; Update stackpointer
	MOV	D, H	; DE is bottom of area to be moved
	MOV	E, L
	DAD	B	; Add 1 frame
	MOV	B, H	; Place to move area to
	MOV	C, L
	POP	H	; Top area to move
	CALL	MOVE	; Remove old frame
	SPHL		; New stack position
@E09F	JMP	LE114	; Use common mode to reinstate textpointer
;
; If INT variable
;
LE0A2	ROMCALL(4, $51)	; Subtract 'from'
	LXI	H, LSTPF	; Get addr. LSTPF
	MVI	M, $80	; Default step implicit
	LDAX	B	; Get evt STEP value
	INX	B
	CPI	$FF
	JZ	LE061	; If no step given
;
; If STEP
;
	CALL	XPLISH	; Save 'to-from' on stack
	INR	M	; Stepflag explicit
	DCX	B
	CALL	REXNA	; Get stepvalue in MACC
	LXI	H, LSTEP	; Addr. stepvalue if explicit
	ROMCALL(4, $0F)	; Stepvalue in LSTEP
	CALL	XPOF	; 'to-from' range in MACC
	ROMCALL(4, $57)	; Find nr of iterations
	JMP	LE061	; Handle loop
;
; **************************************
; * RUN basiccmd NEXT <named variable> *
; **************************************
;
RNEXI	POP	D	; Return addr
	CALL	RVAR	; Get varptr in HL
@E0C9	XCHG
	LHLD	LOPVAR	; Get current loop variable
	MOV	A, L
	ORA	H	; Loop variable 0?
	JZ	ERRNF	; Then run error 'NEXT WITHOUT FOR'
	CALL	COMP	; Compare loop and named variable pntrs
	JZ	LE0EE	; Perform NEXT if identical
	XCHG
	SHLD	GSNWK	; Store in scratch area
	CALL	POPF	; Re-instate next loopvariable
	LHLD	GSNWK	; Get it back
	JMP	@E0C9	; Try for a match
;
; *********************
; * RUN basiccmd NEXT *
; *********************
;
; No variable name is given.
;
RNEXT	POP	D	; Return addr
	LHLD	LOPVAR	; Get current 1oop variable
	MOV	A, L
	ORA	H	; Loopvar is 0?
	JZ	ERRNF	; Then run error 'NEXT WITHOUT FOR'
LE0EE	LDA	LSTPF	; Get LSTPF
	ORA	A
	JM	LE133a	; Jump if INT loop variable
;
; If FPT 1oop variable
;
	RAR
	JC	LE11D	; Jump if explicit step
	CALL	XEINM	; Incr. variable in memory
LE0FC	LXI	H, LCOUNT+3	; Addr 1obyte LCOUNT
@E0FF	MOV	A, M	; Get 1obyte
	SUI	$01
	MOV	M, A	; Decr it
	JNC	LE114	; Continue if no overflow
	DCX	H	; Pnts to next byte LCOUNT
	MOV	A, L
	CPI	$0A	; Hibyte done?
	JNZ	@E0FF	; More bytes if not
;
; Loop finished
;
	CALL	POPF	; Pop frame
	ORA	A	; No special action
	JMP	ENDCOM	; Exit to Basic monitor
;
; More time round (entry from 'FOR')
;
LE114	LHLD	LOPPT	; Get pntr to start 1oop
	MOV	B, H	; in BC
	MOV	C, L
	ORA	A	; No special action
	JMP	ENDCOM	; Exit to Basic monitor
;
; Explicit step
;
LE11D	ROMCALL(4, $0C)	; Get value 1oopvar in MACC
	PUSH	H
	LXI	H, LSTEP	; Addr. LSTEP
	JNC	@E128	; If INT
	ROMCALL(4, $00)	; FPT: add stepval ue
@E128	JC	@E12D	; If FPT
	ROMCALL(4, $4E)	; INT: add stepvalue
@E12D	POP	H
	ROMCALL(4, $0F)	; Store new value in variable
	JMP	LE0FC	; Test end of. loop
;
; If INT 1oopvariables
;
LE133a	JPE	LE11D	; Jump if explicit step
	CALL	XIINM	; Incr. variable in memory
	JMP	LE0FC	; Test end of loop
;
; **************
; * PUSH FRAME *
; **************
;
; Several pointers are save on stack during execution of FOR-NEXT 1oops.
;
PUSHF	POP	D	; Get addr. where to continue
	LHLD	LOPVAR	; Get current loop variable
	MOV	A, H
	ORA	L	; Check if 0
	JZ	@E164	; Then abort routine
	LHLD	LOPPT
	PUSH	H	; Save pntr to start 1oop
	LHLD	LOPLN
	PUSH	H	; Save pntr to start 1oop line
	LHLD	LCOUNT
	PUSH	H	; Save 1oop iteration count
	LHLD	LCOUNT+2	; (4 bytes)
	PUSH	H
	LHLD	LSTEP
	PUSH	H	; Save step value
	LHLD	LSTEP+2	; (4 bytes)
	PUSH	H
	LDA	LSTPF
	PUSH	PSW	; Save LSTPF
	LHLD	LOPVAR
@E164	PUSH	H	; Save current 1oop variable
	XCHG		; Addr. to continue in HL
	PCHL		; Set program counter
;
; *************
; * POP FRAME *
; *************
;
; Restores 1oop pointers in RAM.
;
POPF	POP	D
	POP	H
	SHLD	LOPVAR	; Restore LOPVAR
	MOV	A, H
	ORA	L	; LOPVAR=0?
	JZ	@E18D	; Then abort routine
	POP	PSW
	STA	LSTPF	; Restore LSTPF
	POP	H
	SHLD	LSTEP+2	; Restore LSTEP
	POP	H	; (4 bytes)
	SHLD	LSTEP
	POP	H
	SHLD	LCOUNT+2	; Restore LCOUNT
	POP	H	; (4 bytes)
	SHLD	LCOUNT
	POP	H
	SHLD	LOPLN	; Restore LOPLN
	POP	H
	SHLD	LOPPT	; Restore LOPPT
@E18D	PUSH	D
	RET
;
; **********************************
; * RUN basiccmds DATA - REM - IMP *
; **********************************
;
; RREM/RDATA:
;    Entry: B: Points to length byte of string
;    Exit:  DEHL preserved
;           AF corrupted
; RIMP:
;    No action
;
RREM	.equ	*
RDATA	LDAX	B	; Get 1ength of string
;
; Entry for REXPS
;
LE190	INX	B	; BC points to 1st char
	ADD	C
	MOV	C, A	; BC points to end of string
	RNC
	INR	B	; If overflow correct B
;
; Entry for RUN IMP
;
RIMP	ORA	A	; No special action
	RET
;
; *********************
; * RUN basiccmd LIST *
; *********************
;
; The whole textbuffer contents is listed.
;
RLIST	.equ	*
RLIS0	MVI	A, $FF	; Init. mode 0
	ROMCALL(5, $18)	; Change mode
	MVI	A, $0C
	ROMCALL(5, $03)	; Clear screen
LE19F	LHLD	TXTBGN	; Get startaddr. tex tbuf
	XCHG		; in DE
	LHLD	STBBGN	; Get start symtab
	DCX	H	; End textbuf in HL
	JMP	LE1CF	; Perform listing
;
; ********************************
; * RUN basiccmd LIST linenumber *
; ********************************
;
; Entry: BC points to linenumber.
; Exit:  BC updated
;        AFDEHL corrupted
;
RLIS1	CALL	RLNF	; Read linenr and find it in textbuf
	NOP
	MOV	D, H	; Linenr in DE
	MOV	E, L
	CC	DADM	; If linenr found: calc addr after string in HL
	JMP	LE1CF	; Perform listing
;
; *****************************
; * RUN basiccmd LIST <range> *
; *****************************
;
; Entry: BC points to 1st linenumber
; Exit:  BC updated
;        AFDEHL corrupted
;
RLIS2	LHLD	TXTBGN	; Get start textbuf
	CALL	RLN	; Read 1st linenr
	CNZ	FINDL	; If given: Find it in textbuf
	XCHG		; Addr in DE
	LHLD	STBBGN	; Get start symtab
	DCX	H	; End textbuf in HL
	CALL	RLN	; Read 1st linenr
	STC
	CMC
	CNZ	FINDL	; If 1st nr found: fi nd 2nd
	CC	DADM	; If found: Calc addr after string in HL
;
; Perform listing
;
LE1CF	PUSH	B
	MOV	B, D	; Start listed area in BC
	MOV	C, E
	SHLD	LISW2	; Store end 1isted area
	XCHG		; also in DE
	SHLD	LISW1	; Store start 1isted area
@E1D9	MOV	H, B	; Start addr in HL
	MOV	L, C
	CALL	COMP	; Check if all lines 1isted
	JZ	@E1F2	; Abort if ready
	CALL	LD873	; List curent line if linenr correct
	CALL	FGETC	; Scan keyboard
	JC	@E1F2	; Break pressed: stop 1isting
	NOP
	NOP
	CNZ	WSPACE	; If a key is pressed: Wait for spacebar
	JNC	@E1D9	; No break: list further
;
; If ready:
;
@E1F2	ORA	A	; No special action
	POP	B
	RET
;
;
;
; *********************
; * RUN basiccmd EDIT *
; *********************
;
; The editbuffer is set up by moving the program to the end of the free RAM space.
; All memory between heapstart and textbegin is used as editbuffer.
; On break + space: The edited area is deleted from the textbutter and the program is
; moved to just after the end of the edited text by changing the heapsize.
; EFSW is set for input from editbuffer.
;
REDIT	CALL	REDIN	; Init. edit buffer
	CALL	LE19F	; List into edit buffer
LE1FB	XRA	A
	STA	OTSW	; Set output to screen
	STA	KNSCAN	; Enable complete keyb.scan
	CALL	OTBIN	; 0 on end of buffer
	LXI	H, $0000
	SHLD	v_TABTP	; Clear tab table pntr
	ROMCALL(5, $2A)	; Init Screen editor
@E20D	CALL	GETC	; Get char from keyboard
	JC	@E21B	; If break pressed
	JZ	@E20D	; Wait for inputs
	ROMCALL(5, $2D)	; Obey character
	JMP	@E20D	; Get next input
;
; If Break pressed
;
@E21B	MVI	A, $0C
	ROMCALL(5, $03)	; Clear Screen
@E21F	CALL	GETC	; Get char fram keyboard
	JC	LE24D	; If again Break
;
; Break followed by any character
;
	JZ	@E21F	; Wait for a char typed in
	MVI	A, $02
	STA	EFSW	; EFSW: input from buffer
	LHLD	LISW2	; Get end 1isted area
	XCHG		; in DE
	LHLD	LISW1	; Get start 1isted area
	CALL	SUBDE	; Calc. 1ength 1isted area
	NOP
	CALL	PROGM	; Delete edited area in txtbuf
	LHLD	HEAP	; Get start HEAP
	XCHG		; in DE
	LHLD	v_EBUFN	; Get input pntr editbuf
	CALL	SUBDE	; Calc 1ength used edit area
	INX	H
	INX	H
	XCHG		; DE: length edit area +2
	CALL	HINIT	; Program to end of editbuf
	ORA	A	; No special conditions
	RET
;
; Break followed by 2nd break
;
LE24D	CALL	HRINIT	; Restore original Heap + program buffers
	ORA	A	; No special conditions
	RET
	NOP
;
; ******************************
; * RUN basiccmd EDIT <linenr> *
; ******************************
;
REDI1	CALL	REDIN	; Init edit buffer
	CALL	RLIS1	; List one line
	JMP	LE1FB	; Into Run edit
;
; *****************************
; * RUN basiccmd EDIT <range> *
; *****************************
;
REDI2	CALL	REDIN	; Init edit buffer
	CALL	RLIS2	; List part of program
	JMP	LE1FB	; Into Run edit
;
; ****************************
; * INITIALISE SCREEN EDITOR *
; ****************************
;
; Sets up a mode 0 screen, clears all variables and arrays. Moves Basic program to top of
; free memory, initialises edit pointers.
;
; Exit: BC preserved
;       AFDEHL corrupted
;
REDIN	MVI	A, $FF
	ROMCALL(5, $18)	; Change screen to mode
	CALL	LD86D	; Run 'OUT OF MEMORY' error if insufficient space. Else empty HEAP + variables
	CALL	SIZE	; Calc free RAM space
	XCHG		; in DE
	LHLD	HSIZE	; Get HEAP size
	DAD	D
	XCHG		; Total 'free' RAM in DE
	CALL	HINIT	; Program to end free RAM
	LHLD	TXTBGN	; Get startaddr. textbuf
	DCX	H	; Minus 2
	DCX	H
	SHLD	v_EBUFS	; Store end available space
	LHLD	HEAP	; Get start addr HEAP
	INX	H
	INX	H	; Plus 2
	SHLD	v_EBUFR	; Store start addr. editbuf
	SHLD	v_EBUFN	; Set input pntr editbuf
	LXI	H, OTSW
	MVI	M, $02	; Set output to editbuf
	RET
;
; **************************
; * INPUT FROM EDIT BUFFER *
; **************************
;
; Entry: A=0, CY=0
;
IFBNL	PUSH	PSW
	LHLD	v_EBUFR	; Get startaddr editbuf
	SHLD	EFEPT	; Store it in EFEPT
@E298	MOV	A, M	; Get char from edítbuf
	ORA	A	; Char is 0?
	JZ	@E2AA	; Then editbuf empty
	INX	H
	CPI	$0D	; Car.ret?
	JNZ	@E298	; Get next char 1f not
;
; If char is car.ret
;
	SHLD	v_EBUFR	; Update startaddr. editbuf
	MVI	C, $00	; 1st pos on line
	POP	PSW	; No special action
	RET
;
;  If buffer empty
;
@E2AA	STA	EFSW	; Set input from keyboard
	CALL	HRINIT	; Organise HEAP + buffers
	POP	PSW	; special action
	STC		; CY=1
	RET
;
; **********************
; * RUN basiccmd PRINT *
; **********************
;
; Entry: BC: Position in textbuffer.
;
RPRINT	LDAX	B	; Get 1erngth
	INX	B
	MOV	D, A	; Count of expr in D
	ORA	A
	JZ	@E2F7	; Jump if only car.ret
@E2BA	PUSH	D	; Save nr of expressions
	LDAX	B	; Get expr type
	INX	B
	CPI	$20
	JZ	@E2D2	; Jump if string
;
; If INT/FPT number
;
	CPI	$00
	CALL	REXNA	; Eval expr. Result in MACC
	PUSH	PSW	; Save f1ags on expr.type
	CNZ	PINT	; If INT: print INT number
	POP	PSW
	CZ	PFPT	; If FPT print FPT number
	JMP	@E2E3
;
; If string
;
@E2D2	CALL	REXSR	; Evaluate string expr
	PUSH	H
	ROMCALL(5, $0C)	; Ask cursor pos and size char streen
	MOV	A, E	; X-size of screen in A
	SUB	L	; Minus X-coord cursor pos
	INR	A	; +1
	POP	H
	CMP	M	; (not used further: off-screen printing possible)
	NOP		; (should be: CC CRLF)
	NOP
	NOP
	CALL	PSTR	; Print string pntd by HL
@E2E3	LDAX	B	; Get byte after string
	INX	B
	CPI	$FF	; End marker ?
	JZ	@E2F6	; Then quit with car.ret
	CPI	';'	; ';'?
	CNZ	PSKP	; Cursor to next column if not (must be ',')
	POP	D	; Get nr of expr to print
	DCR	D	; Update expr count
	JNZ	@E2BA	; Loop if more expressions
	ORA	A	; No special action
		RET
;
; If end of print statement
;
@E2F6	POP	D
@E2F7	CALL	CRLF	; Print 'CR'
	ORA	A
	RET
;
; **********************
; * RUN basiccmd INPUT *
; **********************
;
; Runs an input statenert with a prompt ('?').
; RINPQ:	Input with a string
; RINPUT: Input without a string
;
RINPQ	CALL	REXSR	; Evaluate string expression
	CALL	PSTR	; Print string pntd by HL
RINPUT	LXI	H, $0002
	DAD	SP
	CALL	LE447	; Update ERSSP, print '?' and ask for inputs
	CNC	RRDIP	; If no break: store inputs
	PUSH	PSW	; Save last input
	XRA	A
	STA	RDIPF	; Reset f1ag running inputs
	POP	PSW	; Get last input
	JC	@E320	; Abort if break
	INR	E
	JZ	@E31E	; Quit if correct nr of inputs
	CALL_W(PMSGR, MSG001)	; Else: Print 'SOME INPUT IGNORED'
@E31E	ORA	A	; No special action
	RET
;
; If suspended
;
@E320	MVI	A, $02	; Code 'cmd broken in'
	RET
;
; *********************
; * RUN basiccmd READ *
; *********************
;
RREAD	MVI	A, $01
	STA	EFSW	; Set input from string
	LDA	DATAC	; Get offset next char to encode and store it in E
	MOV	E, A
	LHLD	DATAQ	; Get DATAQ addr
	MOV	A, M	; Get length of string
	STA	EFECT	; Store it in EFECT
	INX	H	; Pnts to 1st char
	SHLD	EFEPT	; Addr 1st char in EFEPT
	CALL	RRDIP	; Store data
	MOv	A, E	; Get offset next char
	STA	DATAC	; Store it
	LHLD	EFEPT	; Get EFEPT
	DCX	H	; Pnts to next dataline
	SHLD	DATAQ	; Store it in DATAQ
	XRA	A
	STA	EFSW	; Set input from keyboard
	RET
;
; *********************
; * DATA - (not used) *
; *********************
;
LE34A	.byte	$21, $01, $60, $69, $22, $1F
;
; *****************
; * RESTART INPUT *
; *****************
;
; Error handling if running inputs.
;
INPRS	LHLD	ERSSP	; Get saved stackpntr
	SPHL		; Reload stackpntr
	LHLD	BRKPT	; Get start current command
	MOV	B, H	; Store it in BC
	MOV	C, L
	CALL_W(PMSGR, MSG04)	; Print 'RETYPE LINE'
	JMP	LC87F	; Re-execute input statement
;
; **********************************
; * STORE DATA IN CORRECT LOCATION *
; **********************************
;
; EntrY L0E56 not used.
;
; Stores data read from data statements or gotten from an input line on the correct location
;
; Entry: E:  Offset next character to encode (#0291).
;        HL: Startaddress data line.
;
L0E56	CALL	LE436	; (not used)
;
RRDIP	LDAX	B	; Get nr of data reqd
	INX	B
	MOV	D, A	; Into D
LE367	DCR	D
	JM	LE3C1	; Jump if ready
	INR	E	; Offset next char
	JZ	LE3A8	; Jump if at end of line
	DCR	E
LE370	CALL	RVAR	; Get varptr in HL
	PUSH	B
	PUSH	D
	MOV	C, E	; Offset in C
	PUSH	H	; Save varptr
	LXI	H, EBUF	; Startaddr EBUF
	PUSH	H	; Save it on stack
	ANI	$30	; Encode a constant
	ROMCALL(1, $06)
	MOV	E, C	; Offset in E
	POP	B
	POP	H	; Get varptr
	CPI	$20	; String type ?
	MOV	A, E	; Offset in A
.if ROMVERS == 11
	CZ	LE4B8	; Only JZ E3A2 replaced by its contents
	CNZ	LE4B4	; Perform LET (INT/FPT)
.endif
.if ROMVERS == 10
	JZ	LE3A2	; Jump if string type
	CALL	LE4B4	; Perform LET (INT/FPT)
.endif
;
; Check separator/terminator
;
LE38B	MOV	C, A	; Offset in C
	CALL	IGNB	; Get char from line, neglect tab and space
	INR	C	; Offset + 1
	CPI	','	; ','?
	JZ	@E399
	CPI	$0D	; CR?
	MVI	C, $FF	; Dummy offset for end of line
@E399	POP	D
	MOV	E, C	; Offset in E
	POP	B
.if ROMVERS == 11
;
; Error exit changed: Now checks if end of input is reached.
; EFEPT 1s on1y updated if not running inputs (anymore).
;
	JZ	LE367	; Read next data if no error
XE39F	LDA	RDIPF	; If error: Get 'run-input' flag
	CALL	RRISN
	JMP	ERRSN	; Run 'SYNTAX ERROR'
.endif
.if ROMVERS == 10
	JNZ	RRISN	; Error if char not ',' or car. ret
	JMP	LE367	; Read next data line
;
; If string type
;
LE3A2	CALL	LE4B8	; Perform LET (STR)
	JMP	LE38B	; Check terminator/separator
.endif
;
; If end of line reached ('CR')
;
LE3A8	LDA	RDIPF	; Get flag for running inputs
	ORA	A
	JZ	@E3BB	; Quit if not running inputs
	CALL	COL0	; Cursor to begin next line
	CALL	INPGT	; Print '?', read input line
	JC	LE3C2	; Abort if break pressed
	JMP	LE370	; Cont reading
;
; If whole line read
;
@E3BB	CALL	DATAF	; Find next dataline in txtbuf
	JMP	LE370	; Cont reading
;
; If reading done
;
LE3C1	ORA	A	; No special action
LE3C2	RET
;
; If error
;
.if ROMVERS == 11
RRISN	ANA	A	; Set f1ags
	RNZ		; Abort if running inputs
	LHLD	EFEPT	; Get EFEPT
	LXI	D, $FFFC	; -4
	DAD	D
	SHLD	CURRNT	; Set start current line
	RET
.endif
.if ROMVERS == 10
RRISN	LHLD	EFEPT	; Get EFEPT
	LXI	D, $FFFC
	DAD	D	; EFEPT-4
	SHLD	CURRNT	; Store start current line
	JMP	ERRSN	; Run 'SYNTAX ERROR'
.endif
;
; **************************
; * PREPARE GETTING INPUTS *
; **************************
;
; Continuation of 0E447.
; Prints a prompt ('?') on the screen and gets a textline from input.
;
INPGT	PUSH	D
	ROMCALL(5, $0C)	; Ask cursor pos. and size char screen
	POP	D
	MVI	A, $3F
	CALL	PINPLN	; Print '?'; input a textline
	MOV	E, L
	INR	E	; E pnts after 1ast char of input
	RET
;
; ************************************
; * FIND NEXT DATALINE IN TEXTBUFFER *
; ************************************
;
DATAF	PUSH	PSW
	PUSH	D
	PUSH	H
	LHLD	DATAP	; Get addr current dataline
@E3E2	MOV	A, M	; Get length data string
	ORA	A
	MVI	A, $02
	JZ	ERROR	; Run error 'OUT OF DATA' if no data available
	MOV	D, H	; Addr dataline in DE
	MOV	E, L
	CALL	DADM	; Calc end dataline
	SHLD	DATAP	; Store it in DATAP
	XCHG		; End in DE, start in HL
	INX	H
	INX	H
	INX	H	; Pnts to token
	MOV	A,M	; Get token
	CPI	$A2	; Is it DATA?
	XCHG
	JNZ	@E3E2	; Check next textline if not
	XCHG
	JMP	LE436	; Continue
;
	.byte	$FF
;
;
;
; ************************
; * RUN basiccmd RESTORE *
; ************************
;
RREST	LHLD	TXTBGN	; Get startaddr. textbuf
	SHLD	DATAP	; Store it in DATAP
	XRA	A
	DCR	A
.if ROMVERS == 11
	JMP	XE455
.endif
.if ROMVERS == 10
	JMP	LE452	; Set DATAQ=FF
.endif
;
; *****************
; * RUN RANDOMISE *
; *****************
;
; Returns a hardware random number 0 < R < 1.
;
; Exit: BC preserved
;       AFDEHL corrupted
;       Result in MACC
;
RRAND	PUSH	B
	LXI	H, PORI	; Addr PORI
	CALL	LD65F	; BC=0, E=0, #40 or #80
	MVI	D, $01
;
@E415	LDA	RNDLY	; Get RNDLY (0 by C72E)
	CALL	LD658	; Delay, A=M XOR E
	RLC
	RLC
;
; Now CY is 0 if E=$40 and CY = bit 6 of FD00 (hardware random) if E=0 or E=#80.
;
	MOV	A, D
	RAL		; RAL D
	MOV	D, A
	MOV	A, C
	RAL		; RALC
	MOV	C, A
	MOV	A, B
	RAL		; RALB
	MOV	B, A
	ORA	A
	JP	@E415	; Again if B<$80 (must be normalised FPT nr)
;
; Result in MACC
;
	MVI	A, $01	; Set exp. byte for 1 < R < 2
	ROMCALL(4, $12)	; Copy A, B, C, D to MACC
	LXI	H, FPM1B	; Addr FPT(-1)
	ROMCALL(4, $00)	; Add -1 to MACC
	POP	B	; Now 0 < R < 1
	ORA	A	; No special action
	RET
;
; *****************
; * part of 0E3DC *
; *****************
;
LE436	INX	H
	MOV	A, M	; Get length dataline
	STA	EFECT	; Store it in EFECT
	INX	H	; Pnts to start data bytes
	SHLD	EFEPT	; Startaddr string in EFEPT
	NOP
	NOP
	POP	H
	POP	D
	MVI	E, $00
	POP	PSW
	RET
;
; **************************
; * PREPARE GETTING INPUTS *
; **************************
;
.if ROMVERS == 11
; The keyboard pointers are set to their default values before inputs are asked. This avoids keybounce.
LE447	SHLD	ERSSP
	CALL	KLIRP	; Init keyb pntrs
	MVI	A, $FF
	STA	RDIPF
	JMP	INPGT
; ******************
; * cont. of 0E401 *
; ******************
XE455	STA	DATAC
	RET
	.byte	$FF
.endif
.if ROMVERS == 10
LE447	SHLD	ERSSP	; Store SP+2 in ERSSP
	MVI	A, $FF
	STA	RDIPF	; Set f1ag for running inputs
	JMP	INPGT	; Print '?', input a textline
;
; ******************
; * cont. of 0E401 *
; ******************
;
LE452	STA	DATAC	; Save offset next char to encode
	RET
;
	.byte	 $FF, $FF, $FF, $FF
.endif
;
; ********************
; * RUN basiccmd LET *
; ********************
;
; Valid as direct command or in program. Computes variable pointer or variable reference and
; checks type. 'LET' can be explicitly or implicitly given.
;
; Entry: BC: Points to program line
; Exit:  BC: Updated
;        A:  Type of variable
;        FDEHL corrupted
;
RLETX	.equ	*
RLETI	CALL	RVAR	; Get varptr in HL, T/L in A
	ANI	$30	; Type only
	PUSH	PSW	; Save type
	CPI	$20	; string type?
	JNZ	LE494	; Jump if INT/FPT
;
; If string type
;
LE465	PUSH	H	; Save varptr
	MOV	A, M
	INX	H
	MOV	H, M	; Addr string in HL
	MOV	L, A
	XTHL		; Save stringaddr
	PUSH	H	; and varptr
	CALL	REXPS	; Get value being assigned
	MOV	A, E	; Get status
	CPI	$02
	JZ	@E47F	; Jump if temp on heap
	MOV	A, M	;  Get string length
	XCHG
	CALL	SHREQ	; Get place in heap for string
	PUSH	H
	CALL	SHCOPY	; Transfer string into heap
	POP	H
@E47F	XCHG		; Pntr to string in DE
	POP	H	; Pntr to variable in HL
	MOV	M, E	; Stringpntr in variable
	INX	H
	MOV	M, D
;
; Entry from scratch
;
LE484	LHLD	TXTBGN	; Get startaddr. textbuf
	XCHG		; in DE
	POP	H	; Get pntr old value
	MOV	A, H
	ORA	L
	CNZ	COMP	; If <> 0: Test if on heap
	CC	SHREL	; Then clear string in heap
	JMP	LE4B2	; Ready
;
; If FPT/INT type
;
LE494	PUSH	H
	CALL	REXPN	; Eval numeric arguments
	MOV	A, H
	ORA	L
	JNZ	@E4A3	; Copy num expr if not in MACC
	POP	H
	ROMCALL(4, $0F)	; Copy MACC to variable
	JMP	LE4B2	; Ready
;
; If just constant or variable
;
@E4A3	POP	D	; Get pntr to variable
	PUSH	D
	PUSH	B
	MVI	B, $04	; Nr of bytes
@E4A8	MOV	A, M	; Get byte
	STAX	D	; Store it in variable
	INX	H
	INX	D
	DCR	B	; Decr byte count
	JNZ	@E4A8	; Next byte if not ready
	POP	B
	POP	H
;
; Ready
;
LE4B2	POP	PSW
	RET
;
; Entry from READ/INPUT for FPT/INT
;
LE4B4	PUSH	PSW
	JMP	LE494	; Value to variable
;
; Entry from READ/INPUT for STR
;
LE4B8	PUSH	PSW
	JMP	LE465	; Stringvalue to variabie
;
; **********************
; * RUN basiccmd SOUND *
; **********************
;
; Formats: SOUND <CHAN>ENV><VOL>T6>FRE0
; SOUND CHAN OFF.
; SOUND OFF
;
; * Entry: BC: Points to program line.
; Exit	EC updated, AFDEHL corrupted.
;
RSOUND	LDAX	B	; Get 1st expr
	CPI	$FF	; Is it sound OFF?
	JZ	LE501_	; Then turn all sound off
	MVI	A, $02
	CALL	REXIL	; Get channel nr (0,1,2)
	LXI	H, SCB0	; Startaddr SCB0
	LXI	D, $000E	; Length SCB
	PUSH	PSW	; Save channelnr
@E4CE	DCR	A
	JM	@E4D6	; If chan.0 or ready
	DAD	D	; Absolute addr SCB in HL
	JMP	@E4CE	; If chan.2
@E4D6	POP	D	; Channelnr in D
	CALL	SNGEV	; Set up SCB <ENV><VOL>
	JC	LE4FC	; If channel to be OFF
	MVI	A, $03
	CALL	REXIL	; Get <TG>
	PUSH	PSW
	ANI	$01	; Tremolo flag only
	MOV	M, A	; Into SCB
	INX	H
	NOP
	NOP
	POP	PSW	; Restore <TG>
	ANI	$02	; Glissando flag only
	RAR
	INR	A
	INX	H	; 1 free byte
	MOV	M, A	; Glissando flag in SCB
	INX	H
	INX	H	; Ignore current period
	INX	H
	PUSH	H	; Save pntr to reqd period
	CALL	REXI2	; Get <period>
	XCHG		; inDE
	POP	H
	MOV	M, E	; Reqd period in SCB
	INX	H
	MOV	M, D
LE4FC	CALL	SNDEI	; Enable sound interrupts
	ORA	A	; No special action
	RET
;
; If SOUND OFF
;
LE501_	INX	B
	CALL	SNDDI	; Disable sound interrupts
	PUSH	B
	CALL	SNDINI	; Stop oscillators
	POP	B
	ORA	A	; No special action
	RET
;
; **********************
; * RUN basiccmd NOISE *
; **********************
;
; Sets up a noise control block.
; Fornats: NOISE <ENV><VOL>
;          NOISE OFF
;
; Entry: BC: Points to expression
; Exit:  Noise off: BC updated, DE preserved, AFHL corrupted
;        Noise on:	BC updated, AFDEHL corrupted
;
RNOISE	LXI	H, NCB	; Startaddr NCB
	MVI	D, $03	; Channelnr.3
	CALL	SNGEV	; Set up NCB
	JC	LE4FC	; If channel to be off
	MVI	M, $00	; No tremolo
	INX	H
	MVI	M, $00	; Current volume = 0
	JMP	LE4FC	; Enable sound interrupts
;
; ****************
; * SET ENVELOPE *
; ****************
;
; Sets up a sound or noise control block for a channel
;
; Entry: D:  Channelnumber (0,1,2 or 3)
;        BC: Points to programline
;        HL: Points to startaddr SCB/NCB
; Exit:  If sound/noise off (CY=1):
;        FF in 1st byte of SCB/NCB
;            HL: points to 1st byte SCB/NCB
;            BC: points to 2nd byte SCB/NCB
;            DE preserved
;            AF corrupted
;        If sound/noise on (CY=0):
;        00 in 1st byte SCB/NCB
;            HL: points after free byte
;            DE: Envelopeaddr +1
;            BC: Points beyond volume.
;            AF: Corrupted
;
SNGEV	CALL	SNDDI	; Disable sound interrupts
	MVI	M, $00	; 00 in 1st byte SCB/NCB
	LDAX	B	; Get 1st byte from progr.line
	CPI	$FF
	JZ	@E552	; Jump if channel to be off
;
; If channel on
;
	INX	H	; Pntr to next byte of block
	PUSH	H	; Save pntr
	MVI	A, $01
	CALL	REXIL	; Get envelopenr in A (0, 1)
	LXI	H, ENVST	; Addr envelope area
	RRC
	RRC
	MOV	E, A	; DE=64*A
	MVI	D, $00
	DAD	D	; Add offset for env area
	XCHG		; Pntr to envelope in DE
	POP	H	; Get input pntr SCB/NCB
	MOV	M, E	; Envelope addr in block
	INX	H
	MOV	M, D
	INX	H
	INX	D
	MOV	M, E	; Env addr +1 in b1ock
	INX	H
	MOV	M, D
	INX	H
	MVI	A, $0F
	CALL	REXIL	; Get volune multiplier in A (0-15)
	RLC
	RLC
	RLC
	MOV	M, A	; Vol. * 8 in block
	INX	H	; Pntr to basic volume
	INX	H	; Pntr to tremolo flag
	ORA	A	; Return 'channel on'
	RET
;
; If channel to be off
;
@E552	INX	B
	DCR	M	; FF in 1st byte SCB/NCB
	MOV	A, D	; Get channelnr
	CPI	$03
	JZ	@E563	; Jump if noise channel
	RRC		; Find disable data for
	RRC		; chan. 0-2
	ORI	$36
	STA	SNDC	; Load sound cmd word
	STC		; Return 'channel off'
	RET
;
; If noise to be off
;
@E563	LDA	POR1M	; Get volume osc.2 + noise
	ANI	$0F	; Vol. noise = 0
	STA	POR1M	; Update POR1M
	STA	POR1	; and POR1
	STC		; Return 'channel off'
	RET
;
; *************************
; * RUN basiccmd ENVELOPE *
; *************************
;
; Load envelope table 0 or 1 with data.
; Formats: ENVELOPE <ENV> (<V>,<T>;) <V>,<T> FF
;          ENVELOPE <ENV> (<V>,<T>;) <V>
;
RENV	MVI	A, $01
	CALL	REXIL	; Get envelope number (0, 1)
	RRC
	RRC
	MOV	E, A	; Offset for env addr
	MVI	D, $00
	LXI	H, ENVST	; Addr env storage area
	DAD	D	; Startaddr table in HL
	MVI	M, $00	; 00 in 1st field
	INX	H
	LDAX	B	; Get length of expr
	INX	B
	INR	A
	MOV	D, A	; Nr of complete entries in D
@E585	DCR	D
	JZ	@E59D	; If all entries done
	MVI	A, $10
	CALL	REXIL	; Get volume (0-16)
	MOV	M, A	; Into env table
	INX	H
	CALL	REXI1	; Get time
	SUI	$01	; Min. value is 1
	JC	ERRRA	; Run error 'NUMBER OUT OF RANGE' if time=0
	MOV	M, A	; Time into env table
	INX	H
	JMP	@E585	; Next <V>, <T>
@E59D	MVI	M, $FF	; FF as last in env table
	LDAX	B	; Get 1ast expr
	INX	B
	CPI	$FF	; End marker?
	JZ	@E5B0	; Then quit
	DCX	B
	MVI	A, $10
	CALL	REXIL	; Get final volume <V>
	MOV	M, A	; <V> into env table
	INX	H
	MVI	M, $FF	; Time = forever
@E5B0	ORA	A	; No special action
	RET
;
; ***********************
; * RUN basiccmd CURSOR *
; ***********************
;
RCURS	CALL	RCOOR	; Evaluate coordinate
	MOV	H, A	; Y-coord in H
	ROMCALL(5, $09)	; Set cursor position
	JMP	LE5C9	; Evt run screen error
;
; *********************
; * RUN basiccmd MODE *
; *********************
;
; Entry: BC: Points to program line
;
RMODE	LDAX	B	; Get reqd mode in A
	INX	B
	JMP	LCEB5	; Change screen mode
;
	RET
;
; ********************
; * RUN basiccmd DOT *
; ********************
;
RDOT	CALL	RCOCO	; Eval dot addr + colour
	PUSH	B
	MOV	C, E	; Colour in C
	ROMCALL(5, $1E)	; Draw dot on screen
LE5C8	POP	B
LE5C9	JC	SCRER	; Jump if screen error
	ORA	A	; No special action
	RET
;
; *********************
; * RUN basiccmd DRAW *
; *********************
;
RDRAW	CALL	R2COC	; Eval begin/end addr colour
	XTHL
	ROMCALL(5, $21)	; Draw a line on screen
	JMP	LE5C8	; Evt. run screen error
;
; *********************
; * RUN basiccmd FILL *
; *********************
;
RFILL	CALL	R2COC	; Eval coor dirnates, colour
	XTHL
	ROMCALL(5, $24)	; Fill a rectangular area
	JMP	LE5C8	; Evt run screen error
;
; ***** ***************************
; *EVALUATE 2 coORD INATESCOLOUR *
; **********************************
;
R2COC	CALL	RCOOR	; Get 1st coordinate
	XTHL		; X-coord on stack
	PUSH	H
	MOV	E, A	; Y-coord in E
	CALL	RCOOR	; Get 2nd coordinate, x-coord in HL
	MOV	D, A	; y-coord in D
	CALL	RCOL	; Get colour in A
	PUSH	B
	PUSH	D
	XCHG
	POP	B
	POP	H
	RET
;
; ***********************
; * EVALUATE COORDINATE *
; ***********************
;
RCOOR	CALL	REXI2	; Get x-coord in HL
	JMP	REXI1	; Get y-coord in A
;
; ********************************
; * EVALUATE COORDINATE + COLOUR *
; ********************************
;
RCOCO	CALL	RCOOR	; Get x-coord in HL
	MOV	E, A	; y-coord in E
RCOL	MVI	A, $17
	JMP	REXIL	; Get colour (0-23) in A
;
;
;
; ********************
; * RUN SCREEN ERROR *
; ********************
;
; Entry: A: Error code: 01: Off screen
;                       02: Colour not avai1able
;
SCRER	CPI	$01	; Code is 1?
	MVI	A, $11	; Then run error 'OFF SCREEN'
	JZ	ERROR
	MVI	A, $10	; Else: run error 'COLOUR NOT AVAILABLE'
	JMP	ERROR
;
; ***********************
; * RUN basiccmd COLORT *
; ***********************
;
RCOLT	CALL	R4COL	; Get colours in scratch area
	ROMCALL(5, $06)	; Set text colours
	ORA	A	; No special action
	RET
;
; ***********************
; * RUN basiccmd COLORG *
; ***********************
;
RCOLG	CALL	R4COL	; Get colours in scratch area
	ROMCALL(5, $1B)	; Set graphic colours
	ORA	A	; No special action
	RET
;
; ***********************************
; * GET 4 COLOURS INTO SCRATCH AREA *
; ***********************************
;
; Colour data from a program line are stored in scratch area SCOLT/SCOLG (COLWK).
;
; Exit: HL: Points to start scratch area
;
R4COL	LXI	H, COLWK	; Startaddr SCOLT/SCOLG area
	PUSH	H
@E620	MVI	A, $0F
	CALL	REXIL	; Get one colour (0-15)
	MOV	M, A	; Store it in scratch area
	INX	H
	MOV	A, L
	CPI	$1D	; 4 colours done?
	JNZ	@E620	; Next if not
	POP	H
	RET
;
; ********************
; * RUN basiccmd DIM *
; ********************
;
;
RDIM	LDAX	B	; Get nr of items
	INX	B
LE631	ORA	A
	RZ		; Abort 1f no items or ready
	DCR	A	; Item count
	PUSH	PSW	; Preserve count
	CALL	RARRN	; Get pnr to array in HL type in A
	PUSH	H	; Preserve pntr
	CALL	LCE5C	; Erase array if existing
	ANI	$30	; Get type only
	LXI	D, $0004	; Length array element if FPT/INT
	CPI	$20	; String type?
	JNZ	@E648	; Jump if not
	MVI	E, $02	; Length STR array element
@E648	LDAX	B	; Get number of elements
	INX	B
	MOV	H, A	; In H and in L
	MOV	L, A
	XCHG
;
; Calculate total required length
;
@E64D	CALL	REX1	; Get 1ength next dimension
	PUSH	PSW	; Remember it
	INR	A	; Length +1
	CALL	RDM40	; Calc reqd space
	JC	ERRRA	; Run error 'NUMBER OUT OF RANGE' if total space > 64K
	DCR	D	; nr of elements -1
	JNZ	@E64D	; Next element if not ready
;
; Find space in heap
;
	DCR	H
	INR	H
	JM	ERRRA	; Run error 'NUMBER OUT DF RANGE' if > 32K reserved
	DAD	D
	INX	H	; Size of space reqd in HL
	PUSH	D
	XCHG
	CALL	ZHREQ	; Get space of size needed
	POP	D
	MOV	M, E	; Store nr of elements
	DAD	D	; Last element
;
; Elements into heap
;
@E66B	POP	PSW	; Get length 1 element
	MOV	M, A	; Store it in memory
	DCX	H
	DCR	E
	JNZ	@E66B	; Next element to memory
	XCHG
	POP	H	; Set pntr to array
	MOV	M, E
	INX	H	; Set pointer
	MOV	M, D
	POP	PSW	; Get item count in A
	JMP	LE631	; Next item
;
; ****************************
; * part of RUN TALK (0EE94) *
; ****************************
;
; Entry: A: Code for osc. channel SHR 1.
;
LE67B	DAD	H
LE67C	LXI	D, POR0M	; Addr volumes osc. 0, 1
	ANI	$01	; Code SHR 1 only
	ADD	E
	MOV	E, A	; DE=POR0M for osc.0, 1; DE=POR1M for osc.2,N
	MOV	A, H	; Get mask
	CMA		; Complement it
	XCHG		; Mask + vol in DE, addr POR0M/POR1M in HL
	ANA	M	; Part to be preserved from  old POR0M/POR1M
	ORA	E	; Add new volume
	JMP	LEA40	; Continue
;
; **********************
; * REQUEST HEAP SPACE *
; **********************
;
; Part of Run 'DIM' (0E665).
; Requests space from Heap and fills it with zeroes.
;
; Entry: DE: Size needed.
; Exit:  HL: Points to data area (after 1ength bytes)
;        AFDE carrupted
;
ZHREQ	DCR	D
	INR	D
	JM	ERRRA	; Run error 'NUMBER OUT OF RANGE' if > 32K reqd
	CALL	HREQU	; Run Heap request
	INX	H
	INX	H	; HL pnts after 1ength byte
	PUSH	H
	XCHG		; Start data area in DE
	DAD	D	; End area in HL
	XRA	A
	CALL	FILL	; Load bank with '0'
	POP	H
	RET
;
; *******************
; * RUN basiccmd UT *
; *******************
;
; Valid as direct command only.
;
RUT	XRA	A
	STA	KNSCAN	; Enable complete keyb scan
	ROMCALL(1, $09)	; Go to utility
;
; **********************
; * RUN basiccmd CALLM *
; **********************
;
RCALM	LXI	H, LE6B3	; Returnaddr from Utility
	PUSH	H	; on stack
	CALL	REXI2	; Get UT addr in HL
	PUSH	H	; UT addr on stack
	LDAX	B	; Get next expr
	CPI	$FF	; End marker?
	JNZ	RVAR	; If not: Get varptr of given variable in HL, T/L in A
	INX	B
LE6B3	ORA	A	; No special action
	RET		; On entry: Goto UT addr
			; On exit: Back to Basic monitor
;
; **********************
; * RUN basiccmd CLEAR *
; **********************
;
.if ROMVERS == 11
; Routine is completely modified. Max. useable heap space in V1.0 was $7FFF-4.
; Now it is $7FFF. Doesnot set up anymore a complete new heap, but just empties heap
; and symboltable entries and	shifts the program to after the new heap.
;
RCLEAR	CALL	REXI2	;  Get reqd space in HL
	PUSH	H	; Preserve it
	MOV	A, H	; Get hibyte in A
	DCX	H
	DCX	H
	DCX	H
	DCX	H	; Reqd space-4
	ORA	H
	JM	ERRRA	; Run 'NUMBER 0UT OF RANGE' error if < 4 or > 32K
	POP	D	; Get reqd space in DE
	LHLD	HSIZE	; Get old heapsize
	XCHG
	SHLD	HSIZE	; Store new heapsize
	JMP	LD214
	.byte	$FF
.endif
.if ROMVERS == 10
RCLEAR	CALL	LD87F	; Get space reqd in HL (CY=1 if > 32K)
	CALL	LCEBB	; Must be >=4 bytes, else run error 'NUMBER OUT OF RANGE'
	XCHG
	SHLD	HSIZE	; Set Heap size
	LHLD	TXTBGN	; Get startaddr. textbuf
	PUSH	H
	CALL	SCRATC	; Empty Heap + symtab
	PUSH	D
	CALL	HINIT	; Set Heap to all available
	POP	H
	JMP	LD214	; Continue
.endif
;
; ******************************
; * Run basiccmds TRON - TROFF *
; ******************************
;
; Sets or resets the trace flag.
;
; RTRON: Set trace flag.
; RTROF: Reset trace flag.
;
; Entry: none
; Exit:  Z=1: F1ag reset
;        Z=0: Flag set
;
RTRON	MVI	A, $FF
LE6D0	STA	TRAFL	; Set trace flag
	ORA	A	; No special action
	RET
;
RTROF	XRA	A
	JMP	LE6D0	; Reset trace flag
;
; *******************
; * READ LINENUMBER *
; *******************
;
; Entry: BC: Points to linenumber
; Exit:  Z=0: Linenumber in HL
;        HL preserved
;        BC updated
;        DE preserved
;        AF corrupted
;
RLN	PUSH	H
	LDAX	B
	INX	B
	MOV	H, A
	LDAX	B	; Get linenr in HL
	INX	B
	MOV	L, A
	ORA	H
	JZ	@E6E5	; Abort if linenr is 0
	XTHL		; Linenr on stack
@E6E5	POP	H	; O1d HL or linenr in HL
	RET
;
; *********************************************
; * READ LINENUMBER AND FIND IT IN TEXTBUFFER *
; *********************************************
;
; Entry: BC: Points to linenumber.
; Exit:  BC updated, DE preserved, AF corrupted
;        (RLNF) or preserved (RLNFI)
;        HL: Points to 1st linenr reqd. number
;        CY=1: Linenumber found
;        CY=0: Not found
;
RLNF	CALL	RLN	; Get linenr in HL
	JMP	FINDL	; Find it in textbuffeer
;
; Idem as RLNF, but with error reporting
;
RLNFI	PUSH	PSW
	CALL	RLNF	; Read linenr and find it
	MVI	A, $04
	JNC	ERROR	; Run error 'UNDEFINED NUMBER' if not found
	POP	PSW
	RET
;
; *******************************************
; * RUN A INT EXPRESSION WITH 2-BYTE RESULT *
; *******************************************
;
; Evaluates a i6-bit INT expression (in range 0-$FFFF). The result is in HL.
;
; Entry: BC: Points to expression
; Exit:  HL: Result
;        BC updated
;        AFDE corrupted
;
REXI2	PUSH	PSW
	PUSH	D
	CALL	REXPN	; Eval arguments in num exp Result in MACC or in WORKE
	MOV	A, H
	ORA	L
	JZ	@E710	; Jump if result in MACC
;
; If result in WORKE
;
	MOV	A, M
	INX	H	; Check if 2 bytes
	ORA	M
	JNZ	ERRRA	; Then run error 'NUMBER OUT OF RANGE'
	INX	H
	MOV	A, M
	INX	H	; Get result in HL
	MOV	L, M
	MOV	H, A
	POP	D
	POP	PSW
	RET
;
; If result in MACC
;
@E710	PUSH	B
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	ORA	B	; Check if > 2 bytes
	JNZ	ERRRA	; Then run error 'NUMBER OUT OF RANGE'
	MOV	L, D	; Result in HL
	MOV	H, C
	POP	B
	POP	D
	POP	PSW
	RET
;
; *******************************
; * RUN A 1-BYTE INT EXPRESSION *
; *******************************
;
; Evaluates a 8-bit INT expression (range 0-$FF). Result in A.
;
; Entry: BC: Points to expression.
; Exit:  A Result
;        BC updated
;        DEHL preserved
;
REXI1	PUSH	D
	PUSH	H
	CALL	REXPN	; Eval arguments in num expr. Result in MACC or WORKE
	MOV	A, H
	ORA	L
	JZ	LE736	; If HL=0: Get result frm MACC
;
; Result in WORKE
;
	MOV	A, M
	INX	H
	ORA	M	; Check if 1 byte
	INX	H
	ORA	M
	JNZ	ERRRA	; Then run error 'NUMBER OUT OF RANGE'
	INX	H
	MOV	A, M	; Get result in A
	POP	H
	POP	D
	RET
;
; If result in MACC (also entry from REXF1)
;
LE734	PUSH	D
	PUSH	H
LE736	POP	H
	PUSH	B
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
	ORA	B	; Check if > 1 byte
	ORA	C
	JNZ	ERRRA	; Then run error 'NUMBER OUT OF RANGE'
	MOV	A, D	; Get result in A
	POP	B
	POP	D
	RET
;
; ************************************************
; * RUN 1-BYTE INT EXPRESSION WITH LIMITED RANGE *
; ************************************************
;
; Entry: BC: Points to expression
;        A:  Range of argments (<=FE)
; Exit:  BC:  updated
;        DEHL preserved
;        F:   corrupted
;        A:   Result
;
REXIL	PUSH	D
	MOV	D, A	; Argument range in D
	CALL	REXI1	; Get value of argument in A
	INR	D
	CMP	D	; Out of range? Then run
	JNC	ERRRA	; error 'NUMBER OUT OF RANGE'
	POP	D
	RET
;
; *********************************************
; * CHECK VARIAELE TYPE AND GET ITS INT VALUE *
; *********************************************
;
; Entry: BC: Points to expression
; Exit:  Error: If string type
;        If OK: Value in A (FPT: converted to INT)
;        BC updated
;        DEHL preserved
;
REX1	LDAX	B	; Get var. type byte
	INX	B
	CPI	$20	; String type?
	JZ	ERRTM	; Then run error 'TYPE MISMATCH'
	CPI	$10	; INT type?
	JZ	REXI1	; Then get value in A
;
; If FPT
;
REXF1	CALL	REXNA	; Get value in MACC
	ROMCALL(4, $48)	; Change it to INT
	JMP	LE734	; Get value in A
;
; *======================================*
; * RUN EXPRESSIONS WITH OPERATOR PREFIX *
; *======================================*
;
; $E763-$E8ED evaluate 1ogical, FPT, INT or STR expressions in 'operator prefix' format.
;
; Register allacation during operation:
;    INT/FPT: D=0:    MACC empty
;             E:      Operator
;             HL=0:   Result in MACC
;             HL<>0:  HL points to result
;    STR:     HL:     Points to string
;             E:      Type of string (constant [0], variable [1], temporary [2]).
;
; *********************************
; * EVALUATE A LOGICAL EXPRESSION *
; *********************************
;
REXPL	MVI	D, $00	; MACC free
	LDAX	B	; Get byte
	ANI	$60
	CPI	$40	; String?
	jZ	ROSTR	; Then jump
	LDAX	B	; Get byte
	ANI	$1F
	CPI	$18	; Relational operator?
	JC	LE850	; If not: eval expr which begins with num operator
	INX	B
	CPI	$1A	; Bracket?
	JZ	REXPL	; Then ignore it
;
;  Logical AND or OR
;
	PUSH	PSW	; Preserve type of operation
	CALL	REXPL	; Get 1st operand
	PUSH	PSW	; Preserve it
	CALL	REXPL	; Get 2nd operand
	POP	D	; 1st operand in D
	PUSH	PSW	; Preserve 2nd operand
	ANA	D	; AND operation
	MOV	E, A	; Result in E
	POP	PSW	; 2nd operand in A
	ORA	D	; OR operation
	MOV	D, A	; Result in D
	POP	PSW	; Type of operation in F
	MOV	A, D	; Result OR in A
	JPE	@E790	;  Quit if OR
	MOV	A, E	; Result AND in A
@E790	RET
;
; ******************************
; * EVALUATE STRING EXPRESSION *
; ******************************
;
; This routine returns temporary strings before they are really free.
; The heap is cleared if it is a temporary string.
;
; Entry: BC: Points to expression
; Exit:  BC updated
;        AFD corrupted
;        HL: Points to string
;        E:  Status
;
REXSR	CALL	REXPS	; Evaluate string exppr
	MOV	A, E	; Get status
	CPI	$02	; Temporary?
	PUSH	H
	CZ	SHREL	; Then clear heap entry
	POP	H
	RET
;
;
;
; *******************************************
; * EVALUATE ARGUMENTS IN STRING EXPRESSION *
; *******************************************
;
; Only '+' or compare with logical result is allowed. The right-hand side of a
; string expression is evaluated. If it is not status $02, it is moved into the
; Heap. The stringpointer is saved at the varptr location.
; If the variable had already an old value on the heap, it is cleared, see further
; exit conditions.
;
; Entry: (BC): 1..... Expr. begins with operator
;              0l.... Variable reference
;              001... Function call
;              else   Constant
; Exit:  BC updated
;        DEHL corrupted
;        A: Type (#20)
;
REXPS	LDAX	B	; get 1st byte
	RLC
	JC	ROSTR	; Jump if 1st byte is operator
	RLC
	JC	@E7B3	; Jump if string variable
	RLC
	JC	RFUN	; Jump if string function
;
; If string constant
;
	MVI	E, $00	; Status: constant
	INX	B
	LDAX	B	; Get string length
	MOV	H, B	; Stringpntr in HL
	MOV	L, C
	JMP	LE190	; Abort with BC pnts after STR
;
; If string variable
;
@E7B3	CALL	RVAR	; Get varptr in HL, T/L in A
	MOV	E, M
	INX	H	; Stringaddr in DE
	MOV	D, M
	XCHG		; and in HL
	MVI	E, $01	; Status: variable
	RET
;
; If string operation
;
ROSTR	LDAX	B	; Get 1st byte
	INX	B
	PUSH	PSW
	PUSH	D
	CALL	REXPS	; Evaluate string expression
	POP	PSW
	MOV	D, A
	POP	PSW
	PUSH	H	; Remember it
	MOV	D, E	; Type in D
	PUSH	PSW
	PUSH	D
	CALL	REXPS	; Eval 2nd string expr
	POP	PSW
	MOV	D, A
	POP	PSW
	PUSH	B	; Save it
	MOV	B, H
	MOV	C, L
	POP	H
	XTHL		; Save program pointer
	PUSH	B
	MOV	B, D
	MOV	C, E	; Re-arrange registers
	XCHG
	POP	H
	CPI	$C0	; Operator is '+'?
	JZ	@E7EB	; Then append 2 strings
;
; If string compare
;
	CALL	SHCOMP	; Compare 2 strings
	CALL	DROPS	; Returns operands if temp
	POP	B	; restore
	MOV	E, A	; Opcode in E
	JMP	ROREL	; Evaluate the compare
;
; If operator is '+'
;
@E7EB	PUSH	H
	CALL	SHAPP	; Make 1 string out of 2
	XTHL		; Save pntr to result/store pntr to operand
	CALL	DROPS	; Clean up heap
	POP	H	; Pntr to result in HL
	POP	B	; Program pntr in BC
	MVI	E, $02	; Status: temporary
	RET
;
; CLEAR UP HEAP AFTER STRING OPERATION
;
; Entry: B,C: Code for 1st resp. 2nd operand (0=const, 1=var, 2=temp)
;        DE:  Points to 1st operand
;        HL:  Points to 2nd operand
; Exit:  DEHL corrupted
;        AFBC preserved
;
DROPS	PUSH	PSW
	MOV	A, C	; Get code 2nd oper and
	CPI	$02	; Temporary?
	CZ	SHREL	; Then clear string in heap
	XCHG
	MOV	A, B	; Get code 1st operand
	CPI	$02	; Temporary?
	CZ	SHREL	; Then clear string in heap
	POP	PSW
	RET
;
; *********************************
; * EVALUATE A NUMERIC EXPRESSION *
; *********************************
;
; Entry: BC Points to a numeric function argument or a numeric expression in program
; Exit:  BC updated
;        AFDEHL Preserved
;        Result in MACC
;
REXNA	PUSH	PSW
	PUSH	D
	PUSH	H
	CALL	REXPN	; Eval arguments in num expr
	MOV	A, H
	ORA	L
	JZ	@E815	; Abort if result in MACC
	ROMCALL(4, $0C)	; Else copy operand to MACC
@E815	POP	H
	POP	D
	POP	PSW
	RET
;
; ********************************************
; * EVALUATE ARGUMENTS IN NUMERIC EXPRESSION *
; ********************************************
;
; Checks for constants, functions, variables and operators. The right-hand side of the
; expression is therefore evaluated. The value of the variable is stored at its varptr
; 1ocation.
;
; Entry: BC:   Points to expression in program
;        (BC): 1.... Expr begins with operator
;              01... Variable reference
;              001.. Function call
;              else Constant.
;        D<>0: MACC must be preserved
;
REXPN	MVI	D, $00	; Set MACC free
;
; Called by 1ower levels
;
LE81B	LDAX	B	; Get 1st byte
	RLC
	JC	LE850	; Jump if expr starts with operator
	RLC
	JC	RVARE	; Jump if var reference
	RLC
	JC	@E830	; Jump if function call
;
; If numeric constant
;
	INX	B	; Past flag byte
	MOV	H, B	; HL pnts to constant
	MOV	L, C
	INX	B
	INX	B
	INX	B
	INX	B	; Program pntr pnts beyond
	RET
;
; If numeric function
;
@E830	PUSH	D
	MOV	A, D
	ORA	A
	JZ	@E846	; Jump if MACC free
	CALL	XPLISH	; Save MACC on stack
	CALL	RFUN	; Evaluate function call; result in MACC
	LXI	H, WORKE	; Addr WORKE
	ROMCALL(4, $0F)	; Copy result to WORKE
	CALL	XPOF	; Restore MACC from stack
	POP	D
	RET
@E846	CALL	RFUN	; Evaluate function call; result in MACC
	POP	D
	MVI	D, $FF	; Set MACC to be preserved
	LXI	H, $0000	; Flag 'result in MACC'
	RET
;
; If expr begins with numeric operator
;
LE850	LDAX	B	; Get operator
	ANI	$7F	; Clip operator bit
	INX	B
	CPI	$1A	; Bracket?
	JZ	LE81B	; Then ignore it
	DCR	D
	INR	D	; Check if D<>0
	CNZ	XPLISH	; Then save MACC on stack
	PUSH	D
	MOV	E, A	; Opcode in E
	LXI	H, LE8DC
	PUSH	H	; Returnaddr on stack
	CALL	REXPN	; Get 1st operand
	MOV	A, E	; Opcode in A
	ANI	$1F
	CPI	$1C
	JNC	LE89F	; Jump if unitary operation
;
; If boolean operator
;
	PUSH	H	; Save pntr to 1st operand
	CALL	LE81B	; Get 2nd operand
	MOV	A, H
	ORA	L
	JNZ	@E87D	; Jump if HL pnts to WORKE
	LXI	H, WORKE	; Addr WORKE
	ROMCALL(4, $0F)	; Copy 2nd operand to WORKE
@E87D	XTHL
	MOV	A, H
	ORA	L
	JZ	@E885	; Jump if 1st operand in MACC
	ROMCALL(4, $0C)	; Else copy it from WORKE to MACC
@E885	MOV	A, E	; Get opcode
	ANI	$1F
	CPI	$10
	JNC	LE8C9	; If relational operation
;
; If arithmetic operation
;
	CMP	E
	LXI	H, ROITAB	; Addr table INT routines
	JNZ	@E897	; Jump if INT
	LXI	H, ROFTAB	; Addr table FPT routines
@E897	MVI	D, $00	; Set MACC free
	MOV	E, A	; Opcode in E
	DAD	D
	DAD	D
	DAD	D	; Find routine in table
	XTHL		; Addr routine on stack pntr to 2nd operand in HL
	RET		; Perform routine
;
; If an unitary operation
;
; Entry: HL: Points to operand (0 if in MACC)
;        E:  Full opcode
;        A:  Lower 5 bits opcode
;        Returnaddr on stack (E8DC)
; Exit:  Result in MACC
;        ABCDEHL preserved
;
LE89F	PUSH	PSW
	MOV	A, H
	ORA	L
	JZ	@E8A7	; If operand in MACC
	ROMCALL(4, $0C)	; Else: operand in MACC
@E8A7	POP	PSW
	RZ		; Ready if unitary '+'
	CMP	E	; Bits 6, 7 opcode 0?
	JZ	@E8BE	; Then change MACC to INT
	CPI	$1E	; INOT?
	JC	@E8BB	; Then change sign MACC (INT)
	JNZ	@E8B8	; Then convert MACC to FPT
	ROMCALL(4, $6C)	; Perform INOT
	RET
@E8B8	ROMCALL(4, $4B)	; Convert MACC to FPT
	RET
@E8BB	ROMCALL(4, $60)	; Change sign MACC (INT)
	RET
@E8BE	CPI	$1D
	JZ	@E8C6	; Then change sign MACC (FPT)
	ROMCALL(4, $48)	; Convert MACC to INT
	RET
;
@E8C6	ROMCALL(4, $1B)	; Change sign MACC (FPT)
	RET
;
; If relational numeric operation
;
; Entry: 1st operand in MACC, 2nd operand on stack.
;        E: Ful1 opcode
;        A: Lowest 5 bits opcode
; Exit:  BC preserved
;        DEHL corrupted
;
LE8C9	POP	H	; Get pntr 2nd operand
	CMP	E
	JZ	@E8D6	; Jump if FPT
	CALL	XICOMP	; Compare 2 INT numbers
@E8D1	POP	H	; Kill returnaddr
	POP	H	; Kill saved DE
	JMP	ROREL	; Return 1ogical result
@E8D6	CALL	XFCOMP	; Compare 2 FPT numbers
	JMP	@E8D1
;
; MOVE OPERAND
;
; REX.. routines return here after operation.
; Moves operand to proper 1ocation after computing.
;
; Entry: DE and returnaddress on stack
; Exit:  ABC preserved
;
LE8DC	POP	D
	DCR	D
	INR	D	; Check D=0 (MACC free)
	MVI	D, $FF
	LXI	H, $0000	; Flag 'result in MACC'
	RZ		; Abort if operand in MACC
	LXI	H, WORKE	; Addr WORKE
	ROMCALL(4, $0F)	; Copy MACC to WORKE
	CALL	XPOF	; Restore old MACC fram stack
	RET
;
; TABLE OF JUMPS TO INT/FPT OPERATOR ROUTINES
;
ROFTAB	ROMCALL(4, $00)	; MFADD; +
	RET
	ROMCALL(4, $03)	; MFSUB; -
	RET
	ROMCALL(4, $09)	; MFDIV; /
	RET
	ROMCALL(4, $06)	; MFMUL; *
	RET
	ROMCALL(4, $24)	; MPWR; ^
	RET
ROITAB	ROMCALL(4, $4E)	; MIADD; +
	RET
	ROMCALL(4, $51)	; MISUB; -
	RET
	ROMCALL(4, $57)	; MIDIV; /
	RET
	ROMCALL(4, $54)	; MIMUL; *
	RET
	.byte	$00,$00,$00
	.byte	$00,$00,$00
	.byte	$00,$00,$00
	.byte	$00,$00,$00
	.byte	$00,$00,$00
;
	ROMCALL(4, $63)	; MIAND
	RET
	ROMCALL(4, $66)	; MIOR
	RET
	.byte	$00,$00,$00
	ROMCALL(4, $69)	; MIXOR
	RET
	ROMCALL(4, $6F)	; MSHL
	RET
	ROMCALL(4, $72)	; MSHR
	RET
	ROMCALL(4, $5A)	; MIREM
	RET
;
;
;
;
; *************************
; * LENGTH OF BLOCK IN BC *
; *************************
;
; Part of Run 'CLEAR' (D214)
;
LE92D	CALL	SUBDE	; Calc. 1ength of block
	MOV	B, H
	MOV	C, L	; Length in BC
	RET
;
; **********************
; * EVALUATE A COMPARE *
; **********************
;
; Decodes flags and opcode to a truthtable. Following a XFCOMP or a XICOMP
; by a jump to ROREL 1eaves FF (true) or 00 (false) in A as result.
;
; Entry:  E: Opcode
;         F: Flags
; Exit:   BCDEF preserved
;         HL corrupted
;         A: Truth value
;
ROREL	PUSH	PSW	; Save flags
	MOV	A, E
	ANI	$0F	; Calc offset
	ADD	A
	ADD	A
	LXI	H, BASETT	; Base addr
	CALL	DADA	; Add offset to base
	POP	PSW	; Restore flags
	MVI	A, $FF	; Init truth value
	PCHL		; Goto routine
;
BASETT	.equ	*
;
ROGQ	RP		; FF if MACC >= M
	JMP	RFALSE	; S=0
;
ROGT	JM	RFALSE	; FF if MACC > M
	NOP		; (S=0 and Z=0)
;
RONEQ	RNZ		; FF if MACC <> M
	JMP	RFALSE	; (Z=0)
;
ROLEQ	RZ		; FF if MACC <= M
	NOP		; (S=1 or Z=1)
	NOP
	NOP
;
ROLT	RM		; FF if MACC = M
	JMP	RFALSE	; (S=1)
;
ROEQ	RZ		; FF if MACC M
			; (Z=1)
;
RFALSE	CMA		; 00 if condition false
	RET
;
; ****************************
; * RUN A VARIABLE REFERENCE *
; ****************************
;
; Produces a pointer to the value of a variable. The variable may be simple or subscripted
; and of any type. If subscripted, subscripts are evaluated and checked for range.
;
; Entry: BC: Points to encoded variable
;        D:  0 if MACC free
; Exit:  BC updated
;        DE preserved
;        F  corrupted
;        HL: Points to variable storage
;        A:  Type of variable from symbol table
;
RARRN	PUSH	D
	XRA	A	; Array name only
;
RVREN	MVI	D, $00
	JMP	LD73D	; Run varptr
;
	.byte	$FF, $FF
;
; *************************************
; * RUN VARPTR (ARRAY WITH ARGUMENTS) *
; *************************************
;
; Runs a varptr with A=FF, D=0.
;
; Exit:  BC updated
;        DE preserved
;        HL: varptr
;        A:  T/L byte
;        MACC corrupted
;
RVAR	PUSH	D
	MVI	A, $FF	; Set mask for arrays (not name only)
	JMP	RVREN	; Run varptr
;
	.byte	$FF, $FF
;
; **************************
; * RUN A VARIABLE POINTER *
; **************************
;
; RVARE: Entry for arrays.
; RVR05: Normal entry.
;
; Entry: BC: Points to var. reference in program
;        A:  Mask
;        D:  0 if MACC free
; Exit:  HL: Varptr (for strings: stringpntr)
;        A:  T/L of symtab.
;        BC updated
;        DE preserved
;
RVARE	MVI	A, $FF	; Not array name only
RVR05	PUSH	PSW
	PUSH	D
	LDAX	B
	INX	B
	ANI	$3F	; Get offset in syntab
	MOV	D, A	; in DE
	LDAX	B
	INX	B
	MOV	E, A
	LHLD	STBBGN	; Get start symtab
	DAD	D	; HL pnts to actual addr is symtab
	POP	D
	POP	PSW	; Restore mask
	ANA	M	; And with T/L byte
	ANI	$40	; Bit 6 only
	MOV	A, M
	INX	H
	RZ		; Abort if simple variable or array name only
;
; Compute actual position in array
;
	DCR	D
	INR	D	; Check D=0: MACC freee
	CNZ	XPLISH	; Save MACC on stack if not
	PUSH	D
	PUSH	PSW
	MOV	E, M	; Get pntr from symtab
	INX	H	; in DE
	MOV	D, M
	INX	H
	MOV	A, D	; Check if undimensioned
	ORA	E
ERRUA	MVI	A, $0F	; Then run error 'UNDEFINED ARRAY'
	JZ	ERROR
	PUSH	D
	LXI	H, $0000	; Init index
	XTHL		; Pntr to array in HL
	LDAX	B	; Get nr of subscripts
	INX	B
	MOV	D, A	; in D
	CMP	M	; Comp. with nr of dimensions
	INX	H
	JNZ	ERRBS	; Run 'SUBSCRIPT ERROR' if not identica1
@E9A2	CALL	REX1	; Get variable type in A
	CMP	M
	JC	@E9B1	; If value in A is offset
	JZ	@E9B1
	MVI	A, $05	; If subscript < 0 or > $FF
	JMP	ERROR	; Run 'SUBSCRIPT ERROR'
;
; Calc reference to Nth array element via (a1 * (d2 + 1) + a2 * (d3 + 1) + .. + aN).
; aN is argument, dN is dimension
;
@E9B1	XTHL		; Restore HL=00
	CALL	DADA	; Add offset to index
	DCR	D	; decr nr of arguments
	XTHL
	INX	H
	JZ	@E9C5	; IF no more subscripts
	MOV	A, M	; Next dimension
	INR	A
	XTHL
.if ROMVERS == 11
	CALL	RDM40	; Another calculation routine is used
.endif
.if ROMVERS == 10
	CALL	HLMUL	; Multiply index by it
.endif
	XTHL
	JMP	@E9A2	; Process next subscript
;
@E9C5	XCHG
	POP	H	; Get index to array from symtab
	POP	PSW	; Get type byte
	PUSH	PSW
	ANI	$30	; Bits 5, 6 only
	CPI	$20
	DAD	H	; Add offset to elementt
	JZ	@E9D2
	DAD	H
@E9D2	DAD	D	; Abs addr of element in HL (STR: Pntr to string)
	POP	PSW
	POP	D
	CNZ	XPOF	; Evt retrieve MACC from stack
	RET
; ****************************
; * EVALUATE A FUNCTION CALL *
; ****************************
;
; Finds address of function routine in indirection table (FUNIT) and performs the
; function routine.
;
; Entry: EC: Points to function 1abel ($20) in program line
; Exit:  MACC: Numeric result
;        BC updated
;        AFDEHL corrupted
;
RFUN	INX	B	; Pnts past label
	LDAX	B	; Get fuunction code
	INX	B
	MOV	L, A	; Code in HL
	MVI	H, $00
	LXI	D, FUNIT	; Get startaddr. table
	DAD	H	; Code * 2
	DAD	D	; Add offset to start addr
	MOV	E, M	; 1obyte addr in E
	INX	H
	MOV	A, M	; hibyte addr in A
	ORI	$80	; Set msb = 1
	MOV	D, A	; hibyte in D
	CMP	M	; Was it already E...?
	PUSH	D	; Addr function on stack
	CZ	REXNA	; Then evaluate 1st num expr, result in MACC
	RET		; Go to function routine
;
; ******************************
; * FUNCTION INDIRECTION TABLE *
; ******************************
;
; Startaddress table is FUNIT. The function code is given between brackets.
; If the msb of the address is set, the first argument is a numeric one.
; In the textbuffer, the Basic fuctions are indicated by 20 xx (xx is function code).
;
FUNIT	.equ	*
	_FUNC(0, RABS)	; (00) ABS
	_FUNC(0, RALOG)	; (01) ALOG
	_FUNC(1, RASC)	; (02) ASC
	_FUNC(1, RCHR)	; (03) CHR$
	_FUNC(1, RCURX)	; (04) CURX
	_FUNC(1, RCURY)	; (05) CURY
	_FUNC(0, REXP)	; (06) EXP
	_FUNC(0, RFRAC)	; (07) FRAC
	_FUNC(1, RFRE)	; (08) FRE
	_FUNC(0, RFREQ)	; (09) FREQ
	_FUNC(1, RGETC)	; (0A) GETC
	_FUNC(1, RHEX)	; (0B) HEX$
	_FUNC(1, RINP)	; (0C) INP
	_FUNC(0, RINT)	; (0D) INT
	_FUNC(1, RLEFT)	; (0E) LEFT$
	_FUNC(1, RLEN)	; (0F) LEN
	_FUNC(1, RVPT)	; (10) VARPTR
	_FUNC(0, RLOG)	; (11) LOG
	_FUNC(0, RLOGT)	; (12) LOGT
	_FUNC(1, RXMAX)	; (13) XMAX
	_FUNC(1, RYMAX)	; (14) YMAX
	_FUNC(1, RMID)	; (15) MID$
	_FUNC(1, RPDL)	; (16) PDL
	_FUNC(1, RPEEK)	; (17) PEEK
	_FUNC(1, RPI)	; (18) PI
	_FUNC(1, RRIGHT)	; (19) RIGHT$
	_FUNC(0, RRND)	; (1A) RND
	_FUNC(1, RSCRN)	; (1B) SCRN
	_FUNC(0, RSGN)	; (1C) SGN
	_FUNC(1, RSPC)	; (1D) SPC
	_FUNC(0, RSQR)	; (1E) SQR
	_FUNC(0, RSTR)	; (1F) STR$
	_FUNC(1, RTAB)	; (20) TAB
	_FUNC(1, RVAL)	; (21) VAL
	_FUNC(0, RSIN)	; (22) SIN
	_FUNC(0, RCOS)	; (23) COS
	_FUNC(0, RTAN)	; (24) TAN
	_FUNC(0, RASIN)	; (25) ASIN
	_FUNC(0, RACOS)	; (26) ACOS
	_FUNC(0, RATN)	; (27) ATN
;
;
;
; ****************************
; * part of RUN TALK (0E67B) *
; ****************************
;
; Sets oscillator volumes.
;
; Entry: A:  New volume.
;        HL: Address POROM/POR1M
;
LEA40	MOV	M, A	; Update POROM/POR1M
	LXI	D, $FA70
	DAD	D	; HL = POR0/POR1
	MOV	M, A	; Update osc. volume
	POP	H	; Get parameter pntr
LEA47	INX	H	; Pnts to next code
	JMP	LCD67	; Handle next code
;
	.byte	$FF,$FF,$FF,$FF,$FF
;
; *************************
; * RUN basicfunction ABS *
; *************************
;
RABS	ROMCALL(4, $18)	; MFABS
	RET
;
; **************************
; * RUN basicfunction ALOG *
; **************************
;
RALOG	ROMCALL(4, $30)	; MALOG
	RET
;
; *************************
; * RUN basicfunction EXP *
; *************************
;
REXP	ROMCALL(4, $2A)	; MEXP
	RET
;
; ************************
; RUN basicfunction FRAC *
; ************************
;
RFRAC	ROMCALL(4, $21)	; MFRAC
	RET
;
; *************************
; * RUN basicfunction LOG *
; *************************
;
RLOG	ROMCALL(4, $27)	; MLOG
	RET
;
; **************************
; * RUN basicfunction LOGT *
; **************************
;
RLOGT	ROMCALL(4, $2D)	; MLOGT
	RET
;
; *************************
; * RUN basicfunction SQR *
; *************************
;
RSQR	ROMCALL(4, $33)	; MSQR
	RET
;
; *************************
; * RUN basicfunction SIN *
; *************************
;
RSIN	ROMCALL(4, $36)	; MSIN
	RET
;
; *************************
; * RUN basicfunction COS *
; *************************
;
RCOS	ROMCALL(4, $39)	; MCOS
	RET
;
; **************************
; * RUN basicf unction TAN *
; **************************
;
RTAN	ROMCALL(4, $3C)	; MTAN
	RET
;
; **************************
; * RUN basicfunction ASIN *
; **************************
;
;
RASIN	ROMCALL(4, $3F)	; MASIN
	RET
;
; **************************
; * RUN basicfunction ACOS *
; **************************
;
RACOS	ROMCALL(4, $42)	; MACDS
	RET
;
; **************************
; * RUN basicfunction ATAN *
; **************************
;
RATN	ROMCALL(4, $45)	; MATAN
	RET
;
; **************************
; * RUN basicfunction STR$ *
; **************************
;
; Converts a FPT number into a string.
;
RSTR	CALL	FBCP	; Convert MACC for FPT output string in DECBUF
	NOP
	NOP
	NOP
LEA7D	LHLD	PDECBUF	; Get addr DECBUF
	MVI	E, $01	; Pretend it is a variable
	RET
;
; **************************
; * RUN basicfunction HEX$ *
; **************************
;
; Converts a INT number into an equivalent hex string.
;
RHEX	CALL	REXNA	; Eval expr, result in MACC
	CALL	XHBC	; Conv. MACC to HEX for output
	JMP	LEA7D	; Get addr DECBUF, pretend it is a variable
;
; *************************
; * RUN basicfunction SPC *
; *************************
;
; Returns a string of a number of spaces.
; From SPC10 used by TAB if DOUTC <> 0.
;
RSPC	CALL	REXI1	; Get nr of spaces in A
;
; Entry from RTAB
;
LEA8F	CALL	SHREQ	; Get place in heap for string of spaces
	PUSH	H	; Save pntr to heap
@EA93	ORA	A
	JZ	@EA9E	; Jump if ready
	INX	H
	MVI	M, $20	; Space into heap
	DCR	A
	JMP	@EA93	; Next space
@EA9E	POP	H	; HL pnts to start string
	JMP	LEADF	; Pretend it is a temp string
;
; *************************
; * RUN basicfunction TAB *
; *************************
;
; Returns a string of spaces to move cursor to a given character position (only to
; the right).  Works only if output switch DOUTC=0, else it returns one space only.
;
RTAB	CALL	LCE60	; Get nr of tabs in L, DOUTC in A
.if ROMVERS == 11
; The old routine worked only for DOUTC=0. Now DOLWTC is not checked anymore, but the Z-f1ag
; set by CE60 is evaluated. If Z=1 (all OK), the TAB-instruction is executed. If Z=0, then
; the number of tab's is not correct. Then only one space is printed
	RAR		; Dummy to preserve Z-flag
.endif
.if ROMVERS == 10
	ORA	A	; Check output direction
.endif
	MVI	A, $01	; Init 1 space
	JNZ	LEA8F	; Jump if DOUTC <> 0
	MOV	A, L	; Get nr of tabs
	NOP
	NOP
	ROMCALL(5, $0C)	; Ask cursor pos and size and char screen
	SUB	L	; Calc nr of spaces reqd
	JNC	LEA8F	; Run SPC if not past tab pos
	XRA	A	; If past TAB
	JMP	LEA8F	; Run SPC for no spaces
;
; **************************
; * RUN basicfunction CURX *
; **************************
;
RCURX	ROMCALL(5, $0C)	; Ask cursor pos and size and char screen
	MOV	A, L	; x-coord in A
	JMP	FR1BY	; and into MACC
;
; **************************
; * RUN basicfunction CURY *
; **************************
;
RCURY	ROMCALL(5, $0C)	; Ask cursor pos and size and char screen
	MOV	A, H	; Y-coord in A
	JMP	FR1BY	; and in MACC
;
; *************************
; * RUN basicfunction LEN *
; *************************
;
; Given a string, returns length of the string.
;
RLEN	CALL	REXSR	; Eval string expr
LEAC7	MOV	A, M	; Get length in A
	JMP	FR1BY	; and into MACC
;
; *************************
; * RUN basicfunction ASC *
; *************************
;
; Given a string returns ASCII value of 1st char.
;
RASC	CALL	REXSR	; Eval string expr
	MOV	A, M	; Get length in A
	JMP	LCF7E	; Check if length is 0; get 1st char in MACC if not
;
; **************************
; * RUN basicfunction CHR$ *
; **************************
;
RCHR	CALL	REXI1	; Get argument value in A
	PUSH	PSW	; Save 1t
	MVI	A, $01
	CALL	SHREQ	; Find place in heap for a 1-byte string
	POP	PSW	; Get argument
	INX	H
	MOV	M, A	; Store it in Heap
	DCX	H	; Pnts to length byte
;
; Entry from 'SPC'
;
 LEADF	MVI	E, $02	; Status: temporary
	RET
;
; ***************************
; * RUN basicfunction LEFT$ *
; ***************************
;
; Given a string, returns a number of characters from the 1eft end.
;
RLEFT	CALL	REXPS	; Eval string expr
	PUSH	H	; Save string pntr
	PUSH	D
	CALL	REXIK	; Reqd length in A
	MVI	D, $00
LEAEC	MOV	E, A	; Length in DE
LEAED	CALL	SHMID	; Extract substring
	JNC	ERRRA	; Evt. run error 'NUMBER OUT OF RANGE'
	POP	D
	XTHL
	MOV	A, E	; Get status
	CPI	$02	; Temporary?
	CZ	SHREL	; Then clear heap entry
	POP	H
	MVI	E, $02	; Status temporary
	RET
;
; ****************************
; * RUN basicfunction RIGHT$ *
; ****************************
;
; Extracts a number of characters from the right end of a given string.
;
RRIGHT	CALL	REXPS	; Eval string expr
	PUSH	H	; Save string pntr
	PUSH	D
	CALL	REXIK	; Get length substring
	MOV	E, A	; in E
	MOV	A, M	; Get total string 1ength
	SUB	E
	MOV	D, A	; Startposition in D
	JMP	LEAED	; Extract substring
;
; **************************
; * RUN basicfunction MID$ *
; **************************
;
RMID	CALL	REXPS	; Eval string expr
	PUSH	H	; Save string pntr
	PUSH	D
	CALL	REXIK	; Get startposition
	MOV	D, A	; in D
	CALL	REXI1	; Get 1ength in A
	JMP	LEAEC	; Extract substring
;
; ******************************
; * GET VALUE OF ARGUMENT IN A *
; ******************************
;
; Exit: DEHL preserved
;
REXIK	PUSH	H
	PUSH	D
	CALL	REXI1	; Get value of argument in A
	POP	D
	POP	H
	RET
;
; *************************
; * RUN basicfunction VAL *
; *************************
;
; Takes a string and converts it to a FPT number.
;
RVAL	CALL	REXSR	; Eval string expr
	PUSH	B
SUEPT	MOV	A, M	; Length of string in A
	STA	EFECT	; and in EFECT
	INX	H	; HL pnts to 1st string byte
	SHLD	EFEPT	; Addr into EFEPT
	MVI	C, $00	; Char Count
	LXI	H, EFSW
	MVI	M, $01	; Input from string
	CALL	XFCB	; encode FPT number into MACC
	DCR	M	; Input from keyboard
	MVI	A,$0A	; If over/underflow run
	JNC	ERROR	; error 'INVALID NUMBER'
	POP	B
	RET
;
; *************************
; * RUN basicfunction FRE *
; *************************
;
; Returns a INT given size of free RAM space.
; Result in MACC.
; FR2BY: Also used to copy HL into MACC.
;
; Exit: BC preserved
;       AFDEHL corrupted
;
RFRE	CALL	SIZE	; Calc free RAM space in HL
FR2BY	XRA	A
	PUSH	B
	PUSH	D
	MOV	C, H	; Free space in CD
	MOV	D, L
	MOV	B, A	; A,B=0
	ROMCALL(4, $12)	; Copy reg A, B, C, D into MACC
	POP	D
	POP	B
	RET
;
; ****************************
; * CALCULATE FREE RAM SPACE *
; ****************************
;
; Exit: HL: Free RAM space
;       DE: STBUSE
;       ABC preserved
;       F   corrupted
;
SIZE	LHLD	STBUSE	; Get end syntab
	XCHG		; in DE
	LHLD	SCRBOT	; Get bottom screen RAM
	CALL	SUBDE	; Calc. free space in HL
	RET
;
; **************************
; * RUN basicfunction FREQ *
; **************************
;
; Given a frequency in Hz, returns a period in 'oscillator cycles' (INT).
;
; Entry: MACC: Value for freq
; Exit:  BC preserved
;        AFDEHL corrupted
;
RFREQ	LXI	H, WORKE	; Startaddr scratch area for expresion evaluation
	ROMCALL(4, $0F)	; Copy reqd freq to scratch area
	PUSH	H	; Save Startaddr scratch area
	LXI	H, FPOSC	; Addr sound constant
	ROMCALL(4, $0C)	; Sound constant into MACC
	POP	H	; Get start scratch area
	ROMCALL(4, $09)	; Calc sound const/reqd freq
	ROMCALL(4, $48)	; Change it to INT
	PUSH	B
	ROMCALL(4, $15)	; Copy result to reg A, B, C, D
	ORA	B	; >64K? Then run error 'NUMBER OUT OF RANGE'
	JNZ	ERRRA
	POP	B
	RET
.if ROMVERS == 11
; Better entry to keyboard scan routine to avoid keybounce
RGETC 	XRA	A
 	STA	KNSCAN	; Clear breakflag
 	CALL	GETC	; Run GETC
.endif
.if ROMVERS == 10
;
; *******************
; * DATA (not used) *
; *******************
;
LEB75	.byte $15, $F4, $24, $00	; Sound constant
.endif
;
; **************************
; * RUN basicfunction GETC *
; **************************
;
; Gets one character from keyboard. Returns its ASCII value in MACC; 0 if no inputs.
; FR1BY: Also used to copy 1 byte into MACC.
;
.if ROMVERS == 10
RGETC	CALL	FGETC	; Scan keyboard, result in A
.endif
FR1BY	MOV	L, A	; Result in L
	MVI	H, $00
	JMP	FR2BY	; Result into MACC
;
; *************************
; * RUN basicfunction INP *
; *************************
;
; Reads a byte from a Real World address (DCE-bus).
;
RINP	CALL	REXI1	; Get RW addr in A
	MOV	D, A	; and in D
	CALL	RWIP	; Get input from DCE-bus
	MOV	A, E	; Result in A
	JMP	FR1BY	; Result into MACC
;
; *************************
; * RUN basicfunction INT *
; *************************
;
; Returns an integer FPT value, just less than the FPT argument given.
;
RINT	PUSH	B
	ROMCALL(4, $15)	; Copy MACC to reg A, B, C, D
.if ROMVERS == 11
; Running INT on a number with value 0 gave as result: -1.
; Now this failure is corrected.
	LXI	H, WORKE
	ROMCALL(4, $0F)	; Copy MACC to WORKE
	POP	B
	ROMCALL(4, $1E)	; MACC = INT(MACC)
	ORA	A	; Set f1ags on exp byte
	RP		; Ready if nr positive
	JMP	LCEC5
.endif
.if ROMVERS == 10
; REMARK: Routine is wrong if -1 < nr < 0. Then the result is -1!
	POP	B
	ROMCALL(4, $1E)	; Change MACC to INT, and then to FPT
	LXI	H, FPM1B	; Addr FPT(-1)
	ORA	A
	JP	@EB9C	; Abort if positive
	ROMCALL(4, $00)	; Add -1 if MACC negative
@EB9C	RET
.endif
;
; *******************
; * DATA (not used) *
; *******************
;
LEB9D	.byte	$81, $80, $00, $00	; FPT (-1)
;
; ****************************
; * RUN basicfunction VARPTR *
; ****************************
;
RVPT	CALL	RVAR	; Get varptr in HL, T/L in A
	JMP	FR2BY	; Varptr into MACC
;
; **************************
; * RUN basicfunction XMAX *
; **************************
;
RXMAX	CALL	LEBB4	; Get max Y, X-coord graph area
	XCHG		; Max X-coord in HL
	JMP	FR2BY	; and into MACC
;
; **************************
; * RUN basicfunction YMAX *
; **************************
;
RYMAX	CALL	LEBB4	; Get max Y, X-coord graph area
	JMP	FR1BY	; Max Y-coord into MACC
;
; *******************************************
; * GET MAX. Y, X-COORDINATES GRAPHICS AREA *
; *******************************************
;
; Exit: DE: Max. X-coordinate
;        A: Max. Y-coordinate
;       BC  preserved
;
LEBB4	LXI	H, $0000	; Coord dot 0, 0
	PUSH	B
	MOV	C, H
	ROMCALL(5, $27)	; Ask colour of point and size graphics screen
	JC	SCRER	; Evt run screen error
	MOV	A, B	; Max Y-coord in A
	POP	B
	RET
;
; *************************
; * RUN basicfunction PDL *
; *************************
;
; A given paddle channel is enabled. Counter 0 is set to $FFFF.
; The counter is read over and over unti1 it is counted out.
;
; Exit: BC updated
;       AFDEHL corrupted
;
RPDL	MVI	A, $05
	CALL	REXIL	; Get paddle select (0-5)
	MOV	D, A	; into D
	LDA	POROM	; Get POROM
	ANI	$F8	; ROM/cass. select only
	ORA	D	; OR with paddle select
	ORI	$08	; Paddle enable
	CALL	LD808	; Load PORO/POROM
	PUSH	B
	MVI	A, $30
	LXI	B, SNDC	; Addr 8253 cmd word
	STAX	B	; Select ch.0, mode 0, 2 byte
	LXI	H, $FFFF
	SHLD	PDLCH	; Load counter ch.0
	LDA	PDLST	; Get pdl timer trig impulse (Uselessi: A is cleared in 0EBE3)
@EBE2	XCHG		; DE = $FFFF
	MVI	A, $00
	STAX	B	; (FC06)=00: counter 0, 1atch operation
	LHLD	PDLCH	; Get contents counter
	CALL	COMP	; Compare HL-DE
	JC	@EBE2	; Again if DE > HL
	CALL	CMPHL	; HL = 2-compl. of HL
	LXI	D, $FFCE	; Substract 49
	DAD	D
	JC	@EBFC	; If result negative
	LXI	H, $0000
@EBFC	MOV	A, H
	ORA	A
	JZ	@EC06
	MVI	L, $FF
	NOP
	NOP
	NOP
@EC06	MVI	A, $36
	STAX	B	; (FC06)=$36 Chan 0, mode 3
	LDA	POROM	; Get PORO/POROM
	ANI	$F0	; Disable paddle operation
	CALL	LD806	; Load PORO/POROM
	POP	B
	MOV	A, L	; A=0 if result negative, else FF
	JMP	FR1BY	; Move A into MACC
;
;
;
; **************************
; * RUN basicfunction PEEK *
; **************************
;
; Returns the contents of a memory 1ocation with an address given as INT argument.
;
RPEEK	CALL	REXI2	; Get addr in HL
	MOV	A, M	; Get its contents
	JMP	FR1BY	; Move it into MACC
;
; ************************
; * RUN basicfunction PI *
; ************************
;
; Returns a value of 3.14159.
;
RPI	LXI	H, FPPI	; Addr FPT (PI)
	ROMCALL(4, $0C)	; FPT (PI) into MACC
	RET
;
; *********************
; * DATA - (not used) *
; *********************
;
LEC23 .byte $02, $C9, $0F, $DB	; FPT (PI)
;
; *************************
; * RUN basicfunction RND *
; *************************
;
; Returns a random or pseudo-randam number.
; If argument > 0: Returns a pseudo-random number in the range 0 <= R < argument.
; If argument = 0: Returns an hardware random number 0 < R < 1.
; If argument < 0: Number replaces the kernel for calculating further pseudo-random numbers.
;
RRND	CALL	FTEST	; Test if arg is 0
	JZ	RRAND	; Then hardware random
	LXI	H, RNUM	; Addr random number kernel
	JP	@EC35	; If pseudo random number
	ROMCALL(4, $0F)	; Copy MACC to kernel
@EC35	XCHG
	LXI	H, WORKE	; Addr scratch area WORKE
	ROMCALL(4, $0F)	; Copy MACC to WORKE
	PUSH	H	; Saveaddr WORKE
	XCHG
	PUSH	H	; Save addr RNUM
	MVI	M, $01	; Limit range 1-2
	ROMCALL(4, $0C)	; Copy last nr from RNUM into MACC
	MVI	D, $05
@EC44	LXI	H, RNDA	; Addr RNDA
	ROMCALL(4, $54)	; Multipiy R0 * RNDA
	LXI	H, RNDB	; Addr RNDB
	ROMCALL(4, $4E)	; Add RNDB to R0 * RNDA
	NOP
	NOP
	NOP
	NOP
	NOP
	LXI	H, IRAND	; Addr AND mask
	ROMCALL(4, $63)	; IAND pick out mantissa
	LXI	H, IROR	; Addr OR mask
	ROMCALL(4, $66)	; IOR: set mantissa top bit, + range 1-2
	DCR	D
	JNZ	@EC44	; Again if D<>0
	POP	H	; Get addr RNUM
	ROMCALL(4, $0F)	; Copy MACC to RNUM
	LXI	H, FPM1B	; Addr FPT (-1)
	ROMCALL(4, $00)	; Add -1 to MACC (range 0-1)
	POP	H	; Get addr WORKE
	ROMCALL(4, $06)	; Frig range: multiply MACC*(WORKE)
	RET
;
; ***************************
; * part of RUN TALK (CD64) *
; ***************************
;
; Entry: Z=1 Code = $0C (delay)
;        Z=0 Code = $0D (ML Call)
;
LEC6D	MOV	E, M
	INX	H	; Wait-time/ML address
	MOV	D, M	; in HL
	INX	H
.if ROMVERS == 11
; A bug is removed, caused by XCHG in $EC71. The return from $EC78 (JMP $CD67) could not be
; executed correctly, because of a wrong address stored in the HL-registers. This problem
; existed only forthe 'TALK'-Codes $0C (wait) and $0D (ML cal1).
;
; Entry: DE: Wait time or address ML-routine.
;
	CZ	LDACC	; If to be waited
	CNZ	LCD62	; Goto MLP address
	JMP	LCD67	; Handle next code
	.byte	$FF
.endif
.if ROMVERS == 10
	XCHG
	CZ	LDACC	; If to be waited
	CNZ	DCALL	; Else: Run ML routine
	JMP	LCD67	; Return; Handle next code
.endif
;
; *************************
; * RUN basicfunction SGN *
; *************************
;
; Takes a FPT value and returns:
;             +1 value is positive
;              0 if value is zero
;             -1 if value is negative
;
RSGN	CALL	FTEST	; Test 1f variable is zero
	RZ		; Then ready
	LXI	H, FPM1B	; Addr FPT (-1)
	ROMCALL(4, $0C)	; Copy -1 into MACC
	JM	@EC89	; Ready if already negative
	ROMCALL(4, $1B)	; Else change sign MACC make MACC +1
@EC89	RET
;
; ***********************
; * TEST A FPT VARIABLE *
; ***********************
;
; Entry: Variable in MACC.
; Exit:  Z=l: Variable is zero.
;        Z=0: Other f1ags set on exponent byte of variable.
;        ABCDEHL preserved
;
FTEST	PUSH	B
	PUSH	D
	PUSH	PSW
	ROMCALL(4, $15)	; Copy Macc to reg A, B, C, D
	MOV	E, A	; Exp byte in E
	ORA	B
.if ROMVERS == 11
; The old routine tested all bytes of the FPT nr. Now only the exponent byte and the hibyte
; of the mantissa is tested. In this way, very small FPT numbers are considered to be zero.
	JZ	@EC98	; Abort if A and B are 0
	MOV	A, E	; Exp byte in A
	ORI	$01	; Clar CY-flag
	NOP
.endif
.if ROMVERS == 10
	ORA	C	; Check if nr is zero
	ORA	D
	JZ	@EC98	; Then quit
	MOV	A, E	; Get exp byte
	ORA	A	; Set f1ags on it
.endif
@EC98	POP	D
	MOV	A, D
	POP	D
	POP	B
	RET
;
; **************************
; * RUN basicfunction SCRN *
; **************************
;
RSCRN	CALL	RCOOR	; Eval given coord
	PUSH	B
	MOV	C, A	; Y-coord in C
	ROMCALL(5, $27)	; Ask colour of dot an screen + size graphics screen
	POP	B
	JC	SCRER	; Evt run screen error
	JMP	FR1BY	; Contents screen 1oc in MACC
;
;
;     ============
; *** LIST HANDLER ***
;     ============
;
; This module 1ists a program from the textbuffer onto the screen (or into other
; required direction)
;
; ***********************
; * LIST A PROGRAM LINE *
; ***********************
;
; Entry: BC: Points to start of textline
; Exit:  BC: Points to start of next line
;        DEHL preserved
;        AF corrupted
;
SLINE	PUSH	D
	PUSH	H
	INX	B	; Pnts to line nr
	CALL	LEFAE	; List line nr
	MVI	A, $08
	CALL	SCTAB	; Cursor to tab 8
@ECB6	CALL	SCOM	; List statement
	LDAX	B	; Get next byte
	ORA	A
	JP	@ECC5	; If no more statements
	CALL_B(SCHRI, ':') 	; Else: print ':'
	JMP	@ECB6	; List next statement
@ECC5	CALL_B(SCHRI, $0D) 	; print car.ret
	POP	H
	POP	D
	RET
;
; ********************
; * LIST A STATEMENT *
; ********************
;
; Based on the token in the textbuffer, a particular statement wi11 be printed.
; At first, the Basiccommand will be printed. The pointers to the particular strings are
; in a table starting at LCD8B. The base for the table is LCC08; the offset is calculated
; by TOKEN * 3.
;
; The databyte after the stringaddress pointer indicates which 1ist-routine has to be used
; for the rest of the statement. This byte is a offset for table LECF8.
;
; Entry: BC: Points to token
; Exit:  BC: Points to next statement
;        AFDEHL corrupted
;        On stack: Returnaddress from this subroutine.
;
SCOM	LDAX	B	; Get token
	INX	B	; Update pointer
	MOV	E, A	; token in E
	MVI	D, $00
	LXI	H, CDTAB - 3 * $81	; Startaddr stringtable
	DAD	D	; Add 3 token
	DAD	D
	DAD	D
	MOV	E, M	; Get lobyte stringaddr
	INX	H
	MOV	D, M	; Get hibyte stringaddr
	INX	H	; Point to data after addr
	XCHG		; Stringaddr in HL
	MOV	A, M	; Get 1ength byte of string
	ORA	A	; Length=0?
	CALL	PSTR	; List Basiccmd string
	LDAX	D	; Get data byte after string addres
	JZ	@ECEA	; If length string 0
	CPI	$00
	CNZ	SCHSP	; Print space if byte after stringaddr <> 0
@ECEA	LDAX	D	; Get data byte (= offset)
	ADD	A	; Offset * 2
	MOV	E, A	; in E
	MVI	D, $00
	LXI	H, HROUTINE	; Startaddr table Listroutines
	DAD	D	; Add offset
	MOV	E, M	; Get addr in DE
	INX	H
	MOV	D, M
	XCHG		; Addr routine in HL
	PCHL		; Go to this adress
;
; ***********************************
; * POINTERS LIST HANDLING RDUTINES *
; ***********************************
;
; Table with addresses of listroutines for the part of a statement after a token.
;
; Startaddress table is HROUTINE. The offset (given between brackets) is identical to the
; data byte after the addresses in the table on LCD8B.
;
HROUTINE	.word	SCN1	; (00) nothing more
	.word	SCN2	; (01) linenr
	.word	SCN3	; (02) linenr linenr (not used)
	.word	SCN5	; (03) unquoted string
	.word	SCN6	; (04) E (E=expr)
	.word	SCN7	; (05) E, E
	.word	SCN8	; (06) E	E
	.word	SCN9	; (07) E,E E
	.word	SCN10	; (08) E,E E,E E
	.word	SCN11	; (09) E E E E
	.word	SCN12	; (0A) E
	.word	SCN13	; (0B) linenr-linenr
	.word	SCN14	; (0C) sound
	.word	SC14A	; (0D) noise
	.word	SCN15	; (0E) envelope
	.word	SCN16	; (0F) mode
	.word	SCN17	; (10) input <string>
	.word	SCN18	; (11) input/read/dim
	.word	RDM40	; (12) (not used [*])
	.word	SCN20	; (13) let
	.word	SCN21	; (14) if then <E>
	.word	SCN22	; (15) if goto <linenr>
	.word	SC22A	; (16) if then <linenr>
	.word	SCN23	; (17) for to step
	.word	SCN24	; (18) next
	.word	SCN25	; (19) print
	.word	SCN26	; (1A) on goto
	.word	SCN27	; (1B) on gosub
	.word	SCN28	; (1C) callm
	.word	LEE94	; (1D) (not used [*])
	.word	LD89E	; (1E) savea/loada
;
; The vectors marked with [*] are no pointers to LIST routines.
;
	.byte	$FF, $FF, $FF, $FF
;
; *******************************
; * LIST NO FURTHER EXPRESSIONS *
; *******************************
;
SCN1	RET
;
; ***************************
; * LIST 1 OR 2 LINENUMBERS *
; ***************************
;
; SCN2: List 1 line number.
; SCN3: List 2 line numbers, separated by space (not used).
;
; Exit: BC updated
;       DE preserved
;       AFHL corrupted
;
SCN3	CALL	LEFAE	; List linenr
	CALL	SCHSP	; Print space
SCN2	JMP	LEFAE	; List linenr
;
; ************************
; * LIST UNQUOTED STRING *
; ************************
;
SCN5	JMP	SUQTS	; List unquoted string
;
; ***********************
; * LIST <EXPR>, <EXPR> *
; ***********************
;
; Exit: BC updated, DE preserved, AFHL corrupted.
;
SCN7	CALL	SCEXP	; List <expr>
SCOEX	CALL	SCHCO	; Print ','
SCN6	JMP	SCEXP	; List <expr>
;
; ************************************
; * LIST <EXPR> <EXPR> <EXPR> <EXPR> *
; ************************************
;
; Exit BC updated, DE preserved, AFHL corrupted.
;
SCN11	CALL	SEXPS	; List <expr>; print space
S3EXP	CALL	SEXPS	; List <expr>; print space
SCN8	CALL	SEXPS	; List <expr>; print space
	JMP	SCEXP	; List <expr>
;
; ********************************************
; *LIST <EXPR>, <EXPR> <EXPR>, <EXPR> <EXPR> *
; ********************************************
;
; *Exit: BC updated, DE preserved, AFHL corrupted.
; *
SCN10	CALL	SCN7	; List <expr>, <expr>
	CALL	SCHSP	; Print space
SCN9	CALL	SCN7	; List <expr>, <expr>
SCSEX	CALL	SCHSP	; Print space
	JMP	SCEXP	; List <expr>
;
; ********************************
; * LIST <EXPR>, <EXPR>(,<EXPR>) *
; ********************************
;
SCN12	CALL	SCN7	; List <expr>, <expr>
LED6E	LDAX	B	; Get next byte
	CPI	$FF	; Terminator?
	INX	B
	RZ		; Then abort
	DCX	B
	CALL	SCHCO	; Print ','
	JMP	SCEXP	; List <expr>
;
; **************************
; * LIST <LINENR>-<LINENR> *
; **************************
;
; Exit: BC updated, DE preserved, AFHL corrupted.
;
SCN13	CALL	LEFAE	; List linenr
	CALL_B(SCHRI, '-') 	; Print '-'
	JMP	LEFAE	; List linenr
;
; *********************************
; * LIST EXPRESSION AFTER 'SOUND' *
; *********************************
;
; Exit: BC updated, AFHL corrupted.
;       DE: preserved if ON, corrupted if OFF
;
SCN14	LDAX	B	; Get byte
	CPI	$FF	; OFF sign?
	CNZ	SEXPS	; If not: List <expr>, print space
	LDAX	B	; Get next byte
	CPI	$FF	; OFF sign?
	JNZ	SCN11	; If not: List <expr> <expr> <expr> <expr>; abort
LED90	CALL_W(STXTS, LED97)	; Else print 'OFF'
	INX	B
	RET
;
; DATA
;
LED97	PSTR("OFF")
;
; *******************************
; * LIST EXPRESSION AFTER NOISE *
; *******************************
;
; Exit: BC updated, E preserved, AFDHL corrupted.
;
SC14A	LDAX	B	; Get 1st byte NCB
	CPI	$FF	; OFF sign?
	JZ	LED90	; Then print OFF abort
	JMP	SCN8	; Else: List <expr> <expr>
;
; ************************************
; * LIST EXPRESSION AFTER 'ENVELOPE' *
; ************************************
;
; Exit: BC updated, E preserved, AFDHL corrupted.
;
SCN15	CALL	SEXPS	; List <expr>, print space
	LDAX	B	; Get length of expr
	INX	B
	MOV	D, A	; into D
@EDAA	DCR	D
	JM	@EDB8	; If ready
	CALL	SCN7	; List <V>,<T>
	CALL_B(SCHRI, ';') 	; Print ';'
	JMP	@EDAA	; Next <V>, <T>
@EDB8	LDAX	B	; Get 1ast byte of expr
	INX	B
	CPI	$FF	; Terminator?
	RZ		; Then abort
	DCX	B
	JMP	SCEXP	; List expr
;
; ********************************
; * LIST EXPRESSION AFTER 'MODE' *
; ********************************
;
SCN16	LDAX	B	; Get mode byte
	INX	B
	MVI	D, '0'
	ORA	A	; Mode 0 ($FF)?
	JM	@EDD4	; Then print '0'
	RAR		; CY=1 if A-mode
	INR	A
	PUSH	PSW
	ADD	D	; Convert to ASCII
	CALL	OUTC	; Print modern
	POP	PSW
	CMC
	MVI	D, 'A'	; Prepare print A
@EDD4	MOV	A, D
	CNC	OUTC	; Print 'A' if A-mode
	RET
;
; **********************************************
; * LIST EXPRESSION AFTER 'INPUT'-'READ'-'DIM' *
; **********************************************
;
; Input with string
;
SCN17	CALL	SCEXP	; List string
	CALL_B(SCHRI, ';')	; Print ';'
;
; Rest
;
SCN18	LDAX	B	; Get nr of variables
	INX	B
	MOV	D, A	; into D
@EDE3	PUSH	D
	CALL	LEEFC	; List variable reference
	POP	D
	DCR	D	; Decr nr of variables
	RZ		; Abort if ready
	CALL	SCHCO	; Print ','
	JMP	@EDE3	; List next variable
;
; ****************************************
; * part of RUN 'DIM': CALC. REQD. SPACE *
; ****************************************
;
RDM40	JNZ	HLMUL	; If length element <= 254: then HL = HL * A
	MOV	A, H	; else:
	ORA	A	; Set flags on hibyte
	MOV	H, L
	MVI	L, $00
	RZ		; Abort if H=0
	STC		; Else: CY=1, L into H
	RET
;
; ************************
; * RUBBISH - (not used) *
; ************************
;
	.byte	$CE, $C3, $F4, $ED
;
; *******************************
; * LIST EXPRESSION AFTER 'LET' *
; *******************************
;
; Entry: BC: Points to assign statement
; Exit:  BC updated, AFDEHL corrupted
;
SCN20	CALL	LEEFC	; List 1efthand variable reference
	CALL_B(SCHRI, '=')	; Print '='
	JMP	SCEXP	; List righthand expr
;
; **********************************
; * LIST EXPRESSION AFTER 'IF' (1) *
; **********************************
;
; Lists '<expr> THEN <expr>'.
;
SCN21	CALL	SEXPS	; List <expr>; print space
	CALL_W(STXTS, LEE15)	; Print THEN
	INX	B
	JMP	SCOM	; List statement
;
; *DATA
; *
LEE15	PSTR("THEN")
;
; **********************************
; * LIST EXPRESSION AFTER 'IF' (2) *
; **********************************
;
; Lists '<expr> GOTO <linenr>'.
; *
SCN22	CALL	SEXPS	; List <expr>; print space
	CALL_W(STXTS, SGOTO)	; Print 'GOTO'
	JMP	LEFAE	; List linenr
;
; **********************************
; * LIST EXPRESSION AFTER 'IF' (3) *
; **********************************
;
; Lists '<expr> THEN <linenr>'.
;
SC22A	CALL	SEXPS	; List <expr>; print space
	CALL_W(STXTS, LEE15)	; Print 'THEN'
	JMP	LEFAE	; List linenr
;
; *******************************
; * LIST EXPRESSION AFTER 'FOR' *
; *******************************
;
; Lists <LET statement > TO <expr> (STEP <expr>)'.
;
SCN23	CALL	SCN20	; List expr of LET statement
	CALL	SCHSP	; Print space
	CALL_W(STXTS, LEE4C)	; Print 'TO'
	CALL	SCEXP	; List <expr>
	LDAX	B	; Get next byte
	INX	B
	CPI	$FF	; Terminator?
	RZ		; Then abort
	DCX	B	; Else
	CALL_W(STXSS, SSTEP)	; Print 'STEP'
	JMP	SCEXP	; List <expr>
;
; DATA
;
LEE4C	PSTR("TO")
;
; ********************************
; * LIST EXPRESSION AFTER 'NEXT' *
; ********************************
;
SCN24	JMP	LEEFC	; List var. ref.
;
; **********************************
; * LIST EXPRESSIONS AFTER 'PRINT' *
; **********************************
;
SCN25	LDAX	B	; Get nr of exp
	INX	B
	MOV	D, A	; into D
@EE55	DCR	D
	RM		; Abort if ready
	INX	B
	CALL	SCEXP	; List <expr>
	LDAX	B	; Get next byte
	INX	B
	CPI	$FF	; Terminator?
	RZ		; Then abort
	CALL	OUTC	; Else: print this byte
	JMP	@EE55	; List next expr
;
; **********************************
; * LIST EXPRESSION AFTER 'ON' (1) *
; **********************************
;
; Lists '<expr> GOTO <linenrs>'.
;
SCN26	CALL	SEXPS	; List <expr>; print space
	CALL_W(STXTS, SGOTO)	; Print GOTO
	JMP	LEE79	; List linenrs
;
; **********************************
; * LIST EXPRESSION AFTER 'ON' (2) *
; **********************************
;
; Lists '<expr> GOSUB <linenrs>'.
;
SCN27	CALL	SEXPS	; List <expr>; print space
	CALL_W(STXTS, SGOSUB)	; Print GOSUB
LEE79	LDAX	B	; Get nr of linenrs
	INX	B
	MOV	D, A	; into D
@EE7C	CALL	LEFAE	; List linenr
	DCR	D
	RZ		; Abort if ready
	CALL	SCHCO	; Print ','
	JMP	@EE7C	; List next linenr
;
; *********************************
; * LIST EXPRESSION AFTER 'CALLM' *
; *********************************
SCN28	CALL	SCEXP	; List <expr>
	JMP	LED6E	; Print ','; List next expr
;
; *********************
; * SET I/O DIRECTION *
; *********************
;
; Part of RESET (LC719). Only used for A = 0.
; Depending on A, the input switch INSW and the output switch OTSW are set.
; Default DINC is RS232.
;
;             INSW:     OTSW:
;        A=0: keyboard  sereen/RS232
;        A=1: DINC      Screen
;        A=2: DINC      editbuffer
;        A=3: DINC      DOUTC
;
LEE8D	STA	INSW	; Select keyb or DINC
	STA	OTSW	; Select screen/RS232/edit/DOUTC
	RET
;
; ***************
; * SET VOLUMES *
; ***************
;
; Part of RUN TALK (LCD64).
;
; Entry: A:  Parameter code.
;        HL: Pointer to volume byte.
;
LEE94	PUSH	H	; Save pntr to volume
	MOV	L, M	; Volume in L
	MVI	H, $0F
	RAR		; Check parameter code
	JNC	LE67C	; Jump if channel 0/2
;
; If channel 1/N
;
	DAD	H
	DAD	H
	DAD	H
	JMP	LE67B	; Continue
;
; **********************
; * LIST AN EXPRESSION *
; **********************
;
; Entry: BC:         Points to expression in program
;        (BC): 1.... expr starts with operator
;              01... variable reference
;              001.. function call
;              Else  constant
; Exit:  BC points after expression
;        DE preserved
;        AFHL corrupted
;
SCEXP	PUSH	D
	LDAX	B	; Get opcode
	ORA	A
	JP	@EEDF	; If no starting operator
;
; If starting with operator
;
	INX	B
	ANI	$1F	; Only 5 bits of opcode
	CPI	$1A	; '('?
	PUSH	PSW	; Save opcode
	CC	SCEXP	; List expr if binary operation
	LXI	H, OPTBB	; Addr table opcode strings
@EEB4	MOV	D, H	; in DE
	MOV	E, L
	CALL	DADM	; HL points after table
	POP	PSW	; Get opcode
	PUSH	PSW
	XRA	M	; Comp it with table
	INX	H
	ANI	$1F
	JNZ	@EEB4	; Check next opcode if not found
	XCHG		; If found: addr string in HL
	INX	H
	MOV	A, M	; Get 1st char
	DCX	H	; Pnts to length
	CALL	ALPHA	; Check if upper case char
	PUSH	PSW
	CC	SCHSP	; Print space if 1st char is a letter
	CALL	PSTR	; Print string from table
	POP	PSW
	CC	SCHSP	; Print space if 1st char was a letter
	CALL	SCEXP	; List remaining operand
	POP	PSW	; Get orig. opcode
	CPI	$1A	; Was it '('?
	CZ	LEF55	; Then print ')'
	POP	D
	RET
;
; Not starting with operator
;
@EEDF	RLC
	RLC
	JC	@EEF2	; Jump if var. ref
	RLC
	JC	@EEED	; Jump if function call
;
; If constant
;
	CALL	SCON	; List constant
	POP	D
	RET
;
; If function call
;
@EEED	CALL	SFUN	; List function reference
	POP	D
	RET
;
; If variable reference
;
@EEF2	CALL	LEEFC	; List a var.reference (array with arguments)
	POP	D
	RET
;
; *****************************
; * LIST A VARIABLE REFERENCE *
; *****************************
;
; SCARN:  Entry for arrays without argumentts (name only)
; LEEFC: Entry for arrays with arguments.
;
; Entry: BC points to variable reference in program.
;
SCARN	MVI	D, $BF	; Set mask 'no arg'
	JMP	LEEFE
LEEFC	MVI	D, $FF	; Set mask 'with arg'
LEEFE	PUSH	D	; Save mask
	LDAX	B	; Get byte
	INX	B
	ANI	$3F	; Skip bit 6,7
	MOV	D, A	; Rest in D
	LDAX	B	; Get next byte
	INX	B
	MOV	E, A	; in E (Now DE is offset of start of symtab)
	LHLD	STBBGN	; Get start symtab
	DAD	D	; Add offset from start
	POP	D	; Get mask
	PUSH	H	; Save var addr in symtab
	CALL	FNAME	; Find name in symtabb
	MOV	A, M	; Get T/L byte
	ANA	D	; AND with mask
	PUSH	PSW
	INX	H
	ANI	$0F	; Get length
	MOV	E, M	; Get 1st byte of name in E
	CALL	PSTRM	; List name; addr in HL, length in A
	MVI	D, $00
	LXI	H, IMPTAB-$41	; Startaddr for IMPTAB
	DAD	D	; Addr var.type in IMPTAB
	POP	PSW	; Get mask
	PUSH	PSW
	ANI	$30	; Bits 4,5 only
	CMP	M	; Comp with IMPTAB
	JZ	@EF3C	; Jump if identical
	CPI	$00	; FPT?
	MVI	D, '!'	; Then D: '!'
	JZ	@EF38
	CPI	$10	; INT?
	MVI	D, '%'	; Then D: '%'
	JZ	@EF38
	MVI	D, '$'	; Else D: '$'
@EF38	MOV	A, D
	CALL	OUTC	; Print type sign
@EF3C	POP	PSW	; Get mask
	ANI	$40	; Bit 6 only
	POP	H	; Get addr of string
	RZ
;
; Bit 6=1 (array with arguments)
;
	LDAX	B	; Get nr of expressions
	INX	B
	MOV	D, A	; in D
	CALL_B(SCHRI, '(') 	; Print '('
@EF48	INX	B
	PUSH	D
	CALL	SCEXP	; List expression
	POP	D
	DCR	D	; Ready?
	CNZ	SCHCO	; If not: print ','
	JNZ	@EF48	; and list next expr
LEF55	CALL_B(SCHRI, ')') 	; If ready: Print ')'
	RET
;
; *****************************
; * LIST A FUNCTION REFERENCE *
; *****************************
;
; Finds functionname in table with startaddress FUNTB and prints it.
; Eventual arguments are printed between brackets.
;
; Entry: BC points to function code (#20)
; Exit:  BC updated, AFEHL preserved, D=0.
;
SFUN	INX	B
	LDAX	B
	INX	B
	MOV	D, A
	LXI	H, FUNTB	; Startaddr function table
@EF61	DCR	D
	JM	@EF6B	; If found
	CALL	DADD	; Calc addr next string in tab
	JMP	@EF61	; Test next function name
@EF6B	CALL	PSTR	; List function name
	MOV	A, M	; Get byte after string
	ANI	$0F	; Only nr of following args
	MOV	D, A	; in D
	RZ		; Abort if no arguments
	CALL_B(SCHRI, '(')	; Print '('
@EF77	CALL	SCEXP	; List expression
	DCR	D	; Decr nr of arg
	CNZ	SCHCO	; If <> 0, print ','
	JNZ	@EF77	; and 1ist next expr
	JMP	LEF55	; If ready: print ')'
;
; *******************
; * LIST A CONSTANT *
; *******************
;
; The constant is decoded to ASCII, prettied and printed.
;
; Codes: $10: FPT	$18: Quoted string
;        $14: INT	$19: Unquoted string
;        $15: HEX
;
; Entry: BC: Points to constant in program
; Exit:  BC updated, DE preserved, AF corrupted
;        HL: points after end of printed string
;
SCON	LDAX	B	; Get type of constant
	INX	B
	MOV	H, B	; Addr constant in HL
	MOV	L, C
;
; If string
;
	CPI	$18	; Quoted string?
	JZ	SQTS	; Then 1ist it
	CPI	$19	; Unquoted string?
	JZ	SUQTS	; Then list it
;
; If number
;
	ROMCALL(4, $0C)	; Copy constant value to MACC
	CPI	$10	; FPT?
	JZ	@EFA8	; Then 1ist FPT value
	CPI	$14	; INT
	PUSH	PSW
	CZ	SCINT	; List INT value
	POP	PSW
	CNZ	SCHEX	; Else list HEX value
@EFA3	INX	B
	INX	B
	INX	B
	INX	B	; BC points after constant
	RET
@EFA8	CALL	SCFPT	; List FPT value
	JMP	@EFA3
;
; *********************
; * LISTA LINENUMBER *
; *********************
;
; Entry: BC Points to linenumber
; Exit:  BC updated, DE preserved, AFHL corrupted
;
LEFAE	LDAX	B	; Get hibyte linenr
	INX	B
	MOV	H, A	; in H
	LDAX	B	; Get 1obyte linenr
	INX	B
	MOV	L, A	; in L
LEFB4	CALL	FR2BY	; Linenr into MACC
	MOV	A, H
	ORA	L	; Linenr <> 0?
	CNZ	SCINT	; Then 1ist linenr
	RET
;
; *************************************
; * LIST A INT VALUE OF MACC CONTENTS *
; *************************************
;
; The value is the contents of the MACC, prepared for output, and moved into the
; outputbuffer DECBUF (DECBUF). A leading space is omitted.
;
; Exit: BCDE preserved. A corrupted.
;       HL: Points after string in DECBUF
;
SCINT	CALL	IBCP	; Convert MACC far INT output into DECBUF
SSSPC	LHLD	PDECBUF	; Get addr DECBUF
	PUSH	D
	MOV	D, M	; String 1ength in D
	INX	H
	MOV	A, M	; 1st char in A
	CPI	' '	; Space?
	JNZ	@EFCE	; Jump if no 1eading space
	INX	H	; Omit leading space
	DCR	D
@EFCE	MOV	A, D	; Get nr of char in A
	POP	D
	CALL	PSTRM	; Print contents DECBUF
	RET
;
; ***********************************
; * LIST FPT VALUE OF CONTENTS MACC *
; ***********************************
;
; *Exit: BCDE preserved. AF Corrupted
; HL points after string in DECBUF.
;
SCFPT	CALL	FBCP	; Convert MACC for FPT output
	JMP	SSSPC	; List its contents
;
; ***********************************
; * LIST HEX VALUE OF CONTENTS MACC *
; ***********************************
;
; Exit: BCDE preserved. AF corrupted.
;       HL points after string in DECBUF
;
SCHEX	CALL_B(SCHRI, '#')	; Print '#'
	JMP	PHEX	; List in hex
;
; ************************
; * LIST A QUOTED STRING *
; ************************
;
; Entry: BC: Points to string.
; Exit:  BC and HL point after string
;        AF corrupted. DE preserved.
;
SQTS	CALL_B(SCHRI, '"') 	; Print '"'
	CALL	SUQTS	; List string
	CALL_B(SCHRI, '"') 	; Print
	RET
;
; ************************
; * LIST UNQUOTED STRING *
; ************************
;
; Entry: BC points to string
; Exit:  BC and HL point after string
;        AFDE preserved
;
SUQTS	MOV	H, B	; Stringaddr in HL
	MOV	L, C
	CALL	PSTR	; List string
	MOV	B, H
	MOV	C, L	; Addr after string in BC
	RET
;
; ******************
; * LIST CHARACTER *
; ******************
;
; Entry: On stack: The address of the character to be printed
; Exit:  BCDEHL preserved F corrupted
;        A: Character printed
;
SCHRI	XTHL		; Get addr from stack
	MOV	A, M	; Get char
	INX	H	; HL pnts after char
	XTHL		; Returnaddr on stack
	JMP	OUTC	; List char.
;
; ********************************
; * LIST EXPRESSION; PRINT SPACE *
; ********************************
;
SEXPS	JMP	LCE68	; List expr, print space
;
	.byte	$3E
;
end_rom0	.equ	*
;
;
; ROM Bank 1 - 4KB starting $E000
.bank 1, 4, $E000
.segment "ROM1", 1
.org	$E000
;
bgn_rom1	.equ	*
;
;
;     =====================
; *** MATH. / SOUND PACKAGE ***
;     =====================
;
; The sound package starts at 1EE6E.
;
;     =============
; *** MATH. PACKAGE ***
;     =============
;
; Called by RST 4 + XX.
; XX indicates the offset from $E000 for the different entry points.
;
; The routines jumped to by RST + $7B-$F3 are identical to RST 4 + $00-$78,
; but for use with the AMD9511A math. chip.
; Which routines are used, depends on the offset in RAM address MVECA.
;
; The accumulator is the MACC (FPAC) or the math. chip accu MTOS.
;
; ************************
; * SOFTWARE ENTRYPOINTS *
; ************************
;
; MVECA contains offset 00
;
SVECA	.equ	*
MFADD	JMP	XFADD	; FPT addition
MFSUB	JMP	XFSUB	; FPT subtraction
MFMUL	JMP	XFMUL	; FPT multiplication
MFDIV	JMP	XFDIV	; FPT division
MLOAD	JMP	XLOAD	; Copy operand to accu
MSAVE	JMP	XSAVE	; Copy accu to operand
MPUT	JMP	XPUT	; Copy reg A, B, C, D to accu
MGET	JMP	XGET	; Copy accu to reg A, B, C, D
MFABS	JMP	XFABS	; FPT ABS
MFCHS	JMP	XFCHS	; FPT change sign accu
MFINT	JMP	XFINT	; FPT INT(X)
MFRAC	JMP	XFRAC	; FPT FRAC
MPWR	JMP	XPWR	; FPT power
MLN	JMP	XLN	; LOG
MEXP	JMP	XEXP	; EXP
MLOG	JMP	XLOG	; LOGT
MALOG	JMP	XALOG	; ALOG
MSQRT	JMP	XSQRT	; SQR
MSIN	JMP	XSIN	; SIN
MCOS	JMP	XCOS	; COS
MTAN	JMP	XTAN	; TAN
MASIN	JMP	XASIN	; ASIN
MACOS	JMP	XACOS	; ACOS
MATAN	JMP	XATAN	; ATN
MFIX	JMP	XFIX	; Change accu to INT
MFLT	JMP	XFLT	; Change accu to FPT
MIADD	JMP	XIADD	; INT addition
MISUB	JMP	XISUB	; INT Subtraction
MIMUL	JMP	XIMUL	; INT multiplication
MIDIV	JMP	XIDIV	; INT division
MIREM	JMP	XIREM	; INT divide remainder
MIABS	JMP	XIABS	; INT ABS
MICHS	JMP	XICHS	; INT change sign accu
MIAND	JMP	XIAND	; IAND
MIOR	JMP	XIOR	; IOR
MIXOR	JMP	XIXOR	; IXOR
MINOT	JMP	XINOT	; INOT
MSHL	JMP	XSHL	; SHL
MSHR	JMP	XSHR	; SHR
MSA00	JMP	MSA	; Part of SAVEA
L1E274	JMP	BRET	; Bank return
;
; ************************
; * HARDWARE ENTRYPOINTS *
; ************************
;
; MVECA contains offset $7B from $E000 as base for HVECA.
;
HVECA	.equ	*
	JMP	ZFADD	; FPT addition
	JMP	ZFSUB	; FPT subtraction
	JMP	ZFMUL	; FPT multiplication
	JMP	ZFDIV	; FPT division
	JMP	ZLOAD	; Copy operand to accu
	JMP	ZSAVE	; Lopy accu to operand
	JMP	ZPUT	; Copy reg A, B, C, D to accu
	JMP	ZGET	; Copy accu to reg A, B, C, D
	JMP	ZFABS	; FPT ABS
	JMP	ZFCHS	; FPT change sign accu
	JMP	ZFINT	; FPT INT(X)
	JMP	ZFRAC	; FPT FRAC
	JMP	ZPWR	; FPT power
	JMP	ZLN	; LOG
	JMP	ZEXP	; EXP
	JMP	ZLOG	; LOGT
	JMP	ZALOG	; ALOG
	JMP	ZSQRT	; SQR
	JMP	ZSIN	; SIN
	JMP	ZCOS	; COS
	JMP	ZTAN	; TAN
	JMP	ZASIN	; ASIN
	JMP	ZACOS	; ACOS
	JMP	ZATAN	; ATN
	JMP	ZFIX	; Change accu to INT
	JMP	ZFLT	; Change accu to FPT
	JMP	ZIADD	; INT addition
	JMP	ZISUB	; INT subtraction
	JMP	ZIMUL	; INT multiplication
	JMP	ZIDIV	; INT division
	JMP	ZIREM	; INT divide remainder
	JMP	ZIABS	; INT ABS
	JMP	ZICHS	; INT change sign acc
	JMP	ZIAND	; IAND
	JMP	ZIOR	; IOR
	JMP	ZIXOR	; IXOR
	JMP	ZINOT	; INOT
	JMP	ZSHL	; SHL
	JMP	ZSHR	; SHR
	JMP	MSA	; Part of SAVEA (Not via AMD9511)
	JMP	BRET	; Bank return   (Not via AMD9511)
;
	.byte	$FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF
;
; **********************
; * FPT MULTIPLICATION *
; **********************
;
; MACC = MACC * MEM.
;
; Entry: HL: points to multiplier
; Exit:  All registers preserved
;
XFMUL	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	AMUL	; FPT multiplication
	JMP	EXIT	; Popall, ret
;
; ****************
; * FPT DIVISION *
; ****************
;
; MACC = MACC / MEM.
;
; Entry: HL: points to divisor
; Exit:  All registers preserved
;
XFDIV	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ADIV	; FPT division
	JMP	EXIT	; Popall, ret
;
; **************************
; * COPY OPERAND INTO MACC *
; **************************
;
; Entry: HL: points to operand
; Exit:  All registers preserved
;
XLOAD	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LE9FB	; Copy operand in MACC
	JMP	EXIT	; Popall, ret
;
; ************************
; * COPY MACC TO OPERAND *
; ************************
;
; Entry: HL: points to operand.
; Exit:  All registers preserved
;
XSAVE	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ASAVE	; Copy MACC to operand
	JMP	EXIT	; Popall, ret
;
; ***************************************
; * COPY REGISTERS A, B, C, D INTO MACC *
; ***************************************
;
; Entry: None
; Exit:  All registers preserved
;
XPUT	PUSH	H
	MOV	H, D
	MOV	L, C	; DC in HL
	SHLD	FPAC+2	; Copy D, C into FPAC+2
	MOV	H, B
	MOV	L, A	; BA in HL
	SHLD	FPAC	; Copy B, A into FPAC
	POP	H
	RET
;
; ***************************************
; * COPY MACC INTO RESISTERS A, B, C, D *
; ***************************************
;
; Entry: None
; Exit:  EHLF preserved
;
XGET	PUSH	H
	LHLD	FPAC+2	; Get 1obytes MACC
	MOV	C, L
	MOV	D, H	; Into registers C, D
	LHLD	FPAC	; Get hibytes MACC
	MOV	A, L
	MOV	B, H	; Into registers A, B
	POP	H
	RET
;
; ***********
; * FPT ABS *
; ***********
;
; For FPT values: MACC = Absolute value of MACC.
;
; Entry: None
; Exit:  All registers preserved
;
XFABS	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LE9EE	; Take abs.value of MACC
	JMP	EXIT	; Popall,  ret
;
; *************************
; * FPT: CHANGE SIGN MACC *
; *************************
;
; For FPT values: MACC = -MACC
; Entry: None
; Exit:  All registers preserved
;
XFCHS	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ACHGS	; Change sign MACC
	JMP	EXIT	; Popall, ret
;
; ************
; * FPT FRAC *
; ************
;
; The FPT number in the MACC is replaced by its fractional part.
;
; Entry: None
; Exit:  All registers preserved
;
XFRAC	PUSH	PSW
	PUSH	H
	CALL	PLISH	; Save MACC on stack
	CALL	XFINT	; Take INT value of MACC
	LXI	H, $0000  ;
	DAD	SP	; Pnts to orig MACC on stack
	CALL	XFSUB	; Subtract INT(MACC) - MACC
	CALL	XFCHS	; Make result positive again
	INX	SP
	INX	SP
	INX	SP
	INX	SP	; Correct SP
	POP	H
	POP	PSW
	RET
;
; ********************
; * INTEGER ADDITION *
; ********************
;
; Signed 32-bit addition: MACC = MACC + MEM.
; Evt. overf1ow handling via FPEOV.
;
; Entry: HL: points to 1st byte of operand
; Exit:  All registers preserved
;
XIADD	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LE38C	; MACC into reg E, B, C, A. D compl FPAC EXOR M
	PUSH	D
	ADD	M
	MOV	D, A
	DCX	H
	MOV	A, C
	ADC	M	; Add contents MEM to EBCA
	MOV	C, A	; Result in EBCD
	DCX	H
	MOV	A, B
	ADC	M
	MOV	B, A
	DCX	H
	MOV	A, E
	ADC	M
	MOV	E, A
	RAR		; Evt carry in msb
	XRA	E	; msb=1 if overflow
	POP	H	; Get comp1 FPAC EXOR M (0 if different sígnbits)
	ANA	H	; Overflow only if different signbits
LE187	CM	FPEOV	; Then run overflow error
	JMP	LE384	; Copy E into A; then reg ABCD into MACC
;
; ***********************
; * INTEGER SUBTRACTION *
; ***********************
;
; Signed 32-bit subtraction MACC = MACC - MEM
; Evt. overflow handling via FPEOV.
;
; Entry: HL: points to 1st byte of operand
; Exit:  All registers preserved
;
XISUB	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LE38C	; Copy MACC into reg EBCA D compl 00D5 EXOR M
	PUSH	D
	SUB	M
	MOV	D, A
	DCX	H
	MOV	A, C
	SBB	M
	MOV	C, A	; Subtract EBCA - MEM
	DCX	H	; Result in EBCD
	MOV	A, B
	SBB	M
	MOV	B, A
	DCX	H
	MOV	A, E
	SBB	M
	MOV	E, A
	RAR		; Evt carry in msb
	XRA	E	; msb=1 if overflow
	POP	H	; Get compl FPAC EXOR M
	ORA	H
	CMA
	ORA	A	; msb=1?
	JMP	LE187	; Evt run overflow error
			; Copy result into MACC
;
; **************************
; * INTEGER MULTIPLICATION *
; **************************
;
; Signed 32-bit multiplication: MACC = MACC * MEM.
; The overflow exit is taken if both factors are more than 2 bytes or the product is 1onger
; than the signbit of the 4th byte.
; If MEM > 2 bytes, than MACC into DE and MEM into MACC, assuming that MACC is max. 2 bytes,
;
; Entry: HL: points to multiplier
; Exit:  All registers preserved
;
XIMUL	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LDA	IAC	; Get sign byte
	ORA	A
	CM	XICHS	; If nr < 0: change sign
	JC	@E225	; (Don't work: XICHS preserves f1ags ORA A clears CY)
	XRA	M	; Final sign bit in S-flag
	PUSH	PSW	; Save it
	MOV	A, M
	INX	H
	ORA	A	; Get MEM into BCDE
	MOV	B, A	; Set fl ags on s1gn byte
	MOV	C, M
	INX	H
	MOV	D, M
	INX	H
	MOV	E, M
	CM	LE3C9	; If MEM < 0: negate BCDE
	JC	@E225	; Error exit if overflow
	ORA	C
	JZ	@E1DF	; Jump if MEM <= 2 bytees
;
; MEM > 2 bytes: exchange MACC with BCDE
;
	LHLD	IAC	; Get hibyte MACC
	MOV	A, H
	ORA	L
	JNZ	@E225	; overflow exit if MACC > 2 bytes
	LHLD	IAC+2	; Get 1obytes MACC in HL
	CALL	LE3CF	; Copy reg BCDE (=MEM) into MACC
	MOV	D, L
	MOV	E, H	; Orig. MACC into DE
;
; Now 4-byte nr in MACC and 2 byte nr in DE
;
@E1DF	LXI	H, $0000
	PUSH	H	; $0000 on stack
	LXI	H, FPAC+3	; Addr 1obyte MACC
	MOV	C, M	; 1obyte in C
@E1E7	XTHL		; On stack: addr current MACC byte
	MOV	A, C	; Current byte in A
	ORA	A
	JZ	@E21E	; Jump if byte = 0
	MVI	B, $80
@E1EF	MOV	A, C	; Current MACC byte in A
	RAR
	MOV	C, A
	JNC	@E1F6	; SHR reg H,L and B as long no carry from C
	DAD	D	; Else: Add other nr to HL
@E1F6	MOV	A, H
	RAR
	MOV	H, A
	MOV	A, L	; Effect: Multiply MACC by DE, result in B
	RAR
	MOV	L, A
	MOV	A, B
	RAR
	MOV	B, A
	JNC	@E1EF	; Do @E1EF max 8 times
@E202	XTHL		; HL pnts to current MACC byte
	MOV	M, B	; Result in MACC byte
	DCX	H	; Pnts to next lower MACC byte
	MOV	A, L	; Get 1obyte of addr
	CPI	$D4	; Ready?
	MOV	C, M	; Get next lower byte in C
	JNZ	@E1E7	; Not ready: mult. next byte
;
; Multiplication done
;
	POP	H
	MOV	A, B	; Get last result
	ORA	A
	JM	@E225	; Error exit if overflow
	MOV	A, H
	ORA	L	; Check if HL <> 0
	JNZ	@E225	; Then overf1ow exit
@E217	POP	PSW	; Get final sign in S-flag
	CM	XICHS	; Change sign MACC if nr must be negative
	JMP	EXIT	; Popall, ret
;
; If MACC byte = 0
;
@E21E	MOV	B, L	; Move bytes in HLB one byte
	MOV	L, H	; down
	MVI	H, $00
	JMP	@E202	; Go to next MACC byte
;
; If overflow error
;
@E225	CALL	FPEOV	; Run overflow error
	JMP	@E217	; Quit
;
;
;
; ********************
; * INTEGER DIVISION *
; ********************
;
; Signed 32-bit fixed point division: MACC = MACC / MEM
;
; * Entry: HL: points to divisor
; * Exit:  All registers preserved
;
XIDIV	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LE242	; Signed division
	CALL	LE3CF	; Quotient into MACC
	JMP	EXIT	; Popall, ret
;
; ************************
; * INT DIVIDE REMAINDER *
; ************************
;
; For INT values: MACC = Remainder of (MACC / MEM)
;
; Entry: HL: points to divisor
; Exit:  All registers preserved
;
XIREM	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LE242	; Signed division; remainder in MACC
	JMP	EXIT	; Popall, ret
;
; ***************************
; * SIGNED INTEGER DIVISION *
; ***************************
;
; Divides MACC / MEM; quotient is left in registers B, C, D, E and the remainder in MACC.
;
; Entr: HL:     points to divisor
;       MACC:   dividend.
; Exit: BCDE:   quotient; remainder in MACC
;       S-F1ag: set for result
;       AHL:    corrupted
;       CY = 0
;
LE242	CALL	LED8F	; Get signbyte dividend in A, compare it with sign divisor
	MOV	A, B	; Get signbyte dividend
	PUSH	PSW	; Save result compare
	CALL	LEA0E	; Copy divisor into BCDE
	MOV	A, B
	ORA	C	; Check if divisor = 0
	ORA	D
	ORA	E
	JZ	@E2E4	; Then error 'divide by zero'
	MOV	A, B	; Get signbyte divisor
	ORA	A	; Is it negative?
	CM	LE3C9	; Then negate divisor
	JC	@E2E4	; Error exit if overflow
	PUSH	B	; Save divisor on stack
	PUSH	D
	CALL	LE2EC	; Normalize divisor
	CMA		; H = pos. value of nr of
	INR	A	; times shifted for norma1isation
	MOV	H, A
	LDA	IAC	; Get signbyte dividend
	ORA	A	; Is dividend negative?
	CM	XICHS	; Then change sign dividend
	CALL	LE3D6	; Copy dividend in reg BCDE
	ORA	C
	ORA	D	; Check if dividend zero
	ORA	E
	JZ	@E2E0	; Then abort, 1eaving $0000 in MACC and reg BCDE
	CALL	LE2EC	; Normalize dividend; nrs of shifts in A
	POP	D	; Restore divisor in BCDE
	POP	B
	ADD	H	; Add nr of shifts for divisor, H is total nrs of shifts
	JM	@E2C9	; If resulting nrs of shifts < 0 then result = $0000
	CALL	LSHN	; Shift divisor left (A) times
	PUSH	D	; Save shifted divisor on stack
	PUSH	B
	LXI	B, $8000	; Init BCDE for max neg number
	LXI	D, $0000
	CALL	RSHN	; Shift BCDE right (A) times
	MOV	H, B	; Shifted BC in HL
	MOV	L, C
	POP	B	; Get hibytes shifted divisor
	XTHL		; HL: 1obytes shifted divisor; shifted BC on stack
	XCHG		; DE: 1obytes shifted divisor; HL: shifted DE
	PUSH	H	; Shifted DE on stack
@E28E	LHLD	IAC+2	; Get 1obytes dividend
	MOV	A, H
	SUB	E
	MOV	H, A	; (IAC+2) = (IAC+2) - 1obytes
	MOV	A, L	; shifted divisor
	SBB	D
	MOV	L, A
	SHLD	IAC+2
	LHLD	IAC	; Get hibytes dividend
	MOV	A, H
	SBB	C
	MOV	H, A	; (IAC) = (IAC) - hibytes
	MOV	A, L	; shifted divisor
	SBB	B
	MOV	L, A
	SHLD	IAC
@E2A6	POP	H	; Get shifted DE
	RAL
	CMC
	MOV	A, L
	RAL
	MOV	L, A
	MOV	A, H
	RAL
	MOV	H, A
	XTHL		; Get shifted 'BC' in HL
	MOV	A, L
	RAL
	MOV	L, A
	MOV	A, H
	RAL
	MOV	H, A
	XTHL		; New 'BC' back on staCk
	JC	@E2D0
	CALL	LEB70	; Rotate BCDE right 1 bit
	MOV	A, L
	RAR
	PUSH	H	; New 'DE' back on stack
	JC	@E28E	; CY=1: again
	CALL	LE2F2	; MACC = MACC + BCDE
	JMP	@E2A6	; again
;
; If resulting nr of shifts is negative
;
@E2C9	LXI	D, $0000
	PUSH	D
	JMP	@E2D7	; BCDE = 0000 abort
;
; If ready
;
@E2D0	MOV	A, L
	RAR
	PUSH	H
	CNC	LE2F2	; CY=0: MACC = MACC + BCDE
	POP	D
@E2D7	POP	B
	POP	PSW	; Get result sign compare
	CALL	LED88	; Evt negate FCDE
	CM	XICHS	; Evt change sign MACC
	RET
;
;  If dividend is zero
;
@E2E0	POP	H	; Save BCDE = 0000
	POP	H
	POP	PSW
	RET
;
; If error
;
@E2E4	CC	FPEOV	; CY=1: run overflow error
	CZ	FPEDO	; Z=1:  run divide by 0 error
	POP	PSW
	RET
;
; ************************************************
; * INT: NORMALIZE CONTENTS REGISTERS B, C, D, E *
; ************************************************
;
; Exit: HL preserved
;
LE2EC	PUSH	H
	CALL	LEBA0	; Normalize BCDE (INT)
	POP	H
	RET
;
; *********************************************
; * ADD CONTENTS REGISTERS B, C, D, E TO MACC *
; *********************************************
;
; Exit: BCDE preserved
;       AHL corrupted
;       F set on hibyte of result
;
LE2F2	LHLD	FPAC+2
	MOV	A, H
	ADD	E	; Add DE to (FPAC+2)
	MOV	H, A
	MOV	A, L
	ADC	D
	MOV	L , A
	SHLD	FPAC+2
	LHLD	FPAC
	MOV	A, H
	ADC	C
	MOV	H, A	; Add BC to (FPAC)
	MOV	A, L
	ADC	B
	MOV	L, A
	SHLD	FPAC
	RET
;
; ***********
; * INT ABS *
; ***********
;
; For INT values: MACC = absolute value of MACC.
;
; Exit: All registers preserved
;
XIABS	PUSH	PSW
	LDA	IAC	; Get sign byte
	ORA	A
	CM	XICHS	; If < 0: change sign
	POP	PSW
	RET
;
; **********************************
; * INT: CHANGE SIGN MACC CONTENTS *
; **********************************
;
; For INT values: MACC = -MACC
;
; Exit: All registers preserved
;
XICHS	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LE3D6	; Copy MACC into reg BCDE
	CALL	LE3C9	; Negate BCDE
	JNC	LE328	; Jump if no error
;
; If overfow error
;
LE322	CALL	FPEOV	; Run overflow error
	JMP	EXIT	; Popall, ret
;
; If OK
;
LE328	CALL	LE3CF	; Copy reg BCDE into MACC
	JMP	EXIT	; Popall, ret
;
; ********
; * IAND *
; ********
;
; Logical 'AND': MACC = MACC IAND MEM
;
; Entry: HL points to operand in memory
; Exit:  All registers preserved
;
XIAND	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	JMP	LECE1	; Prepare IAND and perform
;
; ****************
; * PERFORM IAND *
; ****************
;
; Performs: MEM IAND EBCA, result in ABCD.
;
; Entry: HL points to last byte of MEM
;        Fixed point number in EBCA
; Exit:  HL points to 1st byte of MEM
;        E preserved
;
SIAND	ANA	M
	MOV	D, A
	DCX	H
	MOV	A, C
	ANA	M
	MOV	C, A
	DCX	H
	MOV	A, B
	ANA	M
	MOV	B, A
	DCX	H
	MOV	A, E
	ANA	M
	RET
;
LE343	.word	LE385	; (not used)
;
; *******
; * IOR *
; *******
;
; Logical 'OR': MACC = MACC IOR MEM
;
; Entry: HL points to operand in memory
; Exit:  All registers preserved
;
XIOR	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	JMP	LECEA	; Prepare IOR and perform
;
; ***************
; * PERFORM IOR *
; ***************
;
; Performs MEM IOR EBCA. Result in ABCD.
;
; Entry: HL points to last byte of MEM
;        Fixed point nr in EBCA
; Exit:  HL points to 1st byte of MEM
;        E preserved
;
SIOR	ORA	M
	MOV	D, A
	DCX	H
	MOV	A, C
	ORA	M
	MOV	C, A
	DCX	H
	MOV	A, B
	ORA	M
	MOV	B, A
	DCX	H
	MOV	A, E
	ORA	M
	RET
;
LE35A	.word	LE385	; (not used)
;
; ********
; * IXOR *
; ********
;
; Logical 'XOR': MACC = MACC IXOR MEM
;
; Entry: HL points to operand in memory
; Exit:  All registers preserved
;
XIXOR	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	JMP	LECF3	; Prepare IXOR and perform
;
; ****************
; * PERFORM IXOR *
; ****************
;
; Performs MEM IXOR EBCA, result in ABCD.
;
; Entry: HL points 1ast byte of MEM
;        Fixed point number in EBCA
; Exit:  HL points to 1st byte of MEM
;        E preserved
;
SIXOR	XRA	M
	MOV	D, A
	DCX	H
	MOV	A, C
	XRA	M
	MOV	C, A
	DCX	H
	MOV	A, B
	XRA	M
	MOV	B, A
	DCX	H
	MOV	A, E
	XRA	M
	RET
;
LE371	.word	LE385	; (not used)
;
; ********
; * INOT *
; ********
;
; Logical 'INOT': MACC = INOT(MACC)
;
; Exit: All registers preserved
;
XINOT	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LECFC	; Copy MACC into ABCD; CMA
	MOV	E, A	; Save hibyte
	MOV	A, D
	CMA		; INOT D
	MOV	D, A
	MOV	A, C
	CMA		; INOT C
	MOV	C, A
	MOV	A, B
	CMA		; INOT B
	MOV	B, A
LE384	MOV	A, E	; Get back hibyte
LE385	CALL	XPUT	; Copy ABCD into MACC
	JMP	EXIT	; Popall, ret
;
	RET		; (not used)
;
; ***** ******************************
; * COPY MACC INTO REG. E, B, C, A   *
; * D = comp1. FPAC EXOR hibyte MEM *
; ************************************
;
; Entry: HL points to 1st byte MEM
; Exit:  HL points to 1ast byte MEM
;        D = complenent EXOR hibytes MACC and MEM
;            Msb D = 1: aign bits identical
;            Msb D = 0: sign bits different
;
LE38C	JMP	LED01	; Copy MACC into ABCD. A in E: Jump to E38F
;
LE38F	XRA	M	; EXOR sign bytes
	CMA		; Complement result
	INX	H
	INX	H
	INX	H
	PUSH	D
	MOV	D, A	; A = Compl EXOR signbytes
	POP	PSW	; Get D in A
	RET
;
; *******
; * SHR *
; *******
;
; MACC = MACC SHR MEM
; Shifts contents MACC right (MEM) places.
;
; Entry: HL Points to operand in memory
; Exit:  All registers preserved
;        Result is 0 if MEM < 0 or > 31.
;
XSHR	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LED08	; Check MEM. If <= 31: MACC into BCDE, shift in A else: clear ABCDE
	CALL	RSHN	; Shift BCDE right A places
	JMP	LE328	; BCDE into MACC; quit
;
; *******
; * SHL *
; *******
;
; MACC = MACC SHL MEM.
; Shifts contents MACC left (MEM) places.
;
; Entry/exit: See XSHR.
;
XSHL	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LED08	; Check MEM. If <= 31: MACC into BCDE, shift in A Else: clear ABCDE.
	CALL	LSHN	; Shift BCDE 1eft A places
	JMP	LE328	; BCDE into MACC; quit
;
; *******************************
; * TEST VALUE OF AN INT NUMBER *
; *******************************
;
; Tests if an INT has a value between 0 and 31.
; If true: Number into A, else: Clear ABCDE.
;
; Entry: HL points to a 4-byte number
; Exit:  Nr <= $1F: number in A
;        Nr >  $1F: ABCDE cleared
;        HL points to 4th byte in memory.
;
XSTST	MOV	A, M	; Get 1st byte
	INX	H
	ORA	M	; OR with 2nd
	INX	H
	ORA	M	; OR with 3rd
	INX	H
	JNZ	@E3C2	; Jump if highest bytes <> 0
	MOV	A, M	; Get 4th byte
	ANI	$E0	; Test 3 highest bits
	NOP
	NOP
	MOV	A, M	; Get 4th byte in A
	RZ		; Abort if 4th byte <= $1F
;
; If nr > $1F
;
@E3C2	MVI	A, $0
	MOV	B, A
	MOV	C, A	; Clear ABCDE
	MOV	D, A
	MOV	E, A
	RET
;
; *********************************************
; * INT: NEGATE CONTENTS REGISTERS B, C, D, E *
; *********************************************
;
; Exit: HL preserved
;       CY=1 Overflow into msb.
;
LE3C9	PUSH	H
	CALL	LEB82	; Negate BCDE (INT)
	POP	H
	RET
;
; ***************************************
; * COPY REGISTERS B, C, D, E INTO MACC *
; ***************************************
;
; Entry: none
; Exit:  ABCD corrupted
;        FHL preserved
;
LE3CF	MOV	A, B
	MOV	B, C
	MOV	C, D
	MOV	D, E
	JMP	XPUT	; Copy ABCD into MACC
;
; ***************************************
; * COPY MACC INTO REGISTERS B, C, D, E *
; ***************************************
;
; Entry: none
; Exit:  AFHL Ppreserved
;
LE3D6	PUSH	PSW
	CALL	XGET	; Copy MACC into ABCD
	JMP	LED13	; Copy ABCD into BCDE
;
	RET
;
; *******************************
; * CHANGE CONTENTS MACC TO FPT *
; *******************************
;
; Result is incorrect if MACC	= 80 00 00 00.
; Then exponent is 1 too high (E3FC should be a NOP instruction).
;
; Entry: None
; Exit:  All registers preserved
;
XFLT	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	LE3D6	; Copy MACC into BCDE
	CALL	LED83	; Check if BCDE is 0.
	JZ	LE40E	; Then clear MACC + BCDE
	MVI	H, $20	; Init exp. byte for pos. nr
	MOV	A, B
	ORA	A	; Check sign bit
	JP	@E3FD	; Jump 1f nr is positive
;
; If INT nr is negative
;
	MVI	H, $A0	; Init exp. byte for neg. nr
	CALL	LE3C9	; Negate BCDE
	JNC	@E3FD	; Jump if no overflow
	MVI	B, $80
	INR	H
;
; Convert to FPT
;
@E3FD	MOV	A, H	; Get init. exp. byte
	LXI	H, FPAC	; Addr MACC
	MOV	M, A	; Init. exp. byte in MACC
	PUSH	H
	CALL	LEB96	; Normalize BCDE
	POP	H
	MOV	A, M	; Get init. exp. byte
	CALL	ASTORE	; Copy ABCD into MACC
	JMP	EXIT	; Popall, ret
;
; If INT number is 0
;
LE40E	CALL	AZERO	; Clear MACC + reg ABCD
	JMP	EXIT	; Popal1, ret
;
;
;
; ***********************************
; * CHANGE CONTENTS MACC TO INTEGER *
; ***********************************
;
; Entry: none
; Exit:  All registers preserved
;
XFIX	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	XGET	; Copy MACC to ABCD
	PUSH	PSW	; Save exp. byte
	ANI	$7F	; Exponent only
	JZ	@E43B	; Exp=0; Clear MACC, abort
	CPI	$40	; Exp negative?
	JNC	@E43B	; Then clear MACC, abort
	SUI	$20	; Exp >= 32?
	JNC	@E43F	; Then run overflow error
	CMA		; 2-complement of exp
	INR	A	;
	CALL	RSHN	; Shift BCDE right A times
	POP	PSW	; Get exp byte
	ORA	A
	CM	LE3C9	; Nr < 0: negate BCDE
	JC	LE322	; Jump if overflow
	JMP	LE328	; Copy BCDE into MACC abort
;
; If number is 0 or exponent negative
;
@E43B	POP	PSW
	JMP	LE40E	; Clear MACC, abort
;
; if overflow
;
@E43F	POP	PSW
	JMP	LE322	; Run overflow error, abort
;
; **************
; * FPT INT(X) *
; **************
;
; The contents of the MACC is replaced by its FPT integer part. The fractional bits of
; the mantissa are masked off.
;
; Exit: All registers preserved
;
XFINT	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	H, FPAC	; Addr MACC
	MOV	A, M	; Get exp. byte
	ANI	$7F	; Exponent only
	JZ	LE40E	; If exp = 0: Clear MACC, abort
	CPI	$40	; Exp negative?
	JNC	LE40E	; Then clear MACC, abort
	SUI	$19	; Exp - nr of mantissa bits
	LXI	H, FPAC+3	; Addr 1obyte MACC
	MVI	E, $03	; 3 bytes in mantissa
	MOV	D, A	; Rest exp in D
@E45D	MVI	C, $08	; 8 bits pro byte
@E45F	INR	D	; Rest exp + 1
	STC		; Mask '1' for bits reqd
	JP	@E465	; If rest exp >= 0
	CMC		; Mask '0' for bits not reqd
@E465	RAR		; Shift CY into A to make mask
	DCR	C
	JNZ	@E45F	; Next bit if not ready
	ANA	M	; Mask MACC byte with mask
	MOV	M, A	; Result back in MACC
	DCX	H	; Addr next MACC byte
	DCR	E
	JNZ	@E45D	; Next byte if not ready
	JMP	EXIT	; Popall, ret
;
; *********************
; * AMD: FPT ADDITION *
; *********************
;
; MTOS = MTOS + MEM
;
; Entry: HL points to operand in memory
; Exit:  All register preserved
;
ZFADD	CALL_B(WLOPI, $10) 	; Wait, 1oad, operate imm. - MTOS = MTOS + MEM
	RET
;
; ************************
; * AMD: FPT SUBTRACTION *
; ************************
;
; MTOS = MTOS - MEM
;
; Entry: HL points to operand in memory
; Exit:  All registers preserved
;
ZFSUB	CALL_B(WLOPI, $11)	; Wait, load, operate imm. - MTOS = MTOS - MEM
	RET
;
; ***************************
; * AMD: FPT MULTIPLICATION *
; ***************************
;
; MTOS = MTOS * MEM
;
; Entry: HL points to operand in memory
; Exit:  All registers preserved
;
ZFMUL	CALL_B(WLOPI, $12)	; Wait, load, operate imn. - MTOS = MTOS * MEM
	RET
;
; *********************
; * AMD: FPT DIVISION *
; *********************
;
; MTOS = MTOS / MEM
;
; Entry: HL points to operand in memory
; Exit:  All registers preserved
;
ZFDIV	CALL_B(WLOPI, $13)	; Wait, load, operate imm. - MTOS = MTOS / MEM
	RET
;
; ****************
; * AMD: FPT ABS *
; ****************
;
; MTOS is replaced by its absolute value (FPT)
;
; Entry: none
; Exit:  all registers preserved
;
ZFABS	PUSH	PSW
	CALL	M4STAT	; Get status bits
	NOP
	ADD	A	; Test bit 6 (sign)
	CM	ZFCHS	; Change sign if reqd (FPT)
	POP	PSW
	RET
;
; ****************************************
; * AMD: CHANGE SIGN MTOS CONTENTS (FPT) *
; ****************************************
;
; MTOS = -MTOS
;
; Entry: none
; Exit:  all registers preserved
;
ZFCHS	CALL_B(WOPI, $15) 	; Wait, operate immediate - FPT change sign MTOS
	RET
;
; *******************
; * AMD: FPT INT(X) *
; *******************
;
; MTOS is replaced by its integer part.
;
ZFINT	CALL	ZFIX	; Convert MTOS to INT
;
; Entry for AMD: Change MTOZ to FPT
;
ZFLT	CALL_B(WOPI, $1C)	; Wait, load, operate imm. - Convert MTOS to FPT
	RET
;
; *****************
; * AMD: FPT FRAC *
; *****************
;
; MTOS is replaced by its fractional part.
;
ZFRAC	CALL_B(WOPI, $37)	; Wait, 1oad, operate imm. - Push MTOS
	CALL	ZFINT	; MTOS = INT(MTOS)
	CALL_B(WOPI, $11) 	; Wait, load, operate imm. - Subtract whole number
	RET
;
; ******************************
; * part of AMD: POWER (1EDA1) *
; ******************************
;
; Entry: HL points to operand in memory
; Exit:  all registers preserved
;
LE4AC	CALL_B(WLOPI, $0B) 	; Wait, load, operate imm. - MTOS = MTOS ^ MEM
	RET
;
; ************
; * AMD: LOG *
; ************
;
ZLN	CALL_B(WOPI, $09) 	; Wait, operate immediate - MTOS = LN(MTOS)
	RET
;
; ************
; * AMD: EXP *
; ************
;
ZEXP	CALL_B(WOPI, $0A) 	; Wait, operate immediate - MTOS = e ^ MTOS
	RET
;
; *************
; * AMD: LOGT *
; *************
;
ZLOG	CALL_B(WOPI, $08)	; Wait, operate immediate - MTOS = LOG(MTOS)
	RET
;
; *************
; * AMD: ALOG *
; *************
;
ZALOG	PUSH	H
	LXI	H, FLGTI	; Addr 1/1ogn(10)
	CALL	ZFDIV	; MTOS = MTOS / MEM
	POP	H
	CALL	ZEXP	; MTOS = e ^ MTOS
	RET
;
; ************
; * AMD: SQR *
; ************
;
ZSQRT	CALL_B(WOPI, $01) 	; Wait, operate immediate - MTOS = SQRT(MTOS)
	RET
;
; ************
; * AMD: SIN *
; ************
;
ZSIN	CALL_B(WOPI, $02) 	; Wait, operate immediate - MTOS = SIN(MTOS)
	RET
;
; ************
; * AMD: COS *
; ************
;
ZCOS	CALL_B(WOPI, $03) 	; Wait, operate immediate - MTOS = COS(MTOS)
	RET
;
; ************
; * AMD: TAN *
; ************
;
ZTAN	CALL_B(WOPI, $04) 	; Wait, operate immediate - MTOS = TAN(MTOS)
	RET
;
; *************
; * AMD: ASIN *
; *************
;
ZASIN	CALL_B(WOPI, $05) 	; Wait, operate immediate - MTOS = ASIN(MTOS)
	RET
;
; *************
; * AMD: ACOS *
; *************
;
ZACOS	CALL_B(WOPI, $06) 	; Wait, operate immediate - MTOS = ACOS(MTOS)
	RET
;
; ************
; * AMD: ATN *
; ************
;
ZATAN	CALL_B(WOPI, $07)	; Wait, operate immediate - MTOS = ATAN(MTOS)
	RET
;
; ****************************************
; * AMD: CHANGE CONTENTS MTOS TO INTEGER *
; ****************************************
;
ZFIX	CALL_B(WOPI, $1E) 	; Wait, operate immediate - MTOS = INT(MTOS)
	RET
;
; *********************
; * AMD: INT ADDITION *
; *********************
;
; MTOS = MTOS + MEM
;
; Entry: HL points to number in memory
; Exit:  all registers preserved
;
ZIADD	CALL_B(WLOPI, $2C) 	; Wait, 1oad, operate imm. - INT addition
	RET
;
; ************************
; * AMD: INT SUBTRACTION *
; ************************
;
; MTOS = MTOS - MEM
;
; Entry: HL points to number in memory
; Exit:  all registers preserved
;
ZISUB	CALL_B(WLOPI, $2D) 	; Wait, load, operate imm. - INT subtraction
	RET
;
; ***************************
; * AMD: INT MULTIPLICATION *
; ***************************
;
; MTOS = MTOS * MEM
;
; Entry: HL points to number in memory
; Exit:  all registers preserved
;
ZIMUL	CALL_B(WLOPI, $2E) 	; Wait, load, operate imm. - INT multiplication
	RET
;
; *********************
; * AMD: INT DIVISION *
; *********************
;
; MTOS = MTOS / MEM
;
; Entry: HL points to number in memory
; Exit:  all registers preserved
;
ZIDIV	CALL_B(WLOPI, $2F) 	; Wait, 1oad, operate imm. - INT division
	RET
;
; *****************************
; * AMD: INT DIVIDE REMAINDER *
; *****************************
;
; MTOS = INT remainder of MTOS / MEM
;
; Entry: HL points to number 1n memory
; Exit:  all registers preserved
;
ZIREM	CALL_B(WOPI, $37) 	; Wait, operate immediate - Push MTOS
	CALL	ZIDIV	; INT divide
	CALL	ZIMUL	; INT multiply back
	CALL_B(WOPI, $2D) 	; Wait, operate immediate - Subtract: difference = remainder
	RET
;
;
;
; ****************
; * AMD: INT ABS *
; ****************
;
; MTOS = absolute value of MTOS (INT).
;
ZIABS	PUSH	PSW
	CALL	M4STAT	; Get status bits
	NOP
	ADD	A	; Test bit 6 (sign)
	CM	ZICHS	; Change sign MTOS if reqd
	POP	PSW
	RET
;
; *******************************
; * AMD: CHANGE SIGN MTOS (INT) *
; *******************************
;
ZICHS	CALL_B(WOPI, $34)	; Wait, operate immediate - MTOS = -MTOS
	RET
;
; **************************************
; * AMD: WAIT, LOAD, OPERATE IMMEDIATE *
; **************************************
;
; CALL has to be followed by a 1 byte AMD command.
;
WLOPI	CALL	WMATH	; Wait for ready, evt. error indications
	CALL	ZLOAD	; Load 2nd operand in MTOS
OPI	XTHL		; HL pnts to command byte
	PUSH	PSW
	CALL	LECCC	; Issue command to AMD
	POP	PSW
	XTHL		; Restore returnaddr
	RET
;
; ********************************
; * AMD: WAIT, OPERATE IMMEDIATE *
; ********************************
;
; CALL has to be followed by a 1 byte AMD command.
;
 WOPI	CALL	WMATH	; Wait ready, evt. error indications
	JMP	OPI	; Issue command to AMD
;
; **********************************
; * AMD: WAIT FOR MATH. CHIP READY *
; **********************************
;
; Waits for math. chip ready. Handles eventual errors if found.
;
; Exit: If no error: all registers preserved
;
WMATH	PUSH	PSW
@E53C	LDA	MSTATUS	; Get status math. chip
	ORA	A
	JM	@E53C	; If busy: wait for ready
	ANI	$1E	; Error codes only
	JZ	@E55D	; Abort if no errors
	NOP
	CALL	AMD_RST	; Reset AMD status
	RAR
	RAR
	CC	FPEOV	; Evt. run overflow error
	RAR
	CC	FPEUN	; Evt. run underflow error
	RAR
	CC	FPEAE	; Evt. run argument error
	RAR
	CC	FPEDO	; Evt. run divide by 0 error
@E55D	POP	PSW	; Normal return
	RET
;
; ********************************************
; * AMD: COPY REGISTERS A, B, C, D INTO MTOS *
; ********************************************
;
ZPUT	PUSH	PSW
	MOV	A, D	; D into A
	CALL	WMATH	; Wait ready
LE564	STA	MDATA	; Copy (D) into MTOS
	MOV	A, C	; C into A
	STA	MDATA	; Copy (C) into MTOS
	MOV	A, B
	JMP	LECD9	; Copy (B)+(A) into MTOS
;
; ********************************************
; * AMD: COPY MTOS INTO REGISTERS A, B, C, D *
; ********************************************
;
ZGET	CALL	WMATH	; Wait ready
	LDA	MDATA	; Get hibyte from MTOS
	PUSH	PSW	; Save it on stack
	LDA	MDATA	; Get 2nd byte from MTOS
	MOV	B, A	; Store it in B
	LDA	MDATA	; Get 3rd byte from MTOS
	MOV	C, A	; Store it in C
	LDA	MDATA	; Get 1obyte from MTOS
	MOV	D, A	; Store it in D
	JMP	LE564	; Restore MTOS
;
; **************
; * (not used) *
; **************
;
LLE585	MOV	D, L
	POP	H
	RET
;
; *******************************
; * AMD: COPY OPERAND INTO MTOS *
; *******************************
;
; Entry: HL points to 1st byte of operand
; Exit:  all registers preserved
;
ZLOAD	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	MOV	A, M	; 1st byte in A
	INX	H
	MOV	B, M	; 2nd byte in B
	INX	H
	MOV	C, M	; 3rd byte in C
	INX	H
	MOV	D, M	; 4th byte in D
	CALL	ZPUT	; Copy ABCD into MTOS
	JMP	EXIT	; Popall, ret
;
; *****************************
; * AMD: COPY MTOS TO OPERAND *
; ******************************
;
; Entry: HL points to 1st byte of operand
; Exit:  all registers preserved
;
ZSAVE	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ZGET	; Copy MTOS into ABCD
	MOV	M, A
	INX	H
	MOV	M, B
	INX	H	; Copy ABCD into operand
	MOV	M, C
	INX	H
	MOV	M, D
	JMP	EXIT	; Popall,  ret
;
; ************************
; * CALCULATE TAYLOR SUM *
; ************************
;
; Entry: HL points to a list with FPT constants  (Mi with i = 0, 1, 2, ...).
;        MACC: Const. term of Taylor series  (S0)
;        $00E5-E6: Initial pawer pf argument (P)
;        $00E7-EA: Argument X
;
; Routine computes:
; Sum = S0 + MO*P + M1*P*X + M2*P*X^2 + .....
;
; Exit: SUM: Sum of series
;       XN: Last P*X^i added in
;       XK: preserved
;       MACC + ABCD: sum of series
;       FEHL corrupted
;
LE5AA	PUSH	H	; Save table pntr
	LXI	H, SUM
	CALL	ASAVE	; Copy MACC (S0) into 00EB-EE
	LXI	H, FPT_F
	CALL	LE9FB	; Copy $00E3-E6 (P) into MACC
@E5B7	POP	H
	PUSH	H	; Get and save table pntr
	CALL	AMUL	; MACC = P * Mi
	LXI	H, SUM
	PUSH	H
	CALL	AADD	; MACC = sum + P * Mi
	POP	H
	CALL	ASTORE	; Result in SUM
	LDA	EXFDF	; Get difference in exp
	ORA	A
	JP	@E5D3
	CPI	$E8
	JC	@E5F3
@E5D3	POP	H	; Get table pntr
	INX	H
	INX	H
	INX	H
	INX	H	; HL pnts to next table entry
	PUSH	H	; Save table pntr
	INX	H
	MOV	A, M
	ORA	A
	JP	@E5F3	; Jump if ready
	LXI	H, XN
	PUSH	H
	CALL	LE9FB	; Copy XN into MACC and reg ABCD
	LXI	H, XK
	CALL	AMUL	; Multiply with XK
	POP	H	; HL=00E3
	CALL	ASTORE	; Copy ABCD into XN
	JMP	@E5B7	; Calc next sum
;
@E5F3	POP	H
	CALL	ATEST	; Copy result into MACC and reg ABCD
	RET
;
;
;
; ************
; * FPT SQRT *
; ************
;
; MACC = SQRT(MACC)
;
; Method: approximation followed by Newton iterations.
;
; Let X = 2 ^ (2K) * F. Then 2^(2K) is exponent and F is mantissa.
;
; Then SQRT(X) = 2^K*SQRT(F). 2^K is exp/2
;      SQRT(F) = P(i):
;                1st approx: P(1) = a * F + b
;                            0.5<= F < 1: values a1 and b1
;                              1<= F < 2: values a2 and b2
;                Iterations: P(i+1) = (P(i) + F / P(i))/2
; Final SQRT(F): P(3)
;
; Exit: all registers preserved
;
XSQRT	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	TSTZA	; Exp. byte MACC in A (2K)
	JZ	@E63A	; Abort if MACC=0
	RLC
	JC	FASER	; Run argument error if nr in MACC is negative
	RLC
	RRC
	RAR
	ORA	A
	RAR		; A is exp/2 (K)
	PUSH	PSW	; Save it
	MVI	A, $00	; Set A=0 if lsb exp=0
	LXI	D, LE65F	; Addr al, b1 for 0.5<=F<1
	JNC	@E618
	INR	A	; Set A=1 if 1sb exp=1
	LXI	D, LE657	; Addr a2, b2 for 1<=F<2
@E618	MOV	M, A	; Init exp byte MACC
	PUSH	H	; Save addr MACC
	LXI	H, FPT_F
	CALL	XSAVE	; Copy MACC (F) into FPT_F
	XCHG
	PUSH	H	; Save addr a/b
	CALL	AMUL	; Calc a*F
	POP	H
	INX	H
	INX	H
	INX	H
	INX	H	; Pnts to b
	CALL	AADD	; Calc P(1)=a*F*+b
	CALL	@E63D	; Calc P(2)
	CALL	@E63D	; Calc P (3)3 result in MACC and reg ABCD
	POP	H	; Get addr MACC
	POP	B	; Get exp/2 (K) in B
	ADD	B	; Add it to exp SQRT (F)
	ANI	$7F	; Result must be positive
	MOV	M, A	; Final exp. byte into MACC
	NOP
@E63A	JMP	EXIT	; Popall, ret
;
; Calculate P(i+1)
;
@E63D	LXI	H, FPT_P
	PUSH	H
	CALL	ASTORE	; Copy P(i) into FPT_P
	LXI	H, FPT_F
	CALL	LE9FB	; Copy F from FPT_F into MACC
	POP	H
	PUSH	H
	CALL	ADIV	; Calc F/P(i)
	POP	H
	CALL	AADD	; Calc P(i)+F/P(i)
	DCR	A	; exp minus 1: divide by 2
	ANI	$7F	; Skip sign bitt
	RET
;
; CONSTANTS FOR XSQRT
;
 LE657	.byte	$7F, $D2, $D0, $1C	; al: 0.578125
	.byte	$00, $99, $EE, $14	; b1: 0.421875
 LE65F	.byte	$00, $94, $00, $00	; a2: 0.411744
	.byte	$7F, $D8, $00, $00	; b2: 0.601289
;
; ***********
; * FPT EXP *
; ***********
;
; MACC = E ^ MACC
;
; Method: Polynomial approximation
;
; Test for overflow is modified. Overflow occurs for e^X when -45 < X < 43.6.
; This is checked now before exponent routine is entered.
; Let E^X= 2^n * 2^d * 2^z
;     Then X/ln2 = n + d + Z
;        n: integral portion of the real number
;        d: a discrete fraction (1/8, 3/8, 5/8 or 7/8) of the fractional part
;        z: remainder: -1/8 <= z <= 1/8
; Approximation for 2^z
; 2^z = a0 + a1*z + a2*z^2 + ... + a5*z^5
;
XEXP	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LDA	FPAC	; Get exp. byte
	STA	SIGNXN	; Save it
	CALL	LE9EE	; MACC = ABS(MACC)
	LXI	H, LE72B	; Addr 1/ln2
	CALL	AMUL	; Calc X/ln2
	CALL	PLISH	; Result (n+d+z) on stack
	CALL	XFIX	; Convert MACC to INT(n)
	CALL	XGET	; n in ABCD
	CALL	POF	; Get (n+d+z) from stack
	ORA	B
	ORA	C
.if ROMVERS == 11
	JZ	XEFC9	; Jump if n <= 255
.endif
.if ROMVERS == 10
	JZ	LE694	; Jump if n <= 255
.endif
;
; If X too big
;
LE68B	LDA	SIGNXN	; Get exp. byte
	CMA		; Take complement
	ORA	A	; Set flags for error
	STC		; Init error exit
	JMP	LE6F5	; Run error abort
;
; Find d
;
LE694	PUSH	D	; Save n
	CALL	XFRAC	; MACC = FRAC(MACC)
	LXI	D, _FP1o8	; Addr FPT(1/8)
	LHLD	FPAC
	ORA	L
	JZ	LEFF9
	CPI	$7F
	JC	LE6B8
	LXI	D, LE6FF	; Addr FPT(3/8)
	JMP	LE6B8
LE6AD	RLC
	RLC
	LXI	D, LE703	; Addr FPT(5/8)
	JNC	LE6B8
	LXI	D, LE707	; Addr FPT(7/8)
LE6B8	XCHG		; Addr d in HL
	PUSH	H	; Save 1t
	CALL	ASUB	; MACC = MACC-d (z)
	MOV	E, A	; Exp. z in E
	LDA	SIGNXN	; Get exp.
	RLC		; Sign into carry
	PUSH	PSW	; Save sign
	MOV	A, E	; Get exp.
	CC	ACHGS	; Evt. change sign
	LXI	H, XN
	CALL	ASTORE	; Copy 2 into XN
	CALL	ASTORE	; and in XK
	LXI	H, FP1	; Addr a0 (FPT(1))
	CALL	LE9FB	; Copy a0 into MACC
	LXI	H, LE72F	; Addr table a1-a5
	CALL	LE5AA	; Calc Taylor sum 2^z
	POP	PSW	; Get exp. byte X SHL 1
; Sign in CY
	POP	D	; Get addr FPT (n/8)
	PUSH	PSW
	LXI	H, $0010	; Init offset for table L1E283
	JNC	@E6E6	; Jump if X was positive
	DAD	H	; Offset is $0020 for neg. nr.
@E6E6	DAD	D	; Calc addr in LIE283
	CALL	AMUL	; Calc 2^2 * 2^d
	POP	PSW	; Get CY on sign of X
	POP	H	; Get n in H
	MOV	A, H
	JNC	@E6F2	; Jump if X was positive
	CMA		; else complement n
	INR	A
@E6F2	CALL	LC1B7	; Add exponents (n+d+z)
LE6F5	CC	OVUNF	; Evt error handling
LE6F8	JMP	EXIT	; Popall, ret
;
; CONSTANTS FOR 'XEXP'
;
_FP1o8	.byte	$7E, $80, $00, $00	; FPT(1/8)
LE6FF	.byte	$7F, $C0, $00, $00	; FPT(3/8)
LE703	.byte	$00, $A0, $00, $00	; FPT(5/8)
LE707	.byte	$00, $E0, $00, $00	; FPT(7/8)
LE70B	.byte	$01, $8B, $95, $C2	; 2^(1/8)
	.byte	$01, $A5, $FE, $D7	; 2^(3/8)
	.byte	$01, $C5, $67, $2A	; 2^(5/8)
	.byte	$01, $EA, $C0, $C7	; 2^(7/8)
LE71B	.byte	$00, $EA, $C0, $C7	; 2^(-1/8)
	.byte	$00, $C5, $67, $2A	; 2^(-3/8)
	.byte	$00, $A5, $FE, $D7	; 2^(-5/8)
	.byte	$00, $8B, $95, $C2	; 2^(-7/8)
LE72B	.byte	$01, $B8, $AA, $3B	; 1/LN2
LE72F	.byte	$00, $B1, $72, $18	; al: LN2 0.69314718057
	.byte	$7E, $F5, $FD, $EF	; a2: ((LN2)^2)/2! 0.24022648580
	.byte	$7C, $E3, $58, $46	; a3: ((LN2)^3)/3! 0.055504105406
	.byte	$7A, $9D, $A4, $81	; a4: ((LN2)^4)/4! 0.0096217389747
	.byte	$77, $AE, $D1, $FE	; a5: ((LN2)^5)/5! 0.0013337729375
; End of table
	.byte	$00, $00
;
; *******
; * LOG *
; *******
;
; MACC = LN(MACC)
;
; Method: Polynomial approximation.
;
; Write X = 2^K * F (normalized written), with 0.5 <= F < 1
;     If F < SQR(2)/2: J=K-1, G=2*F
;     If F > SQR(2)/2: J=K,	G=F
; Now X = 2^J * G.
;
; Assume G = (1+v)/(1-v), then: ln(X) = J*ln(2) + 1n((1+v)/(1-v))
;
; ln((1+v)/(1-v)) = 2(v+v^3/3+v*5/5+...+v^9/9)
; Only terms up to v^9 are used. The term constants are adjusted for minimum error.
;
; Exit: XN: Last significant summand
;       XK: v^2
;       SUM: Entry MACC(X)
;       MACC:     Result
;       Al1 registers preserved
;
XLN	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	TSTZA	; Check contents MACC
	JZ	FASER	; Run argument error if MACC = 0
	ORA	A
	JM	FASER	; Error if nr is negative
	CALL	SEXT	; Sign extend exp (=K)
	PUSH	PSW	; Save sign extended exp
	MVI	M, $00	; Frig exponent
	LDA	FPAC+1	; Get hibyte mantissa
	CPI	$B5	; Compare with SQR(2)/2
	JNC	FLNA	; if F < SQR(2)/2
;
; If F > SQR(2)/2
;
	LXI	H, FP2	; Addr FPT(2)
	CALL	AMUL	; Calc MACC = 2*F (=G)
	POP	PSW	; Get K
	DCR	A	; J=K-1
	PUSH	PSW	; Save J
;
FLNA	LXI	H, FP1	; Addr FPT(1)
	CALL	AADD	; MACC = G+1
	CALL	PLISH	; Save G+1 on stack
	LXI	H, FP2	; Addr FPT(2)
	CALL	ASUB	; MACC = G-1
	LXI	H, $0000
	DAD	SP	; HL=SP
	CALL	ADIV	; MACC = (G-1)/(G+1) (=v)
	INX	SP	; Suppress 4 bytes on stack
	INX	SP
	INX	SP
	INX	SP
	LXI	H, XN
	CALL	ASTORE	; Copy v into XN
	PUSH	H	; Pnts to $00E7
	CALL	PLISH	; Save v on stack
	LXI	H, $0000
	DAD	SP	; HL=SP
	CALL	AMUL	; MACC = v^2
	INX	SP	; Suppress 4 bytes on stack
	INX	SP
	INX	SP
	INX	SP
	POP	H	; HL=$00E7
	CALL	ASTORE	; Copy v^2 into $00E7-EA
	POP	D	; Get J in D
	MOV	A, D	; Convert J from 1 byte into 4 byte into ABCD
	RAL
	SBB	A
	MOV	B, A
	MOV	C, A
	CALL	XPUT	; Copy ABCD into MACC
	CALL	XFLT	; MACC = INT(MACC)
	LXI	H, XLN_C	; Addr 1n(2)
	CALL	AMUL	; MACC = MACC*1n(2) (=J*1n(2))
	LXI	H, XLN_T	; Addr Taylor sum constants
	CALL	LE5AA	; Calc Taylor sum (= ln(X))
	JMP	EXIT	; Popall, ret
;
; CONSTANTS FOR XLN
;
XLN_C	.byte	$00, $B1, $72, $18	; LN(2)
XLN_T	.byte	$02, $80, $00, $00	; b1: FPT(2)
	.byte	$00, $AA, $AA, $A9	; b3: about 2/3 = 0.666666564181
	.byte	$7F, $CC, $CF, $45	; b5: about 2/5 = 0.400018840613
	.byte	$7F, $91, $AE, $AB	; b7: about 2/7 = 0.2845357266
	.byte	$7E, $80, $00, $00	; b9: about 2/9 = 0.125
; End of table
	.byte	$00, $00
;
;
;
; *******
; * SIN *
; *******
;
; MACC = SIN(MACC) (Angle expressed in radians).
;
; See XCOS for explanation
;
XSIN	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	JMP	LE7E3	; To comnon part XSIN/XCOS
;
; *******
; * COS *
; *******
;
; MACC = COS(MACC) (Angle expresed in radians).
;
; Method: Polynomial approimation
;
; Cos(X) is converted: cos(X) = sin (X+PI/2).
;
; Given X, N and Y are defined for:
;       X/(2*PI) = N + Y; N is integer part
;
; All arguments are converted to a range -PI/2 to +PI/2:
;    sin(N*2*PI+K) = sin(K)
;    sin(PI/2+K)   = sin(PI/2-K)
;    sin(PI*3/2+K) = sin(PI*3/2-K)
;    sin(-PI/2+K)  = sin(-PI/2-K)
;
; Polynomial approx. F(Y) for sin(2*PI*Y) is:
;      F(Y) = a1*Y + a2*Y^3 + ... + a5*Y^9
;
XCOS	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	H, FPHPI	; Addr PI/2
	CALL	AADD	; X = X + PI/2
;
; Entry: from XSIN
;
LE7E3	LXI	H, LE83F	; Addr PI*2
	CALL	ADIV	; MACC = X/(2*PI) = N+Y
	CALL	XFRAC	; Get FRAC(MACC) = Y
	LXI	H, FPAC	; Addr MACC
	MOV	A, M	; Get exp. byte
	ANI	$7F	; Exp only
	JZ	@E7FA	; Jump if exp is 0
	CPI	$7E
	JC	@E818	; Jump if exp < $7E
@E7FA	CMP	M	; Comp masked/non-masked exp
	LXI	H, FP1	; Addr FPT(1)
	CNZ	AADD	; Add 1 to Y if X negative
	LXI	H, LE837	; Addr FPT (0.25)
	PUSH	H	; Save pntr
	CALL	ASUB	; MACC = MACC - 0.25
	CALL	LE9EE	; Take abs. value
	LXI	H, LE83B	; Addr FPT (0.5)
	CALL	ASUB	; MACC = MACC - 0.5
	CALL	LE9EE	; Take abs. value
	POP	H	; Get addr FPT (0.25)
	CALL	ASUB	; MACC = MACC - 0.25
@E818	LXI	H, XN
	PUSH	H
	CALL	ASAVE	; Copy MACC into XN
	XTHL		; HL=XN; stack: $00E7
	CALL	AMUL	; MACC = 2 * MACC
	POP	H	; HL=$00E7
	CALL	ASTORE	; Copy 2*MACC into $00E7-EA
	CALL	AZERO	; Clear MACC + reg ABCD
	LXI	H, LE83F	; Addr Taylor sum constants
	CALL	LE5AA	; Calc Taylor sum
	JMP	EXIT	; Popall, ret
;
; CONSTANTS FOR 'XSIN' AND 'XCOS'
;
FPHPI	.byte	$01, $C9, $0F, $DB	; FPT (PI/2)
LE837	.byte	$7F, $80, $00, $00	; FPT (0.25)
LE83B	.byte	$00, $80, $00, $00	; FPT (0.5)
LE83F	.byte	$03, $C9, $0F, $DB	; al: about PI*2 6.2831853
	.byte	$86, $A5, $5D, $E2	; a2: about -(PI*2)^3/3! -41.341681
	.byte	$07, $A3,	$34, $78	; a3: about  (PI*2)^5/5!  81.602481
	.byte	$87, $99, $29, $9E	; a4: about -(PI*2)^7/7! -76.581285
	.byte	$06, $9F, $0A, $FB	; a5: about  (PI*2)^9/9!  39.760722
; End of table
	.byte	$00, $00
;
; *********
; * POWER *
; *********
;
; MACC = MACC ^ MEM
;
; Entry: HL Points to power in memory
; Exit:  all registers preserved
;
; Conditions for a^X:
;       a > 0
;       ABS (x*ln(a)) in valid range.
;
; Method: a^X = e^(X*ln(a))
;
XPWR	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	H	; Save addr X
	CALL	ATEST	; Get a in reg ABCD
	POP	H	; Restore addr X
	JZ	@E86D	; Abort if a = 0
	JM	FASER	; Argument error if nr < 0
	CALL	XLN	; MACC = ln(a)
	CALL	AMUL	; MACC = X*ln(a)
	CALL	XEXP	; MACC = e^(X*ln(a))
@E86D	JMP	EXIT	; Popall, ret
;
; ********
; * LOGT *
; ********
;
; MACC = LOG(MACC)
;
; Method: 1og(X) = ln(x) / 1n(10)
;
; Exit: al1 registers preserved
;
XLOG	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	XLN	; MACC = ln(ABS(X))
	LXI	H, FLGTI	; Addr 1/ln(10)
	CALL	AMUL	; MACC = ln(x)/ln(10)
	JMP	EXIT	; Popall, ret
;
; ********
; * ALOG *
; ********
;
; MACC = ALOG(MACC)
;
; Method: 10^X = e^(X*1n(10))
;
; Exit: all registers preserved
;
XALOG	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	H, FLGTI	; Addr 1/ln(10)
	CALL	ADIV	; MACC = X*ln(10)
	CALL	XEXP	; MACC = e^(X*ln(10))
	JMP	EXIT	; Popall, ret
;
; CONSTANT FOR 'XLOG' AND 'XALOG'
;
FLGTI	.byte	$7F, $DE, $5B, $D9	; 1/ln(10)
;
; *******
; * TAN *
; *******
;
; MACC = TAN(MACC)  (Angle in radians)
;
; Method: tan(X) = sin(X)/cos(X)
;         In-accurate for X close to 0 or close to n*PI/2
;
; Exit: all registers preserved
;
XTAN	PUSH	H
	CALL	PLISH	; Save X on stack
	CALL	XCOS	; MACC = cos(X)
	LXI	H, FTWRK
	CALL	XSAVE	; Store cos(X) in FTWRK
	CALL	POF	; Get X from stack
	CALL	XSIN	; MACC = sin(X)
	CALL	XFDIV	; MACC = sin(X)/cos(X)
	POP	H
	RET
;
; ********
; * ATAN *
; ********
;
; MACC = ATAN(MACC) (Angle expressed in radians).
;
; Method: Polynomial approximation.
;
; ATAN(Z) for -0.25 <= z <= 0.25 approximated by:
;       F(X) = X*(1 - Q1*X^2 + Q2*X^4- Q3*X^6)
;
; To cope with range:
;       ATAN(-Z) = -ATAN(Z)
;       ATAN(Z)  = a(k) + ATAN(Z-b(k))/(Z*b(k)+1)), with k = 1, 2 or 3,
;                  a(k) = k*PI/7,
;                  b(k) = TAN(a(k))
;
; Values for k:
;       k=0 if ARS(Z) < 0.25
;       k=1 if 0.25 < ABS(Z) < 0.75
;       k=2 if 0.75 < ABS(Z) < 2
;       k=3 if ABS(Z) > 2
;
; Then X = (Z-b(k))/(Z*b(k)+1), and
;        ATAN(Z) = a(k) + F(X), if Z >= 0
;        ATAN(Z) = -a(k) - F(X), if z < 0
;
XATAN	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	TSTZA	; Check if Z=0
	JZ	@E943	; Then abort
	PUSH	PSW	; Save exp byte
	CALL	LE9EE	; reg ABCD = ABS(Z)
	LXI	H, FTWRK
	CALL	ASTORE	; Copy ABS(Z) into 00EF-F2
;
; Calculate k
;
	CPI	$40
	JC	@E8D3	; Jump if exp < #40
	CPI	$7F
	MVI	A, $01
	JZ	@E8E6	; k=1 if exp=$7F
	LXI	H, FP0	; Addr FPT(0)
	PUSH	H
	JMP	@E915	; Cont wi th k=1, a(k)=0
@E8D3	CPI	$01
	MVI	A, $02
	JZ	@E8E6	; k=2 if exp=1
	JNC	@E8E3	; k=3 if exp>1
	MOV	A, B	; Get hibyte mantissa
	RLC
	RLC
	MVI	A, $01	; k=1 if (B)= 10.... k=2 if (B)= 11...
	CMC
@E8E3	CMC
	ACI	$00
;
@E8E6	ADD	A	; Final k in A
	ADD	A
	ADD	A	; * 8
	LXI	H, FATC1-8	; startaddr for a, b table
	MOV	E, A	; offset in DE
	MVI	D, $00
	DAD	D
	PUSH	H	; Addr a(k)
	LXI	D, $0004
	DAD	D
	PUSH	H	; Addr b(k)
	CALL	AMUL	; MACC = Z*b(k)
	LXI	H, FP1	; Addr FPT(1)
	CALL	AADD	; MACC = Z*b(k)+1
	LXI	H, FWORK
	CALL	ASTORE	; (Z*b(k)+1) into FWORK-E2
	LXI	H, FTWRK
	CALL	LE9FB	; ABS(Z) in MACC
	POP	H	; Addr b(k)
	CALL	ASUB	; MACC = Z-b(k)
	LXI	H, FWORK
	CALL	ADIV	; MACC = X = (Z-b(k)/(Z*b(k)+1)
@E915	LXI	H, FTWRK
	PUSH	H
	PUSH	H
	CALL	ASAVE	; Copy X into FTWRK
	POP	H
	CALL	AMUL	; MACC = X^2
	LXI	H, XN
	CALL	ASTORE	; Copy X^2 into XN
	CALL	ASTORE	; Copy X^2 into XK
	LXI	H, FP1	; Addr FPT(1)
	CALL	LE9FB	; Copy FPT(1) into MACC
	LXI	H, FATPL	; Start table Taylor constants
	CALL	LE5AA	; Calc Taylor sum
	POP	H
	CALL	AMUL	; Taylor sum * X (=F(X))
	POP	H
	CALL	AADD	; Add a(k) (= ATAN(Z))
	POP	PSW	; Get orig. exp byte
	ORA	A	; Was Z negative?
	CM	ACHGS	; Then MACC = -ATAN(Z)
@E943	JMP	EXIT	; Popall, ret
;
; CONSTANTS FOR 'XATN'
;
FATC1	.byte	$7F, $E5, $C8, $FA	; a(1): PI/7       0.4487989506
	.byte	$7F, $F6, $90, $F3	; b(1): TAN(a(1))  0.4815746188
	.byte	$00, $E5, $C8, $FA	; a(2): 2*PI/7     0.8975979011
	.byte	$01, $A0, $81, $C6	; b(2): TAN(a(1))  1.253960337
	.byte	$01, $AC, $56, $BB	; a(3): 3*PI/7     1.346396852
	.byte	$03, $8C, $33, $7F	; b(3): TAN(a(3))  4.381286272
FATPL	.byte	$FF, $AA, $AA, $2D	; Q1: about -1/3  -0.333329573
	.byte	$7E, $CC, $6E, $B3	; Q2: about  1/5   0.199641035
	.byte	$FE, $86, $F1, $4F	; Q3: about -1/7  -0.131779888
; End of table
	.byte	$00, $00
;
; ********
; * ASIN *
; ********
;
; MACC = ASIN(MACC). Result in radians.
;
; Range: -PI/2 < X < PI/2
;
; Method: ASIN(X) = ATAN(X/SQR(1-x^2))
;
; Exit: all registers preserved
;
XASIN	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ATEST	; Get X in reg ABCD
	MOV	E, A	; Exp byte in E
	ANI	$7F	; Mask sign
	CPI	$01
	JC	LE999	; Jump if in range
	JNZ	LE994	; If >2 or <1
	MOV	A, B	; Check if mantissa = 80 00 00 (= +/- 1)
	ANI	$7F
	ORA	C
	ORA	D
	JNZ	FASER	; Error if not
	MOV	A, E	; Get exp
	ORA	A	; Set flags on 1t
	LXI	H, FPHPI	; Addr PI/2
	CALL	XLOAD	; Copy PI/2 into MACC
	CM	ACHGS	; If nr<0: MACC = -PI/2
FASRET	JMP	EXIT	; Popall, ret
;
LE994	CPI	$40
	JC	FASER	; Error if exp<$40
LE999	CALL	PLISH	; Save X on stack
	LXI	H, $0000
	DAD	SP	; HL=SP
	CALL	AMUL	; MACC = X^2
	CALL	ACHGS	; MACC = -X^2
	LXI	H, FP1	; Addr FPT(1)
	CALL	AADD	; MACC = 1-X^2
	CALL	XSQRT	; MACC = SQR(1-X^2)
	LXI	H, FATZX
	CALL	XSAVE	; SQR(1-X^2) in 00EF-F2
	CALL	POF	; Get X from stack in MACC
	CALL	XFDIV	; MACC = X/(SQR(1-X*2))
	CALL	XATAN	; MACC = ATAN(MACC)
	JMP	FASRET	; Ready
;
; ********
; * ACOS *
; ********
;
; MACC = ACOS(MACC). Result in radians.
;
; Range: 0 < X < PI
;
; Method: ACOS(X) = PI/2 - ASIN(X)
;
; Exit: all registers preserved
;
XACOS	CALL	XASIN	; MACC =  ASIN(X)
	CALL	XFCHS	; MACC = -ASIN(X)
	PUSH	H
	LXI	H, FPHPI	; Addr PI/2
	CALL	XFADD	; MACC = PI/2 - ASIN(X)
	POP	H
	RET
;
; Error exit
;
FASER	CALL	FPEAE	; Run argument error
	JMP	FASRET	; Abort
;
; **********************************************
; * COPY MACC INTO OPERAND AND INTO A, B, C, D *
; **********************************************
;
; Entry: HL points to operand
; Exit:  HL points past operand
;        AFBCD set as for ATEST
;
; Fron ASTORE used to store reg A, B, C, D into an operand, ponted at by HL.
;
ASAVE	PUSH	H
	CALL	ATEST	; Copy MEM into MACC and ABCD
	POP	H
ASTORE	MOV	M, A	; Copy reg A, B, C, D into MEM
	INX	H
	MOV	M, B
	INX	H
	MOV	M, C
	INX	H
	MOV	M, D
	INX	H
	RET
;
; *******************************
; * SUBROUTINE CHANGE SIGN MACC *
; *******************************
;
ACHGS	CALL	TSTZA	; Check if MACC empty
	RZ		; Then ready
	LXI	B, $FF80	; Set mask
	JMP	LE9F1	; Change sign bit
;
; *****************************
; * SUBROUTINE FPT ABS (MACC) *
; *****************************
;
; From ATEST also used to copy MACC into ABCD.
; From L1E158 used to copy operand (pointd at by HL) into ABCD and into MACC.
;
LE9EE	LXI	B, $7F00	; Set mask
LE9F1	LXI	H, FPAC	; Addr. MACC
	MOV	A, B	; Mask in A
	ANA	M	; AND exp byte with mask
	XRA	C	; Set sign bit 0
	MOV	M, A	; Update exp byte MACC
;
ATEST	LXI	H, FPAC	; Addr MACC
LE9FB	CALL	TSTZ	; Check if MEM = 0, get exp byte in A
	JZ	AZERO	; Then clear MACC + ABCD
	MOV	E, A	; exp byte in E
	INX	H	; Mantissa from MEM into BCD
	MOV	B, M
	INX	H
	MOV	C, M
	INX	H
	MOV	D, M
	LXI	H, FPAC	; Addr MACC
	JMP	LEB17	; Copy ABCD into MACC; exp from E in A, flags set on exp ORI $01
;
;
;
; ******************************************
; * COPY OPERAND INTO REGISTERS B, C, D, E *
; ******************************************
;
; Entry: HL points to operand
; Exit:  HL points to 1ast byte of operand
;        AF preserved
;
LEA0E	MOV	B, M
	INX	H
	MOV	C, M
	INX	H
	MOV	D, M
	INX	H
	MOV	E, M
	RET
;
; ***************************************
; * CLEAR MACC AND REGISTERS A, B, C, D *
; ***************************************
;
AZERO	LXI	H, FPAC	; Addr MACC
	XRA	A	; Clear ABCD
	MOV	B, A
	MOV	C, A
	MOV	D, A
	JMP	ASTORE	; Clear MACC
;
; *************************
; * FPT DIVIDE SUBROUTINE *
; *************************
;
; MACC = MACC / MEM. Rounded quotient in MACC and registers ABCD, exponent in E.
;
; Entry: HL points to operand
; Exit:  CY=1: overflow, result invalid
;        CY=0: result in ABCD, EHL corrupted
;
ADIV	CALL	TSTZ	; Test if MEM=0; exp byte in A
	JZ	DIV0	; Then run divide by 0 error
	PUSH	PSW	; Save exp MEM
	ANI	$80	; Sign bit onIy
	MOV	B, A	; Preserve sign
	POP	PSW	; Get exp MEM
	ANI	$7F	; Skip sign bit
	CMA		; 2-compl of exponent
	INR	A
	CPI	$C0	; Overflow in sign bit?
	JZ	OVERF	; Then run overflow error
	ANI	$7F	; Only compl. exp MEM
	ORA	B	; Add sign
	CALL	MDEX	; Subtract exponents
	JC	OVUNF	; Evt. run overflow error
	JZ	AZERO	; If zero result: clear MACC + ABCD
	CALL	DIVX	; Run fixed division
	JNC	LEB06	; Round up if no overflow
;
;  If overf1ow
;
OVERF	CALL	FPEOV	; Run overflow error
	STC		; Flag error
	RET
;
; ******************
; * ERROR HANDLING *
; ******************
;
; Entry: S=1: Overf1ow error
;        S=0: Underflow error
;        Z=1: Divide by zero error
;
OVUNF	JM	OVERF	; Evt run overflow error
UNDRF	CALL	FPEUN	; Run underf1ow error
	JMP	AZERO	; Clear MACC + ABCD
DIV0	CALL	FPEDO	; Run divide by 0 error
	STC		; Flag error
	RET
;
; *********************************
; * FPT MULTIPLICATION SUBROUTINE *
; *********************************
;
; MACC = MACC * MEM. Result in MACC and in registers A, B, C, D.
;
; Entry: HL points to operand in memory
; Exit:  CY=1: Overflow; result invalid
;        CY=0: Result in ABCD. EHL corrupted
;
AMUL	CALL	TSTZ	; Test if MEM=0; exp byte in A
	CNZ	MDEX	; Add exponents if not
	JC	OVUNF	; Evt run error
	JZ	AZERO	; Result 0: Clear MACC + ABCD
	CALL	MULX	; Multiply mantissa's
;
; Normalise if necessary
;
	MOV	A, B	; 1st product
	ORA	A
	JMP	LEB00	; Common exit with MUL/DIV
;
; ***************************
; * FPT SUBTRACT SUBROUTINE *
; ***************************
;
; MACC = MACC - MEM
;
; Entry: HL points to operand in memory
; Exit.  CY=1: Overflow
;        CY=0: Result in ABCD. EHL corrupted
;
ASUB	MVI	B, $80	; Mask to change sign of operand
	JMP	LEA74	; Into AADD
;
; **********************
; * FPT ADD SUBROUTINE *
; **********************
;
; MACC = MACC + MEM
;
; Entry: HL points to operand in memory
; Exit:  CY=1: Overflow
;        CY=0: Result in ABCD. EHL corrupted
;
AADD	MVI	B, $00	; Zero mask
LEA74	MVI	A, $7F	; Most possible value
	STA	EXFDF	; Set MACC >> MEM
	CALL	TSTZ	; Test if MEM=0; exp in A
	JZ	ATEST	; Then clear MACC + ABCD
	MOV	A, B	; Get mask
	XRA	M	; XOR with exp (ADD: gives exp; SUB: gives -exp)
	INX	H	; Copy mantissa MEM into B
	MOV	B, M
	INX	H
	MOV	C, M
	INX	H
	MOV	D, M
	MOV	E, A	; Exp in E
	LXI	H, FPAC	; Addr MACC
	MOV	A, M	; Get exp MACC
	XRA	E	; XOR with exp MEM
	ANI	$80	; Sign only
	STA	SUBF	; Store $80 1f different signs
	CALL	TSTZ	; Test if MACC=0; exp in A
	JZ	LEB11	; Jump if true
	PUSH	D
	MOV	A, E	; Get exp MEM
	CALL	SEXT	; Sign extend
	MOV	E, A	; Ext exp MEM in E
	MOV	A, M	; Get exp MACC
	CALL	SEXT	; Sign extend
	SUB	E	; Calc difference
	POP	D
	STA	EXFDF	; Save iit
	JM	@EAB2	; If exp MACC < exp MEM: exchange ABCD and MACC
	CPI	$19	; Total bits in mantissa
	JC	@EAC6	; OK if difference between both nrs < $19 in exp
	JMP	ATEST	; Else: Result is zero in MACC and ABCD
;
; Exchange MACC and ABCD
;
@EAB2	CPI	$E7	; Total bits in mantissa
	JC	LEB16	; If difference not too big
	MOV	M, E	; Ext exp MEM 1n MACC
	CMA		; A = ext exp old MACC
	INR	A
	INX	H
	MOV	E, M	; Exchange 1st byte MACC mantissa and byte in B
	MOV	M, B
	MOV	B, E
	INX	H
	MOV	E, M	; Exchange 2nd byte MACC mantissa and byte 1n C
	MOV	M, C
	MOV	C, E
	INX	H
	MOV	E, M	; Exchange 3rd byte MACC mantissa and byte in D
	MOV	M, D
	MOV	D, E	; Now orig MACC in ABCD and orig MEM in MACC
@EAC6	MVI	E, $00
	CALL	RSHN	; Shift BCDE right A places
	LDA	SUBF	; Get result XOR sign bits
	ORA	A
	LXI	H, FPAC+3	; Addr lobyte MACC
	JM	@EAEF	; Jump if different signbits
;
; If both signs equal
;
	MOV	A, M
	ADD	D
	MOV	D, A
	DCX	H
	MOV	A, M	; Add mantissa MACC to BCD. Result in BCD.
	ADC	C
	MOV	C, A
	DCX	H
	MOV	A, M
	ADC	B
	MOV	B, A
	JNC	LEB06	; Jump if no overflow
	CALL	LEB70	; Else: shift BCDE right 1 bit
	CALL	LEBD9	; Incr exponent
	JC	OVERF	; Evt run overflow error
	JMP	LEB06	; Round up
;
; If both signs not equal
;
@EAEF	XRA	A	; Compl exp in E
	SUB	E
	MOV	E, A
	MOV	A, M
	SBB	D
	MOV	D, A	; Subtract BCD from mantissa MACC. Result in BCD.
	DCX	H
	MOV	A, M
	SBB	C
	MOV	C, A
	DCX	H
	MOV	A, M
	SBB	B
	MOV	B, A
	CC	LEB7D	; Correct if overflow
LEB00	CP	LEB96	; Evt normalize BCDE
	JP	AZERO	; and clear MACC + ABCD
;
; Normal exit
;
LEB06	CALL	LEBC3	; Round up BCD, result in MACC exp in E
	JC	OVERF	; Evt run overflow error
LEB0C	MOV	A, E	; Get exponent
	ORI	$01	; Set flaqs on exp OR 1
	MOV	A, E	; Exp in A
	RET
;
; If operand = 0
;
LEB11	MVI	A, $80
	STA	EXFDF	; (EXFDF)=$80
LEB16	MOV	A, E	; Get exponent
LEB17	CALL	ASTORE	; Copy ABCD into MACC
	JMP	LEB0C	; Take normal exit
;
; **********************
; * FPT: ADD EXPONENTS *
; **********************
;
; Adds the exponent of the MACC to the exponent of a operand in memory.
;
; Entry: HL points to FPT number in memory
;        A  contains its exponent
;        Other number in MACC
; Exit:   Z=1:      MACC=0:   HL=FPAC
;        CY=1:      Overflow: HL=FPAC; MACC pres
;                   A: Sum of signed exponents SHL 1
;        Z=0, CY=0: OK: HL=FPAC; sum of exponents in MACC
;
MDEX	MOV	B, A	; Exp MEM in B
	INX	H
	MOV	C, M	; Copy mantissa MEM in CDE
	INX	H
	MOV	D, M
	INX	H
	MOV	E, M
	CALL	TSTZA	; Test MACC=0; Exp MACC in A
	RZ		; Abort if MACC=0, Z=1
	MOV	A, B	; Get exp MEM in A
	CALL	SEXT	; Sign extend
	CALL	LC1BA	; Add exponents, result in MACC
	RC		; Abort if overflow, CY=1
	MOV	A, B	; Get orig exp MEM
	ANI	$80	; sign bit only
	XRA	M	; Evt correct sign
	MOV	M, A	; Exp back into MACC
	MVI	A, $01
	ORA	A
	RET
;
; *********************************
; * SHIFT BCDE LEFT (A) POSITIONS *
; *********************************
;
; Exit: AF preserved
;
LSHN	PUSH	PSW
	MOV	L, A	; Nr of shifts in L
@EB3B	DCR	L
	JM	@EB46	; Abort if ready
	ORA	A	; Clear CY
	CALL	LEB48	; Shift BCDE 1eft 1 position
	JMP	@EB3B	; Next shift
@EB46	POP	PSW
	RET
;
;
; *********************
; * MULTIPLY BCDE * 2 *
; *********************
;
; Shifts BCDE 1eft 1 position. Entry CY goes to 1sb of E.
;
; Exit: A  corrupted
;       HL preserved
;       F set on result
;
LEB48	MOV	A, E
	RAL		; Shift 1eft E
	MOV	E, A
	MOV	A, D
	RAL		; Shift left D
	MOV	D, A
	MOV	A, C
	RAL		; Shift left C
	MOV	C, A
	MOV	A, B
	ADC	A	; B=2*B+CY
	MOV	B, A
	RET
;
; **********************************
; * SHIFT BCDE RIGHT (A) POSITIONS *
; **********************************
;
RSHN	MVI	L, $08	; Nr of shifts for 1 byte
@EB57	CMP	L
	JM	@EB64	; Jump if A<8
;
; Shift 8 bits right
;
	MOV	E, D	; Shift 8 pos in one time
	MOV	D, C
	MOV	C, B
	MVI	B, $00
	SUB	L	; Update nr of shifts left
	JNZ	@EB57	; Again if not ready
;
; Shift 1 bit
;
@EB64	ORA	A
	RZ		; Abort if ready
	MOV	L, A	; L is nr of shifts
@EB67	ORA	A
	CALL	LEB70	; Shift BCDE right one bit
	DCR	L	; Update shift count
	JNZ	@EB67	; Again if not ready
	RET
;
; ********************
; * DIVIDE BCDE BY 2 *
; ********************
;
; Shifts contents BCDE right 1 position.
;
; Exits: AF corrupted
;        HL preserved
;
LEB70	MOV	A, B
	RAR		; Shift right B
	MOV	B, A
	MOV	A, C
	RAR		; Shift right C
	MOV	C, A
	MOV	A, D
	RAR		; Shift right D
	MOV	D, A
	MOV	A, E
	RAR		; Shift right E
	MOV	E, A
	RET
;
; ****************************************
; * CHANGE SIGN OF A NUMBER IN MEMORY    *
; * NEGATE CONTENTS REGISTERS B, C, D, E *
; ****************************************
;
; Entry: HL points to 1st byte mantissa.
;
LEB7D	DCX	H	; Pnts to exp
	MOV	A, M	; Get exp
	XRI	$80	; Change sign bit
	MOV	M, A
LEB82	XRA	A
	MOV	L, A	; L=0
	SUB	E
	MOV	E, A	; Negate E
	MOV	A, L
	SBB	D
	MOV	D, A	; Negate D
	MOV	A, L
	SBB	C
	MOV	C, A	; Negate C
	MOV	A, L
	SBB	B
	MOV	L, A	; Negate B in L
	ANA	B
	RAL		; msb into CY
	MOV	B, L	; B = negated B
	MOV	A, L
	RAR		; restore msb
	ADC	A	; A=2*A+CY
	RET
;
; *********************************************
; * NORMALIZE CONTENTS BCDE, CORRECT EXPONENT *
; *********************************************
;
; Entry: FPT mantissa in BCDE, exponent in MACC
;
; Mantissa is normalized and the exponent is adjusted correctly
;
LEB96	CALL	LEBA0	; Normalize BCDE
	CNC	LC1B7	; Add exponents if BCDE <> 0
	CMC
	RAR
	ORA	A
	RET
;
; *********************************
; * NORMALIZE CONTENTS B, C, D, E *
; *********************************
;
; Shifts contents BCDE 1eft until the msb = 1.
;
; Exit: A: Minus number of shifts
;       HL restored, S+Z-flag set on result
;       CY=1: BCDE was zero
;
LEBA0	PUSH	H
	MVI	L, $20	; Max 32 bits to shift
@EBA3	MOV	A, B	; Get 1st byte
	ORA	A
	JNZ	@EBBA	; If '1'-bits in it
;
; Shift 8 bits at once
;
	MOV	B, C	; Shift 1 byte
	MOV	C, D
	MOV	D, E
	MOV	E, A
	MOV	A, L
	SUI	$08	; count minus 8 bits
	MOV	L, A
	JNZ	@EBA3	; Continue if not ready
	POP	H
	STC		; If 4* 8 bits shifted and no '1' found: BCDE was 0: CY=1
	RET
;
; Shift 1 bit
;
@EBB6	DCR	L	; Update count
	CALL	LEB48	; Shift BCDE 1 bit left
@EBBA	JP	@EBB6	; Again if msb <> 0
;
; If ready
;
	MOV	A, L	; Get nr of shifts left
	SUI	$20	; Calc neg nr of shifts done
	ORA	A
	POP	H
	RET
;
; *********
; * ROUND *
; *********
;
; Rounds up a FPT mantissa in BCD(E). Result in MACC, exponent also in E.
;
; Entry: FPT mantissa in BCDE
; Exit:  CY=1: overflow
;        all registers corrupted
;
LEBC3	MOV	A, E	; Get 1obyte mantissä
	ORA	A
	CM	@EBD1	; Round up BCD if (E) >= $80
	RC		; Abort if overflow
	LXI	H, FPAC	; Addr MACC
	MOV	E, M	; Get exp in E
	MOV	A, M	; and in A
	JMP	ASTORE	; Copy ABCD into MACC
;
; ROUND UP CONTENTS B, C, D
;
; Increments a FPT mantissa in BCD with 1 in the lsb. If required, the normalized exponent
; is adjusted.
;
; Exit: CY=1: overflow
;       AEHL preserved
;
@EBD1	INR	D	; Add 1 to 1obyte
	RNZ
	INR	C	; Add 1 to other bits to if overflow
	RNZ
	INR	B
	RNZ
	MVI	B, $80	; If overflow from B: set B for smallest mantissa and increment exponent
;
; ************************************
; * INCREMENT A FPT EXPONENT OF MACC *
; ************************************
;
; *Exit: ABCDEHL preserved. CY1: Overflow
;
LEBD9	PUSH	B
	PUSH	PSW
	PUSH	H
	MVI	A, $01	; to be added to exponent
LEBDE	LXI	H, FPAC	; Addr MACC
	CALL	LC1BA	; Add 1 to exponent
	POP	H
	POP	B
	MOV	A, B
	POP	B
	RET
;
; ***********************************************
; * DECREMENT FPT EXPONENT OF MACC - (not used) *
; ***********************************************
;
LIE274	PUSH	B
	PUSH	PSW
	PUSH	H
	MVI	A, $FF	; -1 to be added to exponent
	JMP	LEBDE	; Add it to MACC exp
;
; ***************************
; * TEST IF OPERAND IS ZERO *
; ***************************
;
; TSTZA: Test if contents MACC is zero
; TSTZ:  Test if operand, pointed at by HL i5 zero
;
; Exit: A: hibyte operand
;       BCDE preserved
;       Z=1: Operand = 0.
;
TSTZA	LXI	H, FPAC	; Operand = MACC
TSTZ	MOV	A, M
	INX	H
	ORA	M
	INX	H
	ORA	M
	INX	H
	ORA	M	; Flags set on result OR on all bytes of operand
	DCX	H
	DCX	H
	DCX	H
	MOV	A, M	; Hibyte operand in A
	RET
;
;
;
; ************************
; * FIXED MULTIPLICATION *
; ************************
;
; Multiplies a mantissa in registers C, D, E with the mantissa of a number in the MACC.
; The result is in B, C, D, E (binary point left of B).
;
; Used for multiplication of mantissa's in a FPT multiplication.
;
; Exit: AFHL corrupted
;
MULX	MOV	A, C	; Mantissa fr om CDE into OP1, OP2, OP3
	STA	OP1
	MOV	H, D
	MOV	L, E
	SHLD	OP3
	XRA	A	; Clear ABCD
	MOV	D, A
	MOV	C, A
	MOV	B, A
	LDA	FPAC+3	; Get 1obyte MACC mantissa
	CALL	@EC1C	; Multiply
	LDA	FPAC+2	; Get next byte MACC mantissa
	CALL	@EC1C	; Multiply
	LDA	FPAC+1	; Get hibyte MACC mantissa
;
; Prepare multiplication
;
@EC1C	MOV	L, D
	MOV	E, C
	MOV	D, B
	MOV	B, A	; Byte from MACC in B
	XRA	A
	MOV	C, A
	SUB	B
	JC	@EC29	; Then multiply
	MOV	C, D
	MOV	D, E
	RET
;
; Multiply (product in BDCE)
;
@EC29	MOV	A, L
	ADC	A
	RZ		; Abort if 2*L+CY=0
	MOV	L, A	; Else update L
	CALL	LEB48	; Shift BCDE 1 bit left
	JNC	@EC29	; Again if no overflow
	LDA	OP3
	ADD	E
	MOV	E, A	; E=E+(OP3)
	LDA	OP2
	ADC	D
	MOV	D, A	; D=D+(OP2)+CY
	LDA	OP1
	ADC	C
	MOV	C, A	; C=C+(OP1)+CY
	JNC	@EC29	; Again if no overf1ow
	INR	B	; If overflow: B=B+1
	ORA	A	; Clear CY
	JMP	@EC29	; Again
;
; ******************
; * FIXED DIVISION *
; ******************
;
; Divides a mantissa in registers C, D, E by the mantissa of the number in the MACC.
; The result is in B, C, D and the msb of E. The remainder is in the rest of E and in HL.
;
; Used to divide mantissa's in a FPT division.
;
; Exit: AF corrupted
;       CY=1: overflow in adjusting exponents
;       CY=0: OK
;
DIVX	LXI	H, FPAC+3	; Addr 1obyte MACC
	MOV	A, M	; Mantissa MACC = CDE - mantissa MACC
	SUB	E
	MOV	M, A
	DCX	H
	MOV	A, M
	SBB	D
	MOV	M, A
	DCX	H
	MOV	A, M
	SBB	C
	MOV	M, A
	LXI	H, OP1	; Addr Save area
	STC
	MOV	A, C	; OP1, OP2, OP3 = CDE SHR 1 with nsb C=1
	RAR
	MOV	M, A
	DCX	H
	MOV	A, D
	RAR
	MOV	M, A
	DCX	H
	MOV	A, E
	RAR
	MOV	M, A
	DCX	H
	MVI	B, $00
	MOV	A, B
	RAR
	MOV	M, A	; OP4 = 00 or $80, depending on result RAR
	LXI	H, FPAC+1
	MOV	A, M	; Get mantissa MACC in ADE
	INX	H
	MOV	D, M
	INX	H
	MOV	E, M
	ORA	A
	JM	@ECC4	; Junp if normalised
	CALL	LEBD9	; Incr FPT exponent
	RC		; Abort if overflow
	MOV	L, E	; Remainder in EHL
	MOV	H, D
	MOV	E, A
	MVI	D, $01
	MOV	C, B
@EC83	PUSH	B
	MOV	B, H
	MOV	C, L
	LXI	H, OP4
	XRA	A
	SUB	M
	INX	H
	MOV	A, C
	SBB	M
	MOV	C, A
	INX	H
	MOV	A, B
	SBB	M
	MOV	B, A
	INX	H
	MOV	A, E
	SBB	M
	MOV	E, A
	MOV	L, C
	MOV	H, B
	POP	B
	LDA	OP4
@EC9D	RLC
	MOV	A, B
	RAL
	CMC
	RNC
	RAR
	MOV	A, L
	RAL
	MOV	L, A
	MOV	A, H
	RAL
	MOV	H, A
	CALL	LEB48	; Shift BCDE 1eft 1 bit
	MOV	A, D
	RRC
	JC	@EC83
@ECB1	PUSH	B
	MOV	B, H
	MOV	C, L
	LHLD	OP3
	DAD	B
	LDA	OP1
	ADC	E
	MOV	E, A
	POP	B
	LDA	OP4
	JMP	@EC9D
@ECC4	MOV	L, E
	MOV	H, D
	MOV	E, A
	MOV	D, B
	MOV	C, B
	JMP	@ECB1
;
; ***********************************
; * AMD: ISSUE COMMAND TO MATH.CHIP *
; ***********************************
;
; Entry: HL points to command
; Exit:  HL updated,
;        A corrupted
;        BCDEF preserved
;
LECCC	MOV	A, M	; Get command
	INX	H
	STA	MCOMD	; Issue cmd to math. chip
	RET
;
; ******************************
; * AMD: TURN OFF ERROR STATUS *
; ******************************
;
; Exit: all registers preserved
;
AMD_RST	PUSH	PSW
	XRA	A
	STA	MSTATUS	; Cmd math.chip = 0
	POP	PSW
	RET
;
; *****************************************
; * AMD: LOAD 16-BIT DATA INTO MATH. CHIP *
; *****************************************
;
; Entry: 1st byte in A, 2nd on stack
;
LECD9	STA	MDATA	; Load 1st byte in math. chip
	POP	PSW
	STA	MDATA	; Load data in math. chip
	RET
;
; **************************
; * part of 'IAND' (1E32C) *
; **************************
;
LECE1	CALL	LE38C	; Copy MACC into EBCA
	CALL	SIAND	; Run IAND
	JMP	LE385	; Copy ABCD into MACC
;
; *************************
; * part of 'IOR' (1E345) *
; *************************
;
LECEA	CALL	LE38C	; Copy MACC into EBCA
	CALL	SIOR	; Run IOR
	JMP	LE385	; Copy ABCD into MACC
;
; **************************
; * part of 'IXOR' (1E35C) *
; **************************
;
LECF3	CALL	LE38C	; Copy MACC into EBCA
	CALL	SIXOR	; Run IXOR
	JMP	LE385	; Copy ABCD into MACC
;
; ********************************************
; * COPY MACC INTO REGISTERS A, B, C, D; CMA *
; ********************************************
;
; Part of 1E373
;
LECFC	CALL	XGET	; Copy MACC into ABCD
	CMA		; Compl exponent byte
	RET
;
; ***************************************
; * COPY MACC INTO REGISTERS E, B, C, A *
; ***************************************
;
; Part of 1E38C.
;
LED01	CALL	XGET	; Copy MACC into ABCD
LED04	MOV	E, A	; Exp in E
	JMP	LE38F	; Copy BCDE into EBCA
;
; ***************************************
; * COPY MACC INTO REGISTERS B, C, D, E *
; ***************************************
;
;
; Part of SHR (1E398) and SHL (1E3A5).
; Tests if the value of a INT operand in menory is bigger than 32 (nr of bits for a mantissa).
; If not, the contents of the MACC is copied 1nto the registers BCDE.
; If the number is too big the registers BCDE are cleared.
;
; Entry: HL points to INT operand in memory
; *
LED08	CALL	XSTST	; Test if operand > 31; if true: clear ABCDE
	CZ	LE3D6	; If OK: nr in A, contents MACC into BCDE
	RET
;
; ************************************************
; * COPY CONTENTS MACC INTO REGISTERS B, C, D, E *
; ************************************************
;
; Entry: LED0F: Not used.
; Entry: LED13: Copy ABCD into BCDE.
;
LED0F	PUSH	PSW
	CALL	ZGET	; Copy MACC into ABCD
LED13	MOV	E, D	; Copy ABCD into BCDE
	MOV	D, C
	MOV	C, B
	MOV	B, A
	POP	PSW
	RET
;
; *************
; * AMD: IAND *
; *************
;
; MTOS = MTOS IAND MEM
;
; Entry: HL points to operand in memory
; Exit:  all registers preserved
;
ZIAND	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ZIGTP	; Copy MTOS into EBCA
	CALL	SIAND	; Run IAND
	JMP	LED3D	; Result into MTOS
;
; ************
; * AMD: IOR *
; ************
;
; MTOS = MTOS IOR MEM
;
; Entry: HL points to operand in memory
; Exit:  all registers preserved
;
ZIOR	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ZIGTP	; Copy MTOS into EBCA
	CALL	SIOR	; Run IOR
	JMP	LED3D	; Result into MTOS
;
; *************
; * AMD: IXOR *
; *************
;
; MTOS = MTOS IXOR MEM
;
; Entry: HL points to operand in memory
; Exit:  all registers preserved
;
ZIXOR	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ZIGTP	; Copy MTOS into EBCA
	CALL	SIXOR	; Run IXOR; result in ABCD
LED3D	CALL	ZPUT	; Copy ABCD into MTOS
	JMP	EXIT	; Popall, ret
;
; *************
; * AMD: INOT *
; *************
;
; MTOS = INOT(MTOS)
;
; Exit: all registers preserved
;
; REMARK: Wrong routine: MTOS is made -MTOS, and then 1 is added. So result is INOT(MTOS)+2.
;	Correct would be: Add -1
;
ZINOT	CALL	ZICHS	; Change sign MTOS (INT)
	PUSH	H
	LXI	H, I1	; Addr INT (1)
	CALL	ZIADD	; MTOS = -MTOS +1
	POP	H
	RET
;
; *******************************************
; * AMD: COPY MTOS INTO REGITERS E, B, C, A *
; *******************************************
;
ZIGTP	CALL	ZGET	; Copy MTOS into ABCD
	JMP	LED04	; Copy ABCD into EBCA
;
; ************
; * AMD: SHR *
; ************
;
; Shifts MTOS right MEM positions.
;
; Entry: HL points to INT number in memory
; Exit:  all registers preserved
;
ZSHR	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	XSTST	; Check value of MEM. Value in A. Clear ABCDE if too big
	CZ	ZGBCDE	; Else: Copy MTOS in BCDE
	CALL	RSHN	; Shift BCDE right A positions
ZRREG	MOV	A, B	; Copy BCDE into ABCD
	MOV	B, C
	MOV	C, D
	MOV	D, E
	CALL	ZPUT	; Copy ABCD into MTOS
	JMP	EXIT	; Popall, ret
;
; ************
; * AMD: SHL *
; ************
;
; Shifts MTOS 1eft MEM positions.
;
; Entry: HL points to INT number in memory
; Exit:  all registers preserved
;
ZSHL	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	XSTST	; Test value of MEM. Value in A. Clear ABCDE if too big
	CZ	ZGBCDE	; If OK: Copy MTOS into BCDE
	CALL	LSHN	; Shift BCDE 1eft A Pusitions
	JMP	ZRREG	; Copy BCDE into MTOS
;
; ********************************************
; * AMD: COPY MTOS INTO REGISTERS B, C, D, E *
; ********************************************
;
; Exit: AHL preserved
;
ZGBCDE	PUSH	PSW
	CALL	ZGET	; Copy MTOS into ABCD
	JMP	LED13	; Copy ABCD into BCDE
;
;
; **************************************************
; * CHECK IF CONTENTS REGISTERS B, C, D, E IS ZERO *
; **************************************************
;
; Exit: Z=1: contents BCDE is zero
;       BCDEHL preserved
;
LED83	MOV	A, B
	ORA	C
	ORA	D
	ORA	E
	RET
;
; *********************************************
; * EVT. NEGATE CONTENTS REGISTERS B, C, D, E *
; *********************************************
;
; If S=1: Contents BCDE is negated. Overflow exit if negation not possible.
; On exit, flags are set on contents entry A.
;
LED88	PUSH	PSW
	CM	LE3C9	; Evt negate BCDE
	POP	PSW
	ORA	A
	RET
;
; ****************
; * SIGN COMPARE *
; ****************
;
; Entry: HL: points to divisor
; Exit:  B:  exponent MACC
;        F:  set on XOR of exp bytes MACC and MEM
;            S=1 if difference in sign
;
LED8F	LDA	FPAC	; Get exp byte MACC
	MOV	B, A	; in E
	XRA	M	; XOR with exp byte MEM
	RET
;
; ***********************************
; * AMD: GET STATUS BITS MATH. CHIP *
; ***********************************
;
; Exit: A: status
;       FBCDEHL preserved
;
M4STAT	CALL_B(OPI, $37)	; Operate immediate - Push MTOS
	CALL_B(OPI, $38)	; Operate imnediate - Pop MTOS
	LDA	MSTATUS	; Get status math. chip
	RET
;
; **************
; * AMD: POWER *
; **************
;
; MTOS = MTOS ^ MEM
;
; Entry: HL points to power in memory
; Exit:  AF corrupted
;        BCDEHL preserved
;
ZPWR	CALL	M4STAT	; Get status math. chip
	ANI	$20	; MTOS empty?
	RNZ		; Abort if not
	JMP	LE4AC	; Run PWR routine
;
; ****************
; * FPT ADDITION *
; ****************
;
; For FPT values: MACC = MACC + MEM.
;
; Entry: HL points to FPT number in memory
; Exit:  all registers preserved
;
XFADD	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	AADD	; MACC = MACC + MEM
	JMP	EXIT	; Popall, ret
;
; *******************
; * FPT SUBTRACTION *
; *******************
;
; For FPT values: MACC = MACC - MEM.
;
; Entry: HL points to FPT number in memory
; Exit:  all registers preserved
;
XFSUB	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ASUB	; MACC = MACC - MEM
	JMP	EXIT	; Popall, ret
;
	.byte	$FF, $FF
;
; ***************^* *********************
; * SAVEA: PREPARE SAVING STRING ARRAYS *
; ***************************************
;
; Reserves space in free RAM for a string, composed from all string elements of a string
; array. The array elements are moved into this area. If not sufficient free RAM available,
; 'OUT OF MEMORY' error occurs.
;
; Entry: DE: length array to be saved
;        HL: pointer to array
; Exit:  DE: length of block in free RAM
;        HL: Startaddress block in free RAM
;        AF corrupted
;        BC preserved
;
MSA	PUSH	B
	MOV	B, D	; Length array in BC
	MOV	C, E	;
	XCHG		; Varptr in DE
	LHLD	STBUSE	; Get startaddr free RAM space
	PUSH	H	; and save it on stack
	XCHG		; and in DE; HL is array pntr
	MOV	A, B	; Save length array in 1st loocation free RAM
	CALL	LEDFD
	MOV	A, C
	CALL	LEDFD
@EDD1	MOV	A, B
	ORA	C
	JZ	@EDE5	; Abort if ready
	MOV	A, M
	INX	H
	PUSH	H	; Addr array pntr on stack
	MOV	H, M	; Addr string element in HL
	MOV	L, A
	CALL	@EDED	; Store element in free RAM
	POP	H	; Get array pntr back
	INX	H	; Pnts to next element
	DCX	B	; Decr length stil1 to be done
	DCX	B
	JMP	@EDD1	; Continue
;
; If ready
;
@EDE5	POP	H	; Get startaddr new string
	XCHG		; in DE; HL is end used area
	CALL	SUBDE	; calc length of string
	XCHG		; in DE
	POP	B
	RET
;
;  COPY STRING ELEMENT INTO FREE RAM
;
@EDED	PUSH	B
	MOV	B, M	; Get length of string in B
@EDEF	MOV	A, M	; Byte in A
	INX	H	; Pnts to next byte
	CALL	LEDFD	; Copy byte into free RAM
	MOV	A, B	; Update length
	SUI	$01
	MOV	B, A
	JNC	@EDEF	; Next byte if not ready
	POP	B
	RET
;
; STORE STRINGDATA IN FREE RAM SPACE
;
; Moves 1 byte of a string array element into the free RAM space and checks for 'OUT OF MEMORY'.
;
; Entry: DE: points to 1st free address in RAM
;        A:  byte to be moved
; Exit:  DE updated
;        BCHL preserved
;
LEDFD	STAX	D	; Store byte in free RAM
	INX	D	; Update RAM pntr
	PUSH	H
	LHLD	SCRBOT	; Get addr bottom screen RAM
	CALL	COMP	; End free RAM reached?
	JC	ERROM	; Then run error 'OUT OF MEMORY'
	POP	H
	RET
;
; **************
; * (not used) *
; **************
LEE0B	PUSH	H
	CALL	LD891
;
; ***********************************************
; * LOADA: READ ARRAY DATA FROM TAPE INTO ARRAY *
; ***********************************************
;
; Reads block(s) from tape into the free RAM space and move it afterwards into the array.
;
; Entry: HL: length of name requested
;        A:  variable type
;        On stack: address where to dump data
;
LEE0F	PUSH	B
	PUSH	PSW	; Save var. type
	LXI	B, $3200	; File type in B, C for load during program
	CALL	LD681	; Open read file
	POP	H	; Get var. type in H
	CALL	R1BB	; Read var. type from tape
	CMP	H	; Currect type?
	JNZ	ERRTM	; Run error 'TYPE MISMATCH' if not
	CPI	$20
	JZ	@EE38	; Jump if string arrays
;
; If INT/FPT arrays
;
	POP	H
	XTHL		; Get dumpaddr in HL
	XCHG		; Get length in HL
	DAD	D	; HL is end dump area
	XCHG		; in DE; HL is start dump
	CALL	RBLK	; Read block from tape
	JNC	RLEAR	; Evt run 'LOADING ERROR ...'
	CALL	RCLOSE	; Stop reading
@EE32	LDA	POROM	; Get POROM
	JMP	BRET	; Select ROM bank 0, abort
;
; If string arrays
;
@EE38	PUSH	D
	LHLD	SCRBOT	; Get bottom screen RAM
	XCHG		; in DE
	LHLD	STBUSE	; Get begin free RAM space
	PUSH	H
	CALL	LD897	; Read block from tape into free RAM area; evt. run error
	POP	H	; Get begin free RAM
	MOV	D, M	; Length of array 1n DE
	INX	H
	MOV	E, M
	INX	H
	JMP	LD6E5	; Via D6E5 to 1EE4C
;
@EE4C	PUSH	B	; Save length array
	PUSH	D
	CALL	RSVHL	; Erase stringreferencce in heap and symtab
	DCX	H
	DCX	H
	POP	D
	PUSH	H
	LDAX	D
	CALL	SHREQ	; Get place in heap for string
	PUSH	H
	CALL	SHCOPY	; Transter string into heap
	POP	B
	POP	H	; Length into heap at begin of string
	MOV	M, C
	INX	H
	MOV	M, B
	INX	H
	POP	B	; Get 1ength array
	DCX	B	; Update it
	DCX	B
	MOV	A, B
	ORA	C
	JNZ	@EE4C	; Next string if not ready
	JMP	@EE32	; Stop reading, select ROM bank 0; abort
;
;
;     ============
; *** SOUND MODULE ***
;     ============
;
;
TEMPO	MVI	C, $00	; Count SCB
	LXI	H, SCB0	; Addr sound control block 0
LEE73	PUSH	H	; Preserve addr SCB
	MOV	A, M	; Get value of volume counter
	CPI	$FE
	JZ	@EE7E	; If $FE: No increment (sound forever)
	JNC	LEF9D	; If $FF: Goto next block (sound off)
	INR	M	; Incr duration count volume
@EE7E	INR	A
	PUSH	H	; Preserve addr SCB
	MOV	B, A	; Save incr duration count
	INX	H
	MOV	E, M	; Get pntr envelope count in DE
	INX	H
	MOV	D, M
	LDAX	D	; Get envelope duration count
	CMP	B	; Comp with volume count
	JNC	@EEB8	; Jump if env. not counted out
;
; Envelope counted out
;
	XCHG
	XTHL		; Addr env. duration on stack; addr SCB in HL
	MVI	M, $00	; Present duration count is 0
	POP	H	; Get pntr to env. table
	INX	H	; +1
	MOV	A, M	; Get next env. duration
	ORA	A	; Is it $FF?
	CM	LEF93	; Then restart envelope
	MOV	B, A	; Env duration in B
	INX	H	; Pnts to next pos env table
	MOV	A, M	; Value in A
	XCHG
	MOV	M, D	; Set env pointer in SCB to new time field
	DCX	H
	MOV	M, E
	INX	H
	INX	H
	INX	H
	INX	H	; HL pnts to vol. multiplier
	PUSH	H
	MOV	L, M	; Sound volume *8 in L
	MVI	H, $00
	DAD	H	; *16 in HL
	XCHG		; Multiplier in DE
	LXI	H, SCREEN	; Init .value
@EEA9	DCR	B	; Decr. envelope duration
	JM	@EEB1	; Jump if ready
	DAD	D	; Add multiplier
	JMP	@EEA9	; Again
@EEB1	MOV	B, H	; New eff. volume in B
	POP	H
	INX	H
	MOV	M, B	; Set new basic volume
	JMP	LEEBD
;
; If envelope not counted out
;
@EEB8	POP	D
	INX	H
	INX	H
	INX	H
	INX	H
;
; Handle tremolo
;
LEEBD	MOV	B, M	; Get basic volume in B
	INX	H
	MOV	A, M	; Get tremolo count
	ORA	A
	JZ	@EEEB	; Jump if no tremolo adj.
	ADI	$01	; Incr trenolo count
	ACI	$00
	MOV	M, A
	RAR
	RAR
	RAR
	JNC	@EEDC	; No adj. if bít 2 of <T> is 0
	INR	B	; Else add 4 units to basic volume
	INR	B
	INR	B
	INR	B
	RAR
	NOP
	JC	@EEDC	; No adjust if bit 2 of <T> = 0
	MOV	A, B
	SUI	$08	; Else: basic vol. -2 units
	MOV	B, A
 ;
@EEDC	NOP
	MOV	A, B	; Get updated basic volume
	MVI	B, $00
	ORA	A
	JM	@EEEB	; Jump if 81-FF
	MVI	B, $0F
	CMP	B
	JNC	@EEEB	; Jump if >=0F (max value)
	MOV	B, A
;
@EEEB	INX	H	; Pnts to actual volume
	MOV	A, B	; Get new basic volume
	SUB	M	; Minus actual volume
	RLC		; New actual volume is old one + 0.5 (difference +/- 1)
	RAR
	CMC
	ACI	$00
	RLC
	RAR
	RAR
	ADD	M
	MOV	M, A	; Store in SCB
	MOV	B, A	; and in B
	PUSH	H
	PUSH	B
	LXI	D, POR0M	; Addr POR0M
	LXI	H, POR0	; Addr PORO
	MOV	A, C	; Get SCB count
	MVI	C, $F0	; Mask for vol. SCB0, SCB2
	RRC
	JNC	@EF12	; Jump if SCB0, SCB2
	MVI	C, $0F	; Mask for vol. SCB0, NCR
	PUSH	PSW
	MOV	A, B	; Actual volume into hinibble for SCB1 and NCB
	ADD	A
	ADD	A
	ADD	A
	ADD	A
	MOV	B, A
	POP	PSW
@EF12	RAR
	JNC	@EF18	; Jump if SCB0, SCB1
	INX	D	; POROM+1, PORO+1  for SCB2, NCB
	INX	H
@EF18	LDAX	D	; Get POROM, POR1M
	ANA	C	; Only reqd volume
	ORA	B	; Update it
	STAX	D	; Back in POROM, POR1M and in POR0, POR1
	MOV	M, A
	POP	B
	POP	H
	INR	C	; SCB count +1
	MOV	A, C
	CPI	$04
	JZ	LEFA4	; Ready if block was NCB
;
; Handle glissando
;
	INX	H
	MOV	A, M	; Get glissando flag
	DCR	A
	JM	LEF8B	; Ready if end period reached
	INX	H
	MOV	E, M	; Get current period of output in DE
	INX	H
	MOV	D, M
	PUSH	H
	INX	H
	MOV	A, M	; Get reqd final period in HL
	INX	H
	MOV	H, M
	MOV	L, A
	JNZ	@EF3B	; Jump if end period not reached
	MOV	D, H	; HL=DE if 'set freq'
	MOV	E, L
@EF3B	CALL	COMP	; Compare HL-DE
	PUSH	PSW
	PUSH	D
	JNC	@EF44	; Jump if final period >= current period
	XCHG		; Else exchange values
@EF44	CALL	SUBDE	; Calc difference in HL
	POP	D
	PUSH	D
	PUSH	H
	XCHG
	MVI	E, $40
@EF4D	MOV	A, L	; HL = HL SHL 6
	RAL
	MOV	L, A
	MOV	A, H
	RAL
	MOV	H, A
	MOV	A, E
	RAL
	MOV	E, A
	JNC	@EF4D
	MOV	L, H	; HL = 1/64 orig. value
	MOV	H, E
	MOV	A, H
	ORA	L
	JNZ	@EF61
	INX	H
@EF61	POP	D
	CALL	COMP	; Compare HL-DE
	MVI	B, $02
	JC	@EF6D	; Jump if DE > HL
	MVI	B, $00
	XCHG
@EF6D	POP	D
	POP	PSW
	JNC	@EF75
	CALL	CMPHL	; HL is its 2-compl.
@EF75	DAD	D
	XCHG
	POP	H
	MOV	M, D	; Set new current period
	DCX	H
	MOV	M, E
	DCX	H
	MOV	M, B	; Set glissando flag
	PUSH	B
	MOV	A, C
	DCR	A	; Calc offset for oscill. address
	ADD	A
	MOV	C, A
	MVI	B, $00
	LXI	H, SND0	; Addr osc. channel 0
	DAD	B	; HL = addr current osc
	MOV	M, E	; Load oscillator
	MOV	M, D
	POP	B
;
;  Block done
;
LEF8B	LXI	D, $000E
	POP	H	; Get startadr prev. block
	DAD	D	; HL pnts to next block
	JMP	LEE73	; Run next block
;
; RESTART ENVELOPE
;
; Gets 1st volume of envelope.
;
; Entry: DE: Points to 2nd byte of envelope pointer of a SCB
; Exit:	A: volume
;        HL: address volume field in envelope
;        BCDEF preserved
;
LEF93	PUSH	D	; Save pntr
	INX	D
	LDAX	D	; Get 1obyte env pntr
	MOV	L, A	; in L
	INX	D
	LDAX	D	; Get hibyte env pntr
	MOV	H, A	; in H
	POP	D	; Restore pntr
	MOV	A, M	; Get volume in A
	RET
;
; IF SOUND OF BLOCK IS 'OFF': GOTO NEXT BLOCK
;
LEF9D	INR	C	; Update SCB count
	MOV	A, C
	CPI	$04	; All blocks done?
	JNZ	LEF8B	; Next block if not
LEFA4	POP	H
	RET
;
; ***************
; * BANK RETURN *
; ***************
;
; Goto ROM bank 0.
;
; Entry: A: Current POROM.
;
BRET	POP	B
	ANI	$3F	; Select ROM bank 0
	JMP	LD808	; Load PORO/POROM
;
	.byte	$FF, $FF, $FF,
	.byte	$FF, $FF, $FF
	.byte	$FF, $FF, $FF
;
; ***************************************
; * LOADA: READ VARIABLE TYPE FROM TAPE *
; ***************************************
;
; Reads 1 byte from tape.
;
; Exit: A: Variable type.
;       DEHL preserved
;
R1BB	PUSH	H
	PUSH	D
	LXI	H, EBUF	; Startaddr EBUF
	LXI	D, EBUF+1	; Next addr
	CALL	RBLK	; Read type from tape
	JNC	RLEAR	; Evt run 'LOADING ERROR ...'
	LDA	EBUF	; Get var. type in A
	POP	D
	POP	H
	RET
;
.if ROMVERS == 11
;
; Part of XEXP
;
XEFC9	MOV	A, D	; Get lobyte MACC
	ANI	$C0	; Check for max. value
	JNZ	LE68B	; Jump if nr too big
	JMP	LE694	; If OK
.endif
.if ROMVERS == 10
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
.endif
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
;
; *************************
; * part of 'EXP' (1E667) *
; *************************
;
LEFF9	ORA	H
	JP	LE6B8
	JMP	LE6AD
;
end_rom1	.equ	*
;
;
; ROM Bank 2 - 4KB starting $E000
.bank 2, 4, $E000
.segment "ROM2", 2
.org	$E000
;
bgn_rom2	.equ	*
;
;
;     ======================
; *** SCREEN DRIVING PACKAGE ***
;     ======================
;
; Called by RST 5 + $XX. $XX indicates the offset of $E000 for the different entrypoints.
;
; ****************
; * ENTRY POINTS *
; ****************
;
; Screen functions:
;
ZSINIT	JMP	SINIT	; Initialise screen
ZSOUTC	JMP	SOUTC	; Output one character
ZSCLT	JMP	SCOLT	; Set text colours
ZSCUS	JMP	SCURS	; Set cursor position
ZSCUA	JMP	SCURA	; Ask Cursor position and size character screen
ZSCUM	JMP	SCURM	; Set cursor mode
ZSCUI	JMP	SCURI	; Flash cursor
ZSFETC	JMP	SFETC	; Get character from line
ZSMODE	JMP	SSETM	; Change mode
ZSCLG	JMP	SCOLG	; Set graphics colours
ZSDOT	JMP	SDOT	; Draw a dot on the screen
ZSDRAW	JMP	SDRAW	; Draw a line on the screen
ZSFILL	JMP	SFILL	; Fill a rectangular area
ZSCRN	JMP	SSCRN	; Ask colour of a point on the screen and the size of the graphics screen
;
; Edit functions
;
ZEDIT	JMP	EINIT	; Initialise editor
ZEDOB	JMP	EOBEY	; Run edit command
;
; *************************
; * CONSTANT TABLE MODE 0 *
; *************************
;
; These constant tables are moved into the screen variables in RAM (FFB-GXB) when
; the appropriate mode is entered.
;
; Except the last 4 data blocks, all values are offset from the screen top address ($BFFF for
; a 48K machine). This is valid for all modes.
;
CON0	.word	$0CB0	; First free RAM byte
	.word	$0000	; Top of rolled area
	.word	$0000	; End graphics area
	.word	$0010	; Start character area
	.word	$0CA0	; End character area
	.word	$0CB0	; End screen
	.word	$0000	; End area used splitting mode
	.word	$0000	; Start archive save area
	.word	$0000	; Number of blobs horizontally
	.byte	$00	; Number of lines of graphics
	.byte	$00	; Number saved graphics lines
	.byte	$00	; Number of bytes/line
;
; ****************************
; * CONSTANT TABLE MODES 1/2 *
; ****************************
;
CON1	.word	$0638	; First free RAM byte
	.word	$0130	; Top area rolled up or mode
	.word	$0628	; End graphics area
	.word	$0628	; CHS (dummy)
	.word	$0860	; End character area
	.word	$0638	; End screen
	.word	$0748	; End area used splitting mode
	.word	$0740	; Start graphic archive area
	.word	$0048	; Number of blobs horizontal1y
	.byte	$41	; Number of lines of graphics
	.byte	$0C	; Number archive area lines
	.byte	$18	; Number of bytes/line
;
; ******************************
; * CONSTANT TABLE MODES 1A/2A *
; ******************************
;
CON1A	.word	$0860	; First free RAM byte
	.word	$0130	; Top of rolled area
	.word	$0508	; End graphics area
	.word	$0518	; Start character area
	.word	$0730	; End character area
	.word	$0740	; End screen
	.word	$0748	; End area used splitting mode
	.word	$0628	; Start graph temp save area
	.word	$0048	; Number of blobs horizontally
	.byte	$41	; Number of lines of graphics
	.byte	$0C	; Number saved graphics lines
	.byte	$18	; Number of bytes/line
;
; ****************************
; * CONSTANT TABLE MODES 3/4 *
; ****************************
;
CON3	.word	$177C	; First free RAM byte
	.word	$0460	; Top area rolled up
	.word	$176C	; End graphics area
	.word	$176C	; CHS (dummy)
	.word	$19A4	; End character area
	.word	$177C	; End screen
	.word	$1BBC	; End area used splitting mode
	.word	$1554	; Start graph archive area
	.word	$00A0	; Number of blobs horizontal1y
	.byte	$82	; Number of lines of graphics
	.byte	$18	; Number archive area lines
	.byte	$2E	; Number of bytes/line
;
; ******************************
; * CONSTANT TAELE MODES 3A/4A *
; ******************************
;
CON3A	.word	$19A4	; First free RAM byte
	.word	$0460	; Top of rolled area
	.word	$131C	; End graphics area
	.word	$132C	; Start character area
	.word	$1544	; End character area
	.word	$1554	; End screen
	.word	$1BBC	; End area used splitting mode
	.word	$176C	; Start graph temp save area
	.word	$00A0	; Number of blobs horizontally
	.byte	$82	; Number of lines of graphics
	.byte	$18	; Number saved graphics lines
	.byte	$2E	; NLmber of bytes/line
;
; ****************************
; * CONSTANT TABLE MODES 5/6 *
; ****************************
;
CON5	.word	$5A20	; First free RAM byte
	.word	$0F88	; Top area rolled up
	.word	$5A10	; End graphics area
	.word	$5A10	; CHS (dummy)
	.word	$5C48	; End character area
	.word	$5A20	; End screen
	.word	$6988	; End area used splitting mode
	.word	$4CD0	; Start graph archive area
	.word	$0150	; Number of blobs horizontally
	.byte	$00	; Number of lines of graphics
	.byte	$2C	; Number saved graphics lines
	.byte	$5A	; Number of bytes/line
;
; *******************************
; * CONSTANT TABLE MODES 5A/6A *
; *****************************
;
CON5A	.word	$5C48	; First free RAM byte
	.word	$0F88	; Top of rolled area
	.word	$4A98	; End graphics area
	.word	$4AA8	; Start character area
	.word	$4CC0	; End character area
	.word	$4CD0	; End screen
	.word	$6988	; End area used splitting mode
	.word	$5A10	; Start graph temp save area
	.word	$0150	; Number of blobs horizontally
	.byte	$00	; Number of lines of graphics
	.byte	$2C	; Number saved graphics lines
	.byte	$5A	; Number of bytes/line
;
; *********************
; * INITIALISE SCREEN *
; *********************
;
; The screen is initialised into all character format (mode 0), and the cursor mode is set
; and it is positioned in the top 1eft corner. The normal mode set routine is used (memory
; management routine).
;
; This is the only time the package is told the start address of the screen. The colour format
; is as for SCOLT, SCOLG. The cursor format is as for SCURM.
;
; Entry: HL: top 1ocation screen RAM
;        DE: points to list with initialisation parameters (start at $C7E0)
; Exit:  all registers maybe corrupted
;
SINIT	SHLD	SCREEN	; store startaddr screen
	PUSH	D
	LXI	D, $FFF0
	DAD	D
	SHLD	SCTOP	; Set top of screen
	POP	H
	XRA	A
	STA	SMODE	; Select mode 1
	CALL	SCURM	; Set cursor type + info
	INX	H
	INX	H
	CALL	SCOLT	; Init. colours COLORT
	DCR	A
	STA	SMODE	; Select mode 0
	LXI	D, $0004
	DAD	D	; Get addr COLORG parameters
	CALL	SCOLG	; Init. colours COLORG
	DAD	D	; Get addr sceen management parameters
	MOV	E, M	; Get addr screen management routine
	INX	H
	MOV	D, M
	INX	H
	XCHG
	SHLD	ASMKRM	; Store addr SMKRM
	XCHG
	MOV	E, M	; Get addr emergency stop routine
	INX	H
	MOV	D, M
	XCHG
	SHLD	AESTOP	; Store addr em.stop routine
	MVI	A, $10
	STA	SMODE	; Select init. screen mode (no text, no graphics)
	MVI	A, $FF
	CALL	SSETM	; Set up screen for mode 0
	RET
;
; ********************************
; * OUTPUT A CHARACTER TO SCREEN *
; ********************************
;
; Displays one character on the screen.
;
; Entry: A: Character to be displayed
; Exit:  ABCDEHL preserved
;        CY=1: Character ignored
;
SOUTC	STC		; CY=1
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	TMODE	; Change to char mode if not yet done
	LHLD	CURSOR	; Get cursor position
	CALL	CURDEL	; Delete cursor
	CPI	$0D	; Car.ret?
	JZ	LE13D	; Then print it
	CPI	$0C	; Form feed?
	JZ	LE159	; Then clear screen
	CPI	$08	; Backspace?
	JZ	LE166	; Then cancel 1ast character
	PUSH	PSW
	LDA	LNEND	; Get addr 1ast byte on line
	CMP	L	; Reached?
	JZ	LE1A9	; Then extend lines
LE127	POP	PSW
	MOV	M, A	; Put char on screen
	DCX	H
	DCX	H	; Points to next screen 1oc
LE12B	CALL	CURSET	; Put cursor on screen
;
XRCC	POP	H
	POP	D
	POP	B
	POP	PSW
	CMC		; CY=0; char accepted
	RET
;
;  If character not accepted
;
LE134	POP	PSW
LE135	CALL	CURSET	; Put cursor on screen
XRET	POP	H
	POP	D
	POP	B
	POP	PSW	; CY=1: char ignored
	RET
;
; If carriage return
;
LE13D	LHLD	LNSTR	; Get startaddr current line
	XCHG		; in DE
	LXI	H, $FF7A	; -86
	DAD	D	; Get startaddr next line
	XCHG		; in DE
	LHLD	CHE	; Get end char area
	CALL	COMP_	; Check if end is reached
	XCHG		; Next line mode byte in HL
	CZ	SCROLL	; If end reached: scroll up one line
	CZ	LE1FD	; and init. this line with blanks
LE153	CALL	SSETC	; Cursor on begin next line
	JMP	XRCC	; Quit; char accepted
;
; If form feed
;
LE159	LHLD	CHE	; Get end character area
	XCHG		; in DE
	LHLD	CHS	; Get start char acter area
	CALL	LE1FD	; Init screen with spaces
	JMP	LE153	; Cursor top 1eft corner of char area; popall; ret
;
; If backspace
;
LE166	XCHG		; Cursor position in DE
	LHLD	LNSTR	; Get start addr current line
	LXI	B, $FFF8	; Left border width
	DAD	B	; Get addr 1st char on line
	CALL	COMP_	; Cursor at begin of line?
	XCHG
	JZ	LE135	; Then ignore char; abort
	INX	H	; Cursor one location backwards
	INX	H
	MVI	M, ' '	; Load space in this location
	LDA	LCONT	; Get number of extended line
	ORA	A
	JZ	LE12B	; If no cont line: put cursor on screen
	JM	LE12B	; If char accepted: put cursor on screen
;
; Backspace on a continuation line
;
	PUSH	D	; Save addr 1st byte on line on stack
	XCHG		; HL is cursor position
	LXI	B, $FFF2
	DAD	B	; HL end indent area
	CALL	COMP_	; Compare DE-HL
	XCHG
	POP	D
	JNZ	LE12B	; If not there: put cursor on screen quit, char accepted
	XCHG
	MVI	M, ' '	; Else cancel cont char (C)
	LXI	H, LCONT
	DCR	M	; Decr. number extended lines
	LHLD	LNSTR	; Get startaddr current line
	LXI	D, GRR
	DAD	D	; Pnts to start previous line
	CALL	SSETL	; Store addr line mode byte as current one and set 1ast byte on that line
	LXI	D, $FF80
	DAD	D
	JMP	LE12B	; Put cursor on screen quit, char accepted
;
; If end of line is reached
;
LE1A9	LDA	LCONT	; Get number extended lines
	CPI	$03	; Max (3) reached?
	JNC	LE134	; Then put cursor on screen, ret
	INR	A	; Incr. number ext. lines
	MOV	B, A	; Store it in B
	MVI	A, $0D
	CALL	SOUTC	; Output car.ret
	MOV	A, B
	STA	LCONT	; Update nr ext. lines
	LHLD	CURSOR	; Get cursor position addr
	CALL	CURDEL	; Delete cursor
	MVI	M, 'C'	; Print 'C' at left of line
	LXI	D, $FFF2
	DAD	D	; Indent 6 pos
	JMP	LE127	; Store char on new pos; put cursor on screen
;
; *************
; * SCROLLING *
; *************
;
; Scrol1s up text area. Moves the character area of the screen up one line.
; Only the characters are moved, not the control and colour bytes.
;
; Entry: None
; Exit;  AF preserved, BC corrupted
;        DE: end of bottom line
;        HL: start of bottom line
;
SCROLL	LXI	B, $FF7A	; -86 1ength one line
;
; Entry from Edit:
; Scrol1 screen for number of positions given in BC (-2  = 1 position left)
;
LE1CE	PUSH	PSW
	LHLD	CHS	; Get startaddr character area and store it in DE
	MOV	D, H
	MOV	E, L
	DAD	B	; Get addr line mode byte next line
	XCHG		; in DE
@E1D6	LXI	B, $FFF8
	DAD	B	; Get 1st useable 1ocation on 1st line
	XCHG		; in DE
	DAD	B	; Get 1st useable 1acation on 2nd 11ne
	XCHG		; in DE; 1st line in HL
	MVI	B, 60	; max 60 characters
@E1DF	LDAX	D	; Get char from 2nd line
	MOV	M, A	; and move it to 1st line
	DCX	D
	DCX	D	; Next char 2nd line
	DCX	H
	DCX	H	; Next 1oc 1st line
	DCR	B
	JNZ	@E1DF	; Next char to be moved 1 line
	LXI	B, $FFFA
	DAD	B	; Get addr line mode byte 2nd line in DE
	XCHG
	DAD	B	; Get addr line mode byte 3rd line
	XCHG		; in DE; 2nd line in HL
	PUSH	H
	LHLD	CHE	; Get addr end character area
	CALL	COMP_	; Check if end reached
	POP	H
	JC	@E1D6	; If not at end; scroll next line
	POP	PSW
	RET
;
;
;
; ************************************
; * INITIALISE SCREEN CHARACTER AREA *
; ************************************
;
; Fills screen with spaces (clears screen). The line mode byte is set $7A, the line colour
; byte to $40, all colour bytes to $00 (4-colour text), all character bytes to $20.
;
; Entry: HL: 1st byte after header
;        DE: end character area
; Exit:  all registers preserved
;
LE1FD	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
@E201	MVI	M, $7A	; Set control byte for char mode
	DCX	H
	MVI	M, $40	; Set line colour byte
	DCX	H
	MVI	B, $42	; Number of bytes/line
@E209	MVI	M, ' '	; Data byte is space
	DCX	H
	MVI	M, $00	; Colour byte is 00
	DCX	H
	DCR	B
	JNZ	@E209	; Next screen addr
	CALL	COMP_	; All lines done?
	JNZ	@E201	; Next line if not
	JMP	XRET	; Popall, ret
;
; ****************************
; * CHANGE TO CHARACTER MODE *
; ****************************
;
; If a character is output when the screen is in all-graphic mode, the mode is changed to
; the corresponding sp1it-node.
; If not sufficient space avai1able, mode 0 is tried. If still insufficient space, the
; emergency stop routine is used.
;
TMODE	PUSH	PSW
	LDA	SMODE	; Get current screen mode
	RRC		; Already character node
	JC	@E231	; Abort if true
	STC		; CY=1
	RAL		; Set for split mode
	CALL	SSETM	; Change mode
	MVI	A, $FF
	CC	SSETM	; Change to mode 0 if not sufficient space
	JC	@E233	; Emergency stop if still insufficient space
@E231	POP	PSW
	RET
;
; If no space for A-mode or mode O
;
@E233	LHLD	AESTOP	; Get addr emergency stop routine
	PCHL		; Go to this routine
;
; ********************
; * SET TEXT COLOURS *
; ********************
;
; The COLORT parameters are set; the header and trailer of the character area are initialised.
; The colour values are between 0 and F. The top 4 bits are ignored.
; The colour change 1s immediate.
;
; The 1st two colours are the default background and foreground colours for characters.
; The lastt two are alternative, and may be used for (e.g.) the cursor.
; Colours May be repeated.
;
; Entry: HL points to a vector of 4 bytes containing the colours to be set.
; Exit:  all registers preserved.
;
SCOLT	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D, COLMT	; Addr 1st byte colour register memory
	CALL	VCOPY	; Init. COLORT reg menory
	LDA	SMODE	; Get current screen mode
	RAR		; Char mode?
	LHLD	CHS	; Get startaddr char area
	CC	BCOLS	; If char mode; set colours header area
	LHLD	SCE	; Get addr end of screen
	CC	BCOLS	; If char mode; set colours trailer area
	JMP	XRET	; Popall, ret
;
; *************************
; * SET COLOUR PARAMETERS *
; *************************
;
; Loads colour data from ROM into the RAM pointers.
; The high nibbles are 8x, 9x, Ax, Bx.
; Used for both COLORT and COLORG.
;
; Entry: HL: points to colour parameters
;        DE: address colour memory in RAM
; Exit:  DE: points after colour memory
;        other registers corrupted
;
VCOPY	LXI	B, $1080
@E257	MOV	A, M	; Get colour from ROM
	ANI	$0F
	ORA	C	; Add bits 4-7
	STAX	D	; Store in RAM
	INX	H	; Next colour
	INX	D	; Next RAM 1ocation
	MOV	A, C	; Add $10 to C
	ADD	B
	MOV	C, A
	CPI	$C0	; Check if finished
	JNZ	@E257	; Next one if not
	RET
;
; ***************************************
; * LOAD COLOURS IN HEADER/TRAILER AREA *
; ***************************************
;
; Sets blanking area colour bytes according to information given.
; The colour bytes for the character area are 1oaded into the screen header and trailer area.
;
; Entry: HL: points to 1st control byte after blanking area
;        DE: points after table with colours in RAM
; Exit:  AFDE preserved, BCHL corrupted
;
BCOLS	PUSH	PSW
	PUSH	D
	LXI	B, $0004	; Distance between colour byte
	DCX	H	; Addr 1st colour byte of screen RAM
@E26D	DCX	D	; Addr colour table
	LDAX	D	; Get colour byte
	DAD	B	; HL = addr in screen RAM
	MOV	M, A	; Load byte into screen RAM
	ANI	$30	; Finished?
	JNZ	@E26D	; Next colour byte if not
	POP	D
	POP	PSW
	RET
;
; ***********************
; * SET CURSOR POSITION *
; ***********************
;
; Moves the cursor from its current position to any requested position.
; Position 0, 0 is the bottom 1eft corner.
;
; Entry: HL contains the y,x position required for the cursor
; Exit:  HCDEHL preserved
;        CY=0: OK F corrupted, A preserved
;        CY=1: Request off screen. A=01 (error code 'off screen')
;
SCURS	ORA	A
	PUSH	H
	PUSH	D
	PUSH	B
	PUSH	PSW
	MOV	A, L	; X-coord in A
	CPI	60	; After end of line?
	JNC	LE2C5
	ADD	A	; X-coord * 2
	MOV	C, A	; in C
	MVI	B, 24	; Nr of lines in mode
	LDA	SMODE	; Get current screen mode
	ORA	A
	JM	LE295	; Jump if mode 0
	MVI	B, 4	; Nr of lines in A-modes
	RAR
	JNC	LE2C5	; Error if all-graphics mode
LE295	MOV	A, H	; Y-coord in A
	CMP	B	; More than max value
	JNC	LE2C5	; Then request off streen
	CALL	CURDEL	; Delete old cursor
	INR	A
	LXI	H, $0086	; Length 1 char line
	CALL	HLMUL_	; Calc 1ength reqd number af lines (HL=A*HL)
	XCHG		; in DE
	LHLD	GAE	; Store end archive area
	DAD	D	; Start of regd linee
	CALL	SSETL	; Store addr line mode byte current line and store last byte on that line
	LXI	D, $0008
	CALL	SUBDE_	; HL = start of right border
	MOV	E, C
	MVI	D, $00
	CALL	SUBDE_	; Subtract char offset
	CALL	CURSET	; Put cursor on screen
	MVI	A, $00
	STA	LCONT	; No extended lines
	POP	PSW	; No-error return
LE2C1	POP	B
	POP	D
	POP	H
	RET
;
; If error 'off screen'
;
LE2C5	POP	PSW
	MVI	A, $01	; Set error code
	CMC		; Change CY to 1
	JMP	LE2C1	; Pop, ret
;
; *************************************************
; * ASK CURSOR POSITION AND SIZE CHARACTER SCREEN *
; *************************************************
;
; Returns the position of the cursor and the range of possible values.
; Vales given in DE are maximum values of coordinates.
; If the mode is all graphics; DE=HL=0.
;
; Entry: None
; Exit:  HL: gives y,x cursor position
;        DE: gives y,x size of character part of the screen (mode 0: 23, 59; A-modes: 3, 59)
;        AFBC preserved
;
SCURA	PUSH	PSW
	PUSH	B
	LXI	H, $0000
	MOV	D, H
	MOV	E, L	; DE=HL=0
	LDA	SMODE	; Get current screen mode
	RAR		; Char mode?
	JNC	LE313	; Abort if not
	LHLD	LNSTR	; Get startaddr cursor line
	PUSH	H	; Save it on stack
	LXI	D, $FFF8	; Size 1eft border
	DAD	D	; Get addr 1st char byte
	XCHG		; in DE
	LHLD	CURSOR	; Get cursor pos addr
	XCHG
	CALL	SUBDE_	; Calc difference of cursor pos from begin of line
	POP	D	; Get startaddr current line
	MOV	A, L	; (x-coord cursor)*2 in A
	ORA	A
	RAR		; Now x-coord cursor in A
	PUSH	PSW	; Save it on stack
	LHLD	CHE	; Get addr end char area
	LXI	B, 134	; Length 1 char line
	XRA	A	; Init Y-pos
@E2F6	PUSH	PSW	; Save it on stack
	DAD	B	; Get line mode byte next line
	CALL	COMP_	; Is current line this line?
	JZ	@E303	; Then jump
	POP	PSW	; Get Y-coord
	INR	A	; Incr it
	JMP	@E2F6	; Check if on next line
@E303	POP	H	; Y-coord cursor in H
	POP	PSW	; X-coord cursor in A
	MOV	L, A	; and now in L
	MVI	D, 23	; Nr of lines for mode 0 -1
	LDA	SMODE	; Get current screen mode
	ORA	A
	JM	LE311	; Jump if mode 0
	MVI	D, 3	; Nr of lines for A-modes -1
LE311	MVI	E, 59	; Nr of char/line -1
LE313	POP	B
	POP	PSW
	RET
;
;
;
; *******************
; * SET CURSOR MODE *
; *******************
;
; The format of cursor info is 1 byte cursor type and 1 byte of information.
; If the type = 0, the cursor flashes in colour.
; The info is a mask which is exored with the colour byte for that character to flash it.
; If the type = 1, the cursor alternates between the actual character and the one in the info.
;
; If f1ash entry is never called, cursor will be steady in the alternate colour (type 0) or
; permanently the alternate character (type 1).
;
; Entry: HL points to new cursor info
; Exit:  all registers preserved
;
SCURM	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LDA	SMODE	; Get current screen made
	RAR		; Char mode?
	CC	CURDEL	; Then delete current cursor
	MOV	A, M	; Get new cursor type
	STA	CURTY	; Store it in pointer
	INX	H
	MOV	A, M	; Get new cursor into
	STA	CURIN	; Store it in pointer
;
; Entry from CURSET
;
LE32A	CC	SCURI	; Flash cursor once if in char mode
	JMP	XRET	; Popall, ret
;
; **************
; * SET CURSOR *
; **************
;
; Sets some cursor on the screen. Does not delete previous cursor. The screen must already be in a character mode.
; Gets the contents of the cursor position address and stores it in the pointers.
;
; Entry: HL: address new cursor position
; Exit:  all registers preserved
;
CURSET	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	H
	MOV	D, M	; Get contents addr pointed at by new cursor
	DCX	H
	DCX	H
	DCX	H
	MOV	E, M	; Get colour byte of this addr
	POP	H
	CALL	LD68D	; Store contents and colour byte in cursor pointers
	NOP
	NOP
	STC		; CY=1
	JMP	LE32A	; Flash cursor, popall, ret
;
; ****************
; * FLASH CURSOR *
; ****************
;
; Flashes the cursor once if in char mode, otherwise does nothing.
;
; Entry: none
; Exit:  all registers preserved
;
SCURI	.equ	*
CURFL	PUSH	PSW
	PUSH	H
	LHLD	CURSOR	; Get cursor pos addr
	MOV	A, H
	ORA	L	; Check if addr is $0000
	JZ	@E35D	; Abort if no cursor
	LDA	CURTY	; Get cursor type
	ORA	A	; Check type
	LDA	CURIN	; Get cursor info
	JNZ	@E360	; Jump if char type
;
; If 'colour' type
;
	DCX	H	; Get addr colour byte
	DCX	H
	DCX	H
	XRA	M	; Exor mask with colour byte
@E35C	MOV	M, A	; And reload colour byte
@E35D	POP	H
	POP	PSW
	RET
;
; If 'char' type
;
@E360	CMP	M	; Check contents screen 1oc
	MOV	M, A	; Move cursor info in 1oc
	JNZ	@E35D	; Abort if contents screen 1oc is changed now
	LDA	CURSV+1	; Else: get contents scrn loc
	JMP	@E35C	; Store it in this 1oc
;
; *****************
; * DELETE CURSOR *
; *****************
;
; Deletes the current cursor. Loads the address pointed at by the cursor with the data stored in RAM (CURSV/77).
; Routine valid for character modes only.
;
; Entry: none
; Exit:  all registers preserved
;
CURDEL	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	CURSV	; Get contents cursor loc
	XCHG		; in DE
	LHLD	CURSOR	; Get cursor pos addr
	PUSH	H	; Save it on stack
	LXI	H, $0000
	SHLD	CURSOR	; Move cursor to addr $0000
	POP	H	; Restore cursor pos addr
	MOV	A, H
	ORA	L	; Check if addr is 0000
	JZ	@E388	; Abort if no cursor
	MOV	M, D	; Load data into screen 1oc pointed at by cursor
	DCX	H
	DCX	H
	DCX	H
	MOV	M, E	; Load colourbyte into 1oc pointed at
@E388	JMP	XRET	; Popall, ret
;
; ***************************
; * GET CHARACTER FROM LINE *
; ***************************
;
; Returns a character from some position on the current line.
;
; Entry: C: line position of required character (max. legal value = 219)
; Exit:  A: required character (car.ret if at or past cursor)
;        BCDEHLF preserved
;
SFETC	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	PSW
	LXI	H, 134	; Total nr. of bytes/line
	LDA	LCONT	; Get number extended lines
	CALL	HLMUL_	; Calc total nr of bytes (HL=A*HL)
	XCHG		; in DE
	LHLD	LNSTR	; Get addr line mode byte current line
	DAD	D	; Calc start of line on screen
	LXI	D, $FFEA
	DAD	D	; End indent area
	XCHG		; in DE
	MVI	A, $F9	; 1st bytes on line not useable
	ADD	C	; Add pos of required char on line
	PUSH	PSW
	MVI	B, $00
	JNC	LE3B2	; Jump if in 1st 7 positions
	DCR	B
@E3AC	SUI	$35	; 60 useable positions/line
	INR	B	; Count nr of extended lines
	JNC	@E3AC	; Jump if not on thís line
LE3B2	MOV	A, B	; Nr of extensions in A
	LXI	H, $FFE4	; Nr of not used bytes/line
	CALL	HLMUL_	; Add-ons for line ends
	DAD	D
	POP	PSW	; Restore pos of char on line
	MOV	E, A	; into E
	CMC
	SBB	A
	MOV	D, A	; D=char.count - nr of idents
	XCHG
	DAD	H	; Pos * 2 due to colour bytes
	XCHG
	CALL	SUBDE_	; Calc pos of reqd char
	XCHG		; Addr in DE
	LHLD	CURSOR	; Get cursor pos addr
	CALL	COMP_	; Compare it with addr of char
	MVI	A, $0D	; Car.ret in A
	JNC	@E3D2	; If on or after cursor
	LDAX	D	; Get character from line
@E3D2	MOV	H, A	; Save it temporarily
	POP	PSW	; Restore flags
	MOV	A, H	; Get character in A
	POP	H
	POP	D
	POP	B
	RET
;
; ***************
; * CHANGE MODE *
; ***************
;
; Change the mode of the screen.
;
; Entry: A: code new mode
; Exit:  ABCDEHL preserved
;        CY=0: OK
;        CY=1: insufficient room for mode
;
SSETM	STC		; CY=1
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CPI	$FF	; Mode 0?
	CZ	SSM0	; Then set up mode 0 screen
	CNZ	SSMG	; Else: set up screen for other modes
	JC	@E404	; Jump if no room available
	LHLD	SCE	; Get end of screen
	PUSH	D
	LXI	D, $0010	; Nr of bytes in trailer
	DAD	D	; Get 1st addr trailer area
	POP	D	; Get addr 1st colour
	MVI	B, $0F	; Depth of blank
	CALL	SSUBL	; Init traler area
	LHLD	FFB	; Get 1st free byte
	ORA	A	; set flags on scrn mode byte
	CALL	SMKRM	; Perform mem. management
	STA	SMODE	; Store current screen
	JMP	XRCC	; Popall (CY=0), ret
;
; If error
;
@E404	JMP	XRET	; Popall (CY=1), ret
;
;
;
; ****************************
; * SET UP SCREEN FOR MODE 0 *
; ****************************
;
; Sets up a mode 0 screen, whatever the current mode is. If already a character area exists, it is
; moved to the top of the new screen.
;
; Entry: none
; Exit:  all registers corrupted
;        CY=0: OK
;        CY=1: No room
;
SSM0	STC		; CY=1
	PUSH	PSW
	LXI	H, CON0	; Startaddr mode 0 table
	CALL	VARS	; Load pointer with parameter
	JC	LE43C	; If no room available
	LXI	D, COLMT	; Addr text colour table
	PUSH	D	; Save addr
	LHLD	SCREEN	; Get 1st byte screen RAM
	MVI	B, $06
	CALL	SSUBL	; Set up header
	LDA	SMODE	; Get old screen mode
	CPI	$10	; During initialisationn?
	JZ	@E42D	; Then jump
	RAR		; Split screen?
	JNC	@E42D	; Jump if not
	CALL	SMVTXT	; If split mode: move old text, cursor, etc
@E42D	XCHG		; Addr after header in DE
	LHLD	CHE	; Get addr end char area
	XCHG
	CALL	LE1FD	; Blank char area
	CNC	SSETC	; Set cursor at begin 1st line
;
; Entry from SSMG
;
LE438	POP	D
	POP	PSW
	CMC		; CY=0
	RET
;
; If no room available
; Entry from SSMG, SSM, SSMA
;
LE43C	POP	PSW	; CY=1
	RET
;
; **********************************
; * SET UP SCREEN FOR GRAPHIC MODE *
; **********************************
;
; Entry: A:  Screen mode (split if odd)
; Exit:  CY=0: OK
;        Split mode: DE: addr text colours
;        All graphic mode: DE: addr graph colours
;        AF preserved. BCHL corrupted.
;        CY=1: insufficient room
;
SSMG	STC
	PUSH	PSW
	MOV	D, A	; Screen mode in D
	ANI	$01	; Z=1 if full colour mode
	MOV	A, D
	RAR		; Disable split mode bit in A
	CNZ	SSMA	; If split mode: set up screen
	CZ	SSM	; If full colour mode: idem
	JC	LE43C	; Abort if no room
	POP	PSW	; Get mode code
	PUSH	PSW
	PUSH	D
	LXI	D, COLMG	; Addr COLORG table
	LHLD	SCREEN	; Get addr 1st byte screen RAM
	MVI	B, $06	; Depth each blanking line in header -1
	CALL	SSUBL	; Set up header with COLORG colours
	JMP	LE438	; Quit, all OK
;
; SET UP A FULL GRAPHIC SCREEN
;
; Sets up a screen RAM for an all-graphics mode.
;
; Entry: A: Mode code /2
;        D: Mode code
; Exit:  CY=0: OK
;              DE points to table graphic colours.
;              AF preserved. BCHL corrupted.
;        CY=1: Insufficient space
;
SSM	STC
	PUSH	PSW
	LXI	H, TABM	; Addr table vectors full graphic mode
	CALL	TABP	; Set up screen mode
	JC	LE43C	; Jump 1t no room
	LDA	SMODE	; Get current screen mode
	SUB	D	; Check if change split to all graphics
	DCR	A
	JZ	LD700	; Then check if sufficient RAM available and change mode
	CALL	CURDEL	; Delete cursor
	LDA	GRL	; Get nr of graphics lines
	MOV	C, A	; in C
	LHLD	SCTOP	; Get addr top graph area
	CALL	SGINIT	; Blank whole screen
LE47F	LXI	D, COLMG	; Addr COLORG table
	POP	PSW
	CMC		; CY=0: OK
	RET
;
; Change from split to all-graphic mode
;
LE485	JNC	LD70F	; Set up screen mode
	CALL	CURDEL	; Delete cursor
	LHLD	GRE	; Get addr temp save area in BC
	MOV	B, H
	MOV	C, L
	PUSH	B	; Save it on stack
	LHLD	GAS	; Get startaddr archive area
	XCHG		; in DE
	LHLD	GAE	; Get addr end archive area
	CALL	MOVES	; Move archive area into temp save area
	LHLD	GRR	; Get addr top of rolled area in BC
	MOV	B, H
	MOV	C, L
	LHLD	SCTOP	; Get addr top old graphics
	XCHG		; in DE
	LHLD	GREQ	; Get end old screen
	CALL	MOVES	; Move lower part screen downwards
	MOV	B, D	; BC is addr where to put archive area
	MOV	C, E
	POP	D	; Get startaddr temp save area
	LHLD	GTE	; Get end temp save area
	CALL	MOVES	; Move temp save area to top of screen
	JMP	LE47F	; Quit
;
; SET UP SCREEN FOR SPLIT MODE
;
; Sets up a split screen for a given mode in the 1ower RAM.
;
; Entry: A: Mode code /2
;        D: Mode code
; Exit:  CY=0: OK
;              DE: Address text colour table
;              AF preserved, BCHL corrupted
;        CY=1: insufficient space
;
SSMA	STC
	PUSH	PSW
	LXI	H, TABMA	; Startaddr table vectors split modes
	CALL	TABP	; Set up screen mode
	JC	LE43C	; Abort if insufficient space
	LDA	SMODE	; Get old screen mode
	SUB	D	; Check if change from all-graph to split
	INR	A
	PUSH	PSW	; Preserve flags
	PUSH	D	; and new mode code
	JNZ	@E4F9	; If not splitting old mode: clear graph and moved areas
	CALL	LD706	; Check suff RAM available; prepare full graphic mode
	NOP
	JNC	LD70D	; Set up current mode if not OK
	LHLD	GTS	; Get start temp save area in BC
	MOV	B, H
	MOV	C, L
	LHLD	SCTOP	; Get addr after header
	XCHG		; in DE
	LHLD	GRR	; Get addr top of screen
	CALL	MOVES	; Move top of screen into temp save area
	MOV	B, D	; BC is addr top of screen
	MOV	C, E
	XCHG		; Addr top rolled up area
	LHLD	GREQ	; Get previous end of graphics
	CALL	MOVES	; Move 1ower part of screen
	LHLD	SCE	; Get final place for archive code
	MOV	B, H	; in BC
	MOV	C, L
	LHLD	GTS	; Get addr start temp. save area
	XCHG		; in DE
	LHLD	GTE	; Get addr end split mode
	CALL	MOVES	; Move temp save area into archive area
@E4F9	LHLD	CHS	; Get start addr char area
	XCHG		; in DE
	LHLD	CHE	; Get addr end char area
	LDA	SMODE	; Get current screen mode
	RAR		; Check mode
	MVI	C, $04	; Nr of char lines in A-mode
	XCHG
	CNC	LE1FD	; Blank char area
	CNC	SSETC	; Cursor on begin of line
	CC	SMVTXT	; Find old text and move it
	POP	D
	LHLD	SCTOP	; Get addr after header
	LDA	GAL	; Get nr saved graphics lines
	MOV	C, A	; in C
	LDA	GRL	; Get nr of graphics lines
	SUB	C	; minus saved ones
	MOV	C, A	; stored in C
	POP	PSW
	CNZ	SGINIT	; Blank visible graph area
	LHLD	SCE	; Get addr end of screen
	LDA	GAL	; Get nr saved graphics lines
	MOV	C, A	; in C
	CNZ	SGINIT	; Blank saved graph area
	LXI	D, COLMT	; Addr text colour table
	MVI	B, $00	; Middle as narrow as possible
	LHLD	GRE	; Get addr middle area
	POP	PSW	; Get mode code
	CALL	SSUBL	; Set up middle area (blanking)
	CMC
	RET
;
; SET UP SCREEN FOR MODE
;
; Selects the right table according to the mode number and sets the screen variables.
;
; Entry: A:  mode code /2
;        HL: points to screen parameter vectors for each pair of modes.
; Exit:  CY=0: OK
;        AFHL corrupted, BCDE preserved
;        CY=1: insufficient space
;
TABP	ANI	$0E	; Bits 1, 2, 3 only
	CALL	DADA_	; Add offset to start table
	NOP
	NOP
	NOP
	MOV	A, M	; Get addr from table in HL
	INX	H
	MOV	H, M
	MOV	L, A
;
; LOAD POINTERS WITH SCREEN PARAMETERS
;
; Set up vector area FFB-0098 with variables describing the current state of the screen
; in the current mode.
;
VARS	STC
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	H
	PUSH	H
	LHLD	SCREEN	; Get addr 1st byte screen RAM
	MOV	B, H	; in BC
	MOV	C, L
	POP	H	; Get startaddr table
	MOV	A, C	; Calc end area used in new mode. Store it in DE.
	SUB	M
	MOV	E, A
	INX	H
	MOV	A, B
	SBB	M
	MOV	D, A
	LXI	H, $0000
	JC	@E560	; Jump if insufficient space
	XCHG
@E560	STC
	CALL	SMKRM	; Make room for new node
	JNC	LE596	; Jump if no room available
	LHLD	GRE	; Get old addr after end graphics area
	SHLD	GREQ	; and save it
	LHLD	CHS	; Get old startaddr char area
	SHLD	CHS0	; and save it
;
; Set up area FFB-0093
;
	LXI	D, FFB	; Start of variables which need offsets
	MVI	L, $08	; Nr pointers to be set
@E578	XTHL		; Get addr screen parameters
	MOV	A, C
	SUB	M	; Calc 1obyte
	STAX	D	; And store it in pointer
	INX	H	; Next byte
	INX	D
	MOV	A, B
	SBB	M	; Calc hibyte
	STAX	D	; And store it in pointer
	INX	H
	INX	D
	XTHL
	DCR	L	; Decr counter
	JNZ	@E578	; Next parameter
;
; Set up area GRC-GXB
;
	POP	H	; Get addr 1st parameter
	MVI	B, $05	; Nr unadjusted constant bytes
@E58B	MOV	A, M	; Get parameter
	STAX	D	; and store it in pointer
	INX	H
	INX	D
	DCR	B	; Decr counter
	JNZ	@E58B	; Next parameter
	JMP	XRCC	; Popall, CY=0, ret
;
; If no room available
;
LE596	POP	H
	JMP	XRET	; Popall (CY=1) ret
;
; VECTDRS TO TABLES SCREEN PARAMETERS
;
; The startaddresses of the tables with parameters for the graphic modes are given.
;
TABM	.word	CON1	; mode 1/2
	.word	CON3	; mode 3/4
	.word	CON5	; mode 5/6
;
TABMA	.word	CON1A	; mode 1A/2A
	.word	CON3A	; mode 3A/4A
	.word	CON5A	; mode 5A/6A
;
; *************************************
; * PERFORM MEMORY MANAGEMENT ROUTINE *
; *************************************
;
; Entry: HL: points to last free byte in RAM
;
SMKRM	INX	H
	PUSH	H
	LHLD	ASMKRM	; Get addr mem. management routine
	XTHL		; Put it on stack
	RET		; Perform this routine and return afterwards to origin. returnaddress.
;
; *********************************
; * SET UP AN EMPTY GRAPHICS AREA *
; *********************************
;
; Initialises an area of the screen into graphic state and blanks it. In 16-colour modes, all
; pixels are set 'on'. The foreground colour is the first COLORG colour, the background is black.
;
; Entry: D:  mode code
;        C:  number of graphic lines (1-256)
;        HL: start of area
; Exit:  all registers preserved
;
SGINIT	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	MOV	A, D	; Mode in A
	PUSH	H
	LXI	D, $0000	; 8 blobs 1st graph colour
	MVI	L, $00	; Controi byte graph, 1ow def, 4-colour
	RAR
	RAR
	JC	@E5CB	; Jump if 4-colour mode
;
; 16-colour mode only
;
	PUSH	PSW
	LDA	COLMG	; Get 1st colour
	ADD	A	; Move lonibble into hinibble
	ADD	A
	ADD	A
	ADD	A
	MOV	D, A	; Result in D
	MVI	E, $FF	; 8 blobs foreground
	POP	PSW
	MVI	L, $80	; Control byte: graph, low def, 16-colour
@E5CB	RAR
	JC	@E5DE	; Jump if mode 3/4
;
; Mode 1/2 and 5/6 only
;
	RAR
	MVI	H, $0B	; Low def fields/line
	MVI	A, $03	; Low def bit mask
	JNC	@E5E2	; Jump if mode 1/2
;
; Mode 5/6 only
;
	MVI	H, $2C	; Super def fields/line
	MVI	A, $20	; Super def bit mask
	JMP	@E5E2
;
; Mode 3/4 only
;
@E5DE	MVI	H, $16	; High def fields/line
	MVI	A, $11	; High def bit mask
;
@E5E2	ORA	L	; Add def bits to get mode code
	MOV	B, A
	MOV	A, H	; Line length in A
	POP	H	; Get top of area
@E5E6	PUSH	PSW	; Save line length
	MOV	M, B	; Load line control byte
	DCX	H
	MVI	M, $40	; Null line col our byte
	DCX	H
@E5EC	MOV	M, E	; Load screen data locations with 1 blank field
	DCX	H
	MOV	M, D
	DCX	H
	DCR	A	; Next screen 1ocation
	JNZ	@E5EC	; Jump if line not ready
	POP	PSW	; Restore nr of locations in A
	DCR	C	; Next screen line
	JNZ	@E5E6	; Jump if not ready
	JMP	XRET	; Popall, ret
;
;
; *******************************
; * INITIALISE HEADER / TRAILER *
; *******************************
;
; Sets up 4 background colour lines which can act as header/trailer.
; Sets up colours in colour RAM. The header/trailer area consists of 4 groups of
; 4 bytes: 00 00 xx 3y, in which xx is the colour and 3x the mode word:
;    y=6: Header
;    y=F: Trailer
;    y=0: Middle area (split mode).
;
; Entry: HL: 1st byte header/trailer area
;        DE: Address table with required colours
;        A:  screen mode
;        B:  depth -1 in scans of each blanking line: 06 (header) 0F (trailer), 00 (middle)
; Exit:  HL: points after header/trailer area
;        AFBCDE preserved
;
SSUBL	PUSH	PSW
	PUSH	B
	PUSH	D
	MOV	C, A	; Store screen mode in C
	MOV	A, B
	ORI	$30	; Set 4 colour to make mode word + rept. count
	PUSH	PSW	; Save mode word on stack
	MVI	B, $00
	MOV	A, E	; Get 1obyte addr colours
	SUI	$7C
	JZ	@E61E	; If char mode then 4 colours
	MOV	A, C	; Get screen mode
	RAR
	RAR
	MOV	C, B
	JC	@E61F	; Jump if 4-colour mode
;
; 16-colour modes only
;
	POP	PSW	; Restore header/trailer info
	ORI	$80	; Set 16-colour (msb=1)
	PUSH	PSW
	LDAX	D	; Get clour
	ADD	A	;  Move 1onibble into hinibble
	ADD	A
	ADD	A
	ADD	A
	MVI	B, $FF	; Set all foreground
@E61E	MOV	C, A	; Colour in C
;
; Load header/trailer
;
@E61F	POP	PSW	; Get mode word
	PUSH	PSW
	MOV	M, A
	DCX	H	; Next addr in block
	LDAX	D	; Get colour info
	INX	D
	MOV	M, A	; Load 2nd byte
	DCX	H	; Next addr in block
	MOV	M, B	; Load 3rd byte
	DCX	H
	MOV	M, C	; Load 4th byte
	DCX	H
	CPI	$B0	; All blocks done?
	JC	@E61F	; Next one if not
	POP	PSW
	POP	D
	POP	B
	POP	PSW
	RET
;
; *****************************
; * SET UP A 4-LINE TEXT AREA *
; *****************************
;
; Locates the 1ast few lines of text on the screen. If the screen was in split mode, the
; whole contents of the old screen is located. If it was mode 0, the 1ast few lines above
; and the cursor line are located. The text is then moved to a required position, including
; the cursor, etc.
;
; Entry: HL: points to address where the text to be put
; Exit:  HL: points to new top of text
;        AFBCDE preserved
;
SMVTXT	PUSH	PSW
	PUSH	B
	PUSH	D
	MOV	B, H	; New top of text in BC
	MOV	C, L
	LHLD	CHS0	; Get previous start char
	PUSH	H	; on stack
	XCHG		; and in DE
	LXI	H, $FDE8	; Length split screen char area
	DAD	D	; Calc 1st line mode byte outside screen frame
	XCHG		; in DE
	LHLD	CURSOR	; Get cursor pos addr
	CALL	COMP_	; Check if cursor is still inside frame
	JC	@E675	; Jump if not
	XCHG		; HL is addr 1st line mode outside screen frame
	POP	D	; DE is prev start char
@E64F	PUSH	H	; Save end preserved text area
	LHLD	CURSOR	; Get cursor pos addr
	CALL	CURDEL	; Delete cursor
	XTHL		; Previous start char in HL
	CALL	MOVES	; Roll screen area to new top of text; cursor on 1ast line
	XTHL		; Cursor pos in HL
	CALL	SUBDE_	; Calc cursor pos against new frame start
	DAD	B	; Calc new cursor pos addr
	CALL	CURSET	; Keep cursor on same pos on line
	LHLD	LNSTR	; Get old start line pointer
	CALL	SUBDE_	; HL=HL-DE
	DAD	B	; Calc new cursor pos
	CALL	SSETL	; Store addr line mode byte current line and last addr on that line
	POP	H	; Get end preserved text area
	CALL	SUBDE_	; HL=HL-DE
	DAD	B
	POP	D
	POP	B
	POP	PSW
	RET
;
; Scroll frame 1 line if cursor outside frame
;
@E675	POP	H
	LHLD	LNSTR	; Get start addr cursor line
	LXI	D, $FF7A
	DAD	D	; HL: start line after cursor
	PUSH	H
	LXI	D, $0218
	DAD	D	; Subtract 4 lines and get
	XCHG		; line mode byte in DE
	POP	H	; Get end reqd area
	JMP	@E64F
;
; *********************************
; * PLACE CURSOR AT BEGIN OF LINE *
; *********************************
;
; Sets the cursor at the beginning of a line.
; Several painters are updated.
;
; SSETC: given a pointer to the start of line, sets start and end line variables and places
;        the cursor at the beginning of the line.
; SSETL: sets only start and end line positions
;
; Entry: HL: address line mode byte current line
; EXit:  ABCDEHL preserved
;
SSETC	PUSH	PSW
	PUSH	D
	PUSH	H
	LXI	D, $FFF8
	DAD	D	; Get addr 1st data byte on current line
	CALL	CURSET	; Put cursor on screen
	XRA	A
	STA	LCONT	; No extended lines
	POP	H
	POP	D
	POP	PSW
SSETL	PUSH	PSW
	SHLD	LNSTR	; Store addr line mode byte current line
	MVI	A, $80	; Calc 1obyte last addr on this line
	ADD	L
	STA	LNEND	; Store it in LNEND
	POP	PSW
	RET
;
; ************************
; * SET GRAPHICS COLOURS *
; ************************
;
; Sets the colours available in a 4 colour mode and the initial background in a 16 colour mode.
;
; Entry: HL: points to colours vector
; Exit:  al1 registers preserved
;
SCOLG	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LXI	D, COLMG	; Addr 1st COLORG byte
	CALL	VCOPY	; Set COLORG parameters
	LDA	SMODE	; Get current screen mode
	ORA	A	; Check mode type
	LHLD	SCTOP	; Get addr after header
	CP	BCOLS	; If not mode 0: Load COLORG parameters in header
	RAR		; Check if char made
	LHLD	SCE	; Get addr after trailer
	CNC	BCOLS	; If all graphics mode: load colours in trailer
	JMP	XRET	; Popall, ret
;
; ********************
; * MOVE SCREEN AREA *
; ********************
;
; Moves a block of screen data from any poition to any other.
;
; Entry: BC: points to highaddress target area
;        DE: points to highaddresS source area
;        HL: points to 1owaddress -1 source area
; Exit:  all registers preserved
MOVES	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	SUBDE_	; Calc length of block (neg. value)
	MOV	A, E
	SUB	C
	MOV	A, D
	SBB	B
	JC	@E6E2	; Jump if move up
;
; Move down
;
	MOV	D, H	; Length in DE
	MOV	E, L
	DAD	B	; HL = 1owest targetaddr -1
	POP	B	; BC = lowest sourceaddr -1
	PUSH	B
@E6D5	MOV	A, D
	ORA	E
	JZ	@E6EF	; Abort if ready
	INX	D
	INX	H
	INX	B
	LDAX	B	; Get byte from sorce area
	MOV	M, A	; and move it into target area
	JMP	@E6D5	; Next one
;
; Move up:
;
@E6E2	MOV	A, H
	ORA	L
	JZ	@E6EF	; Quit if ready
	INX	H
	LDAX	D	; Get byte from source area
	STAX	B	; Move it into target area
	DCX	B
	DCX	D
	JMP	@E6E2	; Next one
@E6EF	JMP	XRET	; Popall, ret
;
; ****************
; * HL = HL - DE *
; ****************
;
; Entry: none
; Exit:  HL = HL - DE
;        Other registers preserved
;
SUBDE_	PUSH	PSW
	MOV	A, L
	SUB	E
	MOV	L, A	; L = L - E
	MOV	A, H
	SBB	D
	MOV	H, A	; H = H - D
	POP	PSW
	RET
;
; *******************
; * COMPARE HL - DE *
; *******************
;
; Compares HL with DE (HL-DE).
;
; Exit Z=0: not identical:
;           CY=0: DE < HL
;           CY=1: DE > HL
;      Z=1: identical
;      AF corrupted, BCDEHL preserved
;
COMP_	MOV	A, H
	SUB	D
	RNZ
	MOV	A, L
	SUB	E
	RET
;
; *************************
; * ADD OFFSET TO ADDRESS *
; *************************
;
; Sets HL = HL + A
;
; Entry: HL: baseaddress
;         A: offset
; Exit:  HL = HL + A
;        BCDE preserved
;
DADA_	ADD	L	; Add 1obyte addr to offset
	MOV	L, A	; and store it in L
	RNC
	INR	H	; Incr hibyte if overtlow
	RET
;
; **********************************
; * TWO COMPLEMENT OF 16-BITS DATA *
; **********************************
;
; Sets HL = -HL.
;
; Entry: data to be complemented in HL
; Exit:  HL contains two-complement
;        AFBCDE preserved
;
CMPHL_	PUSH	PSW
	MOV	A, L
	CMA		; Compl. L
	MOV	L, A	; and store it
	MOV	A, H
	CMA		; Compl. H
	MOV	H, A	; and store it
	INX	H	; Add 1
	POP	PSW
	RET
;
; ****************************
; * DRAW A DOT ON THE SCREEN *
; ****************************
;
; Draws a single blob of a colour anywhere on the screen.
;
; Entry: C, HL: Y, X coordinate of the dot
;        A: colour of the dot
; Exit:  CY=0: OK
;        CY=1: error code in A
;        ABCDEHL preserved
SDOT	ORA	A
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	MOV	B, C	; Y-coord in B
	MOV	D, H	; X-coord in DE
	MOV	E, L
	JMP	LE81D	; Into 'SFILL'
;
; *****************************
; * DRAW A LINE ON THE SCREEN *
; *****************************
;
; Draws a line in a given colour between twoarbitrary points on the screen.
;
; The coordinates are given inclusively. The line will be drawn starting at the left end,
; whichever order the parameters are given in.
;
; Entry: B, DE: Y, X coordinate of one end of the line
;        C, HL: Idem of the other end
;        A:     Colour of the l1ne
; Exit:  CY=0: OK
;        CY=1: errorcode in A
;        ABCDEHL preserved
;
SDRAW	ORA	A
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	CALL	ARGCHK	; Check arguments, set colour
	PUSH	PSW
	CALL	COMP_	; Check direction of line
	MVI	A, $00	; Set 'no X, Y swap'
	JNC	@E72E	; Jump if X > Y
;
; Swap X, Y
;
	XCHG		; Exchange coordinates
	CMA
;
@E72E	STA	DIRN2	; $FF if X, Y swap, else $00
	MOV	A, C
	ANI	$07
	MOV	D, A	; Offset in field in D
	POP	PSW	; Get Y-pos left end
	PUSH	H	; Save X 1ength
	CALL	SMEMMK	; Pntr to start of line in screen RAM
	XTHL
	PUSH	D	; Save offset
	PUSH	H	; Save DX
	CALL	CMPHL_	; HL = -DX
	XTHL
	PUSH	H	; Save DX
	MOV	L, E
	MVI	H, $00
	DAD	H
	SHLD	COR	; Store 2*DY (adj long sectors)
	MOV	A, E	; DY in A
	STA	SECTC	; Set count of sectors (1-256)
	POP	H
	CALL	HLDIV_	; HL = DX / DY
	SHLD	SECT	; SECT is INT(DX/DY)
	POP	B	; Get -DX
	PUSH	H	; Save SECT
	MOV	A, E
	CALL	HLMUL_	; HL = SECT * DY
	DAD	B	; HL = SECT * DY - DX
	DAD	H	; HL = 2 * (SECT * DY - DX)
	SHLD	DELTA	; Store amount to add into count
	POP	H	; Get SECT
	MOV	A, H
	RAR
	MOV	A, L
	RAR		; A = INT(SECT/2)
	STA	TRIM	; Store amount to trim off last sector
	INR	A
	MOV	L, A
	MVI	H, $00	; HL = INIT
	PUSH	H
	DAD	H	; HL = 2 * INIT
	MOV	A, E
	CALL	HLMUL_	; HL = 2 * INIT * DY
	DAD	B	; HL = 2 * INIT * DY - DX
	SHLD	RT	; Set INIT running total
	POP	H	; Get 1ength 1st sector
	POP	PSW
	MOV	C, A	; C is initial offset
	MOV	A, E
	ORA	A
	JNZ	@E784	; If more than 1 sector
	STA	TRIM	; Store amount to trim off last sector
	LHLD	SECT	; Get 1ower of 2 possible sectors
	INX	H	; Frig length if only 1 sector
@E784	LXI	D, SECTC	; Addr of nr of sectors
	LDAX	D	; Get count of sectors
	SUI	$01	; -1
	STAX	D	; Store it again
	JNC	@E797	; Jump if not last sector
;
; Trim off last sector
;
	LDA	TRIM	; Get amount to trim off 1ast sector
	CMA
	MOV	E, A
	MVI	D, $FF
	INX	D
	DAD	D
;
@E797	LXI	D, $0001	; Init Y-size is 1
	LDA	DIRN2	; Check if swap X, Y dir
	ORA	A	; (line > 45 degrees)
	JZ	@E7A2	; Jump if not
	XCHG		; Swap X, Y direction
@E7A2	MOV	B, E	; Get Y-size in B
	XCHG		; X-size in DE
	POP	H	; Get memory pointer
	DCR	B
	LDA	DIRN1	; Check for Y-invert
	ORA	A
	PUSH	PSW	; Save condition
	CNZ	UPDTP	; Move pntr to bottom of sector
	DCX	D	; Interfacing
	CALL	FILRT	; Draw next sector of line
	INX	D	; Re-instate real values
	INR	B
	POP	PSW	; Get earlier condition
	JZ	@E7BA	; Jump if no Y-invert
	MVI	B, $01	; Init 1 blob down only
@E7BA	CALL	UPDTP	; Move ptr up/down
	MOV	A, C	; Get offset
	ADD	E	; Add X-movement
	MOV	C, A	; Save result
	MOV	B, A
	ANI	$07
	CMP	C
	JZ	@E7D2	; Junp if not new ield
;
; If new field
;
	MOV	C, A	; Update offset
	MOV	A, B	; Get complement new offset
	XRA	C	; Clip bits 0, 1, 2 off
	RAR		; Update pointer to new field
	RAR
	CMA
	MOV	E, A
	MVI	D, $FF
	INX	D
	DAD	D
;
@E7D2	PUSH	H	; Save memory pointer
	LHLD	DELTA	; Get. amount to add into count
	XCHG		; in DE
	LHLD	RT	; Set count running total
	DAD	D	; Add up
	XCHG		; Result in DE
	LHLD	SECT	; Get 1owest of 2 possible sectors
	XCHG		; in DE (distance to go)
	MOV	A, H
	ORA	A
	JP	@E7ED	; Jump if short sector
;
; If long sector
;
	INX	D	; Go one blob further
	PUSH	D
	XCHG
	LHLD	COR	; Get adjustment for 1ong sectors
	DAD	D	; Adjust error term
	POP	D
@E7ED	SHLD	RT	; Update running total
	XCHG
	LDA	SECTC	; Get nr of sectors
	INR	A
	JNZ	@E784	; Next sector if not ready
;
;  If ready
;
	POP	H
	JMP	XRET	; Popall, ret
;
;
; **************************
; * MOVE POINTER UP / DOWN *
; **************************
;
; Subroutine of SDRAW (2E71B).
; Takes a pointer to screen and moves it up or down the screen a number of lines. The move
; direction depends on DIRN1 (DIRN1)
;
; Entry: HL: pointer
;        B:  number of lines
; Exit:  HL updated
;        AFBCDE preserved
;
UPDTP	PUSH	PSW
	PUSH	D
	PUSH	H
	LDA	GXB	; Get number bytes/line
	MOV	L, A	; Store it in HL
	MVI	H, $00
	MOV	A, B	; Get nr of lines
	CALL	HLMUL_	; Calc total length in HL
	LDA	DIRN1	; Get Y-direction
	ORA	A	; Test if up or down
	CNZ	CMPHL_	; 1f down: calc 2-compl of HL
	POP	D
	DAD	D	; Update pntr
	CALL	PTRCK	; Into or out archive area
	POP	D
	POP	PSW
	RET
;
; *****************************************
; * FILL A RECTANGULAR AREA ON THE SCREEN *
; *****************************************
;
; Fills an arbitrary rectangle with a given colour.
;
; The middie of the rectangle is f11led first, then the left and then the right edge vertical strips.
; The coordinates are given inclusively. The rectangle is filled in the same order which
; ever order the parameters are given in.
;
; Entry: B, DE: Y,X coordinate of one corner
;        C, HL: Idem of the opposite corner
;        A: Colour
; Exit:  ABCDEHL preserved
;        CY=0: OK
;        CY=1: A contains error code
;
SFILL	ORA	A
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
LE81D	CALL	ARGCHK	; Check arguments, get colour
	MOV	D, A	; Get Y-coord left corner
	LDA	DIRN1	; Check if Y invert
	ORA	A
	MOV	A, D
	JZ	@E82A	; Jump if no Y-inversion
	SUB	E	; Y-pos bottom left
@E82A	PUSH	H	; Save X-s1ze
	CALL	SMEMMK	; Get memory address
	MOV	A, C
	ANI	$07
	MOV	C, A	; Offset in C
	MOV	B, E	; Height in B
	POP	D	; Width in DE
	CALL	FILRT	; Fill block
	JMP	XRET	; Popall, ret
;
; *******************************
; * CHECK ARGUMENTS, GET COLOUR *
; *******************************
;
; Checks the arguments given to a entry point and sets up the colour variables. Swaps order
; of two points given if necessary.
;
; Entry: ABCDEHL: See SFILL.
;        All registers and a returnaddr on stack.
; Exit:  CY=0: OK:
;              A, BC: Set to left corner
;              DE, HL: Set to Y, X lengths of line
;              DIRN1: <> 0 if Y-direction negative
;        CY=1: error report
;              A=1: off screen
;              A=2: colour not available
;
ARGCHK	CALL	COLSU	; Set up colour variables
	JC	@E875	; Jump it colour not av.
	CALL	TPOSN	; Check if room available
	JC	@E87F	; Jump if not
	PUSH	B
	MOV	C, B	; Y-coord one point in C
	XCHG
	CALL	TPOSN	; Check if room available
	XCHG
	POP	B
	JC	@E87F	; Jump if not
	CALL	COMP_	; Compare HL-DE
	JNC	@E85D	; Right most point to C, HL
;
;  Swap Y-coord.
;
	XCHG
	PUSH	PSW
	MOV	A ,B	; Swap 2 points
	MOV	B, C
	MOV	C, A
	POP	PSW
;
@E85D	CALL	SUBDE_	; Calc horizontal length
	PUSH	D	; Save X-pos 1eft corner
	MOV	A, C
	SUB	B
	MVI	D, $00	; Clear Y-invert flag
	JNC	@E86B	; Jump if end above start
	CMA
	INR	A
	DCR	D
;
@E86B	MOV	E, A	; Get vertical length
	MOV	A, D
	STA	DIRN1	; Set Y-invert flag
	MVI	D, $00
	MOV	A, B	; Get Y-pos 1eft corner
	POP	B	; Get X-pos left corner
	RET
;
;  If colour error
;
@E875	MVI	A, $02	; Error colour not available
@E877	POP	H
	POP	H
	POP	D
	POP	B
	INX	SP
	INX	SP
	STC		; Return error
	RET
;
; If off screen error
;
@E87F	MVI	A, $01	; Error off screen
	JMP	@E877	; Abort
;
; *******************************************
; * ASK COLOUR OF A POINT ON THE SCREEN AND *
; * ASK SIZE OF THE GRAPHICS SCREEN         *
; *******************************************
;
; Aks the colour of a given point on the screen and the size of the graphics area of the screen.
;
; Entry: C, HL: Y, X coordinate of the dot required.
; Exit:  CY=0: OK
;              A: Colour at requested point.
;              B, DE: Max coordinates of the graphics area
;              CHL preserved
;        CY=1: A: error code
;              BCDEHL preserved
;
SSCRN	PUSH	H
	PUSH	B
	CALL	TPOSN	; Check if room available
	JC	@E8D8	; Jump if not
	MOV	A, L
	ANI	$07
	PUSH	PSW	; Remember field offset
	MOV	A, C	; Coord in A, B, C
	MOV	B, H
	MOV	C, L
	CALL	SMEMMK	; Get address of point
	LDA	SMODE	; Get current screen mode
	RAR
	RAR
	JC	@E8B8	; Jump if 4-colour mode
;
; If 16-colour mode
;
	CALL	SSFM	; Colours to buffer
	LXI	H, SCXRUF	; Addr SCXBUF
	POP	PSW
	CALL	DADA_	; Calc addr in buffer
	MOV	A, M	; Get clour for reqd blob
@E8A9	LHLD	GRL	; Get nr of graphics 11nes
	MOV	B, L
	DCR	B	; 1obyte -1 in B
	LHLD	GRC	; Get nr of hor. blobs
	DCX	H	; -1
	XCHG		; in DE
	POP	H
	MOV	C, L	; Y-coord in C
	POP	H	; X-coord in HL
	ORA	A	; CY=0
	RET
;
; If 4-colour mode
;
@E8B8	MOV	D, M	; Get screen data of point in DE
	DCX	H
	MOV	E, M
	POP	PSW
	MOV	C, A	; Field offset in C
	MVI	B, $01
	CALL	SMKMSK	; Set mask for bits
	LXI	H, COLMG	; Pntr to COLORG colours
	MOV	A, B
	ANA	D	; Test top bit result
	JZ	@E8CC	; Skip if 0
	INX	H
	INX	H
@E8CC	MOV	A, B
	ANA	E	; Test bottom bit result
	JZ	@E8D2	; Skip if 0
	INX	H
@E8D2	MOV	A, M	; Get result from table
	ANI	$0F	; Colour bits only
	JMP	@E8A9
;
; If off screen
;
@E8D8	POP	H
	POP	B
	MVI	A, $01	; Error 'off screen'
	STC
	RET
;
; ******************
; * UPDATE A FIELD *
; ******************
;
; Given a mask of bits to be changed, a colour to set them to and a memory address where the field
; starts. This routine reads, updates and replaces a field.
;
; Entry: HL: memory address of start of field
;        B:  mask of bits to be changed
;        C:  colour to change to (hinibble)
; Exit:  all registers preserved
;
SUPDTE	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	MOV	A, C
	RRC		; Move hinibble C into lonibble
	RRC
	RRC
	RRC
	MOV	C, A
	PUSH	B
	CALL	SSFM	; Get current state of screen
	POP	B
	CALL	SUDCH	; Change as required
	POP	H
	PUSH	H
	JMP	SPT02	; Set up screen bits for mode 1
;
	.byte	$FF
;
; **********************************
; * LOAD BUFFER SCXBUF FROM SCREEN *
; **********************************
;
; Takes 2 bytes of screen info in 16-colour mode and places then in SCXBUF (SCXRUF-AB) in 'standard
; form'.
;
; Entry: HL: points to 1st byte of info on screen
; Exit:  all registers corrupted
;
SSFM	INX	H
	MOV	A, M	; Get previous colour byte
	ANI	$0F	; Background only
	MOV	C, A	; Previous background in C
	DCX	H
	MOV	D, M	; Select byte in D
	DCX	H
	MOV	E, M	; Colour byte in E
	DCX	H
	PUSH	H	; Save pntr to next field select byte
	MOV	A, E	; Colour byte in A
	ANI	$F0	; Foreground colour in lonibble
	RRC
	RRC
	RRC
	RRC
	MOV	B, A	; Foreground colour in B
	LXI	H, SCXRUF	; Addr SCXBUF
	MOV	A, D	; Get bit maskk
	MVI	D, $08	; 8 bytes to set
@E90F	RLC
	MOV	M, C	; Set background
	JNC	@E91E	; Jump if background
	MOV	M, B	; Else: set foreground
	PUSH	PSW
	MOV	A, E	; Get colour byte
	ANI	$0F	; Background colour only
	MOV	C, A	; Background is current BG
	STA	SBGOC	; Store it as colour carried out to next field
	POP	PSW
@E91E	INX	H	; Next pos in SCXBUF
	DCR	D	; Count -1
	JNZ	@E90F	; Loop if more bits
	POP	B	; Get pntr to next field select byte
	MVI	M, $FF	; Flag no carry out in SBGOU
	LDAX	B	; Get next select byte
@E927	INR	M	; Set 'carry out' flag
	RLC
	JNC	@E927	; Loop counting carry out
	RET
;
; *********************************
; * SET UP SCREEN BITS FOR MODE 1 *
; *********************************
;
; Takes the 8 blobs represented in standard form in SCXBUF, and tries to represent them in a way
; which the screen requires for mode 1.
; Up to 2 colours is easy. 3 require to attempt to carry in the 1st colour from the previous byte.
;
; Entry: HL: Points to ist of the 2 screen bytes
; Exit:  Screen will be updated as well as possible
;         All registers preserved
;
SBFM	INX	H
	MOV	A, M
	ORI	$80
	MOV	E, A	; Prev backgrournd in E
	MVI	D, $00	; Init bitmap
	LXI	H, SCXRUF	; Addr SCXBUF
	NOP
	NOP
LE939	LDA	SBGOU	; Get flag for colour carried out
	ORA	A
	JZ	@E945	; Jump if no carry out
	LDA	SBGOC	; Get colour carried out
	ORI	$80	; Set msb=1
@E945	MOV	C, A	; Background colour in C
	MOV	A, M
	INX	H
	MOV	B, A	; Set 1st blob as FG colour
	MOV	A, D	; 1 bit in right end bit mask
	STC
	RAL
	MOV	D, A
@E94D	MOV	A, M
	INX	H
	CMP	B	; Is next blob FG colour?
	STC
	JZ	@E961	; Jump if true
	ORI	$80
	CMP	C	; Test if same as BG?
	JZ	@E960	; Jump if true
	DCR	C
	INR	C
	JM	$E986	; No 1uck if BG used already
	MOV	C, A	; Else set it to BG
@E960	ORA	A
@E961	MOV	A, D	; New bit in bottom of mask
	RAL
	MOV	D, A
	MOV	A, L
	CPI	$AB	; End of buffer reached?
	JNZ	@E94D	; Loop until all set up
	POP	H
	PUSH	H
	INX	H
	MOV	A, E
	ANI	$0F
	MOV	E, A	; Only 1onibble of E
	MOV	A, M
	ANI	$F0	; Only hinibble of M
	ORA	E
	MOV	M, A	; Add both nibbles together
	DCX	H
	MOV	A, B
	ADD	A
	ADD	A
	ADD	A
	ADD	A	; FB colour to top bits
	MOV	B, A
	MOV	A, C
	ANI	$0F	; Low nibble only
	ORA	B
	MOV	M, D	; Bitmap from D
	DCX	H
	MOV	M, A	; Calours from E
LE984	POP	H
	RET
;
; 3 colours needed
;
SBF80	MOV	A, E
	ORA	A
	JP	LE984	; Jump if tried BG carried in
	ANI	$0F	; Previous BG
	CMP	B	; Test against 1st blob colour
	POP	H
	PUSH	H
	INX	H
	INX	H
	MOV	A, M	; Get bit map
@E993	STC
	RAL
	JNC	@E993	; Ignore leading BG
	JZ	@E9A1	; Jump if colour matches anyway
	INR	A
	JNZ	LE984	; No good if BG used
;
; Background not in use
;
	MOV	E, B	; Set previous BG
	NOP
@E9A1	LXI	H, SCXRUF	; Addr SCXBUF
	MVI	D, $00	; Init D
	NOP
	MOV	C, D	; and C (BG free)
@E9A8	MOV	A, M	; Get byte from SCXBUF
	CMP	B
	JNZ	LE939	; Jump if blob not old BG colour
	NOP
	INX	H
	JMP	@E9A8	; Next blob
;
; ************************
; * UPDATE BUFFER SCXBUF *
; ************************
;
; Takes a set of 'update instructions' in BC and sets various bytes in SCXBUF accordingly.
;
; Entry: BC: instructions
; Exit:  all registers corrupted
;
SUDCH	LXI	H, SCXRUF	; Addr SCXBUF
	MOV	A, B	; Mask in A
	MVI	B, $08	; 8 byte to be done
@E9B8	RLC		; Bit from mask into CY
	JNC	@E9BD	; Jump if bit = 0
	MOV	M, C	; Else: C into SCXBUF
@E9BD	INX	H
	DCR	B
	JNZ	@E9B8	; Next byte if not ready
	RET
;
; ***************************
; * SET UP COLOUR VARIABLES *
; ***************************
;
; Entry: A: colour
; Exit:  CY=1: colour not available
;        CY=0: OK; ABCDEHL preserved
;
COLSU	ORA	A
	PUSH	PSW
	PUSH	B
	MOV	C, A	; Colour in C
	XRA	A
	STA	ANIM	; Reset animate flag
	LDA	SMODE	; Get current screen mode
	RAR
	RAR
	JNC	@E9FD	; Jump if 16-colour
;
; If 4-colour
;
	MOV	A, C	; Get colour
	CPI	$10
	JC	@E9E1	; Jump if < 16
	CALL	LD886	; Check if >= 20. Set ANIM for 4-colour animate if not
	ANI	$03
	JMP	@E9E7	; Bottom 3 bits only
@E9E1	CALL	STR164	; Find colour in COLORG reg (2 bit code)
	JNC	@EA07	; Jump if colour not av.
@E9E7	MVI	B, $00
	CPI	$02
	JC	@E9EF	; Jump if top bit 0
	DCR	B	; Set 00/$FF on top bit
@E9EF	ANI	$01
	CMA
	INR	A	; Set 00/$FF on bottom bit
@E9F3	STA	FCOLR
	MOV	A, B	; Store details for colour reqd
	STA	FCOLR+1
	POP	B
	POP	PSW
	RET
;
; If 16-colour
;
@E9FD	MOV	A, C	; Get colour
	ADD	A	; * 16
	ADD	A
	ADD	A
	ADD	A
	MVI	B, $FF
	JMP	@E9F3	; Store details for colour reqd
;
; If colour not found
;
@EA07	POP	B
	POP	PSW
	CMC		; Quit; 'colour not available'
	RET
;
;
; **************
; * FILL BLOCK *
; **************
;
; Fills a rectangular block of whole fields with one colour.
;
; Entry: HL: Address bottom left corner.
;        DE: Y, X-counts of size of block (E in fields)
;        FCOLR: colour info
; Exit:  BCDEHL preserved
;        AF corrupted
;
FILBK	PUSH	B
	PUSH	D
	PUSH	H
	LDA	FCOLR	; Get details for colour
	MOV	C, A	; required in BC
	LDA	FCOLR+1
	MOV	B, A
	INR	E	; Count range up by 1
@EA17	PUSH	D
	PUSH	H
@EA19	LDA	ANIM	; Get animate flag
	ORA	A
	JNZ	@EA46	; Jump if set
	LDA	SMODE	; Get current screen mode
	RAR
	RAR
	MOV	M, B	; Colour details in screen RAM
	DCX	H
	JNC	@EA3E	; Jump if 16-colour mode
;
; If 4-colour mode
;
	MOV	M, C	; Colour details in screen RAM
@EA2B	DCX	H
	DCR	E
	JNZ	@EA19	; Loop to do all fields
	POP	H	; HL pnts to left of rectangle
	POP	D	; Get Y-size count
	DCR	D
	INR	D
	JZ	@EA53	; Abort if ready
	DCR	D	; Update Y-count
	CALL	DADCK	; Update pntr to next line
	JMP	@EA17	; Next line
;
; If 16-colour mode
;
@EA3E	MOV	A, M	; Get data from screen RAM
	ANI	$0F	; Lonibble only (old BG)
	ORA	C	; Add details
	MOV	M, A	; Preserve old background
	JMP	@EA2B
;
; If animate
;
@EA46	PUSH	H
	DCR	B
	INR	B
	JNZ	@EA4D
	DCX	H
@EA4D	MOV	M, C	; Change whole field
	POP	H
	DCX	H
	JMP	@EA2B	; Next field
;
@EA53	POP	H
	POP	D
	POP	B
	RET
;
; **************
; * FILL STRIP *
; **************
;
; Fills a vertical strip on the screen with one colour.
;
; Entry: HL: points to bottom field of strip
;        B:  mask bits to change
;        D:  heigth -1 of strip
; Exit:  AF corrupted
;        BCDEHL preserved
;
FILST	PUSH	B
	PUSH	D
	PUSH	H
	LDA	SMODE	; Get current screen mode
	RAR
	RAR
	JNC	@EAA9	; Jump if 16-colour mode
;
; If 4-colour mode
;
	PUSH	D
	XCHG
	LHLD	FCOLR	; Get details for col our reqd
	LDA	ANIM	; Get animate flag
	ORA	A
	JNZ	@EA91	; Jump 1f set
	MOV	A, B	; Mask for bits to be update
	ANA	H
	MOV	C, A
	MOV	A, B
	ANA	L
	MOV	L, A
	MOV	A, B
	CMA		; Bits to be preserved
	MOV	B, A
	MOV	H, A
@EA78	XCHG
@EA79	MOV	A, B
	ANA	M	; Pick up old colours
	ORA	C
	MOV	M, A	; Update top bits
	DCX	H
	MOV	A, D
	ANA	M
	ORA	E
	MOV	M, A	; Update bottom bits
	INX	H
	XTHL
	MOV	A, H
	DCR	H
	ORA	A
	JZ	@EABC	; Jump if ready
	XTHL
	CALL	DADCK	; Update pointer
	JMP	@EA79	; Next line
;
; If animate
;
@EA91	PUSH	H	; Preserve colour details
	MOV	A, B
	ANA	L
	MOV	C, A	; Bits to be set in C
	MOV	A, B
	CMA
	ORA	L
	MOV	B, A	; To be set
	MVI	L, $00
	MVI	H, $FF	; For other byte
	POP	PSW	; Get colour details
	ORA	A
	JNZ	@EAA6
	PUSH	B
	PUSH	H
	POP	B
	POP	H
@EAA6	JMP	@EA78
;
; If 16-colour mode
;
@EAA9	LDA	FCOLR	; Get 1 byte of details colour required
	MOV	C, A	; Set colour as reqd
@EAAD	CALL	SUPDTE	; Update
	MOV	A, D
	DCR	D
	ORA	A
	JZ	@EABD
	CALL	DADCK	; Next line
	JMP	@EAAD	; Next field
;
; 1f ready
;
@EABC	POP	H
@EABD	POP	H
	POP	D
	POP	B
	RET
;
; **************************
; * MOVE AND CHECK POINTER *
; **************************
;
; DADCK: Moves a pointer 1 line up screen and offsets to alternate area if necessary
; PTRCK: Checks a memory pointer and moves it into or out of the archive area if necessary
;
; Exit: H: new pointer
;
DADCK	LDA	GXB	; Get nr bytes/line
	CALL	DADA_	; Add 1 line length
PTRCK	PUSH	B
	PUSH	D
	XCHG
	LHLD	GRE	; Get addr after end graphics area
	CALL	COMP_	; Compare HL-DE
	LHLD	FFB	; Get bottom archive area
	MOV	B, H	; in BC
	MOV	C, L
	LHLD	SCTOP	; Get top visible area
	JNC	LEAE5	; Jump if pntr is below visible screen
	CALL	COMP_	; Compare HL-DE
	JC	LD80F	; Jump if pntr is off top visible screen
LEAE1	XCHG
LEAE2	POP	D
	POP	B
	RET
;
; If pntr is below visible screen
;
LEAE5	PUSH	H	; Swap BC and HL
	PUSH	B
	POP	H
	POP	B
	CALL	COMP_	; Compare HL-DE
	JC	LEAE1	; Jump if within archive area
LEAEF	XCHG
	CALL	SUBDE_	; Subtract nearest boundary
	DAD	B	; Add other
	JMP	LEAE2
;
; ***************************
; * FILL A RECTANGULAR AREA *
; ***************************
;
; Entry: DE: width
;        B:  height
;        C:  offset
;        HL: address
; Exit:  all registers preserved
;
FILRT	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	PUSH	H
	MOV	A, C
	ADD	E
	MOV	H, A	; H = C + E
	MVI	A, $00
	ADC	D
	MOV	D, B
	RAR
	MOV	A, H
	JC	@EB0D
	CPI	$08
	JC	@EB40	; If > 8: Fill only one stri
@EB0D	RAR
	RRC
	ANI	$7E
	XTHL
	PUSH	PSW
	RRC
	SUI	$02
	MOV	E, A
	DCX	H
	DCX	H
	CNC	FILBK	; Fill block
	INX	H
	INX	H
	MOV	A, C
	SUI	$09
	CMA
	MOV	B, A
	CALL	SMKMSK	; Set mask for bits
	CALL	FILST	; Fill strip
	POP	PSW
	CMA
	MOV	C, A
	MVI	B, $FF
	INX	B
	DAD	B
	POP	PSW
	ANI	$07
	INR	A
	MOV	B, A
	MVI	C, $00
@EB37	CALL	SMKMSK	; Set mask for bits
	CALL	FILST	; Fill strip
	JMP	XRET	; Popall, ret
;
; If < 1 field
;
@EB40	MOV	B, E
	INR	B
	POP	H
	JMP	@EB37	; Fill a strip only
;
; *************************
; * CALCULATE HL = A * HL *
; *************************
;
; Exit: AFBCDE preserved
;
HLMUL_	PUSH	PSW
	PUSH	D
	XCHG		; Original HL in DE
	LXI	H, $0000	; Init result
@EB4C	ORA	A
	JZ	@EB5D	; Abort if ready
	RAR		; Calc HL = A * HL
	PUSH	PSW
	JNC	@EB56
	DAD	D
@EB56	XCHG
	DAD	H
	XCHG
	POP	PSW
	JMP	@EB4C	; Cont multiplication
@EB5D	POP	D
	POP	PSW
	RET
;
; *************************
; * CALCULATE HL = HL / A *
; *************************
;
; Exit: AFBCDE preserved
;
HLDIV_	PUSH	PSW
	ORA	A
	JZ	@EB78	; Abort if A=0
	PUSH	B
	PUSH	D
	LXI	B, $FFFF
	CMA
	MOV	E, A
	MVI	D, $FF
	INX	D
@EB6F	DAD	D
	INX	B
	JC	@EB6F
	MOV	L, C	; Result in HL
	MOV	H, B
	POP	D
	POP	B
@EB78	POP	PSW
	RET
;
; *********************************************
; * CHECK IF SUFFICIENT ROOM FOR GRAPHIC MDDE *
; *********************************************
;
; Exit: CY=1: Insufficient room for mode
;       CY=0: OK
;       ABCDEHL preserved
;
TPOSN	PUSH	B
	PUSH	PSW
	PUSH	D
	LDA	SMODE	; Get current screen mode
	ADI	$01
	JC	@EB96	; If mode 0: Abort CY=1
	XCHG
	LHLD	GRC	; Get nr of hor. blobs
	DCX	H	; minus 1
	CALL	COMP_	; Compare HL-DE
	XCHG
	JC	@EB96	; Abort CY=1: if insufficient room
	LDA	GRL	; Get nr of graphics lines
	DCR	A	; minus 1
	CMP	C	; Set flags on difference
@EB96	POP	D
	POP	B
	MOV	A, B
	POP	B
	RET
;
; ***********************************
; * FIND COLOUR IN COLORG REGISTERS *
; ***********************************
;
; Entry: C: requested colour
; Exit:  CY=1: 'Serialnr' of colour in A
;        CY=0: Colour not available
;        BCDEHL preserved
;
STR164	PUSH	B
	PUSH	H
	LXI	H, COLMG	; Addr 1st colour byte graph
	MVI	B, $03	; Total 4 colour data
@EBA2	MOV	A, M	; Get colour
	ANI	$0F	; Colour nibble only
	CMP	C	; Ident to reqd one?
	JZ	@EBB2	; Then colour found
	INX	H	; Pnts to next one
	DCR	B
	JP	@EBA2	; Get next colour
	ORA	A	; CY=0
@EBAF	POP	H
	POP	B
	RET
;
; If colour found
;
@EBB2	MVI	A, $03
	SUB	B	; Colour 'nr' in A
	STC
	JMP	@EBAF	; Quit, CY=1
;
; **********************
; * GET MEMORY POINTER *
; **********************
;
SMEMMK	PUSH	D
	PUSH	PSW
	MOV	A, B
	RRC
	MOV	A, C
	RAR
	RAR
	ANI	$7E
	ADI	$04
	MOV	E, A
	MVI	D, $00
	POP	H
	PUSH	H
	MOV	L, H	; Entry A in L
	MVI	H, $00
	INX	H	; +1
	LDA	GXB	; Get nr bytes/line
	CALL	HLMUL_	; Calc HL = A * HL
	CALL	SUBDE_	; HL = HL - DE
	XCHG		; Result in DE
	LHLD	GRE	; Get addr after end graph area
	DAD	D	; Add offset
	CALL	PTRCK	; Check and move pntr
	POP	PSW
	POP	D
	RET
;
; *********************
; * SET MASK FOR BITS *
; *********************
;
; Entry: B and C are data for mask
; Exit:  B: result
;        AFCDEHL preserved
;
SMKMSK	PUSH	PSW
	PUSH	B
	XRA	A	; A=0
@EBE4	STC		; CY=1
	RAR
	DCR	B
	JNZ	@EBE4	; RAR (B) times
@EBEA	RAR
	DCR	C
	JP	@EBEA	; RAR until C <= $7F
	RAL
	POP	B
	MOV	B, A	; Result in B
	POP	PSW
	RET
;
;
;
;     =====================
; *** SCREEN EDITOR PACKAGE ***
;     =====================
;
;
; *********************
; * INITIALISE EDITOR *
; *********************
;
; Sets up a mode 0 screen, clears v_EWINX-v_ECURY, v_CURPT+1.
; Prints text from v_EBUFR onwards; cursor at top left.
;
; Exit: HL: Cursor position (top left)
;       AF corrupted, BCDE preserved
;
EINIT	MVI	A, $FF	; Init mode 0
	CALL	SSETM	; Change to mode 0
	MVI	A, $0C
	CALL	SOUTC	; Clear screen
	LXI	H, $0000	; Clear edit pointers
	SHLD	v_EWINY
	SHLD	v_ECURY
	MOV	A, H
	STA	v_EWINX
	STA	v_ECURX
	STA	v_CURPT+1
	LHLD	CURSOR	; Get cursor pos addr
	CALL	CURDEL	; Delete cursor
	CALL	LEF3A	; Print full screen from start of edit buffer
	CALL	CURSET	; Put cursor on screen
	RET
;
; *************
; * OBEY EDIT *
; *************
;
; A given character is inserted in the buffer, except:
;   #08 deletes a character
;   #10 moves cursor up
;   #11 moves cursor down
;   #12 moves cursor left
;   #13 moves cursor right
;   #14 moves window up
;   #15 moves window down
;   #16 moves window left
;   #17 moves window right
;
; Entry: A: character given
; Exit:  CY=1: if done
;        CY=0: not done
;        ABCDEHL + rest of F preserved
;
EOBEY	CPI	$08
	JZ	EDLCH	; Delete character
	CPI	$10
	JC	EINCH	; Insert character
	JZ	ECUP	; Cursor up
	CPI	$12
	JC	ECDN	; Cursor down
	JZ	ECLF	; Cursor left
	CPI	$14
	JC	ECRT	; Cursor right
	JZ	EWUP	; window up
	CPI	$16
	JC	EWDN	; Window down
	JZ	EWLF	; Window left
	CPI	$17
	JZ	EWRT	; Window right
	JMP	EINCH	; Insert character
;
; *************
; * WIND0W UP *
; *************
;
; Moves window up one line
;
; Exit: All registers preserved
;       CY=0: window unchanged
;       CY=1: window changed
;
EWUP	PUSH	D
	PUSH	H
	PUSH	PSW
	LHLD	v_EWINY	; Get offset of top of window
	MOV	A, H
	ORA	L
	JZ	LECDA	; Window unchaged if offset = 0; CY=0
	XRA	A
	STA	v_CURPT+1	; Clear cursor pos in buffer
	LDA	v_ECURY	; Get Y-offset cursor in in document
	SUB	L	; Minus offset top of window
	CPI	$17	; Nr of lines in window -1
	CZ	ECUP	; Cursor up if at bottom of window
	LHLD	CURSOR	; Get cursor pos addr
	PUSH	H
	CALL	CURDEL	; Delete cursor
	CALL	LEC74	; Move window, correct pntrs
	POP	H
LEC6E	LXI	D, $FF7A	; Length one line
	JMP	LECD5	; Put cusor on next line, quit with CY=1
;
; SCROLL EDIT DISPLAY DOWN ONE LINE
;
; Exit: BC preserved
;       AFDEHL corrupted
;
LEC74	PUSH	B
	LXI	B, GRR	; Length one screen line
	CALL	LEC86	; Move window up in text 1 line
	PUSH	D
	LHLD	v_EWINY	; Get offset of top of window
	DCX	H	; -1
	SHLD	v_EWINY	; And preserve it
	JMP	LECEF	; Print new line of text at window botton
;
; ***********************
; * MOVE WINDOW IN TEXT *
; ***********************
;
; Moves window up or left.
;
; Entry: BC: Offset (#86 for 1 line, #02 for 1 position)
; Exit:  all registers corrupted
;
LEC86	LHLD	CHE	; Get addr after end char area
	MOV	D, H	; in DE
	MOV	E, L
	DAD	B	; Add offset
	XCHG		; HL: end char area
			; DE: end char area + offset
;
; Move full screen
;
@EC8D	LXI	B, $0006	; 3 not used 1ocations at line end
	DAD	B	; Add it to both HL and DE and exchange DE and HL
	XCHG
	DAD	B
	XCHG
	MVI	B, 60	; 60 char/line visible
;
; Move on line
;
@EC96	INX	H
	INX	H	; New destination pntr
	INX	D
	INX	D	; New origin pntr
	LDAX	D	; Get one char
	MOV	M, A	; Move it to new screen 1oc
	DCR	B	; char count -1
	JNZ	@EC96	; Next char if not ready
	LXI	B, $0008	; 4 not-useable pos at line boundary
	DAD	B	; HL pnts to end previous line (destination)
	PUSH	H
	LHLD	CHS	; Get addr start char area
	XCHG		; in DE
	DAD	B	; Update origin too
	CALL	COMP_	; Compare HL-DE
	XCHG		; New origin in DE
	POP	H	; Destination in HL
	JC	@EC8D	; Evt another line
	RET
;
; ***************
; * WINDOW DOWN *
; ***************
;
; Moves window down one line
;
; Exit: ABCDEHL preserved
;       CY=0: window unchanged
;       CY=1: window changed
;
EWDN	PUSH	D
	PUSH	H
	PUSH	PSW
.if ROMVERS == 11
	LHLD	v_EWINY	; Get offset top of window from start buffer
	XCHG		; in DE
	CALL	XD26B
	CM	ECDN	; Then cursor down
.endif
.if ROMVERS == 10
	LHLD	v_ECURY	; Get Y-offset cursor in document
	LDA	v_EWINY	; Get offset of top of window
	CMP	L	; Cursor at top of screen?
	CZ	ECDN	; Then cursor down
.endif
	JNC	LECDA	; Quit with CY=0 if window unchanged
	XRA	A
	STA	v_CURPT+1	; Clear cursor pos in buffer
	LHLD	CURSOR	; Get cursor pos addr
	PUSH	H
	CALL	CURDEL	; Delete cursor
	CALL	LECDF	; Scroll edit display up one line
	POP	H
LECD2	LXI	D, GRR	; Length one screen line
LECD5	DAD	D	; One line further
LECD6	CALL	CURSET	; Put new cursor on screen
	STC		; Exit CY=1 if cursor moved
LECDA	POP	H
	MOV	A, H
	POP	H
	POP	D
	RET
;
; SCROLL EDIT DISPLAY UP ONE LINE
;
; Exit: BC preserved
;       AFDEHL corrupted
;
LECDF	PUSH	B
	CALL	SCROLL	; Scroll window up 1 line
	PUSH	H
	LHLD	v_EWINY	; Get offset of top of window
	INX	H	; +1
	SHLD	v_EWINY	; Preserve it
	LXI	D, $0017	; Nr of lines for window
	DAD	D	; HL pnts to new line at window bottom
LECEF	CALL	LEE1C	; Skip lines
	POP	D
	CALL	LEEC0	; Print new line of text
	POP	B
	RET
;
; ****************
; * WINDOW RIGHT *
; ****************
;
; Moves window right one position.
;
; Exit: ABCDEHL preserved
;       CY=0: window unchanged
;       CY=1: window changed
;
EWRT	PUSH	D
	PUSH	H
	PUSH	PSW
	LDA	v_EWINX	; Get offset of left side of window
	CPI	$C4	; 256-60
	JZ	LECDA	; Abort if window at right end of text
	MOV	L, A	; Offset in L
	LDA	v_ECURX	; Get X-offset cursor in document
	CMP	L	; Cursor at left side of window?
	CZ	ECRT	; Then move cursor right
	LHLD	CURSOR	; Get cursor pos addr
	PUSH	H
	CALL	CURDEL	; Delete cursor
	CALL	LED1B	; Scroll display left 1 pos
	POP	H
LED16	INX	H
	INX	H
	JMP	LECD6	; Put cursor on screen; quit with CY=1
;
; SCROLL EDIT DISPAY LEFT ONE POSITION
;
; Exit: BC preserved
;       AFDEHL corrupted
;
LED1B	PUSH	B
	LXI	B, $FFFE	;-2
	CALL	LE1CE	; Scroll window
	LDA	v_EWINX	; Get offset of left side of window
	INR	A	; +1
	STA	v_EWINX	; Preserve it
	ADI	$3B	; +60 (offset right side of window)
	LXI	D, $FF82	; -$7E
LED2E	MOV	B, A	; Offset right side of window in B
	MVI	C, $18	; Nr of lines in window
	LHLD	CHS	; Get pntr to start char area
	DAD	D	; Pos 60th char on screen
	XCHG		; in DE
	LHLD	v_EWINY	; Get offset of top of window
	CALL	LEE1C	; Skip lines
;
; Put newly visible 60th character on screen
;
@ED3C	CALL	LEE7B	; Skip to Bth pos on 11ne
	STAX	D	; Next visible char in window
	CALL	LEE38	; Next line
	PUSH	H
	LXI	H, $FF7A	; -86 (1ength one line)
	DAD	D	; Pnts to 60th char on next line
	XCHG
	POP	H
	DCR	C	; Update line count
LED4B	JNZ	@ED3C	; Scroll next line if not ready
	POP	B
	RET
;
; ***************
; * WINDOW LEFT *
; ***************
;
; Moves window left one position.
;
; Exit: ABCDEHL preserved
;       CY=0: window unchanged
;       CY=1: window changed
;
EWLF	PUSH	D
	PUSH	H
	PUSH	PSW
	LDA	v_EWINX	; Get offset of left side of window
	ORA	A
	JZ	LECDA	; Abort if offset = 0
	MOV	L, A	; Offset in L
	LDA	v_ECURX	; Set X-offset of cursor in document
	SUB	L
	CPI	$3B	; Cursor at right side of window?
	CZ	ECLF	; Then cursor 1eft
	LHLD	CURSOR	; Get cursor pos addr
	PUSH	H
	CALL	CURDEL	; Delete cursor
	CALL	LED74	; Move window, correct pntrs
	POP	H
LED6F	DCX	H
	DCX	H	; New cursor pos
	JMP	LECD6	; Put cursor on screen; quit with CY=1
;
; SCROLL EDIT DISPLAY RIGHT ONE POSITION
;
; Exit: BC preserved
;       AFDEHL corrupted
;
LED74	PUSH	B
	LXI	B, $0002
	CALL	LEC86	; Move window in text
	LDA	v_EWINX	; Get offset of left side of window
	DCR	A	; -1
	STA	v_EWINX	; Preserve it
	LXI	D, $FFF8	; Gives in ED2E 1st pos on 1st screen line
	JMP	LED2E	; Scroll display left
;
; *************
; * CURSOR UP *
; *************
;
; Moves cursor up one position.
;
; Exit: ABCDEHL preserved
;       CY=0: cursor not moved
;       CY=1: cursor moved
;
ECUP	PUSH	D
	PUSH	H
	PUSH	PSW
	LHLD	v_ECURY	; Get Y-offset cursor in document
	MOV	A, H
	ORA	L
	JZ	LECDA	; Quit if cursor at top 1eft; CY=0
	XRA	A
	STA	v_CURPT+1	; Clear cursor pos in buffer
	LDA	v_EWINY	; Get offset of top of window
	CMP	L	; Cursor at top of window?
	CZ	EWUP	; Then window up
	DCX	H
	SHLD	v_ECURY	; Store Y-offset cursor in docunent
	LHLD	CURSOR	; Get cursor pos addr
	CALL	CURDEL	; Delete cursor
	JMP	LECD2	; Put cursor on new pos; quit with CY=1
;
; ***************
; * CURSOR DOWN *
; ***************
;
; Moves cursor down one position.
;
; Exit: ABCDEHL preserved
;       CY=0: cursor not moved
;       CY=1: cursor moved
;
ECDN	PUSH	D
	PUSH	H
	PUSH	PSW
	LHLD	v_ECURY	; Get Y-offset cursor in document
	INX	H	; +1
	PUSH	H	; Preserve it
	CALL	LEE1C	; Skip lines
	POP	H
	JNC	LECDA	; No move if cursor at 1ast line of text; CY=0
	XRA	A
	STA	v_CURPT+1	; Clear cursor pos in buffer
	LDA	v_EWINY	; Get offset of top of window
	ADI	$18	; 24 lines in window
	CMP	L	; Cursor at window bottom?
	CZ	EWDN	; Then window down
	SHLD	v_ECURY	; Store Y-offset cursor in document
	LHLD	CURSOR	; Get cursor pos addr
	CALL	CURDEL	; Delete cursor
	JMP	LEC6E	; Put cursor on new pos; quit with CY=1
;
; ***************
; * CURSOR LEFT *
; ***************
;
; Moves cursor 1eft one pos1tion.
;
; Exit: ABCDEHL preserved
;       CY=0: cursor not maved
;       CY=1: cursor moved
;
ECLF	PUSH	D
	PUSH	H
	PUSH	PSW
	LDA	v_EWINX	; Get offset of left side of window
	MOV	L, A	; in L
	LDA	v_ECURX	; Get X-offset cursor in docunent
	ORA	A
	JZ	LECDA	; Abort if X-offset = 0
	CMP	L	; Cursor at left side of window?
	CZ	EWLF	; Then window left
	DCR	A	; X-offset -1
	STA	v_ECURX	; Preserve it
	XRA	A
	STA	v_CURPT+1	; Clear cursor pos in buffer
	LHLD	CURSOR	; Get cursor pos addr
	CALL	CURDEL	; Delete cursor
	JMP	LED16	; Put cursor on new pos; quit with CY=1
;
;
;
; ****************
; * CURSOR RIGHT *
; ****************
;
; Moves cursor right one position.
;
; Exit: ABCDEHL preserved
;       CY=0: cursor not moved
;       CY=1: cursor moved
;
ECRT	PUSH	D
	PUSH	H
	PUSH	PSW
	LDA	v_EWINX	; Get offset of left side of window
	ADI	$3B	; Calc end of window
	MOV	L, A	; Result in L
	LDA	v_ECURX	; Get X-offset of cursor in document
	CPI	$FF	; Max nr char/line reached?
	JZ	LECDA	; Then quit with CY=0
	CMP	L	; End of window reached?
	CZ	EWRT	; Then window right
	INR	A	; Iner cursor pos on line
	STA	v_ECURX	; Store X-offset of cursor in document
	XRA	A
	STA	v_CURPT+1	; Clear cursor pos in buffer
	LHLD	CURSOR	; Get cursor pos addr
	CALL	CURDEL	; Delete old cursor
	JMP	LED6F	; Put new cursor on screen; quit with CY=1
;
; *****************************
; * SKIP LINES IN EDIT BUFFER *
; *****************************
;
; Entry: HL: number of lines to be skipped
; Exit:  HL: points to 1st not skipped line
;        CY=1: OK
;        CY=0: end of text reached before count is zero
;        ABCDE preserved
;
LEE1C	PUSH	D
	PUSH	PSW
	XCHG		; Count in DE
	LHLD	v_EBUFR	; Get startaddr editbuf
@EE22	MOV	A, D	; Abort with CY=1 if ready
	ORA	E
	JZ	@EE33
	CALL	LEE38	; Next line
	NOP
	ORA	A
	JZ	@EE34	; Abort with CY=0 if end of buffer reached before DE=0
	DCX	D	; Count -1
	JMP	@EE22	; Skip next line
@EE33	STC
@EE34	POP	D
	MOV	A, D
	POP	D
	RET
;
; *************
; * NEXT LINE *
; *************
;
; Entry: HL: points to text, each line ended by a car.ret, last line followed by 0.
; Exit:  HL: points to next line.
;        A:  0 if end cf text reached, else CR
;        BCDE preserved
;
LEE38	MOV	A, M	; Get char from text
	ORA	A
	JZ	@EE43	; Ready if end of text reached
	INX	H
	CPI	$0D	; Car. ret?
	JNZ	LEE38	; Loop till end of line found
@EE43	RET
;
; ****************************************
; * FIND CURRENT POSITION IN EDIT BUFFER *
; ****************************************
;
; Exit: CY=1: HL: (v_CURPT+1/AE) = cursor position in buffer
;       CY=0: HL: points to cursor line in the edit buffer
;       ABCDE preserved
;
LEE44	LHLD	v_CURPT	; Get pntr to cursor pos in buffer
	DCR	H
	INR	H
	STC
	RNZ		; Quit (CY=1) if (AF) <> 0
	PUSH	D
	PUSH	B
	PUSH	PSW
	LHLD	v_ECURY	; Get Y-offset of cursor in document (no lines to be skipped)
	MOV	D, H	; in DE
	MOV	E, L
	CALL	LEE1C	; Skip lines
	SHLD	v_CURLB	; Store pntr to start cursor line in buffer
	PUSH	H	; and preserve it
	LHLD	v_EWINY	; Get offset of top of window
	CALL	SUBDE_	; Calc difference
	MVI	A, $86	; Length one line
	CALL	HLMUL_	; Calc total length
	XCHG		; Result in DE
	LHLD	CHS	; Get startaddr char area
	DAD	D	; Add offset
	SHLD	v_CURLS	; Preserve pntr to start cursor line on screen
	POP	H	; Get pntr to start cursor line in buffer
	LDA	v_ECURX	; Get X-offset of cursor in document
	MOV	B, A	; in B
	CALL	LEE7B	; Skip to Bth pos on line exit: HL pnts to cursor pos
	POP	B
	MOV	A, B
	POP	B
	POP	D
	CMC		; Abort with CY=0
	RET
;
; *************************************
; * SKIP TO Bth POSITION ON TEXT LINE *
; *************************************
;
; Looks through a textline until Bth position is found. On exit, character on this position is in A.
;
; Entry: HL: start text line
;        B:  number of position in line
; Exit:  CY=0: position found:
;              A:  character on that position
;              HL: points to Bth position
;              BCDE Preserved
;        CY=1: Bth position is beyond car.ret, tab or end of text
;              HL: points to CR, tab or 0.
;              A:  space
;
LEE7B	PUSH	B
	PUSH	D
	MVI	C, $00	; Init count
LEE7F	JMP	LD1FD	; Evaluate character
LEE82	JZ	@EEA3	; Abort if Bth pos reached
	ORA	A	; Set flags on char
	JZ	@EEA0	; Jump if end of text reached
	CPI	$0D
	JZ	@EEA0	; Jump if char is car.ret.
	CPI	$09
	JZ	@EE98	; Jump if char is tab
	INR	C	; Incr count
@EE94	INX	H	; Pnts to next pos on line
	JMP	LEE7F	; Loop until ready
;
; If character is tab
;
@EE98	CALL	LEEA6	; Tabulate
	MOV	A, B	; Reqd pos in A
	CMP	C	; Compare with tab stops
	JNC	@EE94	; Continue if not past tab
;
; If end of line or end of text reached or if past tab
;
@EEA0	MVI	A, ' '	; Set char is space
	STC		; Abort with CY=1
@EEA3	POP	D
	POP	B
	RET
;
; ************
; * TABULATE *
; ************
;
; Routine goes through tab-table for 1st tab-stop > C.
;
; Entry: v_TABTP: pointer to tab-table
;        C:        line position
; Exit:  If found: Tab in C.
;        E1se:     C = C + 1
;        AFBDEHL preserved
;
LEEA6	PUSH	PSW
	PUSH	B
	PUSH	H
	LHLD	v_TABTP	; Get addr tab table
@EEAC	MOV	B, C	; Line pos in B
	INR	B	; +1
	MOV	A, M	; Get tab from table
	ORA	A
	JZ	@EEBA	; If end tab table reached
	INX	H	; Pnts to next tab
	MOV	B, A	; Tab in B
	MOV	A, C	; Line pos in A
	CMP	B
	JNC	@EEAC	; Get next tab if line pos > tab stop
@EEBA	MOV	C, B	; Replace line pos by tab stop or by line pos +1 if no tab found
	POP	H
	POP	PSW
	MOV	B, A
	POP	PSW
	RET
;
; ********************************
; * PRINT LINE OF TEXT IN WINDDW *
; ********************************
;
; Entry: HL:    address of textline in buffer
;        DE:    line control byte of screen line to print text on
;        v_EWINX: number of non-printing positions
;
; During execution loop:
;        B:   nr of non-printing pos left +1
;        C:   nr of screen line pos left
;        D:   current text line position
;        E:   count of blanks inserted
;        HL:  points to text
;        TOS: points to screen
;
LEEC0	PUSH	B
	XCHG
	LXI	B, $FFF8
	DAD	B	; 1st printable pos on screen
	XCHG		; in DE
	LDA	v_EWINX	; Get offset of left side of window
	INR	A
	MOV	B, A	; B is offset +1
	MVI	C, 60	; 60 visible characters
	PUSH	D	; Preserve start screen line
	MVI	D, $00	; Init current text pos and blanks count
	MOV	E, D
;
; loop
;
LEED2	MVI	A, ' '	; Space
	DCR	E
	INR	E
	JNZ	LEEEC	; E<>0: update screen pos pntr
	MOV	A, M	; Else: get char from buffer
	ORA	A	; Set flags on char
	JMP	LD1D1	; Test character
LEEDE	CPI	$0D
	JZ	LEEEC	; Skip tab-handling if CR
	MVI	E,  $00	; Reset blanks count
	INX	H	; Pnts to next char in text
	CPI	$09	; Tab?
	JZ	LEF08	; Then tab-handling
LEEEB	INR	E
LEEEC	DCR	E	; Update blanks count
	INR	D	; Update line position
	DCR	B	; and nr of pos 1eft in window
	JNZ	LEED2	; No printing, cont with next char
	INR	B
	XTHL		; Screen pos in HL
	MOV	M, A	; Display char on screen
	DCX	H
	DCX	H	; Next screen pos
	XTHL		; Preserve it
	DCR	C	; End of screen line reached?
	JNZ	LEED2	; Next char if not
	CALL	LEE38	; Else: next line
	XTHL		; HL is screen pos
	LXI	D, $FFFA
	DAD	D	; HL is ist useable pos on next line
	XCHG		; into DE
	POP	H
	POP	B
	RET
;
; Tab-handling
;
LEF08	PUSH	B
	MOV	C, D	; C is pos on current line
	CALL	LEEA6	; Tabulate
	MOV	A, C	; Next tab stop in A
	SUB	D	; Calc blanks to be inserted
	DCR	A
	MOV	E, A	; Update blanks count
	POP	B
	MVI	A, $09	; Restore tab char in A
	JMP	LEEEB
;
; ***************************
; * PRINT A COMPLETE WINDOW *
; ***************************
;
; Text is printed in window from (DE) to bottom text screen if text ends.
; A ASCII 0 (vertical bar) is printed at the beginning of al1 following lines.
;
; Entry: HL: points to text
;        DE: points to line control byte screen line
; Exit:  HL: points to next line to print
;        DE: bottom text screen
;        AF  corrupted
;        BC  preserved
;
LEF17	PUSH	H
	LHLD	CHE	; Get bottom text screen
	CALL	COMP_	; Compare HL-DE
	POP	H
	JZ	@EF28	; Quit if window full
	CALL	LEEC0	; Print a textline
	JMP	LEF17	; Loop until ready
@EF28	RET
;
; ****************************************
; * PRINT A TEXT LINE POINTED BY (v_CURLB) *
; * ON SCREEN POSITION (v_CURLS) IN WINDOW *
; ****************************************
;
; Exit: all registers preserved
;
LEF29	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	v_CURLS	; Get pntr to start cursor line on screen
	XCHG		; in DE
	LHLD	v_CURLB	; Get pntr to start cursor line in buffer
	CALL	LEEC0	; Print a text line
	JMP	XRET	; Popall, ret
;
; *********************
; * PRINT FULL SCREEN *
; *********************
;
; Prints from Nth line in full screen window. N is the offset of the top of the window from
; the start of the edit buffer.
;
; Exit: all registers preserved
;
LEF3A	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	CHS	; Get startaddr char area
	XCHG		; in DE
	LHLD	v_EWINY	; Get offset of top of window
	CALL	LEE1C	; Skip lines
	JMP	LCE85	; Print complete window
;
; ******************************
; * INSERT CHARACTER IN BUFFER *
; ******************************
;
; Entry: character in A
; Exit:  ABCDEHL preserved
;        CY=0: buffer full, no action
;        CY=1: character inserted
;
EINCH	PUSH	B
	PUSH	PSW
	PUSH	D
	PUSH	H
	MOV	B, A	; Char in B
	LHLD	v_EBUFS	; Get end available space
	XCHG		; in DE
	LHLD	v_EBUFN	; Get input pointer
	CALL	COMP_	; Compare HL-DE
	XCHG		; Input pntr in E
	MOV	A, B	; Char in A
	CC	LEE44	; Space available: find current pos in buffer
	JNC	LEF96	; Buffer full: quit, char in A
	PUSH	H	; Preserve end available space
	LHLD	CURSOR	; Get cursor pos addr
	XTHL		; Put it on stack
	PUSH	H
	CALL	CURDEL	; Delete cursor
	XCHG		; Old input pntr in HL
	NOP
	INX	H	; +1
	SHLD	v_EBUFN	; Update input pointer
	DCX	H
	MOV	B, H	; Old input pntr in BC
	MOV	C, L
	DCX	H
	XCHG		; Old input pntr -1 in DE
	POP	H	; Get end available space
	DCX	H	; -1
	CALL	MOVES	; Move screen area 1 pos
	INX	H
	MOV	M, A	; Insert char in buffer
	INX	H
	SHLD	v_CURPT	; Preserve pntr to cursor in buffer
	POP	H	; Get end available space
	CPI	$0D
	JZ	LEF9C	; Jump if char is car.ret
	CALL	LEF29	; Reprint text line in window
	CALL	CURSET	; Put cursor on screen
	CPI	$09
	JZ	LEFB9	; Jump if char is tab
	CALL	ECRT	; Move cursor right 1 pos
LEF95	STC
LEF96	POP	H
	POP	D
	POP	B
	MOV	A, B
	POP	B
	RET
;
; If car.ret:
;
LEF9C	XRA	A
	STA	v_EWINX	; Reset pointers
	STA	v_ECURX
	STA	v_CURPT+1
	CALL	LEF3A	; Reprint full screen
	LHLD	v_CURLS	; Get pntr to start cursor line on screen
	LXI	D, $FFF8
	DAD	D	; New cursor addr
	CALL	CURSET	; Put cursor on screen
	CALL	ECDN	; Move cursor down
	JMP	LEF95	; Quit with CY=1
;
; If tab
;
LEFB9	CALL	ECRT	; Move cursor right
	LDA	v_ECURX	; Get X-offset of cursor in document
	MOV	B, A	; in B
	LHLD	v_CURLB	; Get pntr to start cursor line in buffer
	CALL	LEE7B	; Skip to Bth pos on line
	JC	LEFB9	; Again
	JMP	LEF95	; Abort with CY=1
;
; ******************************
; * DELETE CHARACTER IN BUFFER *
; ******************************
;
; Deletes character at cursor position and moves the text above this position.
; No action if past car.ret, tab or at or beyond end of text.
;
; Exit: ABCDEHL preserved
;       CY=1: OK
;       CY=0: if past car.ret, tab or beyond 0.
;
EDLCH	PUSH	B
	PUSH	PSW
	PUSH	D
	PUSH	H
	CALL	LEE44	; Find current pos in buffer
	JNC	LEF96	; Quit if past CR, tab or 0 with CY=0
	MOV	A, M	; Get char
	ORA	A
	JZ	LEF96	; If at end of text: quit with CY=0
	NOP
	NOP
	NOP
	PUSH	H
	LHLD	CURSOR	; Get cursor pos addr
	XTHL		; preserve it on stack
	CALL	CURDEL	; Delete cursor
	XCHG		; Original HL in DE
	LHLD	v_EBUFN	; Get input pointer
	DCX	H	; Decrement it
	SHLD	v_EBUFN	; And store update input pntr
	MOV	B, H	; Move updated pointer into BC
	MOV	C, L
	DCX	B	; Decrenent it once again
	XCHG		; restore original HL
	CALL	MOVES	; Move screen area above downwards
	CPI	$0D	; Deleted car.ret?
	CNZ	LEF29	; If not: reprint text line
	CZ	LEF3A	; Else: reprint full screen
	JMP	LCEF2	; Put cursor on screen, abort with CY=1
;
end_rom2	.equ	*
;
;
; ROM Bank 3 - 4KB starting $E000
.bank 3, 4, $E000
.segment "ROM3", 3
.org	$E000
;
bgn_rom3	.equ	*
;
;
;
;
;     ===========================
; *** ENCODING / UTILITY PACKAGES ***
;     ===========================
;
; Called by RST 1 + $XX. XX indicates the offset of E000 for the different entrypoints.
;
; Contains also the key encoding routines and the Heap organisation routines.
;
; ***************
; * ENTRYPOINTS *
; ***************
;
ELINE	JMP	LE024	; Encode a BASIC line
ELN	JMP	ELNR	; Encode a linenr
ETCON	JMP	LE145	; Encode a constant
LWSTART	JMP	UT_RESET	; Start utility package
DEOOT	JMP	LEF90	; Disc bootstrap
MHREO	JMP	HREQ	; Heap request
MINKEY	JMP	INKEY	; Encode a key input
L3E394	JMP	LE935	; Get inputs from keyb or DINC
;
;     ================
; *** ENCODING PACKAGE ***
;     ================
;
; Generally in the encoding routines, HL points to the first free 1ocation in the EBUF.
; C points to the input text line.
;
; ***********************
; * UPDATE EBUF POINTER *
; ***********************
;
; Increments the input pointer and checks if the encoded input buffer (EBUF) is ful1.
;
; Entry: HL: input pointer EBUF
; Exit:  HL: updated pointer
;        other registers preserved
;
INXCH	INX	H	; Incr pointer
	PUSH	PSW
	MOV	A, L	; Get 1ob yte in A
	CPI	$BE	; Max value reached?
	MVI	A, $1A	; Buffer full?
	JNC	ERROR	; Then run error 'LINE TOO COMPLEX'
	POP	PSW
	RET
;
; **************************
; * ENCODE A BASIC COMMAND *
; **************************
;
; Looks for a match between inout on line and the BASIC command table $CBBF.
; Error exit 'COMMAND INVALID' if the 2 high order bits of the code in the table don't match
; the mask in D. Else the code ($80 + 1ow order 6 bits from code in table) are stored in EBUF.
;
; Entry: HL: 1st free position in EBUF
;        D:  mask for direct command (#80) or program input (#40)
;        C:  position on current line
; Exit:  HL: updated
;        C:  points to 1st not used input in line
;        E:  code just stored
;        BD preserved
;        AF corrupted
;        Exit with jump to address found in table.
;        $E04F is on stack as next returnaddress, entry DE is next on stack.
;
LE024	PUSH	D
	PUSH	H
	LXI	H, @E04F	; Returnaddr after finishing encoding
	XTHL		; Save it on stack
	PUSH	H	; Save HL again
	MVI	E, $02	; Addit. offset for finding instruction in table
	LXI	H, BAS_CMD	; Startaddr table with strings Basic commands
	PUSH	D
	CALL	LOOKC	; Find instr in table
	POP	D	; Get mask for direct/program
	MOV	A, M	; Get instr code from table
	ANI	$C0	; Check if it is a valid command
	ANA	D
	MVI	A, $18	; If not: run error
	JZ	ERROR	; 'COMMAND INVALID'
	MOV	A, M	; Get instr code from table
	INX	H
	ANI	$3F	; Make it a token
	ORI	$80
	MOV	E, A	; Store token in E
	MOV	A, M
	INX	H	; Get addr of encoding
	MOV	H, M	; instruction in HL
	MOV	L, A
	XTHL		; and save it on stack
	MOV	M, E	; Store token in EBUF
	CALL	INXCH	; Update EBUF pointer
	RET		; Go to encoding instruction return afterwards to @E04F
;
; End of encoding of an input line (after running the command specific processing).
; Checks if character after BASIC command is CR o ':'.
;
; Entry: C: points to position on current line.
;        On stack: Original DE.
;
@E04F	POP	D	; Get type of command in D
	CALL	IGNB	; Get char from line, neglect tab + space
	INR	C	; Pntr to next char
	CPI	':'	; ':'?
	JZ	LE024	; Then encode next instr
	CPI	$0D	; 'CR'?
	JNZ	ERRSN	; Run 'SYNTAX ERROR' if not
	RET
;
; ******************************
; * ENCODE 'FOR - TO - (STEP)' *
; *****************************
;
; Valid for all specific encoding routines:
; HL points to 1st free EBUF 1ocation.
;
EFOR	CALL	ELET	; Encode 'LET'
	CPI	$20	; String type?
	JZ	ERRTM	; Then run error 'TYPE MISMATCH'
	CPI	$10	; INT type?
	LXI	D, LE088	; Addr 'TO' table
	JMP	LE09A	; Get addr encoding instr and go to it
;
; Encode 'TO'
;
LE06F	CZ	LE36D	; Encode a INT expr
	CNZ	LE376	; Encode a FPT expr
	LXI	D, LE090	; Addr 'STEP' table
	JMP	LE09A	; Get addr encoding instr and go to it
;
; Encode 'STEP'
;
LE07B	CZ	LE36D	; Encode a INT expr
	CNZ	LE376	; Encode a FPT expr
	RET
;
; End encoding
;
LE082	MVI	M, $FF	; FF in EBUF as separator
	CALL	INXCH	; Update EBUF pointer
	RET
;
; Table:
;
LE088	BAS_ENC("TO", LE06F, 0, ERRSN)	; TO not found: run SYNTAX ERROR
LE090	BAS_ENC("STEP", LE07B, 0, LE082)	; STEP not found: end command
;
; *************************************************
; * GET ADDRESS ENCODING INSTRUCTION AND G0 TO IT *
; *************************************************
;
; Entry: DE: points to table of format:
;            <1ength name / name / jumpaddr> or <00 / jumpaddr >
;        C:  points to input
; Exit:  C:  updated
;        AFBHL preserved. D=0, E=1
;
LE09A	PUSH	H
	PUSH	PSW
	XCHG		; Addr table in HL
	MVI	E, $01
	CALL	LOOKC	; Find instruction in table. On exit, HL points to addr of encoding routine
	MOV	A, M	; Get addr encoding instr in HL
	INX	H
	MOV	H, M
	MOV	L, A
	POP	PSW
	XTHL		; Addr encoding instr on stack
	RET		; Go to it
;
; ***************************************
; * ENCODE 'NEXT' AND 'NEXT <VARIABLE>' *
; ***************************************
;
ENEXT	CALL	TSEOC	; Next char ':' or 'CR'?
	RZ		; Then ready
;
; If NEXT <variable>
;
	DCX	H
	INR	M	; Token +1 ($AC)
	INX	H
	CALL	LE5BC	; Encode variable or array ref
	LDA	TYPE	; Get type latest expression
	CPI	$20	; String type?
	JZ	ERRTM	; Then run error 'TYPE MISMATCH'
	RET
;
; **************************************
; * ENCODE 'IF - THEN' AND 'IF - GOTO' *
; **************************************
;
EIF	PUSH	H
	PUSH	D
	CALL	LE39C	; Encode boolean expr (type $30)
	LXI	D, LE0ED	; Addr 'THEN' table
	JMP	LE09A	; Get addr encoding instr and go to it
;
; Encode 'THEN'
;
LE0C7	CALL	LE731	; Read a linenr into EBUF
	POP	D
	JNC	LE0D4	; Jump if no linenr given
;
; If linenr
;
	XTHL
	DCX	H
	INR	M
	INR	M	; Token +2 ($A8)
	POP	H
	RET
;
; If statement
;
LE0D4	POP	PSW
	PUSH	H	; Preserve EBUF pntr
	CALL	INXCH	; Update EBUF pointer
	CALL	LE024	; Encode BASIC command
	MOV	A, L	; Lobyte new EBUF pntr in A
	XTHL		; O1d EBUF pntr in HL
	SUB	L
	DCR	A
	MOV	M, A	; Length string in EBUF entry
	POP	H
	DCR	C
	RET
;
; Encode 'GOTO'
;
LE0E4	POP	PSW
	XTHL
	DCX	H
	INR	M	; Taken +1 ($A7)
	POP	H
	CALL	ELNR	; Get linenr
	RET
;
; Table:
;
LE0ED	BAS_ENC2("THEN", LE0C7)	; encode THEN
LE0F4	BAS_ENC("GOTO", LE0E4, 0, ERRSN)	; If no 'THEN' or 'GOTO' found run 'SYNTAX ERROR'
;
; ****************
; * ENCODE 'LET' *
; ****************
;
; Encodes a variable or array with arguments. Then finds '=' in input (error if not).
; Then encodes an expression, depending on variable type (error if type non-existing).
;
; Exit: DE: offset of left-side variable
;       A and B: left-side type
;       C, HL updated
;       F corrupted
;
ELET	CALL	LE5BC	; Encode var or array ref
	CALL_B(ECHRI, '=')	; Check next char is '='
	LDA	TYPE	; Get type latest expression
	CPI	$00	; FPT?
	JZ	LE376	; Then encode FPT expr
	CPI	$10	; INT?
	JZ	LE36D	; Then encode INT expr
	JMP	LE3A1	; Else encode STR expr
;
; ***************************************
; * ENCODE 'INPUT' AND 'INPUT <STRING>' *
; ***************************************
;
EINPUT	CALL	IGNB	; Get char from line, neglect tab + space
	CPI	'"'	; "?
	JNZ	EREAD	; Encode 'READ' if no string in INPUT statement
;
; If 'INPUT <string>'
;
	DCX	H
	INR	M	; Token +1 ($A1)
	INX	H
	CALL	LE3A1	; Encode STR expr
	CALL_B(ECHRI, ';')	; Check if next char is ';'
;
; *****************
; * ENCODE 'READ' *
; *****************
;
; From L3E16 used by several routines, with another address in LXI D, ...., pointing to
; various kinds of encoding/get routines.
;
EREAD	LXI	D, LE5BC	; Addr routine encode variable or array reference
LE12A	PUSH	H
	MVI	M, $00	; 00 into EBUF (count)
	CALL	INXCH	; Update EBUF pointer
@E130	PUSH	D
	CALL	LE164	; Go to encoding routine
;
; Return here after encoding
;
	POP	D
	XTHL
	INR	M	; Count in EBUF +1
	XTHL
	CALL	IGNB	; Get char from line, neglect tab + space
	INR	C	; Points to next char on line
	CPI	','	; ','?
	JZ	@E130	; Again if more items
	DCR	C	; Correct line pointer
	INX	SP
	INX	SP	; SP to returnaddr
	RET
; **************************************
; * ENCODE A NUMBER OR STRING CONSTANT *
; **************************************
;
; Entry: A: type
LE145	PUSH	PSW	; Preserve type
	ORA	A
	JZ	LE15E	; Jump if FPT type
	CPI	$10
	JZ	LE888	; Jump if INT type
;
; If STR type
;
	CALL	IGNB	; Get char from line, neglect tab + space
	CPI	'"'	; quoted string?
	PUSH	PSW
	CZ	LE880	; Then store quoted string 1n EBUF
	POP	PSW
	CNZ	LE6A6	; Else store unquoted string in EEUF
LE15C	POP	PSW
	RET
;
; If FPT type
;
LE15E	CALL	LE501	; Encode FPT nr into EBUF
	JMP	LE893	; Quit with evt 'SYNTAX ERROR'
;
; *************************
; * part of EREAD (3E12A) *
; *************************
;
LE164	PUSH	D	; Addr encoding routine on stack
	RET		; Go to it
;
; ****************
; * ENCODE 'DIM' *
; ****************
;
EDIM	LXI	D, LE16C	; Addr routine 'encoding array reference'
	JMP	LE12A	; Continue encoding
;
; *****************************
; * ENCODE AN ARRAY REFERENCE *
; *****************************
;
LE16C	CALL	LE5BC	; Encode var or array ref
	MOV	A, B	; Tpe in A
	ANI	$40	; Array type?
	JZ	ERRBS	; Run 'SUBSCRIPT ERROR' if not
	RET
;
; ***************************************
; * ENCODE 'ON - GOTO' AND 'ON - GOSUB' *
; ***************************************
;
EON	PUSH	H
	CALL	LE36D	; Encode INT expr
	LXI	D, LE18D	; Addr table
	JMP	LE09A	; Get addr encoding instr and go to it
;
; Encode linenr in GOSUB (LE180) and GOTO (LE185)
;
LE180	XTHL
	DCX	H
	INR	M	; Token +1 ($AF)
	INX	H
	XTHL
LE185	XTHL
	POP	H
	LXI	D, ELNR	; Addr routine 'get linenr'
	JMP	LE12A	; Continue encoding
;
; Table
;
LE18D	BAS_ENC2("GOTO", LE185)		; Addr encode GOTO
LE194	BAS_ENC("GOSUB", LE180, 0, ERRSN)	; Addr encode GOSUB
					; If no GOTO or GOSUB found run 'SYNTAX ERROR'
;
; ******************
; * ENCODE 'PRINT' *
; ******************
;
EPRINT	PUSH	H
	MVI	M, $00	; 00 into EBUF (init length)
	CALL	TSEOC	; Next char ':' or 'CR'?
	JZ	@E1CB	; Then ready
;
; If statement after PRINT
;
@E1A8	CALL	INXCH	; Update EBUF pointer
	XTHL
	INR	M	; Length +1
	XTHL
	CALL	LE3B2	; Encode non-boolean expr preceeded by its type
	MVI	M, $FF	; FF into ERUF
	CALL	TSEOC	; Next char ':' or 'CR'?
	JZ	@E1CB	; Then ready
;
; If more statements
;
	MOV	M, A	; Char into EBUF
	CPI	','	; ','?
	JZ	@E1C4	; Then continue
	CPI	';'	;' ';'?
	JNZ	ERRSN	; Run 'SYNTAX ERROR' if not
@E1C4	INR	C	; Update line pntr
	CALL	TSEOC	; Next char ':' or 'CR'?
	JNZ	@E1A8	; Continue if not
;
@E1CB	XTHL
	POP	H
	CALL	INXCH	; Update EBUF pointer
	RET
;
; *****************
; * ENCODE 'MODE' *
; *****************
;
EMODE	MVI	D, $FF	; Default mode 0
	CALL	IGNB	; Get char from line, neglect tab + space
	INR	C	; Points to nex t char
	SUI	'0'
	JZ	@E1F1	; If char is '0': $FF in EBUF
	JC	ERRSN	; Run 'SYNTAX ERROR' if not number or printable char
	CPI	$07	; Between 0 and 7?
	JNC	ERRRA	; Run error 'NUMBER OUT OF RANGE' if not
	DCR	A	; Calc code for mode in D
	ADD	A
	MOV	D, A
	CALL	EFETCH	; Get next char from line
	CPI	'A'	; 'A'?
	JNZ	@E1F1	; Jump if not
	INR	C	; Points to next char
	INR	D	; Set D for A-mode
@E1F1	MOV	M, D	; Mode code in EBUF
	CALL	INXCH	; update EBUF pointer
	RET
;
; *********************
; * ENCODE 'ENVELOPE' *
; *********************
;
; Encodes <ENV> (<V>,<T>;) <V>,<T> or <ENV> (<V>,<T>;) <V>.
;
; Exit: HL points beyond expression in EBUF
;       AFBCDE corrupted
;
EENV	CALL	LE36D	; Encode ENV nr
	PUSH	H	; Preserve EBUF pntr
	CALL	INXCH	; Update EBUF pointer
	MVI	D, $00	; Init 1ength
@E1FF	CALL	@E222	; Encode <V>
	CALL	TSEOC	; Next char ':' or 'CR'?
	JZ	@E21E	; Then Ready
	CALL	LE862	; Check if next char is ',' run error if not
	CALL	@E222	; Encode <T>
	CALL_B(ECHRI, ';')	; Check if next char is ';'
	INR	D	; Length +1
	MVI	M, $FF	; $FF into EBUF
	CALL	TSEOC	; Next char ':' or 'CR'?
	JNZ	@E1FF	; Again if not
	CALL	INXCH	; Update EBUF pointer
@E21E	XTHL
	MOV	M, D	; Length in EBUF after token
	POP	H
	RET
;
; ENCODE A <V> OR <T> ELEMENT
;
; Exit: DE preserved
;
@E222	PUSH	D
	CALL	LE36D	; Encode INT expr
	POP	D
	RET
;
; ****************************
; * ENCODE 'LIST' AND 'EDIT' *
; ****************************
;
; Checks the expression after the token and updates the token on it.
; On exit the token is:
;                    EDIT    LIST
; Without linenr:    B6      93
; One line:          B7      94
; Part of program:   B8      95
;
; Entry: HL: points after token in EBUF
; Exit:  C, HL: updated
;        D:     token
;        AF corrupted
;        BE preserved
ELIST	.equ	*
EEDIT	DCX	H	; Pnts to token
	MOV	D, M	; Token in D
	PUSH	H	; Preserve EBUF pntr
	INX	H
	CALL	TSEOC	; Next char ':' or 'CR'?
	JZ	@E244	; Then ready
	CALL	LE248	; Read linenr into EBUF
	INR	D	; Token +1
	CALL	TSEOC	; Next char ':' or 'CR'?
	JZ	@E244	; Then ready
	CALL_B(ECHRI, '-')	; Next char '-'?
	CALL	LE248	; Read linenr into EBUF
	INR	D	; Again token +1
@E244	XTHL
	MOV	M, D	; Token into EBUF
	POP	H
	RET
;
; READ LINENUMBER INTO EBUF
;
; Reads a linenumber from the input line into the EBUF. If no linenumber is given, $0000 is inserted.
;
; Entry: HL: points to 1st free location in EBUF
;        C:  points to input line
; Exit:  C, HL: updated
;        AF corrupted
;        BDE preserved
;
LE248	PUSH	D
	CALL	LE731	; Read linenr into EBUF
	POP	D
	RC		; Ready if nr given
	MVI	M, $00	; $00 into EBUF
	CALL	INXCH	; Update EBUF pointer
	MVI	M, $00	; $00 into EBUF
	CALL	INXCH	; Update EBUF pointer
	RET
;
; *********************************************
; * ENCODE 'WAIT', 'WAIT TIME' AND 'WAIT MEM' *
; *********************************************
;
EWAIT	LXI	D, LE25F	; Addr table
	JMP	LE09A	; Get addr encoding instr and go to it
;
; Table:
;
LE25F	BAS_ENC2("TIME",  LE285)	; Addr encode 'TIME'
LE266	BAS_ENC("MEM", LE26F, 0, LE272)	; Addr encode 'MEM' and 'port'
;
; Encode 'MEM'
;
LE26F	DCX	H
	INR	M	; Token +1 ($91)
	INX	H
LE272	CALL	ENC_ICI	; Encode <INT expr>, <INT expr>
	MVI	M, $FF	; $FF into EBUF
	CALL	INXCH	; UpdatE EBUF pointer
	CALL	IGNB	; Get char from line, neglect tab + space
	CPI	','	; ','?
	RNZ		; Ready if not
	DCX	H
	INX	B
	JMP	LE36D	; Encode INT expr
;
; Encode 'TIME'
;
LE285	DCX	H
	INR	M
	INR	M	; Token +2 ($92)
	INX	H
	JMP	LE36D	; Encode INT expr
;
; ********************************
; * ENCODE 'DRAW', 'FILL', 'DOT' *
; ********************************
;
EFILL	.equ	*
EDRAW	CALL	ENC_ICI	; Encode <INT expr>, <INT expr>
;
; Entry: for encode 'DOT'
;
EDOT	CALL	ENC_ICI	; Encode <INT expr>, <INT expr>
	JMP	ENC_I	; Encode INT expr
;
; ***********************************
; * ENCODE 'RUN' AND 'RUN <LINENR>' *
; ***********************************
ERUN	CALL	TSEOC	; Next char ':' or 'CR'?
	RZ		; Then ready
;
; If 'RUN <linenr>'
;
	DCX	H
	INR	M	; Token +1 ($88)
	INX	H
	JMP	ELNR	; Get linenr into EBUF
;
; ****************
; * ENCODE 'IMP' *
; ****************
;
; Note: This command is not encoded, but has immediate effect.
;
EIMP	PUSH	H
	LXI	H, IMPTT	; Startaddr table var.types
	MVI	E, $00	; 1 info byte
	CALL	LOOKC	; Find type in table
	MOV	A, M	; Get IMP type from table
	ORA	A
	JM	ERRSN	; 'SYNTAX ERROR' if not found
	PUSH	PSW	; Preserve IMP type
	CPI	$20	; STR type?
	JZ	@E2B9	; Then jump
	CALL	TSEOC	; IMP INT/FPT alone?
	JZ	@E2D9	; Then ready
@E2B9	CALL	EALPHA	; Get char from line; check if uppe case; INR C
	PUSH	PSW	; Save char 1n IMP instruction
	CALL_B(ECHRI, '-')	; Next char is '-'?
	CALL	EALPHA	; Get next char from line; check if upper case; INR C
	LXI	H, IMPTAB-$41	; Base addr IMP table
	MOV	D, H	; into DE
	MOV	E, L
	CALL	DADA	; Calc offset end addr in HL
	INX	h	; +1
	XCHG		; In DE
	POP	PSW	; Get char
	CALL	DADA	; Calc offset begin addr
	XCHG
	POP	PSW	; Get IMP type
@E2D4	CALL	FILL	; Load given range with IMP type
	POP	H	; Re-instate 'encoded' pntr
	RET
;
; If no range given
;
@E2D9	POP	PSW	; Get IMP type
	STA	IMPTYP	; Store default number type
	LXI	D, IMPTAB+00	; Startaddr impl. type table
	LXI	H, IMPTAB+26	; Addr after end table
	JMP	@E2D4	; Fill A-Z with reqd type
;
; Get character from line and check if it is a upper case character
;
EALPHA	CALL	IGNB	; Get char from line, neglect tab + space
	CALL	ALPHA	; Check if upper case char
	JNC	ERRSN	; Run 'SYNTAX ERROR' if not
	INR	C	; Update textline pntr
	RET
;
; STRINGS VARIABLE TYPES TABLE
;
; The first byte is a length byte. The byte after the string is the varible type byte.
;
IMPTT	BAS_TYPE("FPT", $00)
	BAS_TYPE("INT", $10)
	BAS_TYPE("STR", $20)
	; End of table
	.byte	$00, $80
;
; **********************************
; * ENCODE 'POKE', 'OUT', 'CURSOR' *
; **********************************
;
; Also used by: Encode 'DRAW' and 'FILL'.
;
EPOKE	.equ	*
EOUT	.equ	*
ECURS	.equ	*
ENC_ICI	CALL	LE36D	; Encode INT expression
	CALL	LE862	; Check if next char is ','; run error if not
	JMP	LE36D	; Encode INT expression
;
; *****************************
; * ENCODE 'COLORG', 'COLORT' *
; *****************************
;
; Partly also used to encode 'CLEAR' and 'TALK'.
;
; Exit: C, HL: updated
;       AFDE preserved
;       B corrupted
;
ECOLT	.equ	*
ECOLG	CALL	LE36D	; Encode INT expr
	CALL	LE36D	; Encode INT expr
ENC6	CALL	LE36D	; Encode INT expr
;
; Entry for encode CLEAR/TALK
;
ETALK	.equ	*
ECLEAR	.equ	*
ENC_I	JMP	LE36D	; Encode INT expr
;
; **************************************
; * ENCODE 'SOUND' WITH POSSIBLE 'OFF' *
; **************************************
;
; Encodes SOUND <CHAN><ENV><VOL><TG><FREQ>, or
; SOUND <CHAN> OFF or SOUND OFF.
;
; Exit: C, HL: updated
;       A preserved
;       B corrupted
;       D=0, E=1
;       CY=1: sound off
;
ESOUND	CALL	LE32C	; Encode a posible 'OFF'
	RC		; Ready if 'OFF' given
	CALL	LE36D	; Encode <CHAN>
	CALL	ENOISE	; Encode 'OFF' or <ENV><VOL>
	RC		; Ready if 'OFF' given
	JMP	LE311	; Encode <TG><FREQ>
;
; **************************************
; * ENCODE 'NOISE' WITH POSSIBLE 'OFF' *
; **************************************
;
; Encodes NOISE <ENV><VOL> or NOISE OFF.
;
; Exit: C, HL: updated
;       CY=1: noise off
;       A preserved, B corrupted, D=0, E=1
;
ENOISE	CALL	LE32C	; Encode possible 'OFF'
	CNC	LE311	; Encode <ENV><VOL> if no 'OFF' given
	RET
;
; ***************************
; * ENCODE A POSSIBLE 'OFF' *
; ***************************
;
; Exit: CY=1: 'OFF' in input; $FF in EBUF
;       CY=0: No 'OFF' given
;       C, HL: updated
;       AB preserved, D=0, E=1
;
LE32C	LXI	D, LE332	; Startaddr table
	JMP	LE09A	; Get addr encoding instr and go to
;
; Table:
;
LE332	BAS_ENC("OFF", LE33B, 0, LE342) ; encoding addr if no OFF
;
; Encode 'OFF'
;
LE33B	MVI	M, $FF	; $FF into EBUF
	CALL	INXCH	; Update EBUF pointer
	STC		; CY=1
	RET
;
; If no 'OFF'
;
LE342	ORA	A	; CY=0
	RET
;
; ******************
; * ENCODE 'CALLM' *
; ******************
;
ECALM	CALL	LE36D	; Encode memory addr (INT)
	MVI	M, $FF	; $FF into EBUF
	INX	H
	CALL	TSEOC	; Next char ':' or 'CR'?
	RZ		; Then ready
	DCX	H
	CALL	LE862	; Check if next char is ','; run error if not
	JMP	LE5BC	; Encode var. pntr
;
; *************************
; * ENCODE 'SAVE', 'LOAD' *
; *************************
;
; Checks if a name is given after 'SAVE/LOAD', then encodesa string.
; Else $19, $00 (empty unguoted string is added to code).
;
; Exit: C, HL updated, AFB corrupted, DE preserved
;
ELOAD	.equ	*
ESAVE	CALL	TSEOC	; Next char ':' or 'CR'?
	JNZ	LE3A1	; Encode string if not
	MVI	M, $19	; $19 in next 1oc ERUF
	CALL	INXCH	; Update EBUF pointer
	MVI	M, $00	; $00 in next 1oc EBUF
	CALL	INXCH	; Update EBUF pinter
	RET
;
; **********************************
; * ENCODE 'REM' AND '***' (ERROR) *
; **********************************
;
EERR	.equ	*
EREM	.equ	*
ENC_D	JMP	LE6B0	; Encode text
;
; **************************
; * ENCODE SINGLE ROUTINES *
; **************************
;
EREST	.equ	*
EEND	.equ	*
ENEW	.equ	*
ERET	.equ	*
ECHECK	.equ	*
ECONT	.equ	*
ESTEP	.equ	*
ETROF	.equ	*
ESTOP	.equ	*
ETRON	.equ	*
EUT	RET	; No further handling
;
; **************************
; * ENCODE 'GOTO', 'G0SUB' *
; **************************
;
EGOTO	.equ	*
EGOSUB	JMP	ELNR	; Get linenr
;
; ************************************************
; * ENCODE AN EXPRESSION IF VARIABLE TYPE IS INT *
; ************************************************
;
LE36D	PUSH	D
	LXI	D, $0100	; Set D=$01 (conversion) and E=$00 (FPT var type)
	MVI	B, $10	; Reqd type is INT
	JMP	LE37C	; Encode expression
;
; ************************************************
; * ENCODE AN EXPRESSION IF VARIABLE TYPE IS FPT *
; ************************************************
;
LE376	PUSH	D
	LXI	D, $0210	; Set D for evt conversion and E=#10 (INT Var type)
	MVI	B, $00	; Reqd type is FPT
LE37C	PUSH	PSW
	MOV	A, B
	STA	REQTYP	; Set reqd number type
	PUSH	H
	PUSH	D
	CALL	LE3C9_	; Encode expr
	POP	D
	LDA	TYPE	; Get type latest expression
	CMP	B	; Was it as regd?
	JZ	@E398	; Then ready
;
; Type not as expected
;
	CMP	E	; Was it alternative type
	JNZ	ERRTM	; Run error 'TYPE MISMATCH' if not
	MOV	A, D	; Get conversion byte in A
	POP	D
	PUSH	D
	CALL	LE770	; Add conversion byte to expr
@E398	POP	D
LE399	POP	PSW
	POP	D
	RET
;
; *******************************
; * ENCODE A BOOLEAN EXPRESSION *
; *******************************
;
; Variable type is $30.
;
LE39C	MVI	B, $30	; Var type is $30
	JMP	LE3A3	; Encode expression
;
; ******************************
; * ENCODE A STRING EXPRESSION *
; ******************************
;
; Variable type is $20.
;
LE3A1	MVI	B, $20	; Var type is $20
;
; Entry for 'encode Boolean expression'
;
LE3A3	PUSH	D
	PUSH	PSW
	CALL	LE3C9_	; Encode expr
	LDA	TYPE	; Get type 1atest expression
	CMP	B	; Compare with reqd type
	JNZ	ERRTM	; Run error 'TYPE MISMATCH' if not identical
	JMP	LE399	; Quit
;
; ***********************************
; * ENCODE A NON-BOOLEAN EXPRESSION *
; ***********************************
;
; Encodes an entire expression, preceeded by its type, into the EBUF.
; 'TYPE MISMATCH' error occurs if expression is boolean.
;
; Exit: C, HL updated; B preserved
;       A: Type     Type in TYPE
;       D: Orig B	OLDOP, RGTPT, HOPPT preserved
;       E: OLDOP
;
EEXPI	PUSH	H
	CALL	INXCH	; Update EBUF pointer
	XRA	A
	STA	REQTYP	; Req. number type is $00
	CALL	LE3C9_	; Encode expr
	LDA	TYPE	; Get type 1atest expression
	CPI	$30	; Boolean?
	JZ	ERRTM	; Then run error 'TYPE MISMATCH'
	XTHL		; Get old EBUF pntr
	MOV	M, A	; Type into EBUF
	POP	H	; New EBUF pntr
	RET
;
; ************************
; * ENCODE AN EXPRESSION *
; ************************
;
; Routine encodes an entire expression until no operator (or INOT) is found.
; The expression may begin with an unitary operator (highest priority).
;
; Exit: C, HL updated, B preserved
;       A, E: OLDOP
;       D:    Entry B
;       OLDOP, RGTPT, HOPPT preserved
;       Type of expr in TYPE
;       RGTOP: $00 or $1E
;
LE3C9_	XCHG		; Save HL in DE
	MOV	H, B	; Var type in H
	LDA	OLDOP	; Get old priority operator
	MOV	L, A	; in L
	PUSH	H	; Save it on stack
	LHLD	HOPPT	; Get pntr place for operator
	PUSH	H	; Save it on stack
	LHLD	RGTPT	; Get pntr to RGT operand of 1ast operator
	PUSH	H	; Save it on stack
	XCHG
	XRA	A
	STA	OLDOP	; Reset old prio operator
	CALL	LE3F1	; Encode a term with possible unitary operator
	XCHG
	POP	H
	SHLD	RGTPT	; Restore RGTPT
	POP	H
	SHLD	HOPPT	; Restore HOPPT
	POP	H
	MOV	B, H	; Restore B
	MOV	A, L
	STA	OLDOP	; Restore OLDOP
	XCHG
	RET
;
; **************************************************
; * ENCODE A TERM WITH A POSSIBLE UNITARY OPERATOR *
; **************************************************
;
; LE3F1: First operand may be preceeded by unitary operator +, - or INOT.
;        Then code byte preceeding 1st operand is:
;                    +   -  NOT
;            INT:   BC  ED   BE
;            FPT:   9C  9D    *
;
; LE3F8: Encodes a sequence of higher priority operations and their operands.
;        Encodes all terms after OLDOP in input which form a succession of higher priority
;        operators until next 1ower or equal operator is found.
;        This will be in RGTOP. The type of this collection will be in TYPE.
;
; Exit: C, HL updated. BE corrupted. CY=0.
;       A: bits 5, 6, 7 OLDOP; D: bits 5, 6, 7 new RGTOP
;
LE3F1	CALL	LE6F6	; Find unitary operator in table
	ORA	A
	JNZ	LE444	; Jump if found
;
LE3F8	SHLD	HOPPT	; Set pntr place for operator
	CALL	LE455	; Encode 1st operand
LE3FE	CALL	LE6EA	; Find binary or unitary operator in tabie
	STA	RGTOP	; Store 1atest prio operator
@E404	LDA	RGTOP	; Get latest prio operator
	ANI	$E0	; Prio in bits 5, 6, 7
	MOV	D, A	; RGTOP in D
	LDA	OLDOP	; Get old prio operator
	ANI	$E0	; Prio only
	CMP	D	; Compare both operatcrs
	RNC		; Ready if RGTOP <= OLDOP
;
; RGTOP > OLDOP
;
	XCHG
	LHLD	TYPE	; Get type latest expression
	PUSH	H	; Preserve type left operand and RGTOP
	LDA	OLDOP	; Get old prio operator
	PUSH	PSW	; Preserve it
	PUSH	D	; Preserve EBUF pntr
	LHLD	HOPPT	; Get pntr place for operator
	PUSH	H	; Preserve HOPPT
	XCHG		; New EBUF pntr in HL
	LDA	RGTOP	; Get 1atest prio operator
	STA	OLDOP	; and store it as old one
	CALL	LE3F8	; Encode right hand operand until higher prio operators
	XCHG
	POP	H
	SHLD	HOPPT	; Restore HOPPT
	POP	H
	SHLD	RGTPT	; Restore RGTPT
	POP	PSW
	STA	OLDOP	; Restore OLDOP
	XCHG		; New EBUF pntr in HL
	POP	D	; Restore type left operand (E) and orig RGTOP (D)
	MOV	A, D	; Old RGTOP in A
	ANI	$1F	; Op.code only
	CALL	LE7CF	; Obtain type info for binary operation
	CALL	LE757	; Encode binary operation into EBUF
	JMP	@E404	; Check again if prios correct
;
; Unitary operator
;
LE444	SHLD	HOPPT	; Set pntr place for operator
	PUSH	H
	CALL	LE455	; Encode a term
	CALL	LE797	; Entode unitary operator for a term
	POP	D
	CALL	LE783	; Byte in A into EBUF
	JMP	LE3FE	; Encode sequence with prio's
;
; ENCODE A TERM
;
; Non-error exit: C, HL: updated
;                 BCDE corrupted, AF preserved
;
LE455	PUSH	PSW
	CALL	IGNB	; Get char from line, neglect tab + space
	CPI	'"'
	JZ	@E49B	; Jump if char is '"'
	CPI	'('
	JZ	@E486	; Jump if char is '('
	CALL	ALPHA	; Check if char is upper Case
	JC	@E477	; Then jump
	CPI	'-'
	JZ	ERRSN	; Run 'SYNTAX ERROR' if '-'
	CALL	ENUM	; Encode a number
	JNC	ERRSN	; Evt run 'SYNTAX ERROR'
	JMP	@E4A4	; store type and quit
;
; If upper case character
;
@E477	CALL	EFUN	; Encode function
	JC	@E4A4	; If ready: store type ($30) and quit
	MOV	C, B
	MVI	D, $00
	CALL	LE5BC	; Encode var/array referente
	JMP	@E4A7	; Quit
;
; If opening bracket
;
@E486	MVI	M, $9A	; Load $9A in EBUF
	CALL	INXCH	; Update EBUF pointer
	INR	C	; Next pos in textline
	CALL	LE3C9_	; Encode expression
	CALL	EFETCH	; Get char from line
	CPI	')'
	JNZ	ERRSN	; 'SYNTAX ERROR' if not ')'
	INR	C	; Next pos in textline
	JMP	@E4A7	; Quit
;
; If opening '"'
;
@E49B	NOP
	CALL	LE880	; store quoted text in EBUF
	MVI	A, $20	; Type is STR
	JMP	@E4A4	; Store type and quit
;
; Ready
;
@E4A4	STA	TYPE	; Set type latest expression
@E4A7	POP	PSW
	RET
;
; ***************************
; * ENCODE 'SAVEA', 'LOADA' *
; ***************************
;
ELODA	.equ	*
ESAVA	CALL	EARRN	; Enc. array without arguments
	JMP	ELOAD	; Into encode 'SAVE/LOAD'
;
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF
;
; *******************
; * ENCODE A NUMBER *
; *******************
;
; Encodes a INT or a FPT number.
;
; Entry: C: offset of start of number
;        HL: points to EBUF
;
; On exit: in A:     $00 FPT; $10 INT; $10 HEX
;          in EBUF:	 $10 FPT; $14 INT; $15 HEX
;
; On exit, non-hex numbers will only be INT if reqd type or IMP type is INT,
; and there is no '.' or 'E' in the input string.
;
; Non-error exit: CY=1: C, HL updated, E preserved
;                       A: Type-code, DE: Entry BC
; Error exit:     CY=0, BCDEHL preserved
;
ENUM	PUSH	B
	PUSH	H
	CALL	IGNB	; Get char from line, neglect tab + space
	CPI	'#'
	JZ	LE513	; Hex if char is '#'
	LDA	REQTYP	; Get required number type
	ORA	A
	JNZ	@E4DC	; Jump if reqd type is not FPT
	LDA	IMPTYP	; Get default number type
@E4DC	CPI	$00
	JZ	LE4FF	; Jump if type is not FPT
;
; If INT
;
	MVI	M, $14	; Load #14 in EBUF
	CALL	INXCH	; Update EBUF pointer
	CALL	EINT	; INT nr into EBUF
	JNC	LE4FF	; Then handle as FPT
	CALL	EFETCH	; Get char from line
	CPI	'.'
	JZ	LE4FF	; Try FPT if no digits before the '.'
	CPI	'E'
	JZ	LE4FF	; Handle as FPT if 'E'
LE4F9	MVI	A, $10	; Type is INT
LE4FB	POP	D
	POP	D
	STC		; CY=1
	RET
;
; If FPT
;
LE4FF	POP	H
	POP	B
;
; Entry from ETCON
;
LE501	PUSH	B	; Save pointers
	PUSH	H
	MVI	M, $10	; Load $10 in EBUF
	CALL	INXCH	; Update EBUF pointer
	CALL	LE596	; FPT nr into EBUF
	MVI	A, $00	; Type is FPT
	JC	LE4FB	; Jump if no errors
	POP	H
	POP	B
	RET		; Error exit (no number)
;
; If HEX
;
LE513	MVI	M, $15	; Load $15 in EBUF
	CALL	INXCH	; Update EBUF pointer
	NOP
	CALL	EHEX	; Hex nr into EBUF
	JNC	ERRSN	; Run 'SYNTAX ERROR' if no digits
	JMP	LE4F9	; Quit
;
; *********************
; * ENCODE A FUNCTION *
; *********************
;
; Reads a system function (both function and arguments) into EBUF. Error exit if syntax or
; type mismatch errors are found.
;
; Entry: HL: points to 1st free pos. in EBUF
;        C:  points to input
; Exit:  if found: CY=1:
;           A:  type info of result
;           C, HL updated; BDE corrupted
;        if not found: CY=0:
;           A:  end of table count
;           B:  start of name in input
;           C:  points beyond
;           DE: points to 0 T/L byte at table end
;           HL: points to EBUF
;
EFUN	PUSH	H
	STC		; Set 'include type letter'
	CALL	RDID	; Find variable name in input allow !, %, $
	LXI	H, FUNTB	; Addr table BASIC functions
	CALL	LOOKX	; Find function in table
	MOV	A, E	; Get serialnr of entry in table in A
	XCHG
	POP	H
	JNC	@E57A	; Abort if not found (CY=0)
;
; If found in table
;
	MVI	M, $20	; Load fn. code ($20) in EBUF
	CALL	INXCH	; Update EBUF pointer
	MOV	M, A	; Load how manyth function in EBUF
	CALL	INXCH	; Update EBUF pointer
	LDAX	D	; Get T/L byte of function
	INX	D
	PUSH	PSW	; Preserve it
	ANI	$0F	; Length only
	JZ	@E576	; Jump if no arguments reqd
;
; If arguments required
;
	PUSH	PSW	; Preserve length fuction
	CALL_B(ECHRI, '(')	; Check if next char is '(', run 'SYNTAX ERROR' if not
@E549	XCHG
	MOV	A, M	; Get T/L byte
	INX	H
	XCHG
	CPI	$30	; Boolean type?
	CZ	LE5BC	; Then encode var/array ref
	JZ	@E565	; and jump
	CPI	$20	; STR type?
	CZ	LE3A1	; Then encode STR expr
	JZ	@E565	; and jump
	CPI	$10	; INT type?
	CZ	LE36D	; Then encode INT expr
	CNZ	LE376	; Else: encode FPT expr
;
@E565	POP	PSW	; Get length function
	DCR	A	; Check if all arguments done
	JZ	@E572	; Jump if ready
	PUSH	PSW	; Preserve T/L function
	CALL_B(ECHRI, ',')	; Check if next char is ',', run 'SYNTAX ERROR' if not
	JMP	@E549	; Encode next argument
@E572	CALL_B(ECHRI, ')')	; Check if next char is ')', run SYNTAX ERROR if not
@E576	POP	PSW	; Get T/L function
	ANI	$30	; Type only
	STC		; CY=1
@E57A	RET
;
; ************************
; * INT NUMBER INTO EBUF *
; ************************
;
; Entry: C:  points to input
;        HL: Points to EBUF
;
EINT	CALL	IGNB	; Get char from line, neglect tab + space
	CPI	'-'
	JNZ	@E585	; Junp if char is not '-'
	INR	C
	XRA	A	; Else: clear sign bit
@E585	CALL	XICB	; Input INT number to MACC
	JNZ	@E58D	; Jump if nr was >= 0
	ROMCALL(4, $60)	; Change sign MACC
@E58D	JMP	LE5A3	; Move MACC into EBUF
;
; ************************
; * HEX NUMBER INTO EBUF *
; ************************
;
LE590	CALL	XHCB	; Input HEX number to MACC
	JMP	LE5A3	; Move MACC into EBUF
;
; ************************
; * FPT NUMBER INTO ERUF *
; ************************
;
; Entry: C:  Points to input
;        HL: points to EBUF
; Non-error exit: CY=1:
;        C, HL updated. B preserved, A corrupted
;        DE: Location of number in EBUF
; Error exit: CY=0:
;        BDEHL preserved, A corrupted, C updated
;
EFPT	CALL	IGNB	; Get char from line, neglect tab + space
	CPI	'-'
	JNZ	@E5A0	; Jump if char is not '-'
	INR	C
	XRA	A	; Else: clear sign bit
@E5A0	CALL	LE879	; FPT nr into MACC, evt change sign
;
; Entry for HEX/INT numbers
;
LE5A3	JNC	LE5BB	; Abort if there are no digits
	PUSH	B
	MOV	D, H	; O1d ERUF pntr in DE
	MOV	E, L
	CALL	INXCH	; Update EBUF pointer to after new input
	CALL	INXCH
	CALL	INXCH
	CALL	INXCH
	XCHG
	ROMCALL(4, $0F)	; Copy MACC into EBUF
	XCHG
	POP	B
	STC		; CY=1
LE5BB	RET
;
; **************************************
; * ENCODE VARIABLE OR ARRAY REFERENCE *
; **************************************
;
; L3E85: Reference to a variable or an array with arguments.
; L3EB6: Reference to an array without arguments.
;
; Entry: D : Code: 00: reference to a value (array with arguments or variable)
;                  FF: array name without arguments
;        C : Next position in input
;        HL: 1st free position in EBUF
; Exit:  C, HL updated, AF preserved
;        DE: offset to symbol table (to T/L byte)
;        B : T/L byte of name
;
LE5BC	MVI	D, $00
LE5BE	PUSH	PSW
	PUSH	D
	CALL	IGNB	; Get 1st char from line, neglet tab + space
	CALL	ALPHA	; Check if char is upper case
	JNC	ERRSN	; Run "SYNTAX ERROR" if not
	PUSH	H
	PUSH	PSW	; Save 1st char
;
; Check if name is a BASIC command
;
	MVI	E, $02	; Nr of info bytes -1
	LXI	H, BAS_CMD	; Addr command table
	CALL	LOOKC	; Find instr in table. On exit, HL points to string or after it if not found
	MOV	A, M	; Check if end table reached
	ANI	$3F
	CPI	$25
	JNZ	ERRSN	; Run 'SYNTAX ERROR' if name is a command
	ORA	A
;
; Check if name is a BASIC function
;
	CALL	RDID	; Find var.name in input
	LXI	H, FUNTB	; Addr function table
	CALL	LOOKX	; Find function in table
	JC	ERRSN	; Run 'SYNTAX ERROR' if name is a function
;
; Check type marker in input
;
	INR	C	; Points to next char in input
	MVI	E, $02	; 2 bytes in symtab for STR
	MVI	H, $20	; String type byte
	CPI	$24
	JZ	@E60E	; Jump if STR ('$')
	MVI	E, $04	; 4 byte in symtab for INT/FPT
	MVI	H, $10	; INT type byte
	CPI	'%'
	JZ	@E60E	; Jump if INT ('%')
	MVI	H, $00	; FPT type byte
	CPI	'!'
	JZ	@E60E	; Jump if FPT ('!')
;
; If no type marker given
;
	POP	PSW	; Get 1st byte var.name
	LXI	H, IMPTAB-$41	; Baseaddr IMPTAB
	CALL	DADA	; Calc offset addr in HL
	MOV	H, M	; Get type marker in H
	DCR	C
	JMP	@E60F
;
; Handle type marker
;
@E60E	POP	PSW	; Get 1st byte of name
@E60F	MOV	A, H	; type in A
	ORA	D	; OR type (high nibble) with length (1ow nibble)
	MOV	D, A	; T/L on name in D
	POP	H
	POP	PSW	; Get code $00/$FF in A
	PUSH	H
	CALL	INXCH	; Update EBUF pointer 2 positions
	CALL	INXCH
	ORA	A	; Flags on code
	JZ	@E626	; Jump if value
;
; If name
;
	MOV	A, D	; Get T/L byte of name
	ORI	$40	; Set bit 6 (array)
	MOV	D, A	; Preserve it
	JMP	@E62E
;
;  If value
;
@E626	CALL	EFETCH	; Set char from line
	CPI	'('	; '(')?
	CZ	LE653	; Then encode arguments
;
@E62E	XTHL
	PUSH	H
	MOV	A, D	; Get T/L byte on name
	ANI	$30	; Type only
	STA	TYPE	; Set type latest expression
	PUSH	D	; Preserve T/L name
	CALL	LOOK	; Find variable in symtab
	POP	D	; Get T/L name
	CNC	EVARI	; Insert variable in symtab if it is a new one
	MOV	B, D	; T/L name in B
	XCHG		; Var.addr in symtab in DE
	LHLD	STBBGN	; Get startaddr symtab
	XCHG		; in DE; var addr in HL
	CALL	SUBDE	; Calc offset from begin symtab in HL
	XCHG		; Offset in DE
	POP	H	; Retrieve EBUF pntr
	MOV	A, D	; Hibyte offset in A
	ORI	$40	; Set bit 6 (array)
	MOV	M, A	; Hibyte offset in EBUF
	INX	H
	MOV	M, E	; Lobyte offset in EBUF
	INX	H
	POP	H
	POP	PSW
	RET
;
; ENCODE ARRAY ARGUMENTS
;
; An arguments list is encoded into EBUF.
; Format:
;       nr of arg / type of arg / code for expr / < type of arg code for expr >
;
; Entry: D : T/L byte of variable name
;        C : points to '(' of argument 1ist for array in input
;        HL: 1st free position EBUF
; Exit:  D: Subscripted f1ag
;        E: Nr of bytes in symtab (02)
;        C, HL updated. B preserved. A=D.
;
LE653	MVI	E, $00	; Parameter count
	PUSH	H
	CALL	INXCH	; Update EBUF pointer
@E659	INR	E	; Parameter count +1
	INR	C	; Skip 'C' or '.'
	PUSH	D
	CALL	LE3B2	; Encode non-boolean expr preceeded by its type
	POP	D
	CALL	IGNB	; Get char from line neglect tab + space
	CPI	','
	JZ	@E659	; Get next parameter if it is ','
	CPI	')'
	JNZ	ERRSN	; Run 'SYNTAX ERROR' if not ')'
	INR	C	; Skip ')'
	XTHL		; Get old EBUF pntr
	MOV	M, E	; Parameter count inta EBUF
	POP	H
	MVI	E, $02	; 2 bytes space in symtab
	MOV	A, D
	ORI	$40	; Set type is array
	MOV	D, A	; Set f1ag 'subscripted'
	RET
;
; ************************
; * ENCODE AN ARRAY NAME *
; ************************
;
EARRN	MVI	D, $FF	; Code for name only
	JMP	LE5BE	; Encode array name
;
; *****************************************
; * INSERT A NEW VARIABLE IN SYMBOL TABLE *
; *****************************************
;
; The variable name is inserted in the symbol table and the value is cleared.
;
; Entry: See CAB8
; Exit:  HL: points to 2nd T/L byte of entry
;        AF corrupted, BCDE preserved
;
EVARI	CALL	LOOKI	; Insert var.name in symtab
	PUSH	H
	INX	H	; HL pnts after 2nd T/L byte of Entry
	MOV	A, D	; Get T/L of name
	ANI	$40
	JNZ	LE695	; Jump if array type
;
; If number type
;
	MOV	A, D	; Get T/L of name
	ANI	$30
	CPI	$20
	JZ	LE695	; Jump if string type
	CALL	ZFPINT	; Clear value in symtab
	POP	H
	RET
;
; If string/array type
;
LE695	MVI	M, $00	; Clear pointer in symbtab
	INX	H
	MVI	M, $00
	POP	H
	RET
;
; *****************************
; * STORE QUOTED TEXT IN EBUF *
; *****************************
;
LE69C	MVI	M, $18	; Code for quoted string ($18) into EBUF
	CALL	INXCH	; Update EBUF pointer
	MVI	E, $FF	; Text must end with '"'
	JMP	LE6B5	; Inta common end
;
; *********************************
; * STORE UNQUOTED STRING IN EBUF *
; *********************************
;
LE6A6	MVI	E, $01	; Text must end with ','
	MVI	M, $19	; Code for unquoted string ($19) into EBUF
	CALL	INXCH	; Update EBUF pointer
	JMP	LE6B5	; Into common end
;
; ************************
; * STORE TEXT INTO EBUF *
; ************************
;
; Text in DATA, REM and '***' statements is moved into the EBUF.
;
LE6B0	CALL	IGNB	; Get char from line, neglect tab + space
	MVI	E, $02	; Text must end with CR into common end
;
; *************************************
; * COMMON END TEXT ENCODING ROUTINES *
; *************************************
;
; Entry: C:  points to 1st actual character to be stored.
;        HL: points to place for length byte in EBUF
;        E:  handling switch:
;              > 1: (but < $80): text must end with CR
;              = 1: text will end with ',' (',' is no inserted into EBUF)
;             <= 0: text will end at '"' ('"' is not inserted into the EUF)
; Exit:  C:  points beyond text in input
;        HL: points beyond stored text in EBUF
;        D:  length of stored text
;        A:  character which marks end of text
;        B:  preserved
;        E:  corrupted
;
LE6B5	PUSH	H
	CALL	INXCH	; Update EBUF pointer
	MVI	D, $00	; Set 1ength is 0
LE6BB	CALL	EFETCH	; Get char from line
	CPI	$0D
	JZ	LE6DB	; Jump if char is 'CR'
	CPI	','
	JZ	LE6E3	; Jump if char is ','
LE6C8	INR	C
	CPI	'"'
	JNZ	LE6D3	; Jump if char is not '"'
	DCR	E
	JM	LE6DF	; If done: store length in EBUF, quit
	INR	E
;
; Character into EBUF
;
LE6D3	MOV	M, A	; Load char in EBUF
	CALL	INXCH	; Update EBUF pointer
	INR	D
	JMP	LE6BB	; Get next char
;
; If 'CR'
;
LE6DB	DCR	E
	JM	ERRSN	; If E >= $80: Run 'SYNTAX ERROR'
LE6DF	XTHL
	MOV	M, D	; Length in EBUF Entry
	POP	H
	RET
;
; If ','
;
LE6E3	DCR	E
	JZ	LE6DF	; If E=0: Store length in EBUF, quit
	JMP	LE8AB	; incr E, get next char
;
; ********************************************
; * FIND BINARY OR UNITARY OPERATOR IN TABLE *
; ********************************************
;
; Entry/exit: See #3E6F6.
;
LE6EA	PUSH	H
	LXI	H, OPTAB	; Startaddr table
LE6EE	MVI	E, $00
	CALL	LOOKC	; Find instr in table
	MOV	A, M	; Get code to table
	POP	H
	RET
;
; *************************************
; * FIND AN UNITARY OPERATOR IN TABLE *
; *************************************
;
; Routine 1ooks for a init. string beginning at C in table.
;
; Entry: C: points to input
; Exit:  CY=0: Not found
;          C : Points to 1st valid character after entry address
;          A : Contains code info 0
;          DE = 0, BHL preserved
;        CY=1: Found:
;          C : points beyond string found
;          A : code byte from table
;          DE = 0, BHL preserved
;
LE6F6	PUSH	H
	LXI	H, OPTBM	; Startaddr table
	JMP	LE6EE	; Into previous routine
;
;
; *******************************
; * FIND VARIABLE NAME IN INPUT *
; *******************************
;
; Checks if 1st character is a upper case one.
; Reads the input (starting with character after C) till it finds a non-alphanumeric character
; (number or upper case). On a carry CALL, it also accepts %, ! or $ at the end.
; Blanks are not ignored and nat accepted.
;
; Entry: C : input positicon
; Exit:  B : entry C
;        C : points to 1st character not accepted
;        D : count of 1st character not accepted (1st character read has count 1).
;        A, E: 1st non-alphanumeric character read.
;        HL preserved, F corrupted.
;
RDID	PUSH	PSW	; Preserve CY-flag
	MOV	B, C
	MVI	D, $00	; Init count
@E701	INR	D	; Count +1
	INR	C	; Line pos +1
	MOV	A, D	; Count in A
	CPI	$0F	; Max 14 char for a name
	JC	@E70A
	DCR	D	; Skip last char if > 14
@E70A	CALL	EFETCH	; Get char from line
	CALL	ALNUM	; Check if nr or upper case
	JC	@E701	; Get next char if OK
	CALL	EFETCH	; Get 1st non-alphanum. char from line
	MOV	E, A	; Store it in E
	POP	PSW	; Get CY-f1ag back
	MOV	A, E	; Get char back in A
	RNC		; Abort if non-carry CALL
;
; On carry CALL only: acept !, %, $
;
	CPI	'%'
	JZ	@E727	; Jump if char is '%'
	CPI	'!'
	JZ	@E727	; Jump if char is '!'
	CPI	'$'
	RNZ		; Abort if char is not '$'
@E727	INR	C	; Update line pos
	INR	D	; Update count
	RET
;
; *******************
; * GET LINE NUMBER *
; *******************
;
; Exit: C, HL: updated
;       B preserved
;       AFDE corrupted
;       'SYNTAX ERROR' if no linenr given
;
ELNR	CALL	LE731	; Read linenr into EBUF
	JNC	ERRSN	; Run 'SYNTAX ERROR' if no number given
	RET
;
; ******************************
; * READ LINE NUMBER INTO EBUF *
; ******************************
;
; Exit: CY=0: No linenumber given. Error exit if linenumber is 0 or > $FFFF.
;       CY=1: OK
;       C, HL: updated
;       B preserved, AFDE corrupted
;
LE731	CALL	IGNB	; Get char from line, neg1ect tab + space
	CALL	XICB	; Input INT number to MACC
	RNC		; Abort if no linenr given
	PUSH	B
	ROMCALL(4, $15)	; Copy MACC into reg ABCD
	ORA	B
	JNZ	@E751	; Error exit it > $FFFF
	ORA	C
	ORA	D
	JZ	@E751	; Error exit if nr = 0
	MOV	E, D	; Linenr in DE
	MOV	D, C
	MOV	M, D	; Hibyte linenr into EBUF
	CALL	INXCH	; Update EBUF pointer
	MOV	M, E	; Lobyte linenr inta ERUF
	CALL	INXCH	; Update EBUF pointer
	POP	B
	STC		; CY= 1 (OK)
	RET
;
; Error exit
;
@E751	POP	B
	MVI	A, $15
	JMP	ERROR	; Run error 'NUMBER DUT OF RANGE'
;
; *************************************
; * ENCODE BINARY OPERATION INTO EBUF *
; *************************************
;
; Entry: A: result of 3E7CF:
;           1xx xxxx : compute type / opcode
;        E: table code byte
;        HL: 1st free location EBUF
;
LE757	PUSH	PSW
	MOV	A, E	; Get conversion code byte
	XCHG
	LHLD	RGTPT	; addr 1ast operator in EBUF
	XCHG		; in DE
	CALL	LE770	; Add conversion byte for 2nd operand
	RRC
	RRC
	XCHG
	LHLD	HOPPT	; Get addr in EBUF for next operator
	XCHG
	CALL	LE770	; Add conversion byte for 1st operand
	POP	PSW	; Restore compute/opcode in A
	CALL	LE783	; Insert it into EBUF
	RET
;
; *********************************************
; * ADD INT/FPT CONVERSION BYTE TO EXPRESSION *
; *********************************************
;
; Entry: A : conversion byte
;            $01: Convert FPT to INT
;            $02: Convert INT to FPT
;
LE770	PUSH	PSW
	ANI	$03	; Conversion only
	JZ	@E781	; Jump if no conversion reqd
	RAR		; CY=1; if FPT to INT
	MVI	A, $9F	; Conv. byte FPT to INT
	JC	@E77E
	MVI	A, $BF	; Conv. byte INT to FPT
@E77E	CALL	LE783	; Insert conv. byte into EBUF
@E781	POP	PSW
	RET
;
; *************************
; * INSERT BYTE INTO EBUF *
; *************************
;
; Data is moved 1 byte to create space for byte to be inserted.
;
; Entry: A:  byte to be inserted.
;        DE: startaddress source bank
;        HL: endaddress source bank +1
; Exit:  HL = HL + 1
;        ABCDE preserved
;
LE783	PUSH	B	; Start source in BC
	MOV	B, D
	MOV	C, E
	INX	B	; Destination 1 byte higher
	PUSH	PSW
	PUSH	D
	CALL	INXCH	; Update EBUF pointer
	PUSH	H
	DCX	H
	CALL	MOVE	; Move EBUF contents 1 byte
	POP	H
	POP	D
	POP	PSW
	STAX	D	; Store byte into EBUF
	POP	B
	RET
;
; *****************************************
; * ENCODE AN UNITARY OPERATOR FOR A TERM *
; *****************************************
;
; Entry: A:  code according to table CFD8
; Exit:  BCHL preserved. DE corrupted
;        A: code byte
;                 +   -  INOT
;           INT  BC	 BD    BE
;           FPT  9C	 9D     *
;
LE797	PUSH	H
	LXI	H, TYPE	; Addr type 1ast expression
	ANI	$1F	; Opcode only
	CPI	$00
	MVI	D, $1C
	JZ	@E7BA	; Then jump
	CPI	$01	; '-'?
	MVI	D, $1D
	JZ	@E7BA	; Then jump
	CPI	$1E	; 'INOT'?
	JNZ	ERRSN	; Run 'SYNTAX ERROR' if not
;
; If 'INOT'
;
	MOV	A, M	; Get type last expression
	CPI	$10	; Must be INT
	JNZ	ERRTM	; Run error 'TYPE MISMATCH' if not
	MVI	A, $BE	; Code 'INOT' in A
@E7B8	POP	H
	RET
;
; If '+' or '-'
;
@E7BA	MOV	A, M	; Get type last expression
	CPI	$10
	MVI	E, $A0
	JZ	@E7CA	; Jump if INT
	MOV	A, M	; Get type last expression
	CPI	$00
	MVI	E, $80
	JNZ	ERRTM	; Run error 'TYPE MISMATCH' if not FPT
@E7CA	MOV	A, D	; Set up code in A
	ORA	E
	JMP	@E7B8
;
; *****************************************
; * OBTAIN TYPE INFO FOR BINARY OPERATION *
; *****************************************
;
; Entry: A:    code for binary operation (lower 5 bits)
;        E:    type 1st operand
;        TYPE: type 2nd operand
;
; Routine compares both types. If different, one must be INT and the other FPT, else type
; mismatch error.
; Type conversion and operation type are obtained from table on 3E835.
; Type mismatch if illegal type.
; Type of result is stored in TYPE.
;
; Exit: E:  type code from table
;       A:  code for EBUF: 1xx xxxxx:
;	  bits 5, 6: type of compute required:
;             0: FPT
;             1: INT
;             2: STR
;             3: Boolean
;           bits 0-4: opcode
;       BCDHL Ppreserved
;
LE7CF	PUSH	H
	PUSH	D
	ANI	$1F	; Opcode only
	PUSH	PSW
	CALL	LE81F	; Set D according to opcode
	LDA	TYPE	; Get type latest expression
	CMP	E	; Compare both types
	JNZ	LE809	; Junp if not identical
	RLC		; Type code from TYPE in lonibble
	RLC
	RLC
	RLC
	ANI	$03	; Only lower 2 bits
	MOV	L, A	; in L
LE7E5	MOV	A, D	; Get opcode group (0-5)
	ADD	A	; *2
	MOV	D, A	; in D
	ADD	A	; *4
	ADD	D	; *6 (find group in table)
	ADD	L	; Find pos in grouptable
	LXI	H, LE835	; Startaddr result table
	CALL	DADA	; Find addr resultcode in table
	MOV	A, M	; Get resultcode
	INR	A	; Check if code is FF
	JZ	ERRTM	; Then run error 'TYPE MISMATCH'
	DCR	A
	ANI	$30	; Get type of result only
	STA	TYPE	; Store type 1atest expression
	POP	D	; Get code for binary operation in D
	MOV	E, M	; Get resultcode from table in E and in A
	MOV	A, M
	RAR
	ANI	$60	; Reqd computing in bits 5, 6
	ORA	D	; Add opcode in bit 0-4
	ORI	$80	; Set bit 7
	POP	H
	MOV	D, H	; Restore D
	POP	H
	RET
;
; If both types not identical
;
LE809	MVI	L, $04
	CPI	$00	; TYPE is FPT?
	JZ	@E816	; Then jump
	INR	L
	CPI	$10	; TYPE is INT?
	JNZ	ERRTM	; Run error 'TYPE MISMATCH' if not
@E816	ADD	E	; Add other type
	CPI	$10	; Result must be $10
	JNZ	ERRTM	; Run error 'TYPE MISMATCH' if not
	JMP	LE7E5	; Calc conversion
;
; SET D DEPENDING ON OPCODE BINARY OPERATOR:
;
; Entry: A: Opcode binary operator (table OPTAB)
; Exit:  ABCEHL preserved
;
LE81F	MVI	D, $00	; D=0
	CPI	$01
	RC		; Ready if opcode is 0 (+)
	INR	D	; D=1
	CPI	$04
	RC		; Ready if opcode is 1, 2 o 3 (-,/,*)
	MVI	D, $02	; D=2
	RZ		; Ready if opcode is 4 (^)
	INR	D	; D=3
	CPI	$10
	RC		; Ready if opcode is 5-F (IOR, IAND, IXOR, SHL, SHR, MOD)
	INR	D	; D=4
	CPI	$18
	RC		; Ready if opcode is 10-17 (>=, <=, >, <, =, <>)
	INR	D	; D=5
	RET		; If opcode >= 18 (AND, OR)
;
; TABLE WITH TYPE RESULTS
;
; The table g1ves the relation between input operands, the binary operator and the result
; for different groups of binary operations.
; The groupnumbe is calculated in E81F.
;
; Format each group: 6 bytes. Sequence:
;      FPT/FPT
;      INT/INT
;      STR/STR
;      LOGIC/LOGIC
;      INT/FPT
;      FPT/INT
; Format each byte:
;      bit 7, 6: type arithmetic (0: FPT, 1: INT, 2: STR, 3: 1ogic)
;      bit 5, 4: type result (0: FPT, 1: INT, 2: STR, 3: 1ogic)
;      bit 3, 2: conversion left operand
;      bit 1, 0: conversion right operand
;                0: no conversion
;                1: convert to INT
;                2: convert to FPT
;      $FF: not possible
;
LE835	.equ	*
	.byte	$00, $50, $A0, $FF, $08, $02	; Group D=0 (+)
	.byte	$00, $50, $FF, $FF, $08, $02	; Group D=1 (-, /, *)
	.byte	$00, $0A, $FF, $FF, $08, $02	; Group D=2 (^)
	.byte	$55, $50, $FF, $FF, $51, $54	; Group D=3 (IAND, IOR, IXOR, MOD, SHL, SHR)
	.byte	$30, $70, $B0, $FF, $38, $32	; Group D=4 (<, >, <>, =, <=, >=)
	.byte	$FF, $FF, $FF, $F0, $FF, $FF	; Group D=5 (AND, OR)
;
; ******************************
; * CHECK STATEMENT TERMINATOR *
; ******************************
;
; Get character from line and checks if it is a correct terminator (':' or car. ret).
;
; Exit: Z=l: correct terminator
;       Z=0: incorrect
;       BCDEHL preserved, A corrupted
;
TSEOC	CALL	IGNB	; Get char from line, neglect tab + space
	CPI	':'	; Is it ':'?
	RZ
	CPI	$0D	; Is it 'CR'?
	RET
;
; **********************************
; * CHECK IF NEXT CHARACTER IS ',' *
; **********************************
;
; Exit: C updated, AF corrupted, BDEHL preserved
;
LE862	CALL_B(ECHRI, ',')	; Check 1f next char is ','
	RET
;
; ************************
; * CHECK NEXT CHARACTER *
; ************************
;
; Routine finds next valid character in input. If it is not the character expected: syntax error.
;
; Entry: C: points to input.
;        ASCII-value of character to compare with on stack
; Exit:  If correct: C updated, AF corrupted
;        BDEHL preserved
; *
ECHRI	XTHL		; HL pnts to expected char
	CALL	IGNB	; Get char from line, neglect tab + space
	CMP	M	; Is it expected one?
	JNZ	ERRSN	; Run 'SYNTAX ERROR' if not
	INR	C	; Pnts to next input
	INX	H	; Update SP
	XTHL
	RET
;
; *******************************
; * ENCODE 'ERASE' - (not used) *
; *******************************
;
;  The BASIC command ERASE is cancel1ed.
;
EERASE	LXI	D, EARRN	; Addr routine encode array without arguments
	JMP	LE12A	; Encode
;
; ******************************
; * INPUT FPT NUMBER INTO MACC *
; ******************************
;
; Entry: Z=1: change sign too
; Exit:  C updated, ABDEHL preserved
;        CY=0: error
;
LE879	CALL	XFCB	; Input FPT number to MACC
	RNZ		; Ready if Z=0
	ROMCALL(4, $1B)	; Else change sign MACC
	RET
;
; *******************************
; * STORE QUOTED TEXT INTO EBUF *
; *******************************
;
; Entry: C points to 1st '"'
;
LE880	INR	C
	JMP	LE69C	; Store text in EBUF
;
; ********************************
; * STORE A HEX NUMBER INTO EBUF *
; ********************************
;
; Entry: C points to '#' of hex number
;
EHEX	INR	C
	JMP	LE590	; Hex nr into EBUF
;
; **********************************
; * ENCODE AN INT NUMBER INTO EBUF *
; **********************************
;
LE888	CALL	LE8AF	; $14 into EBUF
	CPI	'#'	; '#'?
	JZ	LE899	; Then jump
	CALL	EINT	; INT nr into EBUF
LE893	JNC	LE8B7	; Evt run 'SYNTAX ERROR'
	JMP	LE15C	; Quit
;
; If hex number:
;
LE899	CALL	EHEX	; Hex nr into EFUF
	JMP	LE893
;
	.byte	$FF, $FF, $FF
;
; *****************
; * ENCODE 'DATA' *
; *****************
;
EDATA	MOV	A, L
	CPI	$42
	JNZ	ERRSN	; Run 'SYNTAX ERROR' if not
	JMP	ENC_D	; Encode text
;
; ********************************
; * part of END ENCODING (3E6B5) *
; ********************************
LE8AB	INR	E
	JMP	LE6C8
; *********************************
; * CODE FOR INT NUMBER INTO EFUF *
; *********************************
;
; Gets also next character to encode.
;
LE8AF	MVI	M, $14	; INT coe ($14) in EBUF
	CALL	INXCH	; Update EBUF pointer
	JMP	IGNB	; Get char from line, neglect tab + space
;
; *************************************************
; * ERROR EXIT OF ENCODE INT NR INTO EBUF (3E888) *
; *************************************************
;
.if ROMVERS == 11
LE8B7	LXI	H, XE39F	; Addr routine 'STORE DATA'
	PUSH	H	; Preserve it as returnaddr
	LDA	POROM	; Get POROM
	ANI	$3F	; Select bank 0
	PUSH	PSW
	JMP	LC6E6	; Bank return
.endif
.if ROMVERS == 10
LE8B7	LHLD	EFEPT	; Get EFEPT
	LXI	D, $FFFC
	DAD	D	; Set back linepntr
	SHLD	CURRNT	; Store start current line
	JMP	ERRSN	; Run 'SYNTAX ERROR'
.endif
;
	.byte	$FF
;
; **************************************
; * ASCII TABLE UPPER CASE (UNSHIFTED) *
; **************************************
;
KEYTU	.equ	*
	.byte	'0','1','2','3','4','5','6','7','8','9',':',';',',','-','.','/',$0D
	.byte	'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
	.byte	'[','^',' ',$00,$08,$10,$11,$12,$13,$09,$80,$00,$00
;
; ************************************
; * ASCII TABLE LOWER CASE (SHIFTED) *
; ************************************
;
KEYTS	.equ	*
	.byte	'0','!',$22,'#','$','%','&',$27,'(',')','*','+','<','=','>','?',$0D
	.byte	'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'
	.byte	']','~',' ',$00,$08,$14,$15,$16,$17,$09,$80,$00,$00
;
; ************************************
; * GET INPUTS FROM KEYBOARD OR DINC *
; ************************************
;
; Part of RESET (C719). Determines input source depending on 1st input done.
;
LE935	CALL	FGETC	; Scan keyb; char in A
	RC		; Ready if break pressed
	RNZ		; Ready if key input done
	JMP	LEFF4	; Else: Get input from DINC
;
	.byte	$FF, $FF
;
; **********************************************
; * LOAD ASCII VALUE FOR KEY PRESSED IN BUFFER *
; **********************************************
;
; From the key pressed, the offset to the start address of the ASCII table is calculated.
; The ASCII value for the pressed key is stored in the circular buffer KLIND.
;
; Entry: B: column number
;        C: row number
; Exit:  all registers preserved
;
INKEY	PUSH	PSW
	PUSH	B
	PUSH	H
	MVI	A, $07	; Calc offset of startaddr for key pressed
	SUB	B
	ADD	A
	ADD	A
	ADD	A
	ADD	C
	MOV	C, A	; Store it in C
	LHLD	KBTPT	; Get startaddr ASCII table
	MVI	B, $00
	CPI	$11
	JC	@E95D	; Check if key is a char A-Z
	CPI	$2B
	JNC	@E95D
	LDA	SHLK	; Get shift lock value
	MOV	B, A	; in B
@E95D	LDA	SHLOC	; Get 'shift' byte
	XRA	B	; Take CTRL into account
	ANI	$40	; A=$40 if shift, 00 when not
	JZ	@E96C	; Jump if no shift
	PUSH	D
	LXI	D, $0038	; Add. offset for 1ower casec table
	DAD	D	; Startaddr 1ower case table now in HL
	POP	D
@E96C	MVI	B, $00
	DAD	B	; Add offset to startaddr
	MOV	A, M	; Get ASCII value from table
	ORA	A	; Check if Break, Rept, Shift
	JZ	@E98E	; Then Pop, ret
	CPI	$80	; Check if CTRL
	JZ	@E992	; Then update CTRL flag
	MOV	B, A	; Store ASCII value in B
	LHLD	KLIIN	; Get addr next pos in KLIND
	PUSH	H	; Store KLIND on stack
	CALL	KPTRU	; Update KLIND pointer
	LDA	KLIOU	; Get 1st byte next output pos of KLIND
	CMP	L	; Compare with KLIIN
	JZ	@E98D	; Abort if buffer full
	SHLD	KLIIN	; Update KLIIN
	XTHL		; Get old KLIIN from stack
	MOV	M, B	; Store ASCII char in KLIND
@E98D	POP	H
@E98E	POP	H
	POP	B
	POP	PSW
	RET
;
; Update CTRL flag
;
@E992	LDA	SHLK	; Set shiftlock value
	CMA		; Invert it
	STA	SHLK	; And store it again
	JMP	@E98E	; Pop, ret
;
; ****************
; * HEAP REQUEST *
; ****************
;
; The routine checks the heap for free areas. Evt. consecutive free areas are consolidated.
; If this procedure finds a free area min. 2 bytes 1arger than requested, then it is reserved
; by setting the 1ength bytes (msb=0). An evt. resting free area is set with 1ength bytes and
; msb=1 (this area must be >= 2 bytes).
; The heap contents is never moved to obtain one large conso1idated area of free bytes!!
;
; Entry: DE: Length requested heap space.
; Exit:  AFBCDE preserved
;        HL points to a 2-byte length of the requested gap. If no space available, it points to an error routine
;
HREQ	PUSH	PSW
	PUSH	B
	PUSH	D
	MOV	B, D	; Reqd 1ength in BC
	MOV	C, E
	LHLD	HEAP	; Get startaddr Heap
LE9A4	MOV	D, M	; Contents 1st 2 bytes of heap in DE (1ength)
	INX	H
	MOV	E, M
	INX	H
	MOV	A, D	; 1st byte in A
	ANI	$7F	; Mask bit free/used
	CMP	D
	MOV	D, A	; D is 1ength without msb
	JZ	LD227	; If area not free: check if end of heap reached. JMP LE9FA if not
;
; If free area found: Check all next heap entries and accumulate all free areas in succession
;
@E9B0	PUSH	H	; Save startaddr area +2
	DAD	D	; Begin next area in HL
	MOV	A, M
	ORA	A	; Check msb of this area
	JP	@E9C7	; Jump 1f area occupied
	INX	H
	MOV	A, E
	ADD	M	; Add 1obyte length next area length previous area
	MOV	E, A
	MOV	A, D
	DCX	H
	ADC	M	; Add hibyte length next area length previous area
	ANI	$7F	; Skip bit 'free/occupied'
	MOV	D, A
	INX	D
	INX	D	; Add 2 exta bytes
	POP	H	; Restore start free area +2
	JMP	@E9B0	; Check next area
;
; Next area is not free
;
@E9C7	POP	H	; Restore start free area +2
	PUSH	H
	DCX	H
	MOV	M, E	; Store total free lergth in 1st 2 bytes of free area
	DCX	H
	MOV	A, D
	ORI	$80
	MOV	M, A
	; Space available here: HL pnt to start free area +2; DE is size free area; BC size reqd
	MOV	A, E	; Calc free length reqd. 1ength; result in HL
	SUB	C
	MOV	L, A
	MOV	A, D
	SBB	B
	MOV	H, A
	JM	LE9F9	; Space not sufficient: leave consolidated area as free
	JNZ	@E9E4	; Jump if sufficient space
	ORA	L
	JZ	@E9F0	; Jump if just enough
	DCR	A
	JZ	LE9F9	; Not useable if 1 free byte 1eft
;
; Set not used part of free area to free
;
@E9E4	XCHG		; Addr free area in DE
	DCX	D
	DCX	D	; Reserve 2 bytes for length
	POP	H	; Restore start free area +2
	PUSH	H
	DAD	B	; Add reqd 1ength to find start of resting free area
	MOV	A, D
	ORI	$80	; Set free flag
	MOV	M, A
	INX	H	; Length free area into heap
	MOV	M, E
;
; Reserve area for requested entry
;
@E9F0	POP	H	; Restore start free area +2
	DCX	H
	MOV	M, C	; Reqd length in 1st 2 bytes
	DCX	H
	MOV	M, B
	POP	D
	POP	B
	POP	PSW
	RET
;
; Area too small
;
LE9F9	POP	H	; Restore start free area
LE9Fa	DAD	D	; HL pnts to next area
	JMP	LE9A4	; Check next area
;
	.byte	$FF, $FF
;
;
;
;     ===============
; *** UTILITY PACKAGE ***
;     ===============
;
; **************
; * (not used) *
; **************
;
LEA00	POP	H
	JMP	LEA09
;
; *********************
; * RETURN AFTER 'GO' *
; *********************
;
LEA04	PUSH	H	; Returnaddr after 'GO'
	LXI	H,$BADC	; Dummy 'saved PC' to prevent continuation G with start address
	XTHL		; Returnaddr in HL
LEA09	SHLD	HLSAV	; Save HL
	POP	H	; in HL: $BADC
;
; **********************
; * INITIALISE UTILITY *
; **********************
;
; CPU registers are saved in the utility work area. Input from the keyboard is awaited.
;
; The address EA42 is the general return address for all Utility commands.
;
CALRX	SHLD	PCSAV	; Save PC (next instr)
	PUSH	PSW
	POP	H
	SHLD	AFSAV	; Save PSW
	LXI	H, $0000
	DAD	SP
	SHLD	SPSAV	; Save SP
	XCHG
	SHLD	DESAV	; Save DE
	MOV	H, B
	MOV	L, C
	SHLD	BCSAV	; Save BC
	CALL	LEDE7	; Invert nibbles in CPU reg save area
	LHLD	PCSAV	; Get addr next instr
	MOV	A, H
	ORA	L
	JZ	@EA3C	; If it is $0000 (entry from BASIC) Else:
	DCX	H	; HL on addr current instr
	MOV	A, M	; Get opcode in A
	ANI	$C7
	CPI	$C7
	JNZ	@EA3C	; Jump if instr is a RST
	SHLD	PCSAV	; Save addr next instr
@EA3C	LXI	H, LEA7D	; Startaddr string table
	CALL	LED2F	; Print 'PC UTILITY V3.3'
;
; UT command look-up
;
LEA42	CALL	LCRLF	; Print car.ret
	MVI	C, '>'
	CALL	LEEB4	; Print '>'
	CALL	CIE	; Get keyb input, print char
	LXI	H, LEA42	; Returnaddr in HL
	PUSH	H	; Save it on stack
	LXI	H, UT_CMD-1	; Startaddr table commands
@EA54	INX	H
	CMP	M	; Compare input with table
	JC	UT_ERROR	; Error if invalid input
	INX	H	; Get pointer to address of part. routine in DE
	MOV	E, M
	INX	H
	MOV	D, M
	JNZ	@EA54	; Check with next comnand
	XCHG		; Startaddr routine in HL
	PCHL		; Go to this routine
;
; ************
; * UT_ERROR *
; ************
;
; The only error message in utility is '?'
;
; Exit: B preserved, AFCDEHL corrupted
;
UT_ERROR	CALL	LCRLF	; Print car.ret
	MVI	C, '?'
	CALL	LEEB4	; Print '?'
ERRST	LHLD	SPSAV	; Get saved SP
	SPHL		; Restore stackponter
	NOP
	NOP
	NOP
	JMP	LEA42	; Start again for new input
;
; ********************
; * ENTRY FROM BASIC *
; ********************
;
UT_RESET	SHLD	HLSAV	; Save HL
	LXI	H, $0000	; Addr next instr (dummy)
	JMP	CALRX	; Init utility
;
; *************************
; * UTILITY SCREEN HEADER *
; *************************
;
; $0C is clear screen $20 is space.
;
MSESU	.byte	$0C
	.ascii	"PC UTILITY V3.3"
	.byte	$00
;
; *******************************
; * TABLE WITH UTILITY COMMANDS *
; *******************************
;
UT_CMD	.equ	*
	UT_CMD('B', RINIT)	; return addr to Basic
	UT_CMD('D', DISPK)	; startaddr Display
	UT_CMD('F', FILLK)	; startaddr Fill
	UT_CMD('G', GOK)	; startaddr Go
	UT_CMD('L', LOOKK)	; startaddr Look
	UT_CMD('M', MOVEK)	; startaddr Move
	UT_CMD('R', RHEXK)	; startaddr Read
	UT_CMD('S', SUBSK)	; startaddr Substitute
	UT_CMD('V', VECXK)	; startaddr Vector Examine
	UT_CMD('W', LEEE4)	; startaddr Write
	UT_CMD('X', EXAMK)	; startaddr Examine
	UT_CMD('Z', ZEROK)	; startaddr Reset
	.byte	$FF	; End table
;
; ***************
; * D - DISPLAY *
; ***************
;
; Disp1ays contents of memory. Two address values are required which sperify the range of memory
; to be displayed. Break will abort the print out.
;
; Exit: CY=1, al1 registers corrupted
;
DISPK	MVI	C, $02	; Nr of addr inputs required
	CALL	ADARG	; Get 1addr and haddr on stack
	DCR	C
	JP	UT_ERROR	; Error if only 1 addr given
	POP	D	; Haddr in DE
	POP	H	; Ladd in HL
;
; Direct call entry
DISP	CALL	LCRLF	; Print car.ret
	CALL	LADDR	; Print laddr in ASCII
@EAC4	CALL	LED01	; Print space
	MOV	A, M	; Get contents laddr
	CALL	LBYTE	; Print it in ASCII
	CALL	INXCK	; INX H;  check if ready
	RC		; Quit if ready
	CALL	UT_BREAK	; Scan for Break pressed, abort if pressed
	MOV	A, L
	ANI	$0F	; Last instr on line?
	JZ	DISP	; Then car.ret and continue
	JMP	@EAC4	; Next addr
;
; **************************
; * ADDRESS ARGUMENT INPUT *
; **************************
;
; The keyboard is scanned and the inputs are evaluated.
; (C) address arguments will be input and put on stack (LIFO).
; On return C contains the diference between number entered and number desired.
; At 1east one argument is returned.
; Only the last 4 hex characters are used for the address value.
; Arguments are delimited by a space.
; The entry is terminated by CR, ESC, last argument or an invalid character (then error exit).
; Escape returns with CY set.
;
; Entry: C: max. nr of datablocks/addresses.
; Exit:  B: last character typed in (terminator)
;        AFHL corrupted, DE preserved
;
ADALT	XRA	A	; A=0
	CMP	C	; Max nr af inputs reached?
	RZ		; Then return
ADARG	LXI	H, $0000
ADACL	CALL	CIE	; Scan keyb, print char
	MOV	B, A	; Store char in B
	CALL	ASHEX	; Convert it to hex
	JC	ADADC	; If char not 0-F: check if delimiter
ADACE	DAD	H	; Move bits 1 nibble (compose addr from inputs)
	DAD	H
	DAD	H
	DAD	H
	ADD	L	; Add hex char to L
	MOV	L, A	; and store it
	JMP	LEAE1	; Next char
;
; Check for delimiter/terminator
;
ADADC	XTHL		; Save given addr on stack
	PUSH	H	; Save returnaddr again
	DCR	C	; decr input counter
	MOV	A, B	; Get char last input
	CPI	' '	; Space?
	JZ	ADALT	; Then get next addr
	CPI	$0D	; Car. ret?
	RZ		; Then ready
	CPI	$12	; Escape?
	STC		; Then CY=1
	RZ		; and return
	JMP	UT_ERROR	; Else goto Error
;
; As ADARG, but carry return if 1st character is not a legal hex digits
;
ADART	LXI	H, $0000	; Imnediate delimiter
	CALL	CIE	; Scan keyb, print char
	MOV	B, A	; Store char in B
	CALL	ASHEX	; Convert it to hex
	RC		; Return if no hex char
	JMP	ADACE	; Into previous routine
;
; CONVERT NUMBER FROM ASCII TO HEX-VALUE
;
; Entry: Character in A (bit 7 must be 0).
; Exit:  CY=0: Hex-value in A
;        CY=1: Input was not 0-F; (A) useless
;        BCDEHL preserved
;
ASHEX	SUI	'0'
	RC		; Error if $00-$2F
	CPI	10
	JC	@EB24	; OK if number 0-9
	SUI	7
	CPI	10
	RC		; Error if #3A-$3F
	CPI	$10
@EB24	CMC		; OK if 0-9, A-F
	RET
;
; ************
; * L - LOOK *
; ************
;
LOOKK	MVI	C, $03	; Nr datablocks allowed
	CALL	ADART	; Scan keyb, display char, get addresses on stack
	LHLD	PCSAV	; Get addr next instr
	XCHG		; in DE
	MOV	A, C	; Get nr of inputs done
	CPI	$03	; No addr given?
	MVI	A, $00
	CZ	LEB56	; No addr: check CR given
	CNZ	@EB41	; Else: store windows and start program
	STA	UTWK5	; Set Look flag
	XCHG		; Addr next instr in HL
	JMP	LEF35	; Init RST 0
;
; SET LOOK WINDOWS, START LOOK
;
; Entry: A=0, C=3 minus number of fields read
; Exit:  Input 2 fields: A, C = 0
;        Input 3 fields: A, C = FF. DE corrupted
;        B preserved, HL corrupted
;
@EB41	DCR	C
	DCR	C
	JZ	UT_ERROR	; Error if only 1 addr given
	POP	H	; Get returnaddr fromn stack
	XTHL		; haddr window in HL
	SHLD	UTWK2	; Save haddr
	POP	H	; Returr addr from stack
	XTHL		; laddr window in HL
	SHLD	UTWK3	; Save laddr
	INR	C
	RZ		; Ready if only window given
;
; If startaddress given
;
	DCR	A	; A=FF
	POP	H	; Get returnaddr fron stack
	POP	D	; Get startaddr program in DE
	PCHL		; Return
;
; *******************************
; * GO/LOOK: CHECK FOR CAR. RET *
; *******************************
;
; Entry: B: character to be checked
; Exit:  AF corrupted, BCDEHL preserved
;
LEB56	MOV	A, B	; Get 1ast char typed in
	SUI	$0D
	JNZ	UT_ERROR	; Error if not CR
	RET
;
; *********************
; * RESTART 0 (RST 0) *
; *********************
;
; The RST 0 function is used to operate 'LOOK'. Via a timer 1 interrupt, RST 0 is called.
; The vectoraddress $EF5D must have been initialised by a Z2 or Z3 command.
;
; On entry, HL and PC are on stack (see 0000-0007)
;
LEB5D	PUSH	PSW
	NOP
	LDA	UTWK1	; Get stored EI/DI
	SUI	$FB
	JZ	@EB6C	; Jump if EI stored
	MVI	A, $01	; Else: Set int. massk
	STA	TIC_IM	; for timer 1 only
;
; Save all registers in RAM area
;
@EB6C	EI
	POP	PSW	; Restore PSW
	POP	H	; Restore HL
	SHLD	HLSAV	; Save HL
	PUSH	PSW
	PUSH	B
	PUSH	D
	POP	H
	SHLD	DESAV	; Save DE
	POP	H
	SHLD	BCSAV	; Save BC
	POP	H
	SHLD	AFSAV	; Save PSW
	POP	H
	SHLD	PCSAV	; Save PC
;
; Check if PC points to UTWK4+1 or +2
;
	LXI	D, $FFB3
	DAD	D
	XCHG		; DE = PC + $FFE3 ( = PC - UTWK4 + 1)
	LHLD	IADR	; Get addr where to continue
	MOV	A, D
	ORA	A
	JNZ	@EB98	; Jump if out of interrupt routine
	ORA	E
	CPI	$04
	JC	LEC3E	; Jump if PC = 004D-4E
;
; Put returnaddress on stack if current instruction is a RST or a CALL instruction
;
@EB98	MVI	B, $C7
	MOV	A, M	; Get instr code of next instr
	CPI	$CD
	JZ	@EBAC	; Jump if it is a CALL
	ANA	B	; Check if it is a RST
	CMP	B
	JZ	@EBAE	; Then jump
	MOV	A, M	; Get instr code
	ANA	B	; Check if it is a conditional1 CALL
	CPI	$C4
	JNZ	LEBB0	; Jump if not
@EBAC	INX	H
	INX	H
@EBAE	INX	H
	XTHL		; Addr next instr on stack if it was a RST or CALL
;
; Check if current instruction is inside window
;
LEBB0	LXI	H, $0000
	DAD	SP
	SHLD	SPSAV	; Save SP
	CALL	LEDE7	; Exchange bytes in reg. save area
	LHLD	IADR	; Get adcdr current instr
	XCHG		; in DE
	LHLD	UTWK3	; Get laddr window
	CALL	LEC45	; Compare DE-HL
	JM	LEBDC	; Jump if addr outside window
	LHLD	UTWK2	; Get haddr window
	CALL	LEC45	; Compare DE-HL
	JNC	LEBDC	; Jump if addr outside window
;
; Print registers contents if address inside window
;
	CALL	LCRLF	; Print car. ret
	LXI	D, IADR	; Startaddr reg. save area
	LXI	H, LEE9C	; Startaddr symbol table
	CALL	LEE44_3	; Print reg. contents
LEBDC	CALL	UT_BREAK	; Scan for Break pressed; evt run Break
	LHLD	PCSAV	; Get addr next instr
;
; Disable UT to trace itself. Entry from init, RST 0.
; HL is address where to continue.
;
LEBE2	MVI	A, $EA
	CMP	H	; Check if hibyte = $EA
	JNZ	LEBEE	; Jump if not
	MVI	A, $0D
	CMP	L	; Check if lobyte = $0D
	JZ	UT_ERROR	; Then go to Error
;
; Check if next opcode is RST or EI/DI
;
LEBEE	DI
	SHLD	IADR	; Save addr current instr
	LXI	D, UTWK4
	XCHG
	SHLD	PCSAV	; Set addr next instr = 004C
	XCHG
	MOV	A, M	; Get opcode of instr
	ANI	$C7
	CPI	$C7
	JZ	LEC33	; Jump if RST
	LDA	TICIM	; Get int. mask
	CALL	LEF3E	; Store it in TIC; set A=0
	STA	UTIAD	; Reset timer 1 (trap immediate)
	MOV	A, M	; Get opcode of instr
	ANI	$F7	; Check if EI or DI
	SUI	$F3
	MOV	A, M	; Get inst code
	XCHG		; HL = UTWK4
	MVI	M, $FB	; Load EI in UTWK4
	MVI	C, $03	; 3 instr bytes to be 1oaded into #004D-F
	JZ	LEC2C	; Jump if instr is EI/DI
;
; Load next instruction starting form UTWK4 + 1
;
LEC19	LDAX	D	; Get instr code
LEC1A	INX	H
	MOV	M, A	; Store starting from UTWK4 + 1
	INX	D
	DCR	C
	JNZ	LEC19	; Next byte of instr
;
; Run LOOK: Register contents:
;
;   If 'normal instr': UTWK4  : EI
;                      UTWK4+1: next instruction
;
;   If RST *:	   UTWK4  : RST
;                      UTWK4+1: data **
;                      UTWK4+2: RST 0
;
;   If EI/DI:          UTWK4  : EI
;                      UTWK4+1: NOP
;                      UTWK4+2: Next instruction
;                        This may cause problems, because 0050 is LOOK init flag
;
	CALL	LEF30	; XRA A; LXI H,  UTWK5
	CMP	M	; Check 1ook f1ag
	MOV	M, A	; Reset f1ag
	JZ	LEC63	; If not Look init: restore CPU reg; cont on (PCSAV/E) = UTWK4
	JMP	LED9C	; Else: Restore TIC/GICC/CPU reg/int.mask and 'GO' to (PCSAV/E) = UTWK4
;
;  If instruction is EI or DI
;
LEC2C	STA	UTWK1	; Store EI/DI instr
	XRA	A
	JMP	LEC1A	; Load $00 in #004D, next instr in 004E-0050
;
; If a RST instruction
;
LEC33	XCHG		; HL = UTWK4
	MVI	C, $02	; Only 2-byte instruction
	MVI	A, $C7
	STA	UTWK4+2	; Set (004E) = $C7 (= RST 0)
	JMP	LEF44	; RST*/data ** in UTWK4/D
;
; If PC points to UTWK4+1-004E
;
LEC3E	DAD	D	; Set HL = 0000-0001. This may cause re-entry: problems due to stack manipulation
	SHLD	PCSAV	; Save addr next instr (pnts to RST0)
	JMP	LEBB0
;
;
; **********************
; * COMPARE DE WITH HL *
; **********************
;
; Exit: AF corrupted, BCDEHL preserved
;       HL > DE : A=-1, CY=1, Z=0, S=1
;       HL = DE : A= 0, CY=0, Z=1, S=0
;       HL < DE : A= 1, CY=0, Z=0, S=0
;
LEC45	MOV	A, E
	SUB	L
	MOV	A, D
	SBB	H
	SBB	A
	RM		; If HL>DE: A=1, S=1
	MOV	A, E
	XRA	L
	PUSH	D
	MOV	E, A
	MOV	A, D
	XRA	H
	ORA	E
	POP	D
	STC
	RZ		; If HL=DE: A=0, Z=CY=1
	XRA	A
	INR	A
	RET		; If HL<DE: A=1, CY=0
;
; ************************************
; * DECREMENT HL, COMPARE HL WITH DE *
; ************************************
;
; HL = HL - 1.
;
; Exit: AF corrupted, BCDEHL preserved
;       HL was 0: CY=1, Z=1
;       Else:     New HL > DE : CY=0
;                 New HL = DE	: Z=1
;                 New HL < DE : CY=1
;
LEC58	DCX	H
	MOV	A, H
	ANA	L
	ADI	$01
	RC		; Ready if old HL was 0
	MOV	A, L	; Compare HL - DE
	SUB	E
	MOV	A, H
	SBB	D
	RET
;
; *************************
; * RESTORE CPU REGISTERS *
; *************************
;
; Restores CPU registers AFBCDEHL and PC.
; Continues at PC address.
; Stackpointer, TICC and GIC are not restored!
;
LEC63	CALL	LEDE7	; Exchange bytes in reg. save area
LEC66	LHLD	AFSAV	; Get stored PSW
	PUSH	H
	POP	PSW	; Restore PSW
	LHLD	BCSAV
	MOV	B, H
	MOV	C, L	; Restore BC
	LHLD	DESAV
	XCHG		; Restore DE
	LHLD	PCSAV
	PUSH	H	; Addr next instr on stack
	LHLD	HLSAV	; Restore HL
	RET		; Goto addr in (PCSAV/E)
; *
; *********************
; * CALCULATE DE - HL *
; *********************
;
; Exit: HL = DE - HL
;       BCDE preserved, AF corrupted
;
LEC7C	MOV	A, E
	SUB	L
	MOV	L, A	; L = E - L
	MOV	A, D
	SBB	H
	MOV	H, A	; H = D - H - CY
	RET
;
; ************
; * M - MOVE *
; ************
;
; Moves a block of data (laddr - haddr ) given to a given destination address (daddr).
;
; Exit: BC: 1st unused destination address
;       DE: last source address for direction of movement
;       HL: 1st unused source address
;       AF: corrupted
;
MOVEK	MVI	C, $03	; Nr of addr allowed
	CALL	ADARG	; Get addr on stack
	DCR	C	; addr given?
	JP	UT_ERROR	; Error if not
	POP	B	; daddr in BC
	POP	D	; haddr in DE
	POP	H	; laddr in HL
	PUSH	H	; Save laddr on stack
	CALL	LEC7C	; Calc 1ength of block to be moved
	JC	UT_ERROR	; Error if wrong inputs
	XTHL		; laddr in HL, 1ength on stack
	MOV	A, C	; Check if daddr < laddr
	SUB	L
	MOV	A, B
	SBB	H
	JC	@ECAE
;
; If daddr > laddr
;
	XTHL		; length in HL laddr on stack
	DAD	B	; daddr of highest byte
	MOV	B, H	; store it in BC
	MOV	C, L
	POP	H	; laddr in HL
	XCHG		; DE: laddr, HL: haddr
@ECA4	MOV	A, M	; Get byte to be moved
	STAX	B	; Move it
	DCX	B	; Decr pntr daddr
	CALL	LEC58	; Check if ready
	RC		; Then quit
	JMP	@ECA4	; Next byte
;
; If daddr < laddr
;
@ECAE	XTHL		; Length in HL, laddr on stack
	POP	H	; laddr in HL
@ECB0	MOV	A, M	; Get byte
	STAX	B	; And move it
	INX	B	; Intr pntr daddr
	CALL	INXCK	; INX H; check if ready
	RC		; Then guit
	JMP	@ECB0	; Next byte
;
; *************
; * Z - RESET *
; *************
;
; Z1: Reset CPU save area IADR-PCSAV. Initialise stackpainter to $F900 and save it in $003B/C.
;
; Z2: Sets: current interrupt mask (TICIM) = $C5
;           TICC control word (TICC_CW) = $FC
;           GIC  control word (GIC_CW) = $1B
;     Initialises interrupt vector area #0062-#0071.
;     Sets interrupt vector RST 0 o to $EB5D.
;
; Z3: Z1 + Z2
;
; Exit: all registers corrupted
;
ZEROK	MVI	C, $01	; Nr of databytes allowed
	CALL	ADARG	; Get hexnr and store it on stack
	POP	H	; Get hexnr from stack
	MOV	A, L	; into A
	PUSH	PSW	; Save it again
	ANI	$02
	JZ	@ECE9	; Jump if Z1 only
;
; If Z2 or Z3
;
	MVI	A, $C5	; Set interrupt mask for clock, keyb, ext. timer 1
	STA	TICIM	; Preserve int.mask
	MVI	A, $F4
	NOP
	NOP
	NOP
	ORI	$08
	LXI	H, TICC_CW
	MOV	M, A	; Set TICC contr.word = $FC
	INX	H
	MVI	M, $1B	; Set GIC contr. word 1B
	CALL	INTSU	; Init int.vector addr
	LXI	H, LEB5D
	SHLD	I0USA	; Set RST0 vector LEB5D
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
@ECE9	POP	PSW	; Get nr Z instr back
	RAR		; Check for Z2 only
	RNC		; Ready if Z2 only
;
; If Z1 or Z3
;
	MVI	C, $00
	LXI	D, PCSAV+1	; Init reg. save area
	LXI	H, IADR
	CALL	FILLMEM	; Fill (GO51-0O5E) with 00
	LXI	H, $F900
	SPHL		; Set SP=F900
	SHLD	SPSAV	; Save SP
	JMP	LEA42	; Return for new inputs
;
; ***************
; * PRINT SPACE *
; ***************
;
; Exit: AFC corrupted, BDEHL preserved
;
TSP	.equ	*
LSF	MVI	C, ' '
	JMP	LEEB4	; Print space
;
; **********************************
; * SCAN KEYBOARD, PRINT CHARACTER *
; **********************************
;
; Gets a keybaard input. Zeroes are ignored.
; The character is printed (if not 'ESC').
;
; Exit: A : Character typed in.
;       Other registers preserved
;
CIE	CALL	LEEB8	; Scan keyboard
	ANI	$7F	; Skip bit 7
	JZ	CIE	; Ignore zeroes (await an input)
	CPI	$12	; ESC?
	PUSH	B
	MOV	C, A	; Char in C
	CNZ	LEEB4	; Print char if not 'ESC'
	MOV	A, C	; Char in A
	POP	B
	RET
;
; **************************
; * PRINT ADDRESS IN ASCII *
; **************************
;
; LADDR: An address in HL is converted to ASCII and printed (4 nibbles).
; LBYTE: A 1-byte value is printed in ASCII.
;
; Entry: LADDR: address in HL
;        LBYTE: value in A
; Exit:  AFC corrupted, BDEHL preserved
;
LADDR	MOV	A, H	; Hibyte in A
	CALL	LBYTE	; Print both nibbies in ASCIII
	MOV	A, L	; Lobyte in A
LBYTE	PUSH	PSW	; Preserve hex value 2 char
	RLC		; Move hinibble into 1onibble
	RLC
	RLC
	RLC
	CALL	@ED26	; Print lonibble
	POP	PSW	; Restore byte
@ED26	ANI	$0F	; Lonibble only
	CALL	LED40	; Convert it to ASCII
	MOV	C, A	; And store it in C
	JMP	LEEB4	; Print char in C
;
; ****************
; * PRINT STRING *
; ****************
;
; Entry: HL points to string. End of string is $00
; Exit:  HL points to $00 at end of string
;        AFC corrupted, BDE preserved
;
LED2F	MOV	A, M	; Get byte from string
	MOV	C, A	; into C
	ORA	A	; Byte = $00?
	RZ		; Then ready
	CALL	LEEB4	; Print char in C
	INX	H	; Pnts to next char
	JMP	LED2F	; Print next char
;
; *************************
; * PRINT CARRIAGE RETURN *
; *************************
;
; Exit: AFC corrupted, BDEHL preserved
;
LCRLF	MVI	C, $0D
	CALL	LEEB4	; Print 'CR'
	RET
;
; *******************************
; * CONVERT HEX NIBBLE TO ASCII *
; *******************************
;
; Entry: Hex value in A
; Exit:  ASCII value in A
;        BCDEHL preserved
;        F corrupted
;
LED40	ADI	$30	; Convert
	CPI	$3A	; Number 0-9?
	RC		; Then ready
	ADI	$07	; Convert A-F
	RET
;
; ************
; * F - FILL *
; ************
;
; Fills a memory area between given boundaries with given data.
;
; Exit: CY=1. Al1 registers corrupted
;
FILLK	MVI	C, $03	; Nr of addr/data allowed
	CALL	ADARG	; Get addr/data on stack
	DCR	C	; 3 blocks given?
	JP	UT_ERROR	; Error if not
	POP	B	; Data in C
	POP	D	; haddr in DE
	POP	H	; laddr in HL
FILLMEM	MOV	M, C	; Data into memory
	CALL	INXCK	; INX H; check if ready
	RC		; Then quit
	JMP	FILLMEM	; Fill next addr
;
; ******************
; * S - SUBSTITUTE *
; ******************
;
SUBSK	MVI	C, $01	; Nr of addr allowed
	CALL	ADARG	; Set addr on stack
	POP	H	; Addr in HL
@ED62	MOV	A, M	; Get contents of addr
	CALL	LBYTE	; Frint it in ASCII
	XRA	A
	CALL	LEE6A	; Evt. modify contents
	JNC	@ED62	; Next addr
	RET
;
; ***************
; * E - EXAMINE *
; ***************
;
EXAMK	LXI	H, LEE9C+1	; Startaddr register table
	LXI	D, AFSAV	; Startaddr CPU save area
	JMP	LEE39	; Go to display routine
;
; **********************
; * V - VECTOR EXAMINE *
; **********************
;
VECXK	LXI	H, LEEA8	; Startaddr vector table
	LXI	D, TICIM	; Startaddr vector area
	JMP	LEE39	; Go to display routine
;
; ************************************
; * INCREMENT HL AND COMPARE WITH DE *
; ************************************
;
; Exit: HL was $FFFF: CY=1, Z=1
;       Else: New HL < DE : CY=0
;             New HL = DE : Z=1
;             New HL > DE : CY=1
;       BCDE preserved, HL=HL+1, AF corrupted
;
INXCK	INX	H
	STC		; CY=1
	MOV	A, H
	ORA	L
	RZ		; Abort if new HL is 0000
	MOV	A, E
	SUB	L
	MOV	A, D
	SBB	H
	RET
;
; **********
; * G - GO *
; **********
;
; Reads one field if given.
; If no field given: Restores CéU registers, goes to PC address. Returnaddress is $EA42 (into command 1oop).
; 1f field given: Saves it as PC, initialises TICC and GIC. Returnaddress is $EA04. Goes to the given address.
; REMARK: The stackpointer is never restored!
;
GOK	MVI	C, $01
	CALL	ADART	; Scan keyb; addr on stack
	DCR	C	; No addr given?
	PUSH	PSW
	CZ	LEB56	; Then check if 'CR'
	POP	PSW
	JZ	LEC63	; No addr: restore CPU reg (but not SP/TICC/GIC!) and go to addr in PCSAV/E
	POP	H	; GO addr in HL
	SHLD	PCSAV	; Save it
LED9C	LHLD	TICC_CW	; Get GIC/TICC init values
	MOV	A, H	; GIC init value in A
	CALL	LEDD5	; Init GIC
	MOV	A, L	; TICC init value in A
	CALL	LEDB7	; Init TICC
	LDA	TICIM	; Get current int mask
	STA	TIC_IM	; Set int mask
	CALL	LEDE7	; exch. bytes in IADR-5E
	LXI	H, LEA04	; Returnaddr for 'GO'
	PUSH	H	; Save $EA04 on stack
	JMP	LEC66	; Restore CPU reg and 'GO'
;
; INITIALISE TICC
;
; Entry: A: Initial value TICC command word ($FC)
; Exit:  AFBC corrupted, DEHL preserved
;
LEDB7	MOV	B, A	; Init. value in B
	RLC		; A=$F9
	PUSH	PSW	; On stack: A=F9, CY=1
	RLC		; A=$F3
	RLC		; A=$E7
	RLC		; A=$CF
	ANI	$07	; A=$07
	MOV	C, A	; C=$07
	XRA	A	; A=$00
	STC		; CY=1
@EDC2	RAL		; On exit: A=$80, C=$FF, CY=0
	DCR	C
	JP	@EDC2
	MOV	C, A	; C=$80
	POP	PSW	; A=$F9, CY=1
	MOV	A, C	; A=$8O
	RAR		; A=$C0
	STA	TIC_RR	; Set comn.rate reg for 9600 baud, 1 stop bit
	MOV	A, B	; A=$FC
	ANI	$0F	; A=$0C
	STA	TIC_CM	; Set cmd reg for IN7, INTA enable
	RET
;
; INITIALISE GIC
;
; This initialisation cancels the initial setting done during 'power-on' by 3EF90.
; Only used during 'GO'.
;
; There seems to be some bug in the routine. All ports are set to input, and then data is
; written into one of this ports (PB - FE01). The function of @EDE0 is nonsense (?!).
;
; Entry: A: Initial value GIC command word ($1B)
; Exit:  AFBC corrupted, DEHL preserved
;
LEDD5	PUSH	PSW	; Init value on stack, CY=0
	LXI	B, GIC_CM	; Addr command word
	ORI	$80	; A=$9B
	STAX	B	; Set al1 ports to input
	DCR	C	; BC = GIC_C
	POP	PSW	; A=$1B, CY=0
	RLC		; A=$36, CY=0
	SBB	A	; A=$00
@EDE0	DCX	B	; BC=GIC_B
	STAX	B	; (FE01) = $00 (?!)
	DCR	C	; BC=GIC_A
	JP	@EDE0	; Writes 00 in non-existing address $FDFE (?!)
	RET
;
; ***************************************
; * EXCHANGE BYTE IN REG1STER SAVE AREA *
; ***************************************
;
; The hibytes and the 1obytes of the addresses AFSAV thru HLSAV are exthanged
; which each other.
;
; Exit: AFBCHL corrupted
;       DE preserved
;
LEDE7	LXI	H, AFSAV	; Startaddr
	MVI	A, $04	; Nr of addr to be exchanged
@EDEC	MOV	B, M	; 1st byte in B
	INX	H	; Pnts to next location
	MOV	C, M	; 2nd byte in C
	MOV	M, B	; 1st byte in 2nd location
	DCX	H
	MOV	M, C	; 2nd byte in 1st location
	INX	H
	INX	H	; Points to next addr
	DCR	A	; Update counter
	JNZ	@EDEC	; Next addr if not ready
	RET
;
; ********************************
; * PRINT CONTENTS CPU SAVE AREA *
; ********************************
;
; Entry: HL: Points to register save area.
;        msb A = 0: 1 byte to be printed
;        msb A = 1: 2 bytes to be printed
; Exit:  msb A = 0: AFC corrupted, BDEHL preserved
;        msb A = 1: AFCDE corrupted, BHL preseryed
;
LEDF9	ORA	A	; Test f1ags
	MOV	A, M	; Get contents save area
	JP	LBYTE	; 1 byte: print it in ASCII
;
; If 2 bytes
;
	MOV	E, M	; Get contents in E
	INX	H	; Next addr
	MOV	D, M	; Its contents in D
	DCX	H	; Restore HL
	PUSH	H	; Save it on stack
	XCHG		; Contents addr in HL
	CALL	LADDR	; Print 2 bytes in ASCII
	POP	H	; Restore HL
	RET
;
; ****************************************
; * V+X: PRINT ROUTINE IF REGISTER GIVEN *
; ****************************************
;
; Entry: HL: Startaddress symbol table
;        DE: Startaddress CPU save area
;        A:  last input character
; Exit:  all registers corrupted
;
LEE09	MOV	B, A	; Last input in B
	CALL	LED01	; Print space
@EE0D	MOV	A, M	; Get symbol from table
	ANI	$7F	; Skip bit 7
	JZ	UT_ERROR	; Error if symbol=0
	CMP	B	; Compare input with symbol
	JZ	@EE22	; Jump if identical
	MOV	A, M	; Get symbol
	RLC		; Check for msb set
	INX	H	; Next symbol
	INX	D	; Next memory area
	JNC	@EE0D	; Try next symbol
	INX	D	; Next mem. area for '2 byte' symbols
	JMP	@EE0D	; Try again
;
;  If symbol found
;
@EE22	PUSH	D	; Save addr in mem. area
@EE23	MOV	A, M	; Get symbol
	XTHL		; HL addr mem. area; stack: addr symbol
	PUSH	PSW	; Save symbol
	CALL	LEDF9	; Print contents mem. area
	POP	PSW	; Retrieve symbol
	CALL	LEE6A	; Exchange mem.contents, go to next one
	JC	@EE37	; Jump if 'ESC'
	XTHL		; HL: addr symbo1, stack: next mem. area
	INX	H	; addr next symbol
	MOV	A, M	; Get symbol
	ORA	A	; Set f1ags
	JNZ	@EE23	; Not all symbols done
;
@EE37	POP	D	; Retrieve next mem.area
	RET
;
; ************************
; * V+X: DISPLAY ROUTINE *
; ************************
;
; Displays registers at succesive memory 1ocations.
;
; Entry: DE: startaddress memory area to be displayed
;        HL: startaddress symbol table
; Exit:  all registers corrupted
;
LEE39	CALL	CIE	; Scan keyb, print char
	CPI	$0D	; 'CR'?
	JNZ	LEE09	; Jump if also byte given
;
; If only 'V' or 'X'
;
	NOP
	NOP
	NOP
LEE44_3	PUSH	D	; Save startaddr mem area
	MOV	C, M	; Get symbol in c
	CALL	LEEB4	; Print symbol
	MVI	C, '='
	CALL	LEEB4	; Print '='
	MOV	A, M	; Get symbol in A
	ORA	A	; Check flags
	XTHL		; HL: startaddr mem. area; stack: startaddr symbol table
	PUSH	PSW	; Save symbol + flags
	CALL	LEDF9	; Print contents mem. area
	POP	PSW	; Retrieve symbol and f1ags
	INX	H
	JP	@EE5B	; Jump if '1 byte' symbol
;
; If 2-byte symbol
;
	INX	H
 @EE5B	NOP
	NOP
	NOP
	XTHL		; HL: addr symbol; stack: addr next mem. area
	INX	H	; Next symbol
	POP	D	; Get addr next mem. area
	MOV	A, M	; Get symbol
	ORA	A
	RZ		; Quit if ready
	CALL	LED01	; Print space
	JMP	LEE44_3	; Next one
;
; *****************************
; * V+X: EVT. MODIFY CONTENTS *
; *****************************
;
; Entry: HL: memory address.
;        A:  symbol
LEE6A	ORA	A	; Set flags on symbo1
	PUSH	PSW	; and save it
	MVI	C, '-'
	CALL	LEEB4	; Print '-'
	PUSH	H	; Save addr mem.area
	MVI	C, $01	; Nr of datablocks allowed
	CALL	ADART	; Get input on stacks; 1ast byte typed in B
	DCR	C
	JZ	@EE87	; Jump if incorrect input
	POP	D	; Data typed in in DE
	POP	H	; Set addr mem. area
	POP	PSW	; Get symbol and f1ags
	MOV	M, E	; Change memory contents
	JP	@EE8D	; Jump if '1 byte' symbol
;
; If 2-byte symbol
;
	INX	H
	MOV	M, D	; Change 2nd byte
	JMP	@EE8D
@EE87	POP	H	; Retrieve addr mem. area
	POP	PSW	; Retrieve symbol + flags
	JP	@EE8D	; If '1 byte' symbol
	INX	H	; Add. INX H  if 2-byte symbol
@EE8D	INX	H	; Next mem. area
	MOV	A, B	; Get 1ast input
	CPI	$0D
	RZ		; Ready if 'CR'
	CPI	' '
	RZ		; Ready if 'SP'
	CPI	$12
	STC		; Abort with CY=1 if 'ESC'
	RZ
	JMP	UT_ERROR	; Else: wrong input error
;
; ****************************
; * SYMBOL TABLE EXAMINE (X) *
; ****************************
;
; The msb is '1' for symbols of two-byte registers.
;
LEE9C	.byte	$C9	; I (addr current instr)
	.byte	$41	; A
	.byte	$46	; F (f1ags)
	.byte	$42	; B
	.byte	$43	; C
	.byte	$44	; D
	.byte	$45	; E
	.byte	$48	; H
	.byte	$4C	; L
	.byte	$D3	; S (stackpointer)
	.byte	$D0	; P (program counter)
	.byte	$00
;
; *******************************
; * SYMBOL TABLE VECTOR EXAMINE *
; *******************************
;
; The msb is '1' for symbols of two-byte registers.
;
LEEA8	.equ	*
	.byte	$4D	; M (TICC int mask)
	.byte	$54	; T (TICC cmd + comm.reg)
	.byte	$47	; G (GIC cmd word)
	.byte	$B0	; Interrupt 0 vector address
	.byte	$B1	; Interrupt 1 vector address
	.byte	$B2	; Interrupt 2 vector address
	.byte	$B3	; Interrupt 3 vector address
	.byte	$B4	; Interrupt 4 vector address
	.byte	$B5	; Interrupt 5 vector address
	.byte	$B6	; Interrupt 6 vector address
	.byte	$B7	; Interrupt 6 vector address
	.byte	$00
;
; *******************
; * PRINT CHARACTER *
; *******************
;
; Entry: C: Character to be printed
; Exit:  AF corrupted
;        BCDEHL preserved
;
LEEB4	MOV	A, C	; Char in A
	JMP	SCCHR	; Print char
;
; ******************************
; * SCAN KEYBOARD IGNORE BREAK *
; ******************************
;
; Exit: character in A
;       BCDEHL preserved
;
LEEB8	CALL	LEF83	; Scan keyboard
	JC	LEEB8	; Ignore break
	JZ	LEEB8	; Wait for input
	RET
;
; ***********************************
; * SCAN KEYBOARD FOR BREAK PRESSED *
; ***********************************
;
; Exit: CY=0: No break
;       CY=1: Break pressed
;       A corrupted
;       BCDEHL preserved
;
UT_BREAK	CALL	ASKKEY	; Scan keyb for new inputs
	RNC		; abort if Break nat pressed
	JMP	ERRST	; Restore SP, wait for new inputs
;
;
; *********************
; * CASSETTE ROUTINES *
; *********************
;
LEEC9	JMP	WOPEN	; WOPEN
	.byte	$FF, $FF, $FF
LEECF	JMP	WBLK	; WBLK
	.byte	$FF, $FF, $FF
LEED5	JMP	WCLOSE	; WCLOSE
LEED8	JMP	ROPEN	; ROPEN
	.byte	$FF, $FF, $FF
LEEDE_	JMP	RBLK	; RBLK
LEEE1	JMP	RCLOSE	; RCLOSE
;
; *************
; * W - WRITE *
; *************
;
; Requires 2 address fields evt. name.
; Filetype is '1'. Writes startaddress of datablock + data + trailer on tape.
;
LEEE4	MVI	C, $02	; Nr of addr allowed
	CALL	ADARG	; Scan keyb, addr on stack
	DCR	C	; 2 addr given?
	JP	UT_ERROR	; Error if not
	CALL	LEF48	; Evt. name in input buffer
	MVI	A, $31	; File type byte
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	CALL	LEEC9	; Write file header on tape
	POP	D	; Get haddr from stack
	INX	D	; Incr it
	POP	H	; Get laddr from stack
	CALL	LEF63	; Write startaddr on tape
	MOV	A, E	; Calc 1ength of data block, result in DE
	SUB	L
	MOV	E, A
	MOV	A, D
	SBB	H
	MOV	D, A
	NOP
	CALL	LEECF	; Write datablock on tape
	CALL	LEED5	; Write file trailer
	RET
;
; ************
; * R - READ *
; ************
;
; One address is allowed. An evt. name is stored in the EBUF. Reads header, startaddress and
; data from tape. ErrorcheCk only on data.
;
; Exit: HL: 1st address above file 1oaded
;       BC: evt. offset
;       AFDE corrupted
;
RHEXK	MVI	C, $01	; Nr of addr allowed
	CALL	ADARG	; Scan keyb; addr on stack
	CALL	LEF48	; Evt name in input buffer
	MVI	B, $31	; File type byte
	NOP
	NOP
	NOP
	MVI	C, $00
	CALL	LEED8	; Read file header
	LXI	D, $F900	; Max addr to write data into
	POP	B	; Get evt offset from stack
	CALL	LEF74	; Read startaddr from tape
	DAD	B	; Add offset
	CALL	LEF8A	; Read data block + trailer
	JNC	UT_ERROR	; Print 'error' if reading error
	RET
;
; ***************************************
; * RST 0: POINTER TO 'LOOK'-FLAG IN HL *
; ***************************************
;
; Part of 3EC21.
;
; Exit: A=0
;       BCDE preserved
;
LEF30	XRA	A
	LXI	H, UTWK5
	RET
;
; ********************
; * INITIALISE RST 0 *
; ********************
;
; Entry: On stack: Returnaddress $EA42.
;
LEF35	MVI	A, $FB	; Instr code for EI in A
	STA	UTWK1	; Save it
	POP	D	; Get $EA42 in DE
	JMP	LEBE2	; Into RST 0
;
; **********************
; * SET INTERRUPT MASK *
; **********************
;
; Part of RST0 (3EC05).
;
; Entry: A: Value for TICC interrupt mask
; Exit:  A=0, F corrupted, BCDEHL preserved
;
LEF3E	STA	TIC_IM	; Set TICC int mask
	XRA	A	; A=0
	RET
;
	.byte	$FF
;
; *************************
; * Part of RST 0 (3EC3B) *
; *************************
;
LEF44	DCX	H
	JMP	LEC19	; Into RST 0
;
; *****************************
; * W+R: NAME IN INPUT BUFFER *
; *****************************
;
; Names > 126 characters destroy BASIC pointers.
;
; Entry: last character typed in, in B.
; Exit:  BCD preserved
;        HL points to EBUF
;        A= 0: no file name given
;        A<>0: file name given
;
LEF48	LXI	H, EBUF	; Startaddr EBUF
	MVI	E, $FF
	MOV	A, B	; Last char in A
	SUI	$0D	; 'CR'?
	MOV	M, A	; (13E) is 0 if CR
	RZ		; Quit if no name g1ven
;
; If name given
;
	PUSH	H	; Save startaddr EBUF
@EF53	INR	L	; Points to next 1oc
	INR	E	; Calc 1ength
	CALL	CIE	; Scan keyb, print char
	MOV	M, A	; Char into EBUF
	CPI	$0D
	JNZ	@EF53	; Next char if not 'CR'
	POP	H	; Retrieve startaddr EBUF
	MOV	M, E	; Store 1ength name in EBUF
	RET
;
; **************
; * (not used) *
; **************
;
LEF61	POP	H
	RET
;
; ******************************
; * WRITE STARTADDRESS ON TAPE *
; ******************************
;
; Entry: HL: Startaddress
; Exit:  AF corrupted
;        BCDEHL preserved
;
LEF63	PUSH	D
	PUSH	H
	SHLD	EBUF	; Startaddr in EBUF
	LXI	H, EBUF	; Startaddr to write from
	LXI	D, $0002	; Length
	CALL	LEECF	; Write addr on tape
	POP	H
	POP	D
	RET
;
; *******************************
; * READ STARTADDRESS FROM TAPE *
; *******************************
;
; Exit: HL: Startaddress
;       CY=1: No reading error
;       CY=0: Reading error, errorcode in A
;       BCDE preserved
;
LEF74	PUSH	D
	LXI	H, EBUF	; Addr EBUF
	LXI	D, EBUF+3	; Addr after addr in EBUF
	CALL	LEEDE_	; Read block from tape
	POP	D
	LHLD	EBUF	; Startaddr in HL
	RET
;
; *****************
; * SCAN KEYBOARD *
; *****************
;
; Part of 3EEB8. Scans keyboard. Returns any key received.
;
; Exit: A: Key received.
;       BCDEHL preserved
;       CY=1: break pressed
;
LEF83	XRA	A
	STA	KNSCAN	; Enable complete keyb scan
	JMP	GETC	; Scan keyboard
;
; ************************
; * READ DATA FROM TAPE *
; ************************
;
; Part of READ (3EF29).
;
LEF8A	CALL	LEEDE_	; Read block from tape
	JMP	LEEE1	; Stop reading
;
; ******************************
; * DCE INITIALISATION ROUTINE *
; ******************************
;
; Part of RESET (C719). Bootstrap for disc drive. Sets GIC in initialisation status.
; Checks if any input is received from the DCE-bus and performs the received instructions.
;
; Exit: A=$EE if no DCE-inputs available
;
LEF90	MVI	A, $98
	STA	GIC_CM	; PA+PCH in, PE+PCL out
	MVI	A, $07
	STA	GIC_CM	; PC3=1
	MVI	A, $01
	STA	GIC_B	; Output PB: 01
	MVI	A, $01
	STA	GIC_CM	; PCO=1
	LXI	B, $1000
@EFA7	LDA	GIC_C	; Get input from PCH
	ANI	$20	; Bit 5 only
	JNZ	LEFB8	; Jump if inputs received
;
;  If no inputs
;
	DCX	B	; Wait 1oop until C=$10
	MOV	A, B
	ORA	C
	JNZ	@EFA7
	MVI	A, $EE	; A=$EE if no inputs
	RET
;
; DCE BOOTSTRAP INPUT ROUTINE:
;
; Loads MLP inputs from the DCE-bus into the stackbottom and goes to it.
;
LEFB8	LXI	D, STKBGN	; Addr stackbottom
@EFBB	MVI	A, $05
	STA	GIC_CM	; PC2=1
@EFC0	LDA	GIC_C	; Get input from PC
	ANI	$80	; Bit 7 only
	JZ	@EFC0	; Wait for change to high
	LDA	GIC_A	; Get input from PA
	STAX	D	; Save input in stack area
	INX	D	; Point to next 1oc
	MVI	A, 4
	STA	GIC_CM	; PC2=0
@EFD2	LDA	GIC_C	; Get input from PC
	ANI	$80	; Bit 7 only
	JNZ	@EFD2	; Wait for change to low
	LDA	GIC_C	; Get input from PC
	ANI	$20	; Bit 5 only
	JNZ	@EFBB	; Again if high
	MVI	A, $06
	STA	GIC_mC	; LFE3E hardwarewise read as FE02). PC=06
@EFE7	LDA	GIC_C	; Get input from PC
	ANI	$20	; Bit 5 only
	JZ	@EFE7	; Wait for change to high
	JMP	STKBGN	; Go to stackbottom
;
	.byte	$FF, $FF
;
; *********************
; * SCAN 'DINC' INPUT *
; *********************
;
; Part of 3E935. Default 'DINC' is RS232 input.
;
LEFF4	CALL	CINC	; Get input from DINC
	JZ	LE935	; Scan keyb if no DINC input
;
;  If inputs from DINC
;
	MVI	A, $01
	STA	INSW	; Set INSW for DINC input
	RET
;
end_rom3	.equ	*
