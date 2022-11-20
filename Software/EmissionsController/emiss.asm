; Program that smoothsteps between random values and sends the result out over UART. Can be fed into OSC and VRC to control avatar emissions by a small program on the PC.

PSL_CC1          equ 0b10000000
PSL_CC0          equ 0b01000000
PSL_IDC          equ 0b00100000
PSL_BANK         equ 0b00010000
PSL_WITH_CARRY   equ 0b00001000
PSL_OVERFLOW     equ 0b00000100
PSL_LOGICAL_COMP equ 0b00000010
PSL_CARRY_FLAG   equ 0b00000001

mem_start equ 4096

M32_A1           equ mem_start+1
M32_A2           equ mem_start+2
M32_A3           equ mem_start+3
M32_A4           equ mem_start+4
M32_B1           equ mem_start+5
M32_B2           equ mem_start+6
M32_B3           equ mem_start+7
M32_B4           equ mem_start+8
M32_R1           equ mem_start+9
M32_R2           equ mem_start+10
M32_R3           equ mem_start+11
M32_R4           equ mem_start+12
M32_SIGN         equ mem_start+13
M32_UNSIGNED     equ mem_start+14
PSL_BACK1        equ mem_start+17
PSU_BACK1        equ mem_start+18
PSL_BACK2        equ mem_start+19
PSU_BACK2        equ mem_start+20
M32_RB1          equ mem_start+21
M32_RB2          equ mem_start+22
M32_RB3          equ mem_start+23
M32_RB4          equ mem_start+24
M32_RB5          equ mem_start+25
M32_CTR          equ mem_start+26
M32_CTR2         equ mem_start+27
R0_BACK          equ mem_start+28
R1_BACK          equ mem_start+29
R2_BACK          equ mem_start+30
R3_BACK          equ mem_start+31
SEED_1           equ mem_start+32
SEED_2           equ mem_start+33
SEED_3           equ mem_start+34
SEED_4           equ mem_start+35
OUTPUT_SHADOW equ mem_start+36

; Emissions Controller vars & constants
ADVANCE          equ 131072
ADVANCE_SLOW     equ 65536
A_1              equ mem_start+512
A_2              equ mem_start+513
A_3              equ mem_start+514
B_1              equ mem_start+515
B_2              equ mem_start+516
B_3              equ mem_start+517
DIFF_1           equ mem_start+518
DIFF_2           equ mem_start+519
DIFF_3           equ mem_start+520
DIFF_4           equ mem_start+521
X_1              equ mem_start+522
X_2              equ mem_start+523
X_3              equ mem_start+524
XX_1             equ mem_start+525
XX_2             equ mem_start+526
XX_3             equ mem_start+527
BTN_STATE        equ mem_start+528
SLOW_EMISS       equ mem_start+529
uart_delay_loops equ 230

org 0
programentry:
	eorz,r0
	lpsl
	wrtc,r0
	lodi,r0 0b00100000
	lpsu
	bsta,3 init_8251
	ppsl PSL_WITH_CARRY

	;lodi,r0 67
	;stra,r0 SEED_1
	;lodi,r0 207
	;stra,r0 SEED_2
	;lodi,r0 3
	;stra,r0 SEED_3
	;lodi,r0 69
	;stra,r0 SEED_4

	lodi,r3 255
seed_read_loop:
	bsta,un read_8251
	comi,r0 0
	bctr,eq seed_read_loop
	stra,r0 SEED_1,r3+
	comi,r3 3
	bcfr,eq seed_read_loop
	bsta,3 disable_rx_8251

	bsta,3 xorshift
	bsta,3 xorshift
	bsta,3 xorshift
	bsta,3 xorshift

	bsta,3 rng_B
	bsta,3 rng_B

	eorz r0
	stra,r0 M32_UNSIGNED
	stra,r0 X_1
	stra,r0 X_2
	stra,r0 X_3
	stra,r0 BTN_STATE
	stra,r0 SLOW_EMISS

emissions_loop:
	nop
	db 196 ;nopi,r0
	db 'e'
	db 197 ;nopi,r1
	db '6'
	db 198 ;nopi,r2
	db '2'
	db 199 ;nopi,r3
	db '1'
	db 144 ;nop
	db 145 ;also nop

	tpsu 128
	bctr,0 btn_not_pressed
	loda,r0 BTN_STATE
	bcfr,0 btn_held
	iori,r0 69
	stra,r0 BTN_STATE
	loda,r0 SLOW_EMISS
	eori,r0 1
	stra,r0 SLOW_EMISS
	bctr,3 btn_held
btn_not_pressed:
	eorz r0
	stra,r0 BTN_STATE
btn_held:

	bsta,3 calc_weight
	loda,r0 DIFF_1
	stra,r0 M32_B1
	loda,r0 DIFF_2
	stra,r0 M32_B2
	loda,r0 DIFF_3
	stra,r0 M32_B3
	loda,r0 DIFF_4
	stra,r0 M32_B4
	bsta,3 fixed_mul
	cpsl PSL_CARRY_FLAG
	loda,r0 M32_R1
	adda,r0 A_1
	loda,r1 M32_R2
	adda,r1 A_2
	loda,r2 M32_R3
	adda,r2 A_3
	bsta,3 print_formatted_value

	lodz r1
	bsta,3 print_formatted_value
	lodz r2
	bsta,3 print_formatted_value

	lodz,r2
	rrr,r0
	rrr,r0
	rrr,r0
	andi,r0 31
	loda,r3 SLOW_EMISS
	rrl,r3
	rrl,r3
	rrl,r3
	rrl,r3
	rrl,r3
	andi,r3 32
	iorz,r3
	wrtc,r0
	stra,r0 OUTPUT_SHADOW

	lodi,r0 '#'
	wrtd,r0
	bsta,un uart_delay

	loda,r0 SLOW_EMISS
	bctr,0 inc_x_fast
inc_x_slow:
	lodi,r1 ADVANCE_SLOW%256
	lodi,r2 ADVANCE_SLOW>>8%256
	lodi,r3 ADVANCE_SLOW>>16%256
	bctr,3 inc_x
inc_x_fast:
	lodi,r1 ADVANCE%256
	lodi,r2 ADVANCE>>8%256
	lodi,r3 ADVANCE>>16%256
inc_x:
	cpsl PSL_CARRY_FLAG
	loda,r0 X_1
	addz r1
	stra,r0 X_1
	loda,r0 X_2
	addz r2
	stra,r0 X_2
	loda,r0 X_3
	addz r3
	stra,r0 X_3
	eorz r0
	addi,r0 0
	bcta,0 emissions_loop
	bsta,3 rng_B
	eorz r0
	stra,r0 M32_B1
	stra,r0 M32_B2
	stra,r0 M32_B3
	db 182
	db 0b01000000
	cpsu 0b01000000
	bcta,0 emissions_loop
	ppsu 0b01000000
	bcta,3 emissions_loop

print_formatted_value:
	cpsl PSL_WITH_CARRY
	strz r3
	andi,r0 15
	addi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodz r3
	rrr,r0
	rrr,r0
	rrr,r0
	rrr,r0
	andi,r0 15
	addi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	bsta,un uart_delay
	ppsl PSL_WITH_CARRY
	retc,3

calc_weight:
	loda,r0 X_1
	stra,r0 M32_A1
	stra,r0 M32_B1
	loda,r0 X_2
	stra,r0 M32_A2
	stra,r0 M32_B2
	loda,r0 X_3
	stra,r0 M32_A3
	stra,r0 M32_B3
	eorz r0
	stra,r0 M32_A4
	stra,r0 M32_B4
	bsta,3 fixed_mul
	loda,r0 M32_R1
	stra,r0 M32_A1
	loda,r0 M32_R2
	stra,r0 M32_A2
	loda,r0 M32_R3
	stra,r0 M32_A3
	loda,r0 M32_R4
	stra,r0 M32_A4
	bsta,3 fixed_mul
	cpsl PSL_CARRY_FLAG
	loda,r0 M32_A1
	addz r0
	strz r1
	loda,r0 M32_A2
	addz r0
	strz r2
	loda,r0 M32_A3
	addz r0
	strz r3
	loda,r0 M32_A4
	addz r0
	stra,r0 M32_B4
	cpsl PSL_CARRY_FLAG
	adda,r1 M32_A1
	stra,r1 M32_A1
	adda,r2 M32_A2
	stra,r2 M32_A2
	adda,r3 M32_A3
	stra,r3 M32_A3
	loda,r0 M32_B4
	adda,r0 M32_A4
	stra,r0 M32_A4

	cpsl PSL_CARRY_FLAG
	loda,r0 M32_R1
	addz r0
	strz r1
	loda,r0 M32_R2
	addz r0
	strz r2
	loda,r0 M32_R3
	addz r0
	strz r3
	loda,r0 M32_R4
	addz r0
	stra,r0 M32_B1

	ppsl PSL_CARRY_FLAG
	loda,r0 M32_A1
	subz r1
	stra,r0 M32_A1
	loda,r0 M32_A2
	subz r2
	stra,r0 M32_A2
	loda,r0 M32_A3
	subz r3
	stra,r0 M32_A3
	loda,r0 M32_A4
	suba,r0 M32_B1
	stra,r0 M32_A4
	retc,3

rng_B:
	loda,r0 B_1
	stra,r0 A_1
	loda,r0 B_2
	stra,r0 A_2
	loda,r0 B_3
	stra,r0 A_3

	bsta,3 xorshift
	loda,r0 SEED_2
	stra,r0 B_1
	loda,r1 SEED_3
	stra,r1 B_2
	loda,r2 SEED_4
	stra,r2 B_3
	lodi,r3 0

	ppsl PSL_CARRY_FLAG
	suba,r0 A_1
	stra,r0 DIFF_1
	suba,r1 A_2
	stra,r1 DIFF_2
	suba,r2 A_3
	stra,r2 DIFF_3
	subi,r3 0
	stra,r3 DIFF_4

	retc,3

fixed_mul:
	stra,r0 R0_BACK
	stra,r1 R1_BACK
	stra,r2 R2_BACK
	spsl
	stra,r0 PSL_BACK1
	cpsl PSL_BANK
	ppsl PSL_WITH_CARRY+PSL_LOGICAL_COMP
	eorz r0
	stra,r0 M32_SIGN

	loda,r1 M32_UNSIGNED
	comi,r1 0
	bcfa,0 fixed_mul_unsigned

	loda,r1 M32_A4
	andi,r1 128
	bctr,0 fixed_mul_not_neg_a
	cpsl PSL_CARRY_FLAG
	lodi,r1 255
	lodi,r2 0
	loda,r0 M32_A1
	eorz r1
	addi,r0 1
	stra,r0 M32_A1
	loda,r0 M32_A2
	eorz r1
	addz r2
	stra,r0 M32_A2
	loda,r0 M32_A3
	eorz r1
	addz r2
	stra,r0 M32_A3
	loda,r0 M32_A4
	eorz r1
	addz r2
	stra,r0 M32_A4
	lodi,r2 1
	stra,r2 M32_SIGN
fixed_mul_not_neg_a:
	loda,r1 M32_B4
	andi,r1 128
	bctr,0 fixed_mul_not_neg_b
	cpsl PSL_CARRY_FLAG
	lodi,r1 255
	lodi,r2 0
	loda,r0 M32_B1
	eorz r1
	addi,r0 1
	stra,r0 M32_B1
	loda,r0 M32_B2
	eorz r1
	addz r2
	stra,r0 M32_B2
	loda,r0 M32_B3
	eorz r1
	addz r2
	stra,r0 M32_B3
	loda,r0 M32_B4
	eorz r1
	addz r2
	stra,r0 M32_B4
	loda,r2 M32_SIGN
	eori,r2 1
	stra,r2 M32_SIGN
fixed_mul_not_neg_b:
fixed_mul_unsigned:

	eorz r0
	strz r1
	stra,r0 M32_RB1
	stra,r0 M32_RB2
	stra,r0 M32_RB3
	stra,r0 M32_RB4
	stra,r0 M32_RB5
	ppsl PSL_BANK
	loda,r0 M32_B1
	strz r1
	loda,r0 M32_B2
	strz r2
	loda,r0 M32_B3
	strz r3
	cpsl PSL_BANK
	loda,r0 M32_B4
	strz r1
	eorz r0
	strz r3
	stra,r0 M32_CTR2
	strz r2
fixed_mul_loop:
	loda,r0 M32_A1,r2
	strz r2
	bsta,3 mul32_segment
	loda,r2 M32_CTR2
	comi,r2 3
	bctr,0 fixed_mul_loop_end
	stra,r1 M32_CTR
	ppsl PSL_BANK
	lodz r2
	strz r1
	lodz r3
	strz r2
	loda,r3 M32_CTR
	cpsl PSL_BANK
	lodz r3
	strz r1
	eorz r0
	strz r3
	loda,r0 M32_RB2
	stra,r0 M32_RB1
	loda,r0 M32_RB3
	stra,r0 M32_RB2
	loda,r0 M32_RB4
	stra,r0 M32_RB3
	loda,r0 M32_RB5
	stra,r0 M32_RB4
	eorz r0
	stra,r0 M32_RB5
	addi,r2 1
	stra,r2 M32_CTR2
	bcta,3 fixed_mul_loop
fixed_mul_loop_end:
    loda,r0 M32_SIGN
    comi,r0 0
    bcfr,0 fixed_mul_negate_res
	loda,r0 M32_RB1
	stra,r0 M32_R1
	loda,r0 M32_RB2
	stra,r0 M32_R2
	loda,r0 M32_RB3
	stra,r0 M32_R3
	loda,r0 M32_RB4
	stra,r0 M32_R4
	bctr,3 fixed_mul_no_negate_res
fixed_mul_negate_res:
    lodi,r2 255
    lodi,r3 0
    loda,r0 M32_RB1
    eorz r2
    addi,r0 1
    stra,r0 M32_R1
    loda,r0 M32_RB2
    eorz r2
    addz r3
    stra,r0 M32_R2
    loda,r0 M32_RB3
    eorz r2
    addz r3
    stra,r0 M32_R3
    loda,r0 M32_RB4
    eorz r2
    addz r3
    stra,r0 M32_R4
fixed_mul_no_negate_res:
	loda,r0 PSL_BACK1
	lpsl
	loda,r0 R0_BACK
	loda,r1 R1_BACK
	loda,r2 R2_BACK
	retc,3

; Segment arg A in r2
; Segment arg B in memory at 1.r1 - 1.r2 - 1.r3 - 0.r1 - 0.r3
; Shifted result buffer in memory at M32_RB1 - M32_RB5
mul32_segment:
	lodi,r0 8
	stra,r0 M32_CTR
mul32_segment_loop:
	stra,r0 M32_CTR
	rrr,r2
	db 183
	db 1
	bcfr,0 mul32_segment_no_carry
	cpsl PSL_CARRY_FLAG
	ppsl PSL_BANK
	loda,r0 M32_RB1
	addz r1
	stra,r0 M32_RB1
	loda,r0 M32_RB2
	addz r2
	stra,r0 M32_RB2
	loda,r0 M32_RB3
	addz r3
	stra,r0 M32_RB3
	cpsl PSL_BANK
	loda,r0 M32_RB4
	addz r1
	stra,r0 M32_RB4
	loda,r0 M32_RB5
	addz r3
	stra,r0 M32_RB5
mul32_segment_no_carry:
	cpsl PSL_CARRY_FLAG
	ppsl PSL_BANK
	rrl,r1
	rrl,r2
	rrl,r3
	cpsl PSL_BANK
	rrl,r1
	rrl,r3
	loda,r0 M32_CTR
	bdra,r0 mul32_segment_loop
	retc,3

xorshift:
	spsl
	stra,r0 PSL_BACK1
	ppsl PSL_WITH_CARRY
	cpsl PSL_BANK
	lodi,r0 5
	loda,r1 SEED_1
	loda,r2 SEED_2
	loda,r3 SEED_3
xorshift_loop_1:
	cpsl PSL_CARRY_FLAG
	rrl,r1
	rrl,r2
	rrl,r3
	bdrr,r0 xorshift_loop_1

	eora,r0 SEED_1
	eora,r1 SEED_2
	eora,r2 SEED_3
	eora,r3 SEED_4
	lodz r3
	strz r1
	lodz r2
	lodi,r2 0
	lodi,r3 0
	cpsl PSL_CARRY_FLAG
	rrr,r1
	rrr,r0
	eora,r0 SEED_1
	eora,r1 SEED_2
	eora,r2 SEED_3
	eora,r3 SEED_4

	ppsl PSL_BANK
	lodi,r1 5
xorshift_loop_2:
	cpsl PSL_CARRY_FLAG+PSL_BANK
	rrl,r0
	rrl,r1
	rrl,r2
	rrl,r3
	ppsl PSL_BANK
	bdrr,r1 xorshift_loop_2
	cpsl PSL_BANK

	eora,r0 SEED_1
	eora,r1 SEED_2
	eora,r2 SEED_3
	eora,r3 SEED_4
	stra,r0 SEED_1
	stra,r1 SEED_2
	stra,r2 SEED_3
	stra,r3 SEED_4
	loda,r0 PSL_BACK1
	lpsl
	retc,3

init_8251:
	; Init UART
	; Reset
	lodi,r0 128
	wrtc,r0
	nop
	nop
	nop
	nop
	lodi,r0 64 ; Set to command-mode and un-reset
	wrtc,r0
	nop
	nop
	nop
	nop

	; Send mode word
	lodi,r0 0b01001110 ; 1 stop bit, no parity, 8-bit, 16X baud rate divisor
	wrtd,r0
	; Send command word
	lodi,r0 0b00010111 ; Enable TX, RX
	wrtd,r0
	eorz,r0
	stra,r0 OUTPUT_SHADOW
	; Put in data mode
	wrtc,r0
	nop
	nop
	retc,un

uart_delay:
	stra,r0 R0_BACK
	lodi,r0 64
	iora,r0 OUTPUT_SHADOW
	wrtc,r0
uart_delay_loop:
	nop
	nop
	nop
	nop
	redd,r0
	andi,r0 4
	bctr,0 uart_delay_loop

	loda,r0 OUTPUT_SHADOW
	andi,r0 0b10111111
	wrtc,r0
	nop
	nop

	loda,r0 R0_BACK
	retc,un

read_8251:
	stra,r1 R0_BACK
	lodi,r0 64
	iora,r0 OUTPUT_SHADOW
	wrtc,r0
	nop
	nop
	nop
	nop
	redd,r1
	loda,r0 OUTPUT_SHADOW
	andi,r0 0b10111111
	wrtc,r0
	andi,r1 2
	bctr,0 read_8251_return
	redd,r1
	nop
	lodz,r1
read_8251_return:
	loda,r1 R0_BACK
	retc,un

disable_rx_8251:
	stra,r0 R0_BACK
	lodi,r0 64
	iora,r0 OUTPUT_SHADOW
	wrtc,r0
	nop
	nop
	nop
	nop
	lodi,r0 0b00010011
	wrtd,r0
	loda,r0 OUTPUT_SHADOW
	andi,r0 0b10111111
	wrtc,r0
	nop
	loda,r0 R0_BACK
	retc,un

end
