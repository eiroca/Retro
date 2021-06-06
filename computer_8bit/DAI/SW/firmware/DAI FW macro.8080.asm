;
.macro _FUNC(mode, addr)
.if mode == 0
	.word addr
.endif
.if mode != 0
	.word addr & $7FFF
.endif
.endmacro
;
.macro PSTR(str)
	.byte	@str_end - @str_str
@str_str	.ascii	str
@str_end
.endmacro
;
.macro OPE(name, opcode)
	.byte	@str_end - @str_str
@str_str	.ascii	name
@str_end	.byte	opcode
.endmacro
;
.macro FNC(name, mode1, mode2=$FFFF, mode3=$FFFF, mode4=$FFF)
	.byte	@str_end - @str_str
@str_str	.ascii	name
@str_end	.byte	mode1
.if mode2>=0 && mode2<=$FF
	.byte	mode2
.endif
.if mode3>=0 && mode3<=$FF
	.byte	mode3
.endif
.if mode4>=0 && mode4<=$FF
	.byte	mode4
.endif
.endmacro
;
.macro TBL1(adr, mod)
	.word	adr
	.byte	mod
.endmacro
;
.macro BCMD(name,type,addr)
	.byte	@str_end - @str_str
@str_str	.ascii	name
@str_end	.byte	type
	.word	addr
.endmacro
;
.macro REF_STR(type,addr)
	.byte	((addr - $C000) >> 8 & $0F) | type << 4
	.byte	((addr - $C000) & $FF)
.endmacro
;
.macro BAS_TYPE(name,type)
	.byte	@str_end - @str_str
@str_str	.ascii	name
@str_end	.byte	type
.endmacro
;
.macro BAS_ENC(name,addr,code,erraddr)
	.byte	@str_end - @str_str
@str_str	.ascii	name
@str_end	.word	addr
	.byte	code
	.word	erraddr
.endmacro
;
.macro BAS_ENC2(name,addr)
	.byte	@str_end - @str_str
@str_str	.ascii	name
@str_end	.word	addr
.endmacro
;
.macro UT_CMD(cmd,addr)
	.byte	cmd
	.word	addr
.endmacro
;
.macro ROMCALL(romid, callid)
	RST	romid
	.byte	callid
.endmacro
;
.macro CALL_W(addr, data)
	CALL	addr
	.word	data
.endmacro
;
.macro CALL_B(addr, data)
	CALL	addr
	.byte	data
.endmacro
