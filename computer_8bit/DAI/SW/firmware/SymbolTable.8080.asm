; Segment: RST handlers
RST0_BGN = $00
RST0_END = $07
RST1_BGN = $08
RST1_END = $0F
RST2_BGN = $10
RST2_END = $17
RST3_BGN = $18
RST3_END = $1F
RST4_BGN = $20
RST4_END = $27
RST5_BGN = $28
RST5_END = $2F
RST6_BGN = $20
RST6_END = $37
RST7_BGN = $38
RST7_END = $3F

; Segment: RAM - Bank Switching
POROM    = $40
RSWK1    = $41
RSWK2    = $43
RSWK3    = $45

; Segment: RAM - Utility Work Area
UTWK1    = $47
UTWK2    = $48
UTWK3    = $4A
UTWK4    = $4C
UTWK5    = $50
IADR     = $51
AFSAV    = $53
BCSAV    = $55
DESAV    = $57
HLSAV    = $59
SPSAV    = $5B
PCSAV    = $5D
TICIM    = $5F
TICC_CW  = $60
GIC_CW   = $61

; Segment: RAM - Interrupt Vector Addresses
I0USA    = $62
I1USA    = $64
I2USA    = $66
I3USA    = $68
I4USA    = $6A
I5USA    = $6C
I6USA    = $6E
I7USA    = $70

; Segment: RAM - Screen Variables
CURSOR   = $72
CURTY    = $74
CURIN    = $75
CURSV    = $76
LNSTR    = $78
LNEND    = $7A
LCONT    = $7B
COLMT    = $7C
SCREEN   = $80
SCTOP    = $82
FFB      = $84
GRR      = $86
GRE      = $88
CHS      = $8A
GAE      = $8C
CHE      = $8C
SCE      = $8E
GTE      = $90
GAS      = $92
GTS      = $92
GRC      = $94
GRL      = $96
GAL      = $97
GXB      = $98
GREQ     = $99
CHS0     = $9B
SMODE    = $9D
COLMG    = $9E
SCVR     = $A2
SCXRUF   = $A3
SBGOU    = $AB
SBGOC    = $AC
V_EBUFR  = $A2
V_EBUFN  = $A4
V_EBUFS  = $A6
V_EWINX  = $A8
V_EWINY  = $A9
V_ECURX  = $AB
V_ECURY  = $AC
V_CURPT  = $AE
V_CURLS  = $B0
V_CURLB  = $B2
V_TABTP  = $B4
DELTA    = $B5
RT       = $B7
COR      = $B9
SECT     = $BB
SECTC    = $BD
TRIM     = $BE
DIRN1    = $BF
DIRN2    = $C0
ANIM     = $C1
FCOLR    = $C2
ASMKRM   = $C4
AESTOP   = $C6
V_SPARE1 = $C8

; Segment: RAM - Math. Working Area
EVECT    = $D0
AGETC    = $D2
MVECA    = $D4
FPAC     = $D5
IAC      = $D5
SUBF     = $D9
OP4      = $DA
OP3      = $DB
OP2      = $DC
OP1      = $DD
EXFDF    = $DE
FWORK    = $DF
XPRAS    = $DF
XPHLS    = $E1
FPTWRK   = $E3
DECBUF   = $E3
DECBS    = $E4
DECBD    = $E5
DECBF    = $E6
DECBE    = $F1
DECBP    = $F2
XN       = $E3
XK       = $E7
SUM      = $EB
FPT_F    = $E3
FPT_P    = $E7
SIGNXN   = $EF
FTWRK    = $EF
FATZX    = $EF
ICBWK    = $E3
V_SPARE2 = $F4

; Segment: RAM BASIC Variables
SYSBOT   = $0100
CURRNT   = $0100
BRKPT    = $0102
LOPVAR   = $0104
LSTPF    = $0106
LSTEP    = $0107
LCOUNT   = $010B
LOPPT    = $010F
LOPLN    = $0111
STKGOS   = $0113
STRFL    = $0115
TRAFL    = $0115
SYSTOP   = $0115
STEPF    = $0116
RDIPF    = $0117
RUNF     = $0118
COLWK    = $0119
LISW1    = $0119
LISW2    = $011B
GSNWK    = $0119
ERSSP    = $011D
ERSFL    = $0122
DATAC    = $0123
DATAP    = $0124
V_DATAQ  = $0124
CONFL    = $0126
V_STACK  = $0127
WORKE    = $0129
RNUM     = $012D
OTSW     = $0131
EFEPT    = $0132
EFECT    = $0134
EFSW     = $0135
TYPE     = $0136
RGTOP    = $0137
OLDOP    = $0138
HOPPT    = $0139
RGTPT    = $013B
CASSL    = $013D
EBUF     = $013E
TIMER    = $01BE
CTIMV    = $0F
CTIMR    = $01C0
KBXCK    = $02
KBXCT    = $01C1
NCL      = $09
SCBL     = $0E
SCBAREA  = $01C2
SCB0     = $01C2
SCB0_0   = $01C2
SCB0_1   = $01C3
SCB0_3   = $01C5
SCB0_5   = $01C7
SCB0_6   = $01C8
SCB0_7   = $01C9
SCB0_8   = $01CA
SCB0_9   = $01CB
SCB0_A   = $01CC
SCB0_C   = $01CE
SCB1     = $01D0
SCB2     = $01DE
NCB      = $01EC
ENVLL    = $40
NUMENV   = $02
ENVST    = $01F5
IMPTAB   = $0275
IMPTYP   = $028F
REQTYP   = $0290
DATAQ    = $0291
RNDLY    = $0293
POR0M    = $0294
POR1M    = $0295
INSW     = $0296
V_SPARE3 = $0297
HSIZD    = $0100
HEAP     = $029B
HSIZE    = $029D
TXTBGN   = $029F
TXTUSE   = $02A1
STBBGN   = $02A1
STBUSE   = $02A3
SCRBOT   = $02A5
RPMSK    = $20
BRSEL    = $40
BRMSK    = $40
SHMSK    = $40
KBLEN    = $04
KEYL     = $04
KBTPT    = $02A7
MAP1     = $02A9
MAP2     = $02B1
RPLOC    = $02AF
SHLOC    = $02B0
KNSCAN   = $02B9
KLIND    = $02BA
KLIIN    = $02BE
KLIOU    = $02C0
RPCNT    = $02C2
SHLK     = $02C3
KBRFL    = $02C4
IOVEC    = $02C5
WOPEN    = $02C5
WBLK     = $02C8
WCLOSE   = $02CB
ROPEN    = $02CE
RBLK     = $02D1
RCLOSE   = $02D4
MBLK     = $02D7
JRESET   = $02DA
DOUTC    = $02DD
DINC     = $02E0
J_NOP    = $02E3
TAPSL    = $02E6
TAPSD    = $02E8
TAPST    = $02EA

; Segment: Spaces
RAMSTRT  = $02EC
STKBGN   = $F800
STKEND   = $F900

; Segment: I/O Devices
IOSPARE  = $F900
MTHAD    = $FB00
MDATA    = $FB00
MCOMD    = $FB02
MSTATUS  = $FB02
PDLCH    = $FC00
SNDAD    = $FC00
SND0     = $FC00
SND1     = $FC02
SND2     = $FC04
SNDC     = $FC06
C0FIX    = $00
C0M0     = $30
C0M1     = $32
C0M3     = $36
C1M3     = $76
C2M3     = $B6
PORI     = $FD00
PDLST    = $FD01
POR0     = $FD04
POR1     = $FD05
PORO     = $FD06
GIC_A    = $FE00
GIC_B    = $FE01
GIC_C    = $FE02
GIC_CM   = $FE03
GIC_MC   = $FE3E
TIC_SI   = $FFF0
TIC_KI   = $FFF1
TIC_IR   = $FFF2
TIC_ST   = $FFF3
TIC_CM   = $FFF4
TIC_RR   = $FFF5
TIC_SO   = $FFF6
TIC_KO   = $FFF7
TIC_IM   = $FFF8
TIC_T1   = $FFF9
TIC_T2   = $FFFA
TIC_T3   = $FFFB
TIC_T4   = $FFFC
TIC_T5   = $FFFD
UTIAD    = $FFF9
SNDIAD   = $FFFB
KEIAD    = $FFFC
;
; Segment: ROM
;
BGN_ROM  = $C000
BASE     = $C000
XINIT    = $C003
XFINM    = $C006
XFDCM    = $C009
XFCOMP   = $C00C
XIINM    = $C00F
XIDCM    = $C012
XICOMP   = $C015
XPLISH   = $C018
XPOF     = $C01B
XFCB     = $C01E
XFEC     = $C021
XICB     = $C024
XIBC     = $C027
XHCB     = $C02A
XHBC     = $C02D
XPRTY    = $C030
PDECBUF  = $C033
MINIT    = $C035
FPEOV    = $C04B
LC04F    = $C04F
FPEAE    = $C05E
FPEUN    = $C065
FPEDO    = $C06C
LC073    = $C073
FCOMP    = $C079
LC087    = $C087
LC08B    = $C08B
LC08C    = $C08C
LC09F    = $C09F
LC0A2    = $C0A2
LC0A3    = $C0A3
LC0A4    = $C0A4
LC0A6    = $C0A6
ICOMP    = $C0AC
LC0B7    = $C0B7
IINM     = $C0BB
IDCM     = $C0D5
FINM     = $C0F3
LC10F    = $C10F
LC14A    = $C14A
EXIT     = $C14D
LC152    = $C152
LC1AC    = $C1AC
LC1B7    = $C1B7
LC1BA    = $C1BA
SEXT     = $C1E9
LC1EE    = $C1EE
FDCM     = $C1FB
FPM1     = $C21A
PLISH    = $C21E
LC230    = $C230
POF      = $C234
FCB      = $C249
LC2A2    = $C2A2
LC2A6    = $C2A6
LC2A9    = $C2A9
LC2AE    = $C2AE
LC2BA    = $C2BA
LC2D5    = $C2D5
LC2D9    = $C2D9
LC2DC    = $C2DC
LC2DE    = $C2DE
LC2EB    = $C2EB
LC32D    = $C32D
LC32F    = $C32F
LC34D    = $C34D
FEC      = $C361
I1       = $C420
LC424    = $C424
LC437    = $C437
LC45A    = $C45A
FP0      = $C45E
FP1      = $C462
FP2      = $C466
FP3      = $C46A
FP4      = $C46E
FP5      = $C472
FP6      = $C476
FP7      = $C47A
FP8      = $C47E
FP9      = $C482
PRTY     = $C486
LC51A    = $C51A
LC531    = $C531
LC54B    = $C54B
ICB      = $C573
LC590    = $C590
LC598    = $C598
LC5A5    = $C5A5
LC5A7    = $C5A7
IBC      = $C5B2
I10      = $C610
HCB      = $C614
I4       = $C63D
LC641    = $C641
HBC      = $C653
LC69C    = $C69C
PINPLN   = $C6A0
RNDA     = $C6A8
RNDB     = $C6AC
IROR     = $C6B0
LC6B4    = $C6B4
LC6B6    = $C6B6
SPT02    = $C6BA
MARST    = $C6C0
MRSIO    = $C6CF
LC6E6    = $C6E6
MRDCL    = $C6F2
SCRST    = $C6FD
SRS10    = $C705
UTRST    = $C70E
INIT     = $C719
RESET    = $C719
RINIT    = $C7A0
MSGHDR   = $C7A8
MSGIN    = $C7D3
SIPAR    = $C7E0
STCOL    = $C7EE
MEVEC    = $C7F2
MERET    = $C7FA
MEMCHK   = $C7FB
RSTART   = $C80C
START    = $C814
LC818    = $C818
LC823    = $C823
LC87F    = $C87F
LC880    = $C880
ENDCOM   = $C88F
LC89F    = $C89F
DCALL    = $C8A9
LC8AA    = $C8AA
LC8C0    = $C8C0
LC8C5    = $C8C5
LC8CB    = $C8CB
LC8E5    = $C8E5
LC908    = $C908
PROGI    = $C918
ELINA    = $C93C
LC951    = $C951
ELARS    = $C957
ELAIN    = $C995
LDEL     = $C9A2
LINS     = $C9BD
PROGM    = $C9D1
PRGM1    = $C9F3
ASKRM    = $CA01
LCA21    = $CA21
EMSTP    = $CA25
LOOKC    = $CA34
LOOK     = $CA57
LOOKX    = $CA5A
FNAME    = $CA95
DADD     = $CAAE
DADR     = $CAB1
LOOKI    = $CAB8
FINDL    = $CAF6
SCRATC   = $CB23
LCB56    = $CB56
EARRAY   = $CB5B
ZFPINT   = $CB9E
RSVHL    = $CBA8
BAS_CMD  = $CBBF
SNEW     = $CBBF
SCONT    = $CBC6
SSTOP    = $CBCE
SEND     = $CBD6
SREST    = $CBDD
SRET     = $CBE8
SRUN     = $CBF2
SGOTO    = $CBF9
SGOSUB   = $CC01
SIMP     = $CC0A
SSAVA    = $CC11
SLODA    = $CC1A
SOUT     = $CC23
SPOKE    = $CC2A
SWAIT    = $CC32
SLIST    = $CC3A
SEDIT    = $CC42
SSOUND   = $CC4A
SNOISE   = $CC53
SENV     = $CC5C
SCURS_   = $CC68
SMODE_   = $CC72
SDOT_    = $CC7A
SDRAW_   = $CC81
SFILL_   = $CC89
SCOLT_   = $CC91
SCOLG_   = $CC9B
SINPUT   = $CCA5
SDATA    = $CCAE
SREAD    = $CCB6
SLET     = $CCBE
SIF      = $CCC5
SREM     = $CCCB
SFOR     = $CCD2
SNEXT    = $CCD9
SPRINT   = $CCE1
SPRINT2  = $CCEA
SON      = $CCEF
SDIM     = $CCF5
SAAA     = $CCFC
SUT      = $CD03
SCALM    = $CD09
SCLEAR   = $CD12
SLOAD    = $CD1B
SSAVE    = $CD23
SCHECK   = $CD2B
XCD36    = $CD36
SSTEP    = $CD3D
STRON    = $CD45
STROF    = $CD4D
STALK    = $CD56
LCD62    = $CD62
RTALK    = $CD64
LCD67    = $CD67
LCD78    = $CD78
LCD81    = $CD81
CDTAB    = $CD8B
LCE45    = $CE45
LCE51    = $CE51
MSPACE   = $CE56
LCE5C    = $CE5C
LCE60    = $CE60
LCE68    = $CE68
SCHSP    = $CE6B
SCHCO    = $CE70
STXSS    = $CE75
STXTS    = $CE78
LCE85    = $CE85
LCE8B    = $CE8B
LCE91    = $CE91
LCE95    = $CE95
FBCP     = $CE9B
LCEA4    = $CEA4
LCEAB    = $CEAB
LCEAD    = $CEAD
LCEB1    = $CEB1
LCEB5    = $CEB5
LCEBB    = $CEBB
LCEC5    = $CEC5
LCECF    = $CECF
LCEDA    = $CEDA
LCEDE    = $CEDE
SELB0    = $CEE4
LCEF2    = $CEF2
LCEF9    = $CEF9
CITAB    = $CF02
LCF7E    = $CF7E
OPTBB    = $CF86
OPTAB    = $CF91
SDIV     = $CF91
OPTBM    = $CFD8
FUNTB    = $CFE6
SABS     = $CFE6
SALOG    = $CFEC
SASC     = $CFF3
SCHR     = $CFF9
SCURX    = $D000
SCURY    = $D006
SEXP     = $D00C
SFRAC    = $D012
SFRE     = $D019
SFREQ    = $D01E
SGETC    = $D025
SHEX     = $D02B
SINP     = $D032
SINT     = $D038
SLEFT    = $D03E
SLEN     = $D047
SVPT     = $D04D
SLOG     = $D056
SLOGT    = $D05C
SXMAX    = $D063
SYMAX    = $D069
SMID     = $D06F
SPDL     = $D078
SPEEK    = $D07E
SPI      = $D085
SRIGHT   = $D089
SRND     = $D093
SSCRN_   = $D099
SSGN     = $D0A1
SSPC     = $D0A7
SSQR     = $D0AD
SSTR     = $D0B3
STAB     = $D0BA
SVAL     = $D0C0
SSIN     = $D0C6
SCOS     = $D0CC
STAN     = $D0D2
SASIN    = $D0D8
SACOS    = $D0DF
SATN     = $D0E6
ENDFT    = $D0ED
FPOSC    = $D0ED
FPM1B    = $D0F1
FPPI     = $D0F5
I4B      = $D0F9
IRAND    = $D0FD
SHINIT   = $D101
SHAPP    = $D106
SHCOMP   = $D121
SHMID    = $D14F
SCOPF    = $D16D
SHCOPY   = $D172
SCOPT    = $D173
LD175    = $D175
SHREL    = $D187
SHREQ    = $D18B
HINIT    = $D195
HREQU    = $D1C5
XD1C8    = $D1C8
LD1D1    = $D1D1
LD1DB    = $D1DB
LD1E2    = $D1E2
LD1E8    = $D1E8
LD1FD    = $D1FD
MSG001   = $D208
LD20C    = $D20C
LD214    = $D214
LD227    = $D227
HREL     = $D236
RSAVE    = $D23D
XD265    = $D265
XD26B    = $D26B
RLOAD    = $D274
RLERR    = $D2A8
RLEAR    = $D2B3
CWOPEN   = $D2B8
RCHECK   = $D2C3
CWBLK    = $D2F1
LD30F    = $D30F
LD316    = $D316
CROPEN   = $D325
LD329    = $D329
CRBLK    = $D340
LOERR    = $D380
INSC     = $D384
RBUEX    = $D387
INLNG    = $D38D
RHLEX    = $D39B
CMBLK    = $D3A2
RHDR     = $D3F4
WHDR     = $D40C
LD414    = $D414
LD422    = $D422
WTRL     = $D427
CWCLOS   = $D427
CASST    = $D42E
CRCLOS   = $D445
CASSP    = $D445
RBIT     = $D453
RLEAD    = $D480
RBYTE    = $D4D4
WLEAD    = $D4ED
LD4F6    = $D4F6
WBYTE    = $D509
WBIT     = $D524
WCYC     = $D53C
WTRLX    = $D550
XD55A    = $D55A
KLIRS    = $D560
KBINIT   = $D560
KLIRP    = $D563
KBINT    = $D578
KBSCAN   = $D59A
KFSCAN   = $D620
TKEY     = $D632
SINKEY   = $D63F
TOUTSE   = $D642
LD64E    = $D64E
LD658    = $D658
LD65F    = $D65F
LD668    = $D668
LD678    = $D678
LD681    = $D681
LD687    = $D687
LD68D    = $D68D
LD695    = $D695
KPTRU    = $D69C
ASKKEY   = $D6A5
BREAK    = $D6A5
FGETC    = $D6BB
GETC     = $D6BE
LD6C1    = $D6C1
WSPACE   = $D6DA
LD6E5    = $D6E5
LD6F5    = $D6F5
LD700    = $D700
LD706    = $D706
LD70D    = $D70D
LD70F    = $D70F
LD71A    = $D71A
LD720    = $D720
LD72D    = $D72D
LD73D    = $D73D
LD743    = $D743
LD74C    = $D74C
LD750    = $D750
SNTMP    = $D755
LD783    = $D783
LD78A    = $D78A
LD790    = $D790
CASIN    = $D795
CINTB    = $D7A4
CINTE    = $D7CB
WPT      = $D7CB
LD7D8    = $D7D8
LD7DE    = $D7DE
XD7E6    = $D7E6
WBCPUC   = $D7EC
LD7F8    = $D7F8
LD7FF    = $D7FF
LD806    = $D806
LD808    = $D808
LD80F    = $D80F
RSAVA    = $D81D
RLSAS    = $D83B
RLODA    = $D85E
LD86D    = $D86D
LD873    = $D873
LD879    = $D879
LD87F    = $D87F
LD886    = $D886
LD88D    = $D88D
LD891    = $D891
LD897    = $D897
LD89E    = $D89E
SNDINI   = $D8A6
RWOP     = $D8C8
RWIP     = $D8E0
INTINI   = $D8FB
INTSU    = $D91E
VECSU    = $D949
ITMPL    = $D96B
ITMPLE   = $D973
KBDI     = $D973
INTCH    = $D977
KBEI     = $D988
SNDDI    = $D98F
SNDEI    = $D996
KBIS     = $D99D
SNDIS    = $D9A3
CLKINT   = $D9A9
INTRM    = $D9CD
CLKEI    = $D9DB
SPINT    = $D9E2
ERROR    = $D9F5
ERRSN    = $DA0B
ERROM    = $DA10
ERRRA    = $DA15
ERRTM    = $DA1A
ERROV    = $DA1F
ERRD0    = $DA24
ERRBS    = $DA29
ERRNF    = $DA2E
ERREL    = $DA33
ERRLS    = $DA38
ERRRU    = $DA3D
ERRMS    = $DA50
ERRCO    = $DA64
MSGIL    = $DA75
ERITB    = $DA94
E_NF     = $DA94
E_RG     = $DA96
E_OD     = $DA98
E_OV     = $DA9A
E_US     = $DA9C
E_BS     = $DA9E
E_D0     = $DAA0
E_OS     = $DAA2
E_LS     = $DAA4
E_RA     = $DAA6
E_IN     = $DAA8
E_LO0    = $DAAA
E_LO1    = $DAAC
E_LO2    = $DAAE
E_LO3    = $DAB0
E_UA     = $DAB2
E_NC     = $DAB4
E_OF     = $DAB6
E_EL     = $DAB8
E_OM     = $DABA
E_TM     = $DABC
E_LN     = $DABE
E_SO     = $DAC0
E_SN     = $DAC2
E_ID     = $DAC4
E_CN     = $DAC6
E_TC     = $DAC8
E_ST     = $DACA
LDACC    = $DACC
PMSG     = $DAD4
PMSGR    = $DAFF
PSKP     = $DB0D
LDB1A    = $DB1A
LDB1C    = $DB1C
LDB1D    = $DB1D
LDB27    = $DB27
SCTAB    = $DB2A
TAB      = $DB2A
SCSTR    = $DB32
PSTR     = $DB32
LDB35    = $DB35
LDB36    = $DB36
SCSTM    = $DB44
PSTRM    = $DB44
PHEX     = $DB4A
PGP      = $DB4D
PINT     = $DB53
PFPT     = $DB59
IBCP     = $DB5F
BPP      = $DB65
LDB6A    = $DB6A
RMS01    = $DB6F
MSG01    = $DB6F
MSG02    = $DB7F
MLINE    = $DB83
MSG03    = $DB89
MSG04    = $DB93
MLINR    = $DB98
MSG15    = $DB9C
MSB05    = $DBA8
MSG06    = $DBB0
MSG07    = $DBB8
MSG17    = $DBC0
MSG09    = $DBC5
MSG10    = $DBC9
MSG11    = $DBCF
MSG14    = $DBDB
MBREAK   = $DBE0
MWITHO   = $DBE6
MSTRIN   = $DBF0
MING     = $DBF3
MTYPE    = $DBF7
MTAPE    = $DBFD
MUNDF    = $DC03
MOUTOF   = $DC0D
MERROR   = $DC15
ERMNF    = $DC1C
ERMSN    = $DC23
ERMRG    = $DC2C
ERMOD    = $DC33
ERMSO    = $DC38
ERMOV    = $DC3E
ERMOM    = $DC47
ERMUS    = $DC50
MLINN    = $DC53
MNUMBE   = $DC55
ERMBS    = $DC5C
ERMD0    = $DC68
ERMID    = $DC79
MINVAL   = $DC81
ERMTM    = $DC8A
ERMOS    = $DC95
ERMLS    = $DC9D
ERMCN    = $DCA9
ERMIN    = $DCB2
ERMOF    = $DCB7
ERMNC    = $DCC2
ERMLN    = $DCD6
ERMNA    = $DCD8
MSGOR    = $DCDB
ERMTC    = $DCE3
ERMUA    = $DCF1
ERML0    = $DCFA
ERML1    = $DCFE
ERML2    = $DD02
ERML3    = $DD06
MSGL     = $DD0A
ERMEL    = $DD12
INPL0    = $DD1A
INPLN    = $DD1F
EXIT1    = $DD45
LDD49    = $DD49
COL0     = $DD55
CRLF     = $DD5E
SCCHR    = $DD60
OUTC     = $DD60
COUTC    = $DD6A
LDD70    = $DD70
OTBIN    = $DD75
LDD8C    = $DD8C
LDD8E    = $DD8E
OUTSE    = $DD94
CINC     = $DDB4
INSER    = $DDB4
BRSER    = $DDC0
IGNBR    = $DDD1
IGNB     = $DDD2
EFETCH   = $DDE0
ALPHA    = $DE02
ALNUM    = $DE09
NUMBER   = $DE0D
COMP     = $DE14
SUBDE    = $DE1A
CMPHL    = $DE26
DADA     = $DE30
DADM     = $DE39
DELAY    = $DE41
MOVE     = $DE4F
FILL     = $DE7C
HLMUL    = $DE8F
XDEB0    = $DEB0
RNEW     = $DEB8
HRINIT   = $DECA
RCONT    = $DED5
LDED6    = $DED6
RSTEP    = $DEFE
RSTOP    = $DF03
REND     = $DF0C
RIFG     = $DF15
RIFTL    = $DF15
RIFTC    = $DF20
RGOSUB   = $DF2A
LDF2D    = $DF2D
LDF48    = $DF48
RRET     = $DF4C
RGOTO    = $DF63
LDF66    = $DF66
RONGT    = $DF6A
RONGS    = $DF71
RONFN    = $DF78
RRUN     = $DF9E
LDFA4    = $DFA4
RRUNN    = $DFBA
RPOKE    = $DFC0
RPEN     = $DFC3
ROUT     = $DFC9
RWAIT    = $DFD5
RWTEM    = $DFF7
END_ROM  = $E000
;
; Segment: ROM0
;
BGN_ROM0 = $E000
LE012    = $E012
RWTET    = $E016
RFOR     = $E02B
LE061    = $E061
LE0A2    = $E0A2
RNEXI    = $E0C5
RNEXT    = $E0E5
LE0EE    = $E0EE
LE0FC    = $E0FC
LE114    = $E114
LE11D    = $E11D
LE133A   = $E133
PUSHF    = $E13C
POPF     = $E167
RREM     = $E18F
RDATA    = $E18F
LE190    = $E190
RIMP     = $E195
RLIST    = $E197
RLIS0    = $E197
LE19F    = $E19F
RLIS1    = $E1AA
RLIS2    = $E1B6
LE1CF    = $E1CF
REDIT    = $E1F5
LE1FB    = $E1FB
LE24D    = $E24D
REDI1    = $E253
REDI2    = $E25C
REDIN    = $E265
IFBNL    = $E291
RPRINT   = $E2B3
RINPQ    = $E2FC
RINPUT   = $E302
RREAD    = $E323
LE34A    = $E34A
INPRS    = $E350
L0E56    = $E361
RRDIP    = $E364
LE367    = $E367
LE370    = $E370
LE38B    = $E38B
XE39F    = $E39F
LE3A8    = $E3A8
LE3C1    = $E3C1
LE3C2    = $E3C2
RRISN    = $E3C3
INPGT    = $E3D0
DATAF    = $E3DC
RREST    = $E401
RRAND    = $E40C
LE436    = $E436
LE447    = $E447
XE455    = $E455
RLETX    = $E45A
RLETI    = $E45A
LE465    = $E465
LE484    = $E484
LE494    = $E494
LE4B2    = $E4B2
LE4B4    = $E4B4
LE4B8    = $E4B8
RSOUND   = $E4BC
LE4FC    = $E4FC
LE501_   = $E501
RNOISE   = $E50C
SNGEV    = $E51F
RENV     = $E570
RCURS    = $E5B2
RMODE    = $E5BB
RDOT     = $E5C1
LE5C8    = $E5C8
LE5C9    = $E5C9
RDRAW    = $E5CE
RFILL    = $E5D7
R2COC    = $E5E0
RCOOR    = $E5F3
RCOCO    = $E5F9
RCOL     = $E5FD
SCRER    = $E602
RCOLT    = $E60E
RCOLG    = $E615
R4COL    = $E61C
RDIM     = $E62F
LE631    = $E631
LE67B    = $E67B
LE67C    = $E67C
ZHREQ    = $E68B
RUT      = $E69E
RCALM    = $E6A4
LE6B3    = $E6B3
RCLEAR   = $E6B5
RTRON    = $E6CE
LE6D0    = $E6D0
RTROF    = $E6D5
RLN      = $E6D9
RLNF     = $E6E7
RLNFI    = $E6ED
REXI2    = $E6F8
REXI1    = $E71D
LE734    = $E734
LE736    = $E736
REXIL    = $E743
REX1     = $E74F
REXF1    = $E75B
REXPL    = $E763
REXSR    = $E791
REXPS    = $E79D
ROSTR    = $E7BD
DROPS    = $E7F8
REXNA    = $E808
REXPN    = $E819
LE81B    = $E81B
LE850    = $E850
LE89F    = $E89F
LE8C9    = $E8C9
LE8DC    = $E8DC
ROFTAB   = $E8EE
ROITAB   = $E8FD
LE92D    = $E92D
ROREL    = $E933
BASETT   = $E943
ROGQ     = $E943
ROGT     = $E947
RONEQ    = $E94B
ROLEQ    = $E94F
ROLT     = $E953
ROEQ     = $E957
RFALSE   = $E958
RARRN    = $E95A
RVREN    = $E95C
RVAR     = $E963
RVARE    = $E96B
RVR05    = $E96D
ERRUA    = $E990
RFUN     = $E9D9
FUNIT    = $E9F0
LEA40    = $EA40
LEA47    = $EA47
RABS     = $EA50
RALOG    = $EA53
REXP     = $EA56
RFRAC    = $EA59
RLOG     = $EA5C
RLOGT    = $EA5F
RSQR     = $EA62
RSIN     = $EA65
RCOS     = $EA68
RTAN     = $EA6B
RASIN    = $EA6E
RACOS    = $EA71
RATN     = $EA74
RSTR     = $EA77
LEA7D    = $EA7D
RHEX     = $EA83
RSPC     = $EA8C
LEA8F    = $EA8F
RTAB     = $EAA2
RCURX    = $EAB8
RCURY    = $EABE
RLEN     = $EAC4
LEAC7    = $EAC7
RASC     = $EACB
RCHR     = $EAD2
LEADF    = $EADF
RLEFT    = $EAE2
LEAEC    = $EAEC
LEAED    = $EAED
RRIGHT   = $EAFF
RMID     = $EB0E
REXIK    = $EB1D
RVAL     = $EB25
SUEPT    = $EB29
RFRE     = $EB43
FR2BY    = $EB46
SIZE     = $EB51
RFREQ    = $EB5C
RGETC    = $EB75
FR1BY    = $EB7C
RINP     = $EB82
RINT     = $EB8D
LEB9D    = $EB9D
RVPT     = $EBA1
RXMAX    = $EBA7
RYMAX    = $EBAE
LEBB4    = $EBB4
RPDL     = $EBC1
RPEEK    = $EC16
RPI      = $EC1D
LEC23    = $EC23
RRND     = $EC27
LEC6D    = $EC6D
RSGN     = $EC7B
FTEST    = $EC8A
RSCRN    = $EC9D
SLINE    = $ECAB
SCOM     = $ECCC
HROUTINE = $ECF8
SCN1     = $ED3A
SCN3     = $ED3B
SCN2     = $ED41
SCN5     = $ED44
SCN7     = $ED47
SCOEX    = $ED4A
SCN6     = $ED4D
SCN11    = $ED50
S3EXP    = $ED53
SCN8     = $ED56
SCN10    = $ED5C
SCN9     = $ED62
SCSEX    = $ED65
SCN12    = $ED6B
LED6E    = $ED6E
SCN13    = $ED7A
SCN14    = $ED84
LED90    = $ED90
LED97    = $ED97
SC14A    = $ED9B
SCN15    = $EDA4
SCN16    = $EDC1
SCN17    = $EDD9
SCN18    = $EDE0
RDM40    = $EDF0
SCN20    = $EDFF
SCN21    = $EE09
LEE15    = $EE15
SCN22    = $EE1A
SC22A    = $EE25
SCN23    = $EE30
LEE4C    = $EE4C
SCN24    = $EE4F
SCN25    = $EE52
SCN26    = $EE66
SCN27    = $EE71
LEE79    = $EE79
SCN28    = $EE87
LEE8D    = $EE8D
LEE94    = $EE94
SCEXP    = $EEA2
SCARN    = $EEF7
LEEFC    = $EEFC
LEEFE    = $EEFE
LEF55    = $EF55
SFUN     = $EF5A
SCON     = $EF84
LEFAE    = $EFAE
LEFB4    = $EFB4
SCINT    = $EFBD
SSSPC    = $EFC0
SCFPT    = $EFD4
SCHEX    = $EFDA
SQTS     = $EFE1
SUQTS    = $EFED
SCHRI    = $EFF5
SEXPS    = $EFFC
END_ROM0 = $F000
;
; Segment: ROM1
;
BGN_ROM1 = $E000
SVECA    = $E000
MFADD    = $E000
MFSUB    = $E003
MFMUL    = $E006
MFDIV    = $E009
MLOAD    = $E00C
MSAVE    = $E00F
MPUT     = $E012
MGET     = $E015
MFABS    = $E018
MFCHS    = $E01B
MFINT    = $E01E
MFRAC    = $E021
MPWR     = $E024
MLN      = $E027
MEXP     = $E02A
MLOG     = $E02D
MALOG    = $E030
MSQRT    = $E033
MSIN     = $E036
MCOS     = $E039
MTAN     = $E03C
MASIN    = $E03F
MACOS    = $E042
MATAN    = $E045
MFIX     = $E048
MFLT     = $E04B
MIADD    = $E04E
MISUB    = $E051
MIMUL    = $E054
MIDIV    = $E057
MIREM    = $E05A
MIABS    = $E05D
MICHS    = $E060
MIAND    = $E063
MIOR     = $E066
MIXOR    = $E069
MINOT    = $E06C
MSHL     = $E06F
MSHR     = $E072
MSA00    = $E075
L1E274   = $E078
HVECA    = $E07B
XFMUL    = $E0FE
XFDIV    = $E108
XLOAD    = $E112
XSAVE    = $E11C
XPUT     = $E126
XGET     = $E133
XFABS    = $E140
XFCHS    = $E14A
XFRAC    = $E154
XIADD    = $E16D
LE187    = $E187
XISUB    = $E18D
XIMUL    = $E1AC
XIDIV    = $E22B
XIREM    = $E238
LE242    = $E242
LE2EC    = $E2EC
LE2F2    = $E2F2
XIABS    = $E30B
XICHS    = $E315
LE322    = $E322
LE328    = $E328
XIAND    = $E32E
SIAND    = $E335
LE343    = $E343
XIOR     = $E345
SIOR     = $E34C
LE35A    = $E35A
XIXOR    = $E35C
SIXOR    = $E363
LE371    = $E371
XINOT    = $E373
LE384    = $E384
LE385    = $E385
LE38C    = $E38C
LE38F    = $E38F
XSHR     = $E398
XSHL     = $E3A5
XSTST    = $E3B2
LE3C9    = $E3C9
LE3CF    = $E3CF
LE3D6    = $E3D6
XFLT     = $E3DE
LE40E    = $E40E
XFIX     = $E414
XFINT    = $E443
ZFADD    = $E474
ZFSUB    = $E479
ZFMUL    = $E47E
ZFDIV    = $E483
ZFABS    = $E488
ZFCHS    = $E493
ZFINT    = $E498
ZFLT     = $E49B
ZFRAC    = $E4A0
LE4AC    = $E4AC
ZLN      = $E4B1
ZEXP     = $E4B6
ZLOG     = $E4BB
ZALOG    = $E4C0
ZSQRT    = $E4CC
ZSIN     = $E4D1
ZCOS     = $E4D6
ZTAN     = $E4DB
ZASIN    = $E4E0
ZACOS    = $E4E5
ZATAN    = $E4EA
ZFIX     = $E4EF
ZIADD    = $E4F4
ZISUB    = $E4F9
ZIMUL    = $E4FE
ZIDIV    = $E503
ZIREM    = $E508
ZIABS    = $E517
ZICHS    = $E522
WLOPI    = $E527
OPI      = $E52D
WOPI     = $E535
WMATH    = $E53B
ZPUT     = $E55F
LE564    = $E564
ZGET     = $E56F
LLE585   = $E585
ZLOAD    = $E588
ZSAVE    = $E599
LE5AA    = $E5AA
XSQRT    = $E5F8
LE657    = $E657
LE65F    = $E65F
XEXP     = $E667
LE68B    = $E68B
LE694    = $E694
LE6AD    = $E6AD
LE6B8    = $E6B8
LE6F5    = $E6F5
LE6F8    = $E6F8
_FP1O8   = $E6FB
LE6FF    = $E6FF
LE703    = $E703
LE707    = $E707
LE70B    = $E70B
LE71B    = $E71B
LE72B    = $E72B
LE72F    = $E72F
XLN      = $E745
FLNA     = $E76A
XLN_C    = $E7B8
XLN_T    = $E7BC
XSIN     = $E7D2
XCOS     = $E7D9
LE7E3    = $E7E3
FPHPI    = $E833
LE837    = $E837
LE83B    = $E83B
LE83F    = $E83F
XPWR     = $E855
XLOG     = $E870
XALOG    = $E880
FLGTI    = $E890
XTAN     = $E894
XATAN    = $E8AC
FATC1    = $E946
FATPL    = $E95E
XASIN    = $E96C
FASRET   = $E991
LE994    = $E994
LE999    = $E999
XACOS    = $E9C1
FASER    = $E9D0
ASAVE    = $E9D6
ASTORE   = $E9DB
ACHGS    = $E9E4
LE9EE    = $E9EE
LE9F1    = $E9F1
ATEST    = $E9F8
LE9FB    = $E9FB
LEA0E    = $EA0E
AZERO    = $EA16
ADIV     = $EA20
OVERF    = $EA46
OVUNF    = $EA4B
UNDRF    = $EA4E
DIV0     = $EA54
AMUL     = $EA59
ASUB     = $EA6D
AADD     = $EA72
LEA74    = $EA74
LEB00    = $EB00
LEB06    = $EB06
LEB0C    = $EB0C
LEB11    = $EB11
LEB16    = $EB16
LEB17    = $EB17
MDEX     = $EB1D
LSHN     = $EB39
LEB48    = $EB48
RSHN     = $EB55
LEB70    = $EB70
LEB7D    = $EB7D
LEB82    = $EB82
LEB96    = $EB96
LEBA0    = $EBA0
LEBC3    = $EBC3
LEBD9    = $EBD9
LEBDE    = $EBDE
LIE274   = $EBE9
TSTZA    = $EBF1
TSTZ     = $EBF4
MULX     = $EC00
DIVX     = $EC4A
LECCC    = $ECCC
AMD_RST  = $ECD2
LECD9    = $ECD9
LECE1    = $ECE1
LECEA    = $ECEA
LECF3    = $ECF3
LECFC    = $ECFC
LED01    = $ED01
LED04    = $ED04
LED08    = $ED08
LED0F    = $ED0F
LED13    = $ED13
ZIAND    = $ED19
ZIOR     = $ED26
ZIXOR    = $ED33
LED3D    = $ED3D
ZINOT    = $ED43
ZIGTP    = $ED4F
ZSHR     = $ED55
ZRREG    = $ED62
ZSHL     = $ED6C
ZGBCDE   = $ED7C
LED83    = $ED83
LED88    = $ED88
LED8F    = $ED8F
M4STAT   = $ED95
ZPWR     = $EDA1
XFADD    = $EDAA
XFSUB    = $EDB4
MSA      = $EDC0
LEDFD    = $EDFD
LEE0B    = $EE0B
LEE0F    = $EE0F
TEMPO    = $EE6E
LEE73    = $EE73
LEEBD    = $EEBD
LEF8B    = $EF8B
LEF93    = $EF93
LEF9D    = $EF9D
LEFA4    = $EFA4
BRET     = $EFA6
R1BB     = $EFB5
XEFC9    = $EFC9
LEFF9    = $EFF9
END_ROM1 = $F000
;
; Segment: ROM2
;
BGN_ROM2 = $E000
ZSINIT   = $E000
ZSOUTC   = $E003
ZSCLT    = $E006
ZSCUS    = $E009
ZSCUA    = $E00C
ZSCUM    = $E00F
ZSCUI    = $E012
ZSFETC   = $E015
ZSMODE   = $E018
ZSCLG    = $E01B
ZSDOT    = $E01E
ZSDRAW   = $E021
ZSFILL   = $E024
ZSCRN    = $E027
ZEDIT    = $E02A
ZEDOB    = $E02D
CON0     = $E030
CON1     = $E045
CON1A    = $E05A
CON3     = $E06F
CON3A    = $E084
CON5     = $E099
CON5A    = $E0AE
SINIT    = $E0C3
SOUTC    = $E102
LE127    = $E127
LE12B    = $E12B
XRCC     = $E12E
LE134    = $E134
LE135    = $E135
XRET     = $E138
LE13D    = $E13D
LE153    = $E153
LE159    = $E159
LE166    = $E166
LE1A9    = $E1A9
SCROLL   = $E1CB
LE1CE    = $E1CE
LE1FD    = $E1FD
TMODE    = $E21C
SCOLT    = $E237
VCOPY    = $E254
BCOLS    = $E267
SCURS    = $E279
LE2C1    = $E2C1
LE2C5    = $E2C5
SCURA    = $E2CC
SCURM    = $E316
LE32A    = $E32A
CURSET   = $E330
SCURI    = $E344
CURFL    = $E344
CURDEL   = $E36B
SFETC    = $E38B
SSETM    = $E3D9
SSM0     = $E407
LE438    = $E438
LE43C    = $E43C
SSMG     = $E43E
SSM      = $E45F
LE47F    = $E47F
LE485    = $E485
SSMA     = $E4B6
TABP     = $E539
VARS     = $E545
LE596    = $E596
TABM     = $E59A
TABMA    = $E5A0
SMKRM    = $E5A6
SGINIT   = $E5AD
SSUBL    = $E5FC
SMVTXT   = $E635
SSETC    = $E687
SSETL    = $E698
SCOLG    = $E6A4
MOVES    = $E6C2
SUBDE_   = $E6F2
COMP_    = $E6FB
DADA_    = $E701
CMPHL_   = $E706
SDOT     = $E710
SDRAW    = $E71B
UPDTP    = $E7FC
SFILL    = $E818
LE81D    = $E81D
ARGCHK   = $E83A
SSCRN    = $E884
SUPDTE   = $E8DE
SSFM     = $E8F6
SBFM     = $E92D
LE939    = $E939
LE984    = $E984
SBF80    = $E986
SUDCH    = $E9B2
COLSU    = $E9C3
FILBK    = $EA0B
FILST    = $EA57
DADCK    = $EAC1
PTRCK    = $EAC7
LEAE1    = $EAE1
LEAE2    = $EAE2
LEAE5    = $EAE5
LEAEF    = $EAEF
FILRT    = $EAF7
HLMUL_   = $EB46
HLDIV_   = $EB60
TPOSN    = $EB7A
STR164   = $EB9B
SMEMMK   = $EBB9
SMKMSK   = $EBE1
EINIT    = $EBF4
EOBEY    = $EC1E
EWUP     = $EC4B
LEC6E    = $EC6E
LEC74    = $EC74
LEC86    = $EC86
EWDN     = $ECB3
LECD2    = $ECD2
LECD5    = $ECD5
LECD6    = $ECD6
LECDA    = $ECDA
LECDF    = $ECDF
LECEF    = $ECEF
EWRT     = $ECF8
LED16    = $ED16
LED1B    = $ED1B
LED2E    = $ED2E
LED4B    = $ED4B
EWLF     = $ED50
LED6F    = $ED6F
LED74    = $ED74
ECUP     = $ED88
ECDN     = $EDAB
ECLF     = $EDD3
ECRT     = $EDF6
LEE1C    = $EE1C
LEE38    = $EE38
LEE44    = $EE44
LEE7B    = $EE7B
LEE7F    = $EE7F
LEE82    = $EE82
LEEA6    = $EEA6
LEEC0    = $EEC0
LEED2    = $EED2
LEEDE    = $EEDE
LEEEB    = $EEEB
LEEEC    = $EEEC
LEF08    = $EF08
LEF17    = $EF17
LEF29    = $EF29
LEF3A    = $EF3A
EINCH    = $EF4B
LEF95    = $EF95
LEF96    = $EF96
LEF9C    = $EF9C
LEFB9    = $EFB9
EDLCH    = $EFCC
END_ROM2 = $F000
;
; Segment: ROM3
;
BGN_ROM3 = $E000
ELINE    = $E000
ELN      = $E003
ETCON    = $E006
LWSTART  = $E009
DEOOT    = $E00C
MHREO    = $E00F
MINKEY   = $E012
L3E394   = $E015
INXCH    = $E018
LE024    = $E024
EFOR     = $E05F
LE06F    = $E06F
LE07B    = $E07B
LE082    = $E082
LE088    = $E088
LE090    = $E090
LE09A    = $E09A
ENEXT    = $E0A9
EIF      = $E0BC
LE0C7    = $E0C7
LE0D4    = $E0D4
LE0E4    = $E0E4
LE0ED    = $E0ED
LE0F4    = $E0F4
ELET     = $E0FE
EINPUT   = $E115
EREAD    = $E127
LE12A    = $E12A
LE145    = $E145
LE15C    = $E15C
LE15E    = $E15E
LE164    = $E164
EDIM     = $E166
LE16C    = $E16C
EON      = $E176
LE180    = $E180
LE185    = $E185
LE18D    = $E18D
LE194    = $E194
EPRINT   = $E19F
EMODE    = $E1D1
EENV     = $E1F6
ELIST    = $E228
EEDIT    = $E228
LE248    = $E248
EWAIT    = $E259
LE25F    = $E25F
LE266    = $E266
LE26F    = $E26F
LE272    = $E272
LE285    = $E285
EFILL    = $E28C
EDRAW    = $E28C
EDOT     = $E28F
ERUN     = $E295
EIMP     = $E29F
EALPHA   = $E2E6
IMPTT    = $E2F1
EPOKE    = $E302
EOUT     = $E302
ECURS    = $E302
ENC_ICI  = $E302
ECOLT    = $E30B
ECOLG    = $E30B
ENC6     = $E311
ETALK    = $E314
ECLEAR   = $E314
ENC_I    = $E314
ESOUND   = $E317
ENOISE   = $E325
LE32C    = $E32C
LE332    = $E332
LE33B    = $E33B
LE342    = $E342
ECALM    = $E344
ELOAD    = $E355
ESAVE    = $E355
EERR     = $E366
EREM     = $E366
ENC_D    = $E366
EREST    = $E369
EEND     = $E369
ENEW     = $E369
ERET     = $E369
ECHECK   = $E369
ECONT    = $E369
ESTEP    = $E369
ETROF    = $E369
ESTOP    = $E369
ETRON    = $E369
EUT      = $E369
EGOTO    = $E36A
EGOSUB   = $E36A
LE36D    = $E36D
LE376    = $E376
LE37C    = $E37C
LE399    = $E399
LE39C    = $E39C
LE3A1    = $E3A1
LE3A3    = $E3A3
EEXPI    = $E3B2
LE3C9_   = $E3C9
LE3F1    = $E3F1
LE3F8    = $E3F8
LE3FE    = $E3FE
LE444    = $E444
LE455    = $E455
ELODA    = $E4A9
ESAVA    = $E4A9
ENUM     = $E4C8
LE4F9    = $E4F9
LE4FB    = $E4FB
LE4FF    = $E4FF
LE501    = $E501
LE513    = $E513
EFUN     = $E522
EINT     = $E57B
LE590    = $E590
EFPT     = $E596
LE5A3    = $E5A3
LE5BC    = $E5BC
LE5BE    = $E5BE
LE653    = $E653
EARRN    = $E678
EVARI    = $E67D
LE695    = $E695
LE69C    = $E69C
LE6A6    = $E6A6
LE6B0    = $E6B0
LE6B5    = $E6B5
LE6BB    = $E6BB
LE6C8    = $E6C8
LE6D3    = $E6D3
LE6DB    = $E6DB
LE6DF    = $E6DF
LE6E3    = $E6E3
LE6EA    = $E6EA
LE6EE    = $E6EE
LE6F6    = $E6F6
RDID     = $E6FD
ELNR     = $E72A
LE731    = $E731
LE757    = $E757
LE770    = $E770
LE783    = $E783
LE797    = $E797
LE7CF    = $E7CF
LE7E5    = $E7E5
LE809    = $E809
LE81F    = $E81F
LE835    = $E835
TSEOC    = $E859
LE862    = $E862
ECHRI    = $E867
EERASE   = $E873
LE879    = $E879
LE880    = $E880
EHEX     = $E884
LE888    = $E888
LE893    = $E893
LE899    = $E899
EDATA    = $E8A2
LE8AB    = $E8AB
LE8AF    = $E8AF
LE8B7    = $E8B7
KEYTU    = $E8C5
KEYTS    = $E8FD
LE935    = $E935
INKEY    = $E93F
HREQ     = $E99C
LE9A4    = $E9A4
LE9F9    = $E9F9
LE9FA    = $E9FA
LEA00    = $EA00
LEA04    = $EA04
LEA09    = $EA09
CALRX    = $EA0D
LEA42    = $EA42
UT_ERROR = $EA62
ERRST    = $EA6A
UT_RESET = $EA74
MSESU    = $EA7D
UT_CMD   = $EA8E
DISPK    = $EAB3
DISP     = $EABE
ADALT    = $EADB
ADARG    = $EADE
ADACL    = $EAE1
ADACE    = $EAEB
ADADC    = $EAF4
ADART    = $EB07
ASHEX    = $EB15
LOOKK    = $EB26
LEB56    = $EB56
LEB5D    = $EB5D
LEBB0    = $EBB0
LEBDC    = $EBDC
LEBE2    = $EBE2
LEBEE    = $EBEE
LEC19    = $EC19
LEC1A    = $EC1A
LEC2C    = $EC2C
LEC33    = $EC33
LEC3E    = $EC3E
LEC45    = $EC45
LEC58    = $EC58
LEC63    = $EC63
LEC66    = $EC66
LEC7C    = $EC7C
MOVEK    = $EC83
ZEROK    = $ECBA
TSP      = $ED01
LSF      = $ED01
CIE      = $ED06
LADDR    = $ED18
LBYTE    = $ED1D
LED2F    = $ED2F
LCRLF    = $ED3A
LED40    = $ED40
FILLK    = $ED48
FILLMEM  = $ED54
SUBSK    = $ED5C
EXAMK    = $ED6E
VECXK    = $ED77
INXCK    = $ED80
GOK      = $ED8A
LED9C    = $ED9C
LEDB7    = $EDB7
LEDD5    = $EDD5
LEDE7    = $EDE7
LEDF9    = $EDF9
LEE09    = $EE09
LEE39    = $EE39
LEE44_3  = $EE44
LEE6A    = $EE6A
LEE9C    = $EE9C
LEEA8    = $EEA8
LEEB4    = $EEB4
LEEB8    = $EEB8
UT_BREAK = $EEC2
LEEC9    = $EEC9
LEECF    = $EECF
LEED5    = $EED5
LEED8    = $EED8
LEEDE_   = $EEDE
LEEE1    = $EEE1
LEEE4    = $EEE4
RHEXK    = $EF0F
LEF30    = $EF30
LEF35    = $EF35
LEF3E    = $EF3E
LEF44    = $EF44
LEF48    = $EF48
LEF61    = $EF61
LEF63    = $EF63
LEF74    = $EF74
LEF83    = $EF83
LEF8A    = $EF8A
LEF90    = $EF90
LEFB8    = $EFB8
LEFF4    = $EFF4
END_ROM3 = $F000
