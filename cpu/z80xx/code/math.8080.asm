; Electronics/February 24, 1982
;
; Divides 32 bit (HL-DE) by 16bit (BC). Quotient in DE, remainder in HL. cy for DE overflow
; Take up to 1745 clock cycles (worst case)
DIV	mov	A, L	; check for overflow
	sub	C
	mov	A, H
	sbb	B
	rnc		; return on overflow
	mov	A, B	; 2's complement bc
	cma
	mov	B, A
	mov	A, C
	cma	
	mov	C, A
	inx	b
	call	@loop1	; divide into highest order 3 bytes of dividend
; loop divides 3-byte dividend by 2-byte divisor
@loop1	mov	A, D	; move third byte to be divided into A
	mov	D, E	; save lowest-order byte dividend or highest-order byte quotient
	mvi	E, 8	; load loopl counter
@loop2	dad	H	; shift dividend left
	jc	@over	; jump if dividend overflowed hl
	add	A
	jnc	@sub
	inx	H	; convey carry if there 
@sub	push	H	; save highest-order 2 bytes of dividend
	dad	B	; subtract divisor
	jc	@ok	; jump if no borrow
	pop	H	; unsubtract if borrow
	dcr	E	; update loopl counter
	jnz	@loop2	; loop until done
	mov	E, A	; put byte of quotient in E
	stc	
	ret	
@ok	inx	SP	; clean up stack
	inx	SP
	inr	A	; put a 1 in quotient
	dcr	E	; update loopl counter
	jnz	@loop2	; loop until done
	mov	E, A	; put byte of quotient in E	
	stc		
	ret		
@over	adc	A	; finish dividend shift, put 1 in quotient
	jnc	@oversub	
	inx	H	; convey carry if there 
@oversub	dad	B	; subtract divisor  
	dcr	E	; update loopl counter
	jnz	@loop2	; loop until done 
	mov	E, A	; put byte of quotient in E
	stc		 
	ret		 

;Perform 16bit (BC) x 16bit (DE). 32bit Result in DE-HL
; Take up to 1023 clock cycles (worst case)
MULT	mov	A, E	; load lowest-order byte of multiplier
	push	D	; save highest-order byte multiplier
	call	mult8	; do 1-byte multiply
	xthl		; save lowest-order bytes product, get multiplier
	push	PSW	; store highest-order byte of first product
	mov	A, H	; load highest-order byte of multiplier
	call	mult8	; do second 1-byte multiply
	mov	D, A	; position highest-order byte of product
	pop	PSW	; get highest-order byte of first product
	add	H	; update third byte of product
	mov	E, A	; and put it in E
	jnc	@nc	; don't increment D if no carry
	inr	D	; increment D if carry
@nc	mov	H, L	; relocate lowest-order bytes of second product
	mvi	L, 0	
	pop	B	; get lowest-order 2 bytes of first product
	dad	B	; get final product lowest-order 2 bytes
	rnc		; done if no carry
	inx	D	; otherwise update highest-order 2 bytes
	ret		; 

; mult8 performs a 1-byte (A) by 2-byte (BC) multiply
; Take up to 424 clock cycles (worst case)
MULT8	lxi	H, 0	; zero partial product
	lxi	D, 7	; D = 0, E = bit counter
	add	A	; get first multiplier bit
@loop	jnc	@zero	; zero-skip
	dad	B	; one-add multiplicand
	adc	D	; add carry to third byte of product
@zero	dad	H	; shift product left
	adc	A	
	dcr	E	; decrement bit counter
	jnz	@loop	; loop until done
	rnc		; done if no carry
	dad	B	; otherwise do last add
	adc	D	
	ret		; and return
	
