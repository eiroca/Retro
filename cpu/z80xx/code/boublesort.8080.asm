; Bouble Sort 
; 
; compiled with RetroAssembler

	.target	"8080"
	.format	"sbin"
	
	.org	$1000

	lxi	H, DATA
	lda	DATA_LEN
	call	sort_b
	hlt

;data
DATA_LEN:	.byte 4
DATA:	.byte 4, 6, 2, 5

; BoubleSort of a byte array
; Input: A len of the array
; Input: HL pointer of the array
; preserves: A, HL
; destroys: F, BC, DE
sort_b:	ora	a
	rz		; 0 elements to sort, return
	mov	e, a
	dcr	e
	rz		; 1 elements to sort, return
	push 	psw
	push	h
@NewLoop:	mov	c, e
	mvi	d, $00	; D flag to track swaps
@ChkLoop:	mov	a, m	; compare (HL) and (HL+1) 
	inx	h
	cmp	m
	jc	@Skipswp
	mov	b, m	; Swap data
	mov	m, a
	dcx	h
	mov	m, b
	inx	h
	mvi	d, $01
@SkipSwp:	dcr	c
	jnz	@ChkLoop	; If comparision count C != 0 loop
	pop	h	; Recover base array pointer
	dcr	e
	jz	@Exit
	mov	a, d	; Swap done?
	rrc
	push	h
	jc	@NewLoop
@Exit:	pop	psw
	ret
