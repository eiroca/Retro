;Program to convert BCD to binary (8-bit)
; 
; compiled with RetroAssembler

	.target	"8080"
	.format	"sbin"
	
	.org	$1000

	lda	bcd	;load the bcd number
	call	bcd2bin
	sta	bin
	hlt

bcd:	.byte	$99
bin:	.byte	$00

; Input  A in BCD format
; Output A in binary format
; destroys BC
; no checks if BCD is valid
bcd2bin:	mov	b, a
	ani	$F0	; tens bcd part
	jz	less10
	rlc		; convert to tens and keep it in "c"
	rlc
	rlc
	rlc
	mov	c, a
	mov	a, b
	ani	$0F	; units
	mvi	b, 10	; do tens x 10 
@loop	add	b
	dcr	c
	jnz	@loop
	ret
less10:	mov	a, b
	ret

