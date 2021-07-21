;
;
.segment "RST handlers"
;
; RST 0 - Interrupt vector routine 0
; Used by Utility (LOOK)
RST0_BGN	.EQU	$0000
RST0_END	.EQU	$0007
;
; RST 1 - Interrupt vector routine 1
; Used by Utility and encoding Basic
; Usage: RST 1 + $xx: Switch to ROM-bank 3
RST1_BGN	.EQU	$0008
RST1_END	.EQU	$000F
;
; RST 2 - Interrupt vector routine 2
; Used by stack interrupt (Hardware stack protection)
RST2_BGN	.EQU	$0010
RST2_END	.EQU	$0017
;
; RST 3 - Interrupt vector routine 3
; Used by sound interrupt.
RST3_BGN	.EQU	$0018
RST3_END	.EQU	$001F
;
; RST 4 - Interrupt vector routine 4
; Used by Utility and encoding Basic
; Usage: RST 4 + $xx: Switch to ROM-bank 1
RST4_BGN	.EQU	$0020
RST4_END	.EQU	$0027
;
; RST 5 - Interrupt vector routine 5
; Used for screen handling routines
; Usage: RST 5 + $xx: Switch to ROM-bank 2
RST5_BGN	.EQU	$0028
RST5_END	.EQU	$002F
;
; RST 6 - Interrupt vector routine 6
; Used for keyboard service routines
RST6_BGN	.EQU	$0020
RST6_END	.EQU	$0037
;
; RST 7 - Interrupt vector routine 7
; Used to flash the cursor
RST7_BGN	.EQU	$0038
RST7_END	.EQU	$003F
;
.segment "RAM - Bank Switching"
POROM	.EQU	$0040	; B Memory of last outputs to output ports. Duplicate of ($FD06)
RSWK1	.EQU	$0041	; W Save PSW during ROM bank switching
RSWK2	.EQU	$0043	; W Save HL duri nà ROM bank switching
RSWK3	.EQU	$0045	; W Unused
;
.segment "RAM - Utility Work Area"
UTWK1	.EQU	$0047	; B Store EI/DI instructions after using LOOK the first time (No clear occurs)
UTWK2	.EQU	$0048	; W High address trace window
UTWK3	.EQU	$004A	; W Low address trace window
UTWK4	.EQU	$004C	;DW Store current instruction if LOOK is used, preceeded by EI. In case of a RST-instruction is stored: RSTx/data y; RST0. In case of an EI instruction is stored: EI, NOP, next instruction
UTWK5	.EQU	$0050	; B Flag for Look initialisation: $FF: init. Look, else: $00
IADR	.EQU	$0051	; W IAddress current instruction
AFSAV	.EQU	$0053	; W Contents AF after execution of I
BCSAV	.EQU	$0055	; W Contents BC after execution of I
DESAV	.EQU	$0057	; W Contents DE after execution of I
HLSAV	.EQU	$0059	; W Contents HL after execution of I
SPSAV	.EQU	$005B	; W Contents SP after execution of I
PCSAV	.EQU	$005D	; W Address next instruction to be executed
TICIM	.EQU	$005F	; B Current interrupt mask. Duplicate of ($FFF8)
TICC_CW	.EQU	$0060	; B Value TICC control word ($FC after Z2)
GIC_CW	.EQU	$0061	; B Value GIC control word ($1B after Z2)
;
.segment "RAM - Interrupt Vector Addresses"
I0USA	.EQU	$0062	; W Vector address RST 0: set by UT (Z2)
I1USA	.EQU	$0064	; W Vector address RST 1: utility/encode
I2USA	.EQU	$0066	; W Vector address RST 2: stack interrupt
I3USA	.EQU	$0068	; W Vector address RST 3: sound interrupt
I4USA	.EQU	$006A	; W Vector address RST 4: math. restart
I5USA	.EQU	$006C	; W Vector address RST 5: screen restart
I6USA	.EQU	$006E	; W Vector address RST 6: keyb. int. serv
I7USA	.EQU	$0070	; W Vector address RST 7: clock interrupt
;
.segment "RAM - Screen Variables"
CURSOR	.EQU	$0072	; W Cursor position address
CURTY	.EQU	$0074	; B Cursor type:
			;    $00: cursor flashes in colour
			;    $01: cursor alternates between actual character and contents od CURIN
CURIN	.EQU	$0075	; B Cursor information: 
			;    If type = 0: mask which is EXOR'ed with the colour byte for that character to flash it
			;    If type = 1: cursor alternates between actual character and this information
CURSV	.EQU	$0076	; W Contents screen RAM location indicated by the cursor:
			;    $0076 contains the colour byte
			;    $0077 contains the data
LNSTR	.EQU	$0078	; W Address line mode byte of currently used 1ine of the screen RAM
LNEND	.EQU	$007A	; B Lobyte of end of cursor 1ine. Used to check if end of line is reached
LCONT	.EQU	$007B	; B Number of extended 1ines
COLMT	.EQU	$007C	;DW Colours for colour registers COLORT 
SCREEN	.EQU	$0080	; W Points to first byte of screen RAM ($BFFF)
SCTOP	.EQU	$0082	; W Points after header ($BFEF)
FFB	.EQU	$0084	; W First free byte in this mode
GRR	.EQU	$0086	; W Points to top of rolled area. Contains the 1ine mode byte of the 1ine where split mode starts
GRE	.EQU	$0088	; W Points after end of graphics area
CHS	.EQU	$008A	; W Points to start of character area
GAE	.EQU	$008C	; W Unsplit: end archive area
CHE	.EQU	$008C	; W Split: after end of character area
SCE	.EQU	$008E	; W End of screen (after traller)
GTE	.EQU	$0090	; W End area used splitting mode
GAS	.EQU	$0092	; W Unsplit: start archive area	
GTS	.EQU	$0092	; W Split: start temporary save area
GRC	.EQU	$0094	; W Number of blobs horizonta1ly in mode
GRL	.EQU	$0096	; B Number of lines of graphics in mode
GAL	.EQU	$0097	; B Number saved 1ines of graphics
GXB	.EQU	$0098	; B Number of bytes/line this mode
GREQ	.EQU	$0099	; W Previous end of graphics
CHS0	.EQU	$009B	; W Previous start character:
			;     Was split: previous mode byte of 1st text 1ine
			;     Was graphics: previous last COLORT-byte
SMODE	.EQU	$009D	; B Current screen mode (updated after mode changed):
			;     $00 mode 1	$01 mode 1A
			;     $02 mode 2	$03 mode 2A
			;     $04 mode 3	$05 mode 3A
			;     $06 mode 4	$07 mode 4A
			;     $08 mode 5	$09 mode 5A
			;     $0A mode 6	$0B mode 6A
			;     $10 during init
			;     $FF mode 0
COLMG	.EQU	$009E	;DW Colours for colour registers COLORG
SCVR	.EQU	$00A2	; B

SCXRUF	.EQU	$00A3	;8b Buffer used to hold contents of an 8 bit field during 16 colour updates
SBGOU	.EQU	$00AB	; B Flags if colour is being carried out to next field 
SBGOC	.EQU	$00AC	; B Colour being carried out
;
; Edit Variables
;
v_EBUFR	.EQU	$00A2	; W Address start EDIT buffer	
v_EBUFN	.EQU	$00A4	; W Address end of text in EDIT buffer
v_EBUFS	.EQU	$00A6	; W End available space in EDIT buffer
v_EWINX	.EQU	$00A8	; B Offset of left side of window
v_EWINY	.EQU	$00A9	; W Offset of top of window from start buffer	
v_ECURX	.EQU	$00AB	; B X-offset of cursor in document (current cursor position in text 1ine)
v_ECURY	.EQU	$00AC	; W Y-offset of cursor in document (count of current cursor 1ine)
v_CURPT	.EQU	$00AE	; W Pointer to cursor position in buffer
v_CURLS	.EQU	$00B0	; W Pointer to 1ine mode byte of cursor 1ine on screen	
v_CURLB	.EQU	$00B2	; W Pointer to start of cursor 1ine in buffer
v_TABTP	.EQU	$00B4	; W Address tab position table
;
; Line drawing variables
;
DELTA	.EQU	$00B5	; W Amount to add into count
RT	.EQU	$00B7	; W Count
COR	.EQU	$00B9	; W Adjustments for 1ong sectors
SECT	.EQU	$00BB	; W Lower of 2 possible sector lengths.
SECTC	.EQU	$00BD	; B Number of sectors
TRIM	.EQU	$00BE	; B Amount to trim off 1ast sector
DIRN1	.EQU	$00BF	; B Set if Y-direction is negative
DIRN2	.EQU	$00C0	; B Set if swap X, Y directions
ANIM	.EQU	$00C1	; B Set if animate in 4 colour mode
FCOLR	.EQU	$00C2	; W Details of colour required
;
ASMKRM	.EQU	$00C4	; W Address memory management routine ($CA01). Checks available RAM space
AESTOP	.EQU	$00C6	; W Adress energency stop routine ($CA25). Return-routine fo 'Out of space for mode'
;
v_SPARE1	.EQU	$00C8	;8b Unused
;
.segment "RAM - Math. Working Area"

EVECT	.EQU	$00D0	; W Pointer to table with error routines ($C7F2)
AGETC	.EQU	$00D2	; W Pointer to input routine ($DDE0)
MVECA	.EQU	$00D4	; B Math. chip flag: offset of start HW/SW vector: (offset for RST 4 restart routines): $00 No math. chip. $7B: math. chip present.
FPAC	.EQU	$00D5	;DW Arithmetic FPT accumulator
IAC	.EQU	$00D5	;DW Arithmetic INT accumulator
SUBF	.EQU	$00D9	; B Subtraction flag
OP4	.EQU	$00DA	; B Operand 4th byte
OP3	.EQU	$00DB	; B Operand 3th byte
OP2	.EQU	$00DC	; B Operand 2th byte
OP1	.EQU	$00DD	; B Operand 1th byte
EXFDF	.EQU	$00DE	; B Difference in exponents for 1ast FPT add/sub operations	
;
; Work area for math. operations. Also used for data save during stack operations
;
FWORK	.EQU	$00DF	;DW
XPRAS	.EQU	$00DF	; W
XPHLS	.EQU	$00E1	; W
FPTWRK	.EQU	$00E3	;DW
;
; Number output variables
;
DECBUF	.EQU	$00E3	; $00E3-$00F1 Decimal output buffer
			;    MAXSIG: $0A: Max. possible signiticant figures
			;    FPTSIG: $06: Number of significant digits for FPT
DECBS	.EQU	$00E4	; B Sign	
DECBD	.EQU	$00E5	; B Decimal point
DECBF	.EQU	$00E6	;10b Digits, most significant one in $00E6
DECBE	.EQU	$00F1	; B Exponent
DECBP	.EQU	$00F2	; W Buffer pointer
;
; FPOLY variables
;
XN	.EQU	$00E3	;DW Running power of (X^K)	
XK	.EQU	$00E7	;DW Power mutiplier (x^J)	
SUM	.EQU	$00EB	;DW Running sum
;
; SQRT variables 
;
FPT_F	.EQU	$00E3	;DW Mantissa	
FPT_P	.EQU	$00E7	;DW Polynomial approximation
;
; EXP variables 
;
SIGNXN	.EQU	$00EF	; B Input sign
;
; TRIG variables
;
FTWRK	.EQU	$00EF	;DW Work location for TAN.
;
; Inverse TRIG variables
;
FATZX	.EQU	$00EF	;DW Z, X. Used by ATAN, ASIN, ACOS	
;
; Number input variables
;
ICBWK	.EQU	$00E3	;DW Number to add for each digit
;
v_SPARE2	.EQU	$00F4	;12b Unused

;
.SEGMENT "RAM BASIC Variables"
;
; User state
; Following are saved by soft break: (SFRAME = SYSTOP - SYSBOT)
;
SYSBOT	.EQU	$0100	; W
CURRNT	.EQU	$0100	; W Start of current line. Points to first byte of line number
BRKPT	.EQU	$0102	; W Start of current command
LOPVAR	.EQU	$0104	; W Points to current 1oop variable. Points to position of variable in symbol table. $00 if no running 1oop.
LSTPF	.EQU	$0106	; B Flag for integer /fpt loop and implicit/explicit step
			;   bit 0: 0 = implicit step	     1 = explicit step
			;   bit 7: 0 = FPT 1oop variable   1 = INT 1oop variable
LSTEP	.EQU	$0107	;DW Step value if explicit
LCOUNT	.EQU	$010B	;DW Loop iteration count
LOPPT	.EQU	$010F	; W Pointer to start address loop
LOPLN	.EQU	$0111	; W Pointer to start 1oop 1ine
STKGOS	.EQU	$0113	; W Stack 1evel at 1ast GOSUB. $00 if no active call
STRFL	.EQU	$0115	; B Trace/step flag together
TRAFL	.EQU	$0115	; B Trace flag ($FF if set)
SYSTOP	.EQU	$0115	; B 
STEPF	.EQU	$0116	; B Step f1ag ($FF if set)
RDIPF	.EQU	STEPF+1	; B Flag set while running input (set: $FF)
RUNF	.EQU	RDIPF+1	; B Flag set while running program. (Previous 2 bytes must be consecutive)
;
; Runtime scratch area
;
COLWK	.EQU	$0119	;4b Scratch area for SCOLG, SCOLT. Contains last selected COLORT/COLORG values
LISW1	.EQU	$0119	; W Startaddress of 1isted area
LISW2	.EQU	$011B	; W End address 1isted area
GSNWK	.EQU	$0119	; W Scratch area for GOSUB/NEXT. Points to destination address 1ast GOSUB
;
; Save area for restart on error
;
ERSSP	.EQU	$011D	; W  Stack pointer	
ERSFL	.EQU	$0122	; B Set if encoding a stored 1ine (set: $01)
;
; Data/read variables
;
DATAC	.EQU	$0123	; B Offset of next character to encode
DATAP	.EQU	$0124	; W Pointer to address current data line.	
v_DATAQ	.EQU	$0124	; W Pointer after current data 11ne
CONFL	.EQU	$0126	; B Set if there is a suspended program (set: $01)
v_STACK	.EQU	$0127	; W Current base stack 1evel
;
; Scratch 1ocation for expression/function evaluation
;
WORKE	.EQU	$0129	;SW Seratch area. Contains also the argument A of	the last software random RND(A)
;
; Random number kernel
;
RNUM	.EQU	$012D	;DW Random number kernel
;
; Output switching
;
OTSW	.EQU	$0131	; BW Output switch
			;   $00 output to screen + RS232
			;   $01 output to screen only
			;   $02 output to edit buffer
			;   $03 output via DOUTC
;
; Encoding input source switching
;
EFEPT	.EQU	$0132	; W Encoding input pointer. Points to start addres of Basic-1ine just being encoded
EFECT	.EQU	$0134	; B Encded input count. CoLunts 1ength of 1ine
EFSW	.EQU	$0135	; B Encoded input switching:
			;    $00 Input from keyboard/DINC.
			;    $01 Input from string	
			;    $02 From edit buffer to program area
;
; Variables used during expression encoding. (could overlap with runtime variables)
;

TYPE	.EQU	$0136	; B Type of latest expression or item: $00 FPT, $10 INT, $20 STR, $30 Boolean
RGTOP	.EQU	$0137	; B Latest priority operator:	
			;    $00 no operation, $38 AND, $39 OR, $50 >=, $51 >, $52 <>
			;    $53 <=, $54 <, $55 =, $69 IAND, $6A IOR, $6C IXOR, $8D SHL, 
			;    $8E SHR, $A0 +, $A1 -, $C2 /, $C3 *, $CF MOD, $E4 ^
OLDOP	.EQU	$0138	; B O1d priority operator
HOPPT	.EQU	$0139	; W Pointer to place in encoded input buffer for next operator
RGTPT	.EQU	$013B	; W Pointer to place in encoded input buffer of operand latest operator
;
; Mask to select cassette l or 2
;
CASSL	.EQU	$013D	; $10 Cassette 1 activated
			; $20 Cassette 2 activated
;
; Encoded input buffer
;
EBUF	.EQU	$013E	;128 bytes buffer. Also used by utility
;
; Interrupt handler variables
;
TIMER	.EQU	$01BE	; W Timer 1ocation. Also used in WAIT TIME.	
CTIMV	.EQU	$0F	; Flash time in 20 ms units. If $00, cursor flashes
CTIMR	.EQU	$01C0	; B Cursor clock. Used for cursor flashing.	
KBXCK	.EQU	2	; Keyboard scan time (16 ms units). Also used by RAND routine.
KBXCT	.EQU	$01C1	; B Extend keyboard scan time counter. When $00, keyboard scan will be performed
;
; Sound control block storage
;	
NCL	.EQU	9	; Length of noise block (9 bytes)
SCBL	.EQU	14	; Length of a sound block (14 bytes)
SCBAREA	.EQU	$01C2	;14b Sound Control Block 0
SCB0	.EQU	$01C2	;14b Sound Control Block 0
SCB0_0	.EQU	SCB0+0	; B Elapsed count of current volume:
			;    $FF: channel off
			;    $FE: current volume forever
SCB0_1	.EQU	SCB0+1	; W Pointer to required count at this volume in envelope table
SCB0_3	.EQU	SCB0+3	; W Pointer to start envelope table being used
SCB0_5	.EQU	SCB0+5	; B Sound-volume*8. Multiplier for volume, between 0 and 16, shifted 3 places left
SCB0_6	.EQU	SCB0+6	; B Basic volume at this moment, calculated from sound volume and present envelope volume
SCB0_7	.EQU	SCB0+7	; B Counter for tremolo. 0 if no tremolo
SCB0_8	.EQU	SCB0+8	; B Actual volume, calculated from volume and tremolo fluctuations
SCB0_9	.EQU	SCB0+9	; B G1issando f1ag:	$00 endperiod reached, $01 set frequency, $02 endperiod not reached
SCB0_A	.EQU	SCB0+10	; W Current period of output	
SCB0_C	.EQU	SCB0+12	; W Required final period of output
SCB1	.EQU	$01D0	;14b Sound Control Block 1
SCB2	.EQU	$01DE	;14b Sound Control Block 2
NCB	.EQU	$01EC	;9b Noise Control Block. The noise control block is identical to the Sound Control Block, but without period-values and	tremolo
;
; Envelope storage (Two envelope tables of each 64 bytes)
;
ENVLL	.EQU	64	; Number of bytes/envelope	
NUMENV	.EQU	2	; Number of envelopes
ENVST	.EQU	$01F5	;128 bytes of envelope storage
;
; Type storage
;
IMPTAB	.EQU	$0275	;26 bytes. Implicit type table
			; $0275 A, $0276 B ... $028E Z
IMPTYP	.EQU	$028F	; B Default number type. Selected by IMP Command.	$00 FPT, $10 INT, $20 STR
REQTYP	.EQU	$0290	; B Required number type for present operation. $00 FPT, $10 INT, $20 STR, $30 Variable name argument, $40 Array without arguments
DATAQ	.EQU	$0291	; W Pointer to begin current data line
RNDLY	.EQU	$0293	; B
POR0M	.EQU	$0294	; B Duplicate of $FD04
POR1M	.EQU	$0295	; B Duplicate of $FD05
INSW	.EQU	$0296	; B Input switching: if = 0, input from keyboard, if <> 0, input from DINC (Default: RS232)
v_SPARE3	.EQU	$0297	;84 Unused
;
; Heap/text buffer/symbol table pointers
;
HSIZD	.EQU	$100 	; Default HEAP size
HEAP	.EQU	$029B	; W Start address of HEAP
HSIZE	.EQU	$029D	; W Size of HEAP	
TXTBGN	.EQU	$029F	; W Start address of text buffer
TXTUSE	.EQU	$02A1	; W End text buffer 
STBBGN	.EQU	$02A1	; W Start symbol table
STBUSE	.EQU	$02A3	; W End of symbol table
SCRBOT	.EQU	$02A5	; W Bottom screen RAM area (48K):
			;     mode 0: $E350	
			;     mode 1/2(A): $B7A0
			;     mode 3/4(A): $A65C
			;     mode 5/6(A): $63B8
;
; Keyboard variables + constants
;
RPMSK	.EQU	$20	; Rept key bit
BRSEL	.EQU	$40 	; Column select mask for BREAK.
BRMSK	.EQU	$40 	; Break key bit
SHMSK	.EQU	$40	; Shift key bit
KBLEN	.EQU	$4	; Length rollover buffer
KEYL	.EQU	$4	; Length rollover buffer
;
KBTPT	.EQU	$02A7	; W Pointer to table with ASCII-codes
MAP1	.EQU	$02A9	;8b Latest scan of keys (key-codes). Row 0 in $02A9, row 7 in $02B0
MAP2	.EQU	$02B1	;8b Previus scanning of keyboard
RPLOC	.EQU	$02AF	; B Byte containing REPT key	
SHLOC	.EQU	$02B0	; B Byte containing SHIFT
KNSCAN	.EQU	$02B9	; B Set to scan for BREAK only. When is $FF scan for BREAK only
KLIND	.EQU	$02BA	;4b Circular buffer to store the ASCII values for keys pressed.	
KLIIN	.EQU	$02BE	; W Next position for input to KLIND
KLIOU	.EQU	$02C0	; W Next position for output from KLIND

RPCNT	.EQU	$02C2	; Count for REPT. $01 if REPT is not pressed. Else it is used as timer for the repeat function
SHLK	.EQU	$02C3	; Set to $FF if CTRL is pressed to invert SHIFT. Else $00. Used to calculate the offset for the ASCII code table
KBRFL	.EQU	$02C4	; Break flag. $FF indicates BREAK pressed (only if suspended program). If BREAK is pressed, $02C4 counts from $00 to #0F before stopping the program
;
; Data/cassette switching vectors
; Copy of ROM ($D7A4 - $D7CA) for cassette and R232.
; Can be loaded with other I/O vectors
IOVEC	.EQU	$02C5

WOPEN	.EQU	$02C5	;3b JMP $xxxx
WBLK	.EQU	$02C8	;3b JMP $xxxx
WCLOSE	.EQU	$02CB	;3b JMP $xxxx
ROPEN	.EQU	$02CE	;3b JMP $xxxx
RBLK	.EQU	$02D1	;3b JMP $xxxx
RCLOSE	.EQU	$02D4	;3b JMP $xxxx
MBLK	.EQU	$02D7	;3b JMP $xxxx
jRESET	.EQU	$02DA	;3b JMP $xxxx
DOUTC	.EQU	$02DD	;3b JMP $xxxx
DINC	.EQU	$02E0	;3b JMP $xxxx
j_NOP	.EQU	$02E3	;3b JMP $xxxx
TAPSL	.EQU	$02E6	; W Tape speed leader
TAPSD	.EQU	$02E8	; W Tape speed data
TAPST	.EQU	$02EA	; W Tape speed trailer
;
.segment "Spaces"
RAMSTRT	.EQU	$02EC
STKBGN	.EQU	$F800
STKEND	.EQU	$F900
;
.segment "I/O Devices"
;
; $F900-$FAFF Spare I/0 device addresses (Not wired on PC board)
;
IOSPARE	.EQU	$F900
;
; $FB00-$FBFF: MATH. CHIP AMID 9511
;
MTHAD	.EQU	$FB00	; B Data math. chip
MDATA	.EQU	$FB00
MCOMD	.EQU	$FB02	; B Command + status
MSTATUS	.EQU	$FB02
			; AMD9511 operator and status bytes
			; ODADD:	$2C Int addition	OFADD:	$10 Fpt addition	
			; ODSUB:	$2D Int subtract	OFSUB:	$11 Fpt subtract	
			; ODMUL:	$2E Int multiply	OFMUL:	$12 Fpt multiply	
			; ODDIV:	$2F Int divis1on	OFDIV:	$13 Fpt division	
			; OSQRT:	$01 Square root	OFIXD:	$1E Fix	
			; OSIN:	$02 Sine		OFLTD:	$1C Float	
			; OCOS:	$03 Cosine	OCHSD:	$34 Change sign int	
			; OTAN:	$04 Tangent	OCHSF:	$15 Change sign fpt	
			; OASIN:	$05 Arc sine	OPTOD:	$37 Push int/fpt	
			; OACOS:	$06 Arc cosine	OPOPD:	$38 Fop int/fptt	
			; OATAN:	$07 ArC tangent	
			; OLOG:	$08 Log base 10	
			; OLN	$09 Log base e	MBUSY:	$80 Busy status bit	
			; OEXP:	$0A Expotential	MERRB:	$1E All error bits
			; OPWR:	$0B X^Y		MZERO:	$20 Top of stack
;
; $FC00-$FCFF: PROGRAMMABLE INTERVAL TIMER 8233
; Used for sound generator. 3 independent 16 bits down counters with programmable counter modes
;
PDLCH	.EQU	$FC00	; B Used as counter for paddle operations
SNDAD	.EQU	$FC00	; B 
SND0	.EQU	$FC00	; B Counter 0 (oscillator channel 0). 16 bit data, LSB first
SND1	.EQU	$FC02	; B Counter 1 (oscillator channel 1). 16 bit data, LSB first
SND2	.EQU	$FC04	; B Counter 2 (oscillator channel 2). 16 bit data, LSB first
SNDC	.EQU	$FC06	; B Command 8233. To be loaded prior to freq. selection with resp $36, $76 and $B6
			;     Command word format:
			;     bit 0     : 0   binary counter 16 digits
			;                 1   BCD counter (4 decades)
			;         3,2,1 : 000 mode 0: Interrupt on end count
			;                 001 mode 1: Programmable one shot
			;                 x10 mode 2: Rate generator
			;                 x11 mode 3: Sq.wave rate generator
			;                 100 mode 4: SW trig. strobe
			;                 101 made 5: HW trig. strobe	
			;         5,4   :  00 Counter latch operation	
			;                  01 Read/1oad MSB only	
			;                  10 Read/1oad LSB only
			;                  11 Read/load LSB first, then MSB
			;         7,6   :  00 Select counter 0
			;                  01 Select counter l
			;                  10 Select counter 2
			;                  11 I1legal
; Several control words	
C0FIX	.EQU	$00 	; Fix count on channel 0
C0M0	.EQU	$30	; Chan. 0, mode 0, 2 byte op.	
C0M1	.EQU	$32	; Chan. 0, mode 1, 2 byte op.	
C0M3	.EQU	$36 	; Chan. 0, mode 3, 2 byte op.	
C1M3	.EQU	$76 	; Chan. 1, mode 3, 2 byte op.	
c2M3	.EQU	$B6	; Chan. 2, mode 3, 2 byte op.
;
; $FD00-$FDFF: DISCRETE I/O DEVICE ADDRESSES
;
PORI	.EQU	$FD00	; RW  bit 0: -
			;         1: - 
			;         2: PIPGE: Page signal
			;         3: PIDTR: Serial output ready
			;         4: PIBU1: Button on paddle 1 (1 = closed)
			;         5: PIBU2: Button on paddle 2 (1 = closed)
			;         6: PIRPI: Random data	
			;         7: PICAI: Cassette input data	
PDLST	.EQU	$FD01	; R   Single pulse used to trigger paddle timer circuit
POR0	.EQU	$FD04	; RW  bit 0..3: volume osc. channel 0
			;         4..7: volume osc. channel 1
POR1	.EQU	$FD05	; RW  bit 0..3: volume osc. channel 2
			;         4..7: volume random noise generator
PORO	.EQU	$FD06	; R   bit   0: POCAS:  Cassette data output	
			;         1,2: PDLMSK: Paddle select	
			;           3: POPNA:  Paddle enable	
			;           4: POCM1:  Cassette 1 motor control (0 = run)	
			;           5: POCM2:  Cassette 2 motor control (0 = run)
			;         7,6:         ROM bank switching:	
			;                        00 bank 0
			;                        01 bank 1
			;                        10 bank 2
			;                        11 bank 3
;
; $FE00-$FEFF: PROGR. PERIPHERAL INTERFACE 8255
; Used for DCE-bus (GIC controller)
;
GIC_A	.EQU	$FE00	; RW I/O port A
GIC_B	.EQU	$FE01	; RW I/O port B
GIC_C	.EQU	$FE02	; RW I/O port C
GIC_CM	.EQU	$FE03	; W  Command word 8255:
			;    Contr.  PA   PCH  PCL  PB   (mode 0)
			;       $80  out  out  out  out  RWMOP
			;       $81  out  out  in   out  
			;       $82  out  out  out  in   
			;       $83  out  out  in   in   
			;       $88  out  in   out  out  
			;       $89  out  in   in   out  
			;       $8A  out  in   out  in   
			;       $8B  out  in   in   in   
			;       $90  in   out  out  out  RWMIP
			;       $91  in   out  in   out  
			;       $92  in   out  out  in   
			;       $93  in   out  in   in   
			;       $98  in   in   out  out  
			;       $99  in   in   in   out  
			;       $9A  in   in   out  in   
			;       $9B  in   in   in   in   
GIC_mC	.EQU	$FE3E	; RW I/O port C
;
; $FF00-$FFFF: TICC: TIMER + INTERRUPT CONTROLLER 5501
;
TIC_SI	.EQU	$FFF0	; R Serial input buffer. Contains the 1ast character received on the RS232 interface
TIC_KI	.EQU	$FFF1	; R Keyboard input port. 
			;     bit 0..6: data input from the keyboard. 
			;     bit    7: IN7	line from the DCE-bus and is attached to the page-blanking signal for the TV. Every 20 ms. an impulse is present
TIC_IR	.EQU	$FFF2	; RW Interrupt address register:	
			;     bit   7,6: always 1
			;     bit 5,4,3: number of pernding interrupt	
			;     bit 2,1,0: always 1
TIC_ST	.EQU	$FFF3	; R Status register:
			;     bit 0: Frame error. Set by a BREAK on the RS232 input
			;         1: Overrun error. Set if a character has been received but not taken by the CPU
			;         2: Serial input. Set if no data is received
			;         3: Receive buffer loaded. Set if a character has been received
			;         4: Transmit buffer empty. Set if RS232 output is ready to accept another character
			;         5: Interrupt pending. Set if one or more of the enabled interrupts has occured
			;         6: Ful1 bit detected. Set if the first data bit of an incoming character has been detected
			;         7: Start bit detected. Set if the start	bit of an incoming character has been detected
TIC_CM	.EQU	$FFF4	; RW Command register
			;     bit 0: TICC reset
			;         1: Send Break. If set, the serial output is high impedance
			;         2: Interrupt 7 select. A '1' zelects IN7 of the DCE-bus, a 0 selects Timer 5
			;         3: Interrupt acknowledge enable. A 1 enables TICC to accept a INTA signal from the CPU
			;      4..7: Always 0
TIC_RR	.EQU	$FFF5	; W Communications rate register:
			;     bit 0:  110 baud	
			;     bit 1:  150 baud	
			;     bit 2:  300 baud	
			;     bit 3: 1200 baud	
			;     bit 4: 2400 baud	
			;     bit 5: 4800 baud	
			;     bit 6: 9600 baud	
			;     bit 7:  1 - one stop bit
			;             0 - two stop bits
TIC_SO	.EQU	$FFF6	; W Serial output buffer. Write byte to this location to send it on the RS232 output. Use only when $FFF3-bit 4 is high
TIC_KO	.EQU	$FFF7	; W Keyboard output port Data output to scan keyboard
TIC_IM	.EQU	$FFF8	; RW Interrupt mask register:
			;     bit 0: timer 1 has expired (UTIM)
			;         1: timer 2 has expired
			;         2: Externai interrupt (STKIM)
			;         3: Timer 3 has expired (SNDIM)
			;         4: Serial receiver 1oaded
			;         5: Serial transmitter empty
			;         6: Timer 4 has expired (KBIM)	
			;         7: Timer 5 has expired or IN7 (CLKIM)
			;   (react only on 1ow-high transition)
TIC_T1	.EQU	$FFF9	; RW Timer 1 address
TIC_T2	.EQU	$FFFA	; RW Timer 2 address
TIC_T3	.EQU	$FFFB	; RW Timer 3 address
TIC_T4	.EQU	$FFFC	; RW Timer 4 address
TIC_T5	.EQU	$FFFD	; RW Timer 5 address
UTIAD	.EQU	$FFF9	; RW Timer 1 address (UT)
SNDIAD	.EQU	$FFFB	; RW Timer 3 address (sound)
KEIAD	.EQU	$FFFC	; RW Timer 4 address (keyboard)
