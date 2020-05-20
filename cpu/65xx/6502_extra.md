# Extra Instructions Of The 65XX Series CPU

By: Adam Vardy (abe0084@infonet.st-johns.nf.ca) - 22, Aug. 1995... 27, Sept. 1996

References:
* [Extra Instructions Of The 65XX Series CPU](http://www.ffd2.com/fridge/docs/6502-NMOS.extra.opcodes)
* Joel Shepherd. "Extra Instructions" COMPUTE!, October 1983.
* Jim Butterfield. "Strange Opcodes" COMPUTE, March 1993.
* Raymond Quirling. "6510 Opcodes" The Transactor, March 1986.
* John West, Marko Mäkelä. '64doc' file, 1994/06/03.

The following is a list of 65XX/85XX extra opcodes. The operation codes for the 6502 CPU fit in a single byte; out of 256 possible combinations, only 151 are "legal." This text describes the other 256-151= 105 operation codes. These opcodes are not generally recognized as part of the 6502 instruction set. They are also referred to as undefined opcodes or undocumented opcodes or non-standard opcodes or unofficial opcodes. In "The Commodore 64 Programmer's Reference Guide" their hexadecimal values are simply marked as future expansion. This list of opcodes was compiled with help from "The Complete Inner Space Anthology" by Karl J. H. Hildon.

At times, I also included an alternate name in parenthesis.
All opcode values are given in hexadecimal. These hexadecimal values are listed immediately to the right of any sample code. The lowercase letters found in these examples represent the hex digits that you must provide as the instruction's immediate byte value or as the instruction's destination or source address. Thus immediate values and zero page addresses are referred to as 'ab'. For absolute addressing mode the two bytes of an absolute address are referred to as 'cd' and 'ab'.

Execution times for all opcodes are given alongside to the very right of any sample code. A number of the opcodes described here combine the operation of two regular 6502 instructions. You can refer to a book on the 6502 instruction set for more information, such as which flags a particular instruction affects.


### ASO (SLO)
(Sub-instructions: ORA, ASL)

This opcode ASLs the contents of a memory location and then ORs the result with the accumulator.

| Example    | Equivalent |
| ---------- | ---------- |
| ASO $C010  | ASL $C010 <br/> ORA $C010 |

Supported modes:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| ASO abcd     | 0F cd ab | 6 |
| ASO abcd, X  | 1F cd ab | 7 |
| ASO abcd, Y  | 1B cd ab | 7 |
| ASO ab       | 07 ab    | 5 |
| ASO ab, X    | 17 ab    | 6 |
| ASO (ab, X)  | 03 ab    | 8 |
| ASO (ab), Y  | 13 ab    | 8 |


### RLA
(Sub-instructions: AND, ROL)

RLA ROLs the contents of a memory location and then ANDs the result with the accumulator.

| Example    | Equivalent |
| ---------- | ---------- |
| RLA $FC, X | ROL $FC, X <br/> AND $FC, X |

Supported modes:

| Instruction | OpCodes  | Cycles |
| ----------- | -------- | ------:|
| RLA abcd    | 2F cd ab | 6 |
| RLA abcd, X | 3F cd ab | 7 |
| RLA abcd, Y | 3B cd ab | 7 |
| RLA ab      | 27 ab    | 5 |
| RLA ab, X   | 37 ab    | 6 |
| RLA (ab, X) | 23 ab    | 8 |
| RLA (ab),Y  | 33 ab    | 8 |


### LSE (SRE)
(Sub-instructions: EOR, LSR)

LSE LSRs the contents of a memory location and then EORs the result with the accumulator.

| Example    | Equivalent |
| ---------- | ---------- |
| LSE $C100, X | LSR $C100, X <br/> EOR $C100, X |

Supported modes:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| LSE abcd     | 4F cd ab | 6 |
| LSE abcd, X  | 5F cd ab | 7 |
| LSE abcd, Y  | 5B cd ab | 7 |
| LSE ab       | 47 ab    | 5 |
| LSE ab, X    | 57 ab    | 6 |
| LSE (ab, X)  | 43 ab    | 8 |
| LSE (ab), Y  | 53 ab    | 8 |


### RRA
(Sub-instructions: ADC, ROR)

RRA RORs the contents of a memory location and then ADCs the result with the accumulator.

| Example    | Equivalent |
| ---------- | ---------- |
| RRA $030C  | ROR $030C <br/> ADC $030C |

Supported modes:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| RRA abcd     | 6F cd ab | 6 |
| RRA abcd, X  | 7F cd ab | 7 |
| RRA abcd, Y  | 7B cd ab | 7 |
| RRA ab       | 67 ab    | 5 |
| RRA ab, X    | 77 ab    | 6 |
| RRA (ab, X)  | 63 ab    | 8 |
| RRA (ab), Y  | 73 ab    | 8 |


## AXS (SAX)
(Sub-instructions: STA, STX)

AXS ANDs the contents of the A and X registers (without changing the contents of either register) and stores the result in memory. AXS does not affect any flags in the processor status register.

| Example    | Equivalent |
| ---------- | ---------- |
| AXS $FE    | STX $FE <br/> PHA <br/> AND $FE <br/> STA $FE <br/> PLA |

Supported modes:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| AXS abcd     | 8F cd ab | 4 |
| AXS ab       | 87 ab    | 3 |
| AXS ab, Y    | 97 ab    | 4 |
| AXS (ab, X)  | 83 ab    | 6 |


### LAX
(Sub-instructions: LDA, LDX)

This opcode loads both the accumulator and the X register with the contents of a memory location.

| Example      | Equivalent |
| ------------ | ---------- |
| LAX $8400, Y | LDA $8400, Y <br/> LDX $8400, Y |

Supported modes:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| LAX abcd     | AF cd ab | 4  |
| LAX abcd, Y  | BF cd ab | 4* |
| LAX ab       | A7 ab    | 3  |
| LAX ab, Y    | B7 ab    | 4  |
| LAX (ab, X)  | A3 ab    | 6  |
| LAX (ab), Y  | B3 ab    | 5* |

    * add 1 if page boundary is crossed

### DCM (DCP)
(Sub-instructions: CMP, DEC)

This opcode DECs the contents of a memory location and then CMPs the result with the A register.

Supported modes:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| DCM abcd     | CF cd ab | 6 |
| DCM abcd, X  | DF cd ab | 7 |
| DCM abcd, Y  | DB cd ab | 7 |
| DCM ab       | C7 ab    | 5 |
| DCM ab, X    | D7 ab    | 6 |
| DCM (ab, X)  | C3 ab    | 8 |
| DCM (ab), Y  | D3 ab    | 8 |

Example:

| Example      | Equivalent |
| ------------ | ---------- |
| DCM $FF      | DEC $FF <br/> CMP $FF |


### INS (ISC)
(Sub-instructions: SBC, INC)

This opcode INCs the contents of a memory location and then SBCs the result from the A register.

Supported modes:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| INS abcd     | EF cd ab | 6 |
| INS abcd, X  | FF cd ab | 7 |
| INS abcd, Y  | FB cd ab | 7 |
| INS ab       | E7 ab    | 5 |
| INS ab, X    | F7 ab    | 6 |
| INS (ab, X)  | E3 ab    | 8 |
| INS (ab), Y  | F3 ab    | 8 |

Example:

| Example      | Equivalent |
| ------------ | ---------- |
| INS $FF      | INC $FF <br/> SBC $FF |


### ALR
This opcode ANDs the contents of the A register with an immediate value and then LSRs the result.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| ALR #ab      | 4B ab    | 2 |

Example:

| Example      | Equivalent |
| ------------ | ---------- |
| ALR #$FE     | AND #$FE <br/> LSR A |


### ARR
This opcode ANDs the contents of the A register with an immediate value and then RORs the result.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| ARR #ab      | 6B ab    | 2 |

Here's an example of how you might write it in a program.

| Example      | Equivalent |
| ------------ | ---------- |
| ARR #$7F     | AND #$7F <br/> ROR A |


### XAA
XAA transfers the contents of the X register to the A register and then ANDs the A register with an immediate value.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| XAA #ab      | 8B ab    | 2 |

Example:

| Example      | Equivalent |
| ------------ | ---------- |
| XAA #$44     | TXA <br/> AND #$44 |


### OAL
This opcode ORs the A register with #$EE, ANDs the result with an immediate value, and then stores the result in both A and X.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| OAL #ab      | AB ab    | 2 |

Here's an example of how you might use this opcode:

| Example      | Equivalent |
| ------------ | ---------- |
| OAL #$AA     | ORA #$EE <br/> AND #$AA <br/> TAX |


### SAX
SAX ANDs the contents of the A and X registers (leaving the contents of A intact), subtracts an immediate value, and then stores the result in X. ... A few points might be made about the action of subtracting an immediate value. It actually works just like the CMP instruction, except that CMP does not store the result of the subtraction it performs in any register. This subtract operation is not affected by the state of the Carry flag, though it does affect the Carry flag. It does not affect the Overflow flag.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| SAX #ab      | CB ab    | 2 |

Example:

| Example      | Equivalent |
| ------------ | ---------- |
| SAX #$5A     | STA $02 <br/> TXA <br/> AND $02 <br/> SEC <br/> SBC #$5A <br/> TAX <br/> LDA $02 |

Note: Memory location $02 would not be altered by the SAX opcode.


### NOP
NOP performs no operation. Opcodes: 1A, 3A, 5A, 7A, DA, FA.
Takes 2 cycles to execute.


### SKB
SKB stands for skip next byte.
Opcodes: 80, 82, C2, E2, 04, 14, 34, 44, 54, 64, 74, D4, F4.
Takes 2, 3, or 4 cycles to execute.

Opcode 89 is another SKB instruction. It requires 2 cycles to execute.

### SKW
SKW skips next word (two bytes).
Opcodes: 0C, 1C, 3C, 5C, 7C, DC, FC.
Takes 4 cycles to execute.

To be dizzyingly precise, SKW actually performs a read operation. It's just that the value read is not stored in any register. Further, opcode 0C uses the absolute addressing mode. The two bytes which follow it form the absolute address. All the other SKW opcodes use the absolute indexed X addressing mode. If a page boundary is crossed, the execution time of one of these SKW opcodes is upped to 5 clock cycles.

--------------------------------------------------------------------------

The following opcodes were discovered and named exclusively by the author.
(Or so it was thought before.)

### HLT
HLT crashes the microprocessor. When this opcode is executed, program execution ceases. No hardware interrupts will execute either. The author has characterized this instruction as a halt instruction since this is the most straightforward explanation for this opcode's behavior. Only a reset will restart execution. This opcode leaves no trace of any operation performed! No registers affected.

Opcodes: 02, 12, 22, 32, 42, 52, 62, 72, 92, B2, D2, F2.


### TAS
(Sub-instructions: STA, TXS)

This opcode ANDs the contents of the A and X registers (without changing the contents of either register) and transfers the result to the stack pointer. It then ANDs that result with the contents of the high byte of the target address of the operand +1 and stores that final result in memory.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| TAS abcd, Y  | 9B cd ab | 5 |

Here is an example of how you might use this opcode:

| Example      | Equivalent |
| ------------ | ---------- |
| TAS $7700, Y | STX $02 <br/> PHA <br/> AND $02 <br/> TAX <br/> TXS <br/> AND #$78 <br/> STA $7700, Y <br/> PLA <br/> LDX $02 |

Note: Memory location $02 would not be altered by the TAS opcode.

Above I used the phrase 'the high byte of the target address of the operand +1'. By the words target address, I mean the unindexed address, the one specified explicitly in the operand. The high byte is then the second byte after the opcode (ab). So we'll shorten that phrase to AB+1.


### SAY
This opcode ANDs the contents of the Y register with <ab+1> and stores the result in memory.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| SAY abcd, X  | 9C cd ab | 5 |

Example:

| Example      | Equivalent |
| ------------ | ---------- |
| SAY $7700, X | PHA <br/> TYA <br/> AND #$78 <br/> STA $7700, X <br/> PLA |


### XAS
This opcode ANDs the contents of the X register with <ab+1> and stores the result in memory.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| XAS abcd, Y  | 9E cd ab | 5 |

Example:

| Example      | Equivalent |
| ------------ | ---------- |
| XAS $6430, Y | PHA <br/> TXA <br/> AND #$65 <br/> STA $6430, Y <br/> PLA |


### AXA
This opcode stores the result of A AND X AND the high byte of the target address of the operand +1 in memory.

Supported modes:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| AXA abcd, Y  | 9F cd ab | 5 |
| AXA (ab), Y  | 93 ab    | 6 |

Example:

| Example      | Equivalent |
| ------------ | ---------- |
| AXA $7133, Y | PHA <br/> STX $02 <br/> AND $02 <br/> AND #$72 <br/> STA $7133, Y <br/> PLA LDX $02 |

Note: Memory location $02 would not be altered by the AXA opcode.


The following notes apply to the above four opcodes: TAS, SAY, XAS, AXA.

None of these opcodes affect the accumulator, the X register, the Y register, or the processor status register!

The author has no explanation for the complexity of these instructions. It is hard to comprehend how the microprocessor could handle the convoluted sequence of events which appears to occur while executing one of these opcodes. A partial explanation for what is going on is that these instructions appear to be corruptions of other instructions. For example, the opcode SAY would have been one of the addressing modes of the standard instruction STY (absolute indexed X) were it not for the fact that the normal operation of this instruction is impaired in this particular instance.

One irregularity uncovered is that sometimes the actual value is stored in memory, and the AND with <ab+1> part drops off (ex. SAY becomes true STY). This happens very infrequently. The behavior appears to be connected with the video display. For example, it never seems to occur if either the screen is blanked or C128 2MHz mode is enabled.

WARNING: If the target address crosses a page boundary because of indexing, the instruction may not store at the intended address. It may end up storing in zero page, or another address altogether (page=value stored). Apparently certain internal 65XX registers are being overridden. The whole scheme behind this erratic behavior is very complex and strange.


### ANC
(Sub-instructions: AND, ROL)

ANC ANDs the contents of the A register with an immediate value and then moves bit 7 of A into the Carry flag. This opcode works basically identically to AND #immed. except that the Carry flag is set to the same state that the Negative flag is set to.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| ANC #ab      | 2B ab    | 2 |
| ANC #ab      | 0B ab    |   |


### LAS
This opcode ANDs the contents of a memory location with the contents of the stack pointer register and stores the result in the accumulator, the X register, and the stack pointer. Affected flags: N Z.

One supported mode:

| Instruction  | OpCodes  | Cycles |
| ------------ | -------- | ------:|
| LAS abcd, Y  | BB cd ab | 4* |

### OPCODE EB
Opcode EB seems to work exactly like SBC #immediate. Takes 2 cycles.

------

This list is a full and complete list of all undocumented opcodes, every last hex value. It provides complete and thorough information and it also corrects some incorrect information found elsewhere. The opcodes MKA and MKX (also known as TSTA and TSTX) as described in "The Complete Commodore Inner Space Anthology" do not exist. Also, it is erroneously indicated there that the instructions ASO, RLA, LSE, RRA have an immediate addressing mode. (RLA #ab would be ANC #ab.)

The opcode ARR operates more complexly than actually described in the list above. Here is a brief rundown on this. The following assumes the decimal flag is clear. You see, the sub-instruction for ARR ($6B) is in fact ADC ($69), not AND. While ADC is not performed, some of the ADC mechanics are evident. Like ADC, ARR affects the overflow flag. The following effects occur after ANDing but before RORing. The V flag is set to the result of exclusive ORing bit 7 with bit 6. Unlike ROR, bit 0 does not go into the carry flag. The state of bit 7 is exchanged with the carry flag. Bit 0 is lost. All of this may appear strange, but it makes sense if you consider the probable internal operations of ADC itself.

SKB opcodes 82, C2, E2 may be HLTs. Since only one source claims this, and no other sources corroborate this, it must be true on very few machines. On all others, these opcodes always perform no operation.

LAS is suspect. This opcode is possibly unreliable.

> OPCODE BIT-PATTERN: 10x0 1011

Now it is time to discuss XAA ($8B) and OAL ($AB). A fair bit of controversy has surrounded these two opcodes. There are two good reasons for this:
  1. They are rather weird in operation.
  2. They do operate differently on different machines. Highly variable.

Here is the basic operation: OAL

This opcode ORs the A register with #xx, ANDs the result with an immediate value, and then stores the result in both A and X.

On my 128, xx may be EE, EF, FE, OR FF. These possibilities appear to depend on three factors: the X register, PC, and the previous instruction executed. Bit 0 is ORed from x, and also from PCH. As for XAA, on my 128 this opcode appears to work exactly as described in the list.

On my 64, OAL produces all sorts of values for xx: 00, 04, 06, 80, etc... A rough scenario I worked out to explain this is here. The constant value EE disappears entirely. Instead of ORing with EE, the accumulator is ORed with certain bits of X and also ORed with certain bits of another "register" (nature unknown, whether it be the data bus, or something else). However, if OAL is preceded by certain other instructions like NOP, the constant value EE reappears and the foregoing does not take place.

On my 64, XAA works like this. While X is transferred to A, bit 0 and bit 4 are not. Instead, these bits are ANDed with those bits from A, and the result is stored in A.

There may be many variations in the behavior of both opcodes. XAA #$00 or OAL #$00 are likely quite reliable in any case. It seems clear that the video chip (i.e., VIC-II) bears responsibility for some small part of the anomalousness, at least. Beyond that, the issue is unclear.

One idea I'll just throw up in the air about why the two opcodes behave as they do is this observation. While other opcodes like 4B and 6B perform AND as their first step, 8B and AB do not. Perhaps this difference leads to some internal conflict in the microprocessor. Besides being subject to "noise", the actual base operations do not vary.

All of the opcodes in this list (at least up to the dividing line) use the naming convention from the CCISA Anthology book. There is another naming convention used, for example in the first issue of C=Hacking. The only assembler I know of that supports undocumented opcodes is Power Assembler. And it uses the same naming conventions as used here.

One note on a different topic. A small error has been pointed out in the 64 Programmers Reference Guide with the instruction set listing. In the last row, in the last column of the two instructions AND and ORA there should be an asterisk, just as there is with ADC. That is the indirect,Y addressing mode. In another table several pages later correct information is given.

(A correction: There was one error in this document originally. One addressing mode for LAX was given as LAX ab,X. This should have been LAX ab,Y (B7). Also note that Power Assembler apparently has this same error, likely because both it and this document derive first from the same source as regards these opcodes. Coding LAX $00,X is accepted and produces the output B7 00)
