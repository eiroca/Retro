; MICRO FAST GRAPHICS from DAInamic 18 (October 1983)
;
; This utility provides a fast drawing facility
; applicable for each mode except mode 0.
; It is tailored to be used together with basic.
; This means that parameters are passed via basic
; symbol table. You have to specify four variables
; i.e. - X (abscise of the graphics screen)
;      - Y (ordinate of the graphics screen)
;      - C (desired color)
;      - E (entry of a table with the necessary info
;          to draw a picture). See further.
; X, Y specify the start positon of the picture on
; the screen.
; Before calling the procedure one must pass the
; necessary information referring to the mentioned
; variables.
; This can be done in this way (I = integer)
; I=VARPTR(X)+2:POKE#2F0,I MOD 256:POKE#2F1,I/256
; I=VARPTR(Y)+3:POKE#2F2,I MOD 256:POKE#2F3,I/256
; I=VARPTR(C)+3:POKE#2F4,I MOD 256:POKE#2F5,I/256
; I=VARPTR(E)+2:POKE#2F6,I MOD 256:POKE#2F7,I/256
; PICT=#300, to activate procedure by CALLM PICT
; The user must create his specific table containing
; all necessary information to draw the required
; picture(s).
; The table consists of one or more entries, one
; for each picture. Each entry consists of several
; elements (one for each dot, draw of fill function).
; Each element consists of 5 bytes: M,x1,y1,x2,y2
; The last element however consists of only one
; byte (#FF) denoting the end of the entry.
; - M = operator: #1E/dot, #21/draw, #24/fill
; - x1, x1 abscise in a 256x256 matrix (if mode 6)
; - y1, y2 ordinates in the same matrix
; x and y are offsets of X and Y.
; Note that x2, y2 are don’t care in case of the
; dot operation.

;
;symbol table #2f0...2f8
;
	.org $2F0

; user definable
x	.word	0	; varptr(x-coord)+2
y	.word	0	; varptr(y-coord)+3
color	.word	0	; varptr(color)+3
entry	.word	0	; varptr(entry)+2

; system temporary storage
kleur	.byte	0

; Start program
	.org	$300
start	push	H	; Push all
	push	D
	push	B
	push	PSW
; Get entry
	lhld	entry	; Load address of Table entry (2 bytes)
	mov	D, M
	inx	H
	mov	E, M
; Get color
	lhld	color	; get color
	mov	A, M
	sta	kleur	; store temporary
	xchg
; Pick up operator (Fill, Draw, Dot)
mfgt0	mov	A, M	; First element of entry indicates fill, dor, draw
	inx	H
	cpi	$FF
	jz	end
	sta	label	; Fill in operator
; pick up x1,y1,x2,y2
	mvi	B, 3	; Reapeat 2 times following loop
mfgt1	dcr	B
	jz	mfgt2
; calculate X1 = X + x1 and X2 = X + x2
	mov	E, M	; Load x
	inx	H
	mvi	D, 0
	push	H
	push	D
	lhld	X	; Load contents of X
	mov	D, M
	inx	H
	mov	E, M
	pop	H
	dad	D	; Calculate X + x
	xchg
	pop	H	; Current table pointer
	push	D	; Push X1 or X2 on stack
; Calculate Y1 = y1 + Y or Y2 = y2 + Y
	mov	C, M	; get y1 or y2
	inx	H
	push	H
	lhld	Y	; Load contents of Y (only one byte)
	mov	A, M
	add	C
	mov	C, A
	pop	H
	push	B	; Push Y1 or Y2 on stack
	jmp	mfgt1
; perform operation
mfgt2	xthl		; Fetch Y2
	mov	B, L
	pop	H
	pop	D	; Fetch X2
	xthl		; Fetch Y1
	mov	C, L
	pop	H
	xthl		; Fetch X1
	lda	kleur	; Fetch color
	rst	5	; Activate Draw, Fill, or Dor
label	.byte	$21	; $1E->DOT $21->DRAW $24->FILL
	pop	H	; Fetch tablepointer
	jc	error	; Check for error
	jmp	mfgt0
error	mvi	A, 'E'	; In case an error is detected a 'E' is printed
	rst	5
	.byte	3
end	pop	PSW	; pop all
	pop	B
	pop	D
	pop	H
	ret
