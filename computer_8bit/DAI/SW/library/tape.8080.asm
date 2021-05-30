; DAInamic 22 - May/June 1984
;
; Berlin, 8/12/1983
; Use this program to write memory-contents to, or read 
; them from, tape under use of the Basic or with ML-programs.
;
; Writing:
; in basic first do a ) INPUT NAME$:P0KE$13F,LEN(NAME§) 
; (in order to put a name for the tape-sequenze into the input
; buffer. Don't worry about, the stringname, it will not be used.
; Using this program from a ML-program, you have to put the name 
; directly into the input buffer which has to be bilt up in the 
; following form:
; $13E: $19 
; $13F: length of name
; $140 - $1BD : name
; Afterwards poke the begin-address of the memory area, which 
; has to be written on tape, into memory location ADR1 (low 
; byte first). In the same way you put the enda dress into ADR2. 
; Then the program is started with CALLM WRITE. 
; (You find the values of ADR1, ADR2 and WRITE in the Symbol Table).
;
; Reading: 
; Put the tape-sequenze-name into the input-buffer like discribed 
; above. Then poke the offset for reading from tape (same meaning 
; like T xxxx in utility) into OFFSET like described above.
; The program is started with CALLM READ. 
; (You find READ in the Symbol Table).
;

; Writing a memory-area on tape
INBUF	.equ	$013f	; start address input-buffer
BSW1	.equ	$0040	; bank-switch address 1
BSW2	.equ	$FD06	; bank-switch address 2
Bank0	.equ	$30	; code for bank 0
Bank3	.equ	$F0	; code for bank 3

	.org	$0400	; start of WRITE
WRITE	push	PSW
	push	H
	push	B
	push	D
	mvi	A, Bank3	; switch bank 3
	sta	BSW1
	sta	BSW2
	lxi	H, FORT1	; store address for
	push	H	; continuing after writing
	lhld	ADR2	; load endaddress
	xchg		; into DE
	lhld	ADR1	; begin address into HL
	push	H	; store them
	push	D
	lxi	H, INBUF	; start input-buffer
	jmp	$EEF0	; call WRITE in ROM
FORT1	mvi	A, Bank0	; switch bank 0
	sta	BSW1
	sta	BSW2
	pop	D
	pop	B
	pop	H
	pop	PSW
	ret
ADR1	.word	0
ADR2	.word	0

READ	push	PSW	; start of read
	push	H
	push	B
	push	D
	mvi	A, Bank3	; switch bank 3
	sta	BSW1
	sta	BSW2
	lxi	H, FORT2	; store address for
	push	H	; continuing after reading
	lhld	OFFSET	; load offset into HL
	push	H	; store it
	lxi	H, INBUF	; start address input-buffer
	jmp	$EF17	; call READ in ROM
FORT2	mvi	A, Bank0	; switch bank 0
	sta	BSW1	; store offset here
	sta	BSW2
	pop	D
	pop	B
	pop	H
	pop	PSW
	ret
OFFSET	.word	0
