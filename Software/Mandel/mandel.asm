; Mandelbrot set renderer!

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
OUTPUT_SHADOW equ mem_start+90

; Mandel renderer vars
C1               equ mem_start+32
C2               equ mem_start+36
C3               equ mem_start+40
C4               equ mem_start+44
CURR_ROW         equ mem_start+48
CURR_COL         equ mem_start+49
C_IM             equ mem_start+50
C_RE             equ mem_start+54
MAN_X            equ mem_start+58
MAN_Y            equ mem_start+62
MAN_XX           equ mem_start+66
MAN_YY           equ mem_start+80
ITERATION        equ mem_start+84
uart_delay_loops equ 220

; Pre-computed constants for w=238, h=48
M_WIDTH          equ 238
M_HEIGHT         equ 48
C1_PRE           equ 1101
C4_PRE           equ 2730
W_D2             equ 119
H_D2             equ 24

; Settings
;ZOOM             equ 16210690
ZOOM             equ 436208
RE               equ 2684355
IMAG             equ 17456693
MAX_ITER         equ 400

org 0
programentry:
	eorz,r0
	lpsl
	wrtc,r0
	lodi,r0 0b00100000
	lpsu
	bsta,3 init_8251

	eorz r0
	stra,r0 M32_UNSIGNED

	; c1 = C1_PRE * ZOOM
	; c2 = W_D2 * c1
	eorz r0
	stra,r0 M32_A1
	stra,r0 M32_A4
	lodi,r0 C1_PRE%256
	stra,r0 M32_A2
	lodi,r0 C1_PRE>>8
	stra,r0 M32_A3
	lodi,r0 ZOOM%256
	stra,r0 M32_B1
	lodi,r0 ZOOM>>8%256
	stra,r0 M32_B2
	lodi,r0 ZOOM>>16%256
	stra,r0 M32_B3
	lodi,r0 ZOOM>>24%256
	stra,r0 M32_B4
	bsta,3 fixed_mul
	loda,r0 M32_R1
	stra,r0 C1+0
	stra,r0 M32_A1
	loda,r0 M32_R2
	stra,r0 C1+1
	stra,r0 M32_A2
	loda,r0 M32_R3
	stra,r0 C1+2
	stra,r0 M32_A3
	loda,r0 M32_R4
	stra,r0 C1+3
	stra,r0 M32_A4
	lodi,r0 W_D2
	stra,r0 M32_B4
	eorz r0
	stra,r0 M32_B1
	stra,r0 M32_B2
	stra,r0 M32_B3
	bsta,3 fixed_mul
	loda,r0 M32_R1
	stra,r0 C2+0
	loda,r0 M32_R2
	stra,r0 C2+1
	loda,r0 M32_R3
	stra,r0 C2+2
	loda,r0 M32_R4
	stra,r0 C2+3

	; c4 = C4_PRE * ZOOM
	; c3 = H_D2 * c4
	eorz r0
	stra,r0 M32_A1
	stra,r0 M32_A4
	lodi,r0 C4_PRE%256
	stra,r0 M32_A2
	lodi,r0 C4_PRE>>8
	stra,r0 M32_A3
	lodi,r0 ZOOM%256
	stra,r0 M32_B1
	lodi,r0 ZOOM>>8%256
	stra,r0 M32_B2
	lodi,r0 ZOOM>>16%256
	stra,r0 M32_B3
	lodi,r0 ZOOM>>24%256
	stra,r0 M32_B4
	bsta,3 fixed_mul
	loda,r0 M32_R1
	stra,r0 C4+0
	stra,r0 M32_A1
	loda,r0 M32_R2
	stra,r0 C4+1
	stra,r0 M32_A2
	loda,r0 M32_R3
	stra,r0 C4+2
	stra,r0 M32_A3
	loda,r0 M32_R4
	stra,r0 C4+3
	stra,r0 M32_A4
	lodi,r0 H_D2
	stra,r0 M32_B4
	eorz r0
	stra,r0 M32_B1
	stra,r0 M32_B2
	stra,r0 M32_B3
	bsta,3 fixed_mul
	loda,r0 M32_R1
	stra,r0 C3+0
	loda,r0 M32_R2
	stra,r0 C3+1
	loda,r0 M32_R3
	stra,r0 C3+2
	loda,r0 M32_R4
	stra,r0 C3+3

	ppsl PSL_WITH_CARRY
	lodi,r0 M_HEIGHT-1
mandel_loop_rows:
	stra,r0 CURR_ROW
	; res = row * c4
	stra,r0 M32_B4
	loda,r0 C4+0
	stra,r0 M32_A1
	loda,r0 C4+1
	stra,r0 M32_A2
	loda,r0 C4+2
	stra,r0 M32_A3
	loda,r0 C4+3
	stra,r0 M32_A4
	eorz r0
	stra,r0 M32_B1
	stra,r0 M32_B2
	stra,r0 M32_B3
	bsta,3 fixed_mul
	; c_im  = res + IMAG
	cpsl PSL_CARRY_FLAG
	lodi,r0 IMAG%256
	adda,r0 M32_R1
	stra,r0 C_IM+0
	lodi,r0 IMAG>>8%256
	adda,r0 M32_R2
	stra,r0 C_IM+1
	lodi,r0 IMAG>>16%256
	adda,r0 M32_R3
	stra,r0 C_IM+2
	lodi,r0 IMAG>>24%256
	adda,r0 M32_R4
	stra,r0 C_IM+3
	; c_im = c_im - c3
	ppsl PSL_CARRY_FLAG
	loda,r0 C_IM+0
	suba,r0 C3+0
	stra,r0 C_IM+0
	loda,r0 C_IM+1
	suba,r0 C3+1
	stra,r0 C_IM+1
	loda,r0 C_IM+2
	suba,r0 C3+2
	stra,r0 C_IM+2
	loda,r0 C_IM+3
	suba,r0 C3+3
	stra,r0 C_IM+3
	eorz r0
	; Toggle LED
	tpsu 0b01000000
	cpsu 0b01000000
	bctr,0 mandel_loop_cols
	ppsu 0b01000000
mandel_loop_cols:
	stra,r0 CURR_COL
	; res = col * C1
	stra,r0 M32_B4
	loda,r0 C1+0
	stra,r0 M32_A1
	loda,r0 C1+1
	stra,r0 M32_A2
	loda,r0 C1+2
	stra,r0 M32_A3
	loda,r0 C1+3
	stra,r0 M32_A4
	eorz r0
	stra,r0 M32_B1
	stra,r0 M32_B2
	stra,r0 M32_B3
	lodi,r0 1
	stra,r0 M32_UNSIGNED
	bsta,3 fixed_mul
	eorz r0
	stra,r0 M32_UNSIGNED
	; regs = res + RE
	cpsl PSL_CARRY_FLAG
	lodi,r0 RE%256
	eori,r0 255
	adda,r0 M32_R1
	lodi,r1 RE>>8%256
	eori,r1 255
	adda,r1 M32_R2
	lodi,r2 RE>>16%256
	eori,r2 255
	adda,r2 M32_R3
	lodi,r3 RE>>24%256
	eori,r3 255
	adda,r3 M32_R4
	; c_re = x = regs - c2
	ppsl PSL_CARRY_FLAG
	suba,r0 C2+0
	stra,r0 C_RE+0
	stra,r0 MAN_X+0
	suba,r1 C2+1
	stra,r1 C_RE+1
	stra,r1 MAN_X+1
	suba,r2 C2+2
	stra,r2 C_RE+2
	stra,r2 MAN_X+2
	suba,r3 C2+3
	stra,r3 C_RE+3
	stra,r3 MAN_X+3

	; y = c_im
	loda,r0 C_IM+0
	stra,r0 MAN_Y+0
	loda,r0 C_IM+1
	stra,r0 MAN_Y+1
	loda,r0 C_IM+2
	stra,r0 MAN_Y+2
	loda,r0 C_IM+3
	stra,r0 MAN_Y+3

	; iteration = 0
	eorz r0
	stra,r0 ITERATION+0
	stra,r0 ITERATION+1
mandel_calc_loop:
	; yy = y * y
	loda,r0 MAN_Y+0
	stra,r0 M32_A1
	stra,r0 M32_B1
	loda,r0 MAN_Y+1
	stra,r0 M32_A2
	stra,r0 M32_B2
	loda,r0 MAN_Y+2
	stra,r0 M32_A3
	stra,r0 M32_B3
	loda,r0 MAN_Y+3
	stra,r0 M32_A4
	stra,r0 M32_B4
	bsta,3 fixed_mul
	loda,r0 M32_R1
	stra,r0 MAN_YY+0
	loda,r0 M32_R2
	stra,r0 MAN_YY+1
	loda,r0 M32_R3
	stra,r0 MAN_YY+2
	loda,r0 M32_R4
	stra,r0 MAN_YY+3
	; res = x * y
	loda,r0 MAN_X+0
	stra,r0 M32_A1
	loda,r0 MAN_Y+0
	stra,r0 M32_B1
	loda,r0 MAN_X+1
	stra,r0 M32_A2
	loda,r0 MAN_Y+1
	stra,r0 M32_B2
	loda,r0 MAN_X+2
	stra,r0 M32_A3
	loda,r0 MAN_Y+2
	stra,r0 M32_B3
	loda,r0 MAN_X+3
	stra,r0 M32_A4
	loda,r0 MAN_Y+3
	stra,r0 M32_B4
	bsta,3 fixed_mul
	; regs = res << 1
	cpsl PSL_CARRY_FLAG
	loda,r0 M32_R1
	loda,r1 M32_R2
	loda,r2 M32_R3
	loda,r3 M32_R4
	rrl,r0
	rrl,r1
	rrl,r2
	rrl,r3
	; y = regs + c_im
	cpsl PSL_CARRY_FLAG
	adda,r0 C_IM+0
	adda,r1 C_IM+1
	adda,r2 C_IM+2
	adda,r3 C_IM+3
	stra,r0 MAN_Y+0
	stra,r1 MAN_Y+1
	stra,r2 MAN_Y+2
	stra,r3 MAN_Y+3
	; res = xx = x * x
	loda,r0 MAN_X+0
	stra,r0 M32_A1
	stra,r0 M32_B1
	loda,r0 MAN_X+1
	stra,r0 M32_A2
	stra,r0 M32_B2
	loda,r0 MAN_X+2
	stra,r0 M32_A3
	stra,r0 M32_B3
	loda,r0 MAN_X+3
	stra,r0 M32_A4
	stra,r0 M32_B4
	bsta,3 fixed_mul
	; regs = res - yy
	ppsl PSL_CARRY_FLAG
	loda,r0 M32_R1
	loda,r1 M32_R2
	loda,r2 M32_R3
	loda,r3 M32_R4
	stra,r0 MAN_XX+0
	stra,r1 MAN_XX+1
	stra,r2 MAN_XX+2
	stra,r3 MAN_XX+3
	suba,r0 MAN_YY+0
	suba,r1 MAN_YY+1
	suba,r2 MAN_YY+2
	suba,r3 MAN_YY+3
	; x = regs + c_re
	cpsl PSL_CARRY_FLAG
	adda,r0 C_RE+0
	adda,r1 C_RE+1
	adda,r2 C_RE+2
	adda,r3 C_RE+3
	stra,r0 MAN_X+0
	stra,r1 MAN_X+1
	stra,r2 MAN_X+2
	stra,r3 MAN_X+3

	; check if xx + yy <= 4
	cpsl PSL_CARRY_FLAG
	loda,r0 MAN_XX+0
	adda,r0 MAN_YY+0
	loda,r0 MAN_XX+1
	adda,r0 MAN_YY+1
	loda,r0 MAN_XX+2
	adda,r0 MAN_YY+2
	loda,r0 MAN_XX+3
	adda,r0 MAN_YY+3
	ppsl PSL_LOGICAL_COMP
	comi,r0 4
	cpsl PSL_LOGICAL_COMP
	bcfr,2 mandel_calc_loop_overflow

	; iteration++
	cpsl PSL_CARRY_FLAG
	loda,r0 ITERATION+0
	addi,r0 1
	stra,r0 ITERATION+0
	loda,r1 ITERATION+1
	addi,r1 0
	stra,r1 ITERATION+1
	comi,r1 MAX_ITER>>8
	bcfa,0 mandel_calc_loop
	comi,r0 MAX_ITER%256
	bcfa,0 mandel_calc_loop
	; Max iters exit
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	bcta,un mandel_calc_loop_exit ; TODO: Change back to relative jump
mandel_calc_loop_overflow:
	; Overflow exit
	loda,r0 ITERATION+0
	andi,r0 7
	cpsl PSL_WITH_CARRY
	addz r0
	addz r0
	addz r0
	ppsl PSL_WITH_CARRY
	strz r1
print_loop1:
	loda,r0 mandel_colors,r1+
	comi,r0 33
	bctr,0 print_loop1_exit
	wrtd,r0
	bsta,un uart_delay
	bctr,un print_loop1
;	andi,r0 15
;	strz r1
;	loda,r0 mandel_chars,r1
;	wrtd,r0

print_loop1_exit:
	lodi,r0 '#'
	wrtd,r0
	bsta,un uart_delay
;	loda,r0 ITERATION+1
;	rrr,r0
;	rrr,r0
;	rrr,r0
;	rrr,r0
;	andi,r0 15
;	loda,r0 hex,r0
;	wrtd,r0
;	loda,r0 ITERATION+1
;	andi,r0 15
;	loda,r0 hex,r0
;	wrtd,r0

;	loda,r0 ITERATION+0
;	rrr,r0
;	rrr,r0
;	rrr,r0
;	rrr,r0
;	andi,r0 15
;	loda,r0 hex,r0
;	wrtd,r0
;	loda,r0 ITERATION+0
;	andi,r0 15
;	loda,r0 hex,r0
;	wrtd,r0

mandel_calc_loop_exit:
	; End col loop
	loda,r0 CURR_COL
	cpsl PSL_CARRY_FLAG
	addi,r0 1
	comi,r0 M_WIDTH
	bcfa,0 mandel_loop_cols

	; End row loop
	loda,r0 newline+0
	wrtd,r0
	bsta,un uart_delay
	loda,r0 newline+1
	wrtd,r0
	bsta,un uart_delay
	loda,r0 CURR_ROW
	bdra,r0 mandel_loop_rows

	lodi,r1 255
print_loop2:
	loda,r0 mandel_color_reset,r1+
	comi,r0 0
	bctr,0 print_loop2_exit
	wrtd,r0
	bsta,un uart_delay
	bctr,3 print_loop2

print_loop2_exit:
	ppsu 0b01000000
end_loop:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	tpsu 0b10000000
	bctr,0 end_loop
	cpsu 0b01000000
	bcta,3 programentry

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
	tpsl PSL_CARRY_FLAG
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

print_mul_res:
	spsl
	stra,r0 PSL_BACK1
	cpsl PSL_CARRY_FLAG+PSL_LOGICAL_COMP
	ppsl PSL_WITH_CARRY
	lodi,r1 '+'
	loda,r0 M32_R4
	comi,r0 0
	bcfr,2 print_mul_res_pos
	lodi,r1 '-'
	lodi,r2 255
	lodi,r3 0
	loda,r0 M32_R1
	eorz r2
	addi,r0 1
	stra,r0 M32_R1
	loda,r0 M32_R2
	eorz r2
	addz r3
	stra,r0 M32_R2
	loda,r0 M32_R3
	eorz r2
	addz r3
	stra,r0 M32_R3
	loda,r0 M32_R4
	eorz r2
	addz r3
	stra,r0 M32_R4
print_mul_res_pos:
	wrtd,r1
	bsta,un uart_delay
	bstr,3 print_hex
	lodi,r0 '.'
	wrtd,r0
	bsta,un uart_delay
	loda,r0 M32_R3
	bstr,3 print_hex
	loda,r0 M32_R2
	bstr,3 print_hex
	loda,r0 M32_R1
	bstr,3 print_hex
	loda,r0 newline
	wrtd,r0
	bsta,un uart_delay
	loda,r0 newline+1
	wrtd,r0
	bsta,un uart_delay
	loda,r0 PSL_BACK1
	lpsl
	retc,3

print_hex:
	stra,r0 R0_BACK
	stra,r1 R1_BACK
	stra,r2 R2_BACK
	stra,r3 R3_BACK
	lpsl
	stra,r0 PSL_BACK2
	; Print first char
	strz r3
	rrr,r0
	rrr,r0
	rrr,r0
	rrr,r0
	andi,r0 15
	loda,r0 hex,r0
	wrtd,r0
	bsta,un uart_delay
	; Print second char
	lodz r3
	andi,r0 15
	loda,r0 hex,r0
	wrtd,r0
	bsta,un uart_delay
	loda,r0 PSL_BACK2
	spsl
	loda,r0 R0_BACK
	loda,r1 R1_BACK
	loda,r2 R2_BACK
	loda,r3 R3_BACK
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

hex:
	db "0123456789ABCDEF"
newline:
	db 0x0D
	db 0x0A
mandel_chars:
	db "..--:=itIJYVXRB#"
mandel_colors:
	db 33,27,91,51,49,109,0,33
	db 33,27,91,51,49,109,0,33
	db 33,27,91,51,50,109,0,33
	db 33,27,91,51,51,109,0,33
	db 33,27,91,51,52,109,0,33
	db 33,27,91,51,53,109,0,33
	db 33,27,91,51,54,109,0,33
	db 33,27,91,51,55,109,0,33
mandel_color_reset:
	db 27,91,48,109
	db "Done."
	db 0x0D
	db 0x0A
	db 0

end
