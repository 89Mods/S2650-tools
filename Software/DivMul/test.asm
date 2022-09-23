; Implementations of various multiplication and division algorithms

PSL_CC1          equ 0b10000000
PSL_CC0          equ 0b01000000
PSL_IDC          equ 0b00100000
PSL_BANK         equ 0b00010000
PSL_WITH_CARRY   equ 0b00001000
PSL_OVERFLOW     equ 0b00000100
PSL_LOGICAL_COMP equ 0b00000010
PSL_CARRY_FLAG   equ 0b00000001

mem_start equ 4096

OUTPUT_SHADOW equ mem_start+768
R0_BACK equ mem_start+769

org 0
programentry:
	lodi,r0 0
	wrtc,r0
	lpsl
	lodi,r0 0b00100000
	lpsu
	bsta,3 init_8251
	db 196 ;nopi,r0
	db 't'
	db 197 ;nopi,r1
	db 'e'
	db 198 ;nopi,r2
	db 's'
	db 199 ;nopi,r3
	db 't'
	db 144 ;nop
	db 145 ;also nop
	eorz r0
	stra,r0 mem_start+22
test_loop:
	stra,r0 mem_start
	strz r2
	adda,r2 mem_start
	; Do mul & print result
	loda,r0 test_ins,r2
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 '*'
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	loda,r0 test_ins,r2+
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 '='
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	
	loda,r1 mem_start
	adda,r1 mem_start
	loda,r0 test_ins,r1
	strz r2
	loda,r0 test_ins,r1+
	strz r3
	bsta,3 mul_8x8_8
	strz r2
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	
	loda,r0 mem_start
	loda,r0 test_results,r0
	comz r3
	bcfr,0 incorrect_res
	lodi,r0 50
	bsta,3 set_console_color
	lodi,r0 226
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x9C
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x93
	wrtd,r0
	bsta,un uart_delay
	bctr,3 correct_res
incorrect_res:
	lodi,r0 49
	stra,r0 mem_start+22
	bsta,3 set_console_color
	lodi,r0 'X'
	wrtd,r0
	bsta,un uart_delay
correct_res:
	bsta,3 reset_console_color
	bsta,3 print_newline
	
	loda,r0 mem_start
	addi,r0 1
	comi,r0 16
	bcfa,0 test_loop
	
	eorz r0
test_loop_16:
	stra,r0 mem_start
	strz r2
	loda,r0 test_ins_16,r2
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 '*'
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	loda,r0 test_ins_16,r2+
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 '='
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	
	loda,r1 mem_start
	loda,r0 test_ins_16,r1
	strz r2
	loda,r0 test_ins_16,r1+
	strz r3
	bsta,3 mul_8x8_16
	ppsl PSL_BANK
	lodz r2
	cpsl PSL_BANK
	bsta,3 print_hex
	ppsl PSL_BANK
	lodz r3
	cpsl PSL_BANK
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	
	ppsl PSL_BANK
	loda,r1 mem_start
	loda,r0 test_results_16,r1
	comz r2
	bcfr,0 incorrect_res_16
	loda,r0 test_results_16,r1+
	comz r3
	bcfr,0 incorrect_res_16
	lodi,r0 49
	bsta,3 set_console_color
	lodi,r0 50
	bsta,3 set_console_color
	lodi,r0 226
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x9C
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x93
	wrtd,r0
	bsta,un uart_delay
	bctr,3 correct_res_16
incorrect_res_16:
	lodi,r0 49
	stra,r0 mem_start+22
	bsta,3 set_console_color
	lodi,r0 'X'
	wrtd,r0
	bsta,un uart_delay
correct_res_16:
	cpsl PSL_BANK
	bsta,3 reset_console_color
	bsta,3 print_newline
	
	loda,r0 mem_start
	addi,r0 2
	comi,r0 32
	bcfa,0 test_loop_16
	
	eorz r0
test_loop_div:
	stra,r0 mem_start
	strz r2
	adda,r2 mem_start
	; Do mul & print result
	loda,r0 test_ins_div,r2
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 '/'
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	loda,r0 test_ins_div,r2+
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 '='
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	
	loda,r1 mem_start
	adda,r1 mem_start
	loda,r0 test_ins_div,r1
	strz r2
	loda,r0 test_ins_div,r1+
	strz r3
	bsta,3 div_8x8
	strz r2
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	
	loda,r0 mem_start
	loda,r0 test_results_div,r0
	comz r3
	bcfr,0 incorrect_res_div
	lodi,r0 50
	bsta,3 set_console_color
	lodi,r0 226
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x9C
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x93
	wrtd,r0
	bsta,un uart_delay
	bctr,3 correct_res_div
incorrect_res_div:
	lodi,r0 49
	stra,r0 mem_start+2
	bsta,3 set_console_color
	lodi,r0 'X'
	wrtd,r0
	bsta,un uart_delay
correct_res_div:
	bsta,3 reset_console_color
	bsta,3 print_newline
	
	loda,r0 mem_start
	addi,r0 1
	comi,r0 16
	bcfa,0 test_loop_div
	
	eorz r0
test_loop_div_16:
	stra,r0 mem_start
	strz r2
	adda,r2 mem_start
	adda,r2 mem_start
	loda,r0 test_ins_div_16,r2
	bsta,3 print_hex
	loda,r0 test_ins_div_16,r2+
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 '/'
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	loda,r0 test_ins_div_16,r2+
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 '='
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	
	loda,r1 mem_start
	adda,r1 mem_start
	adda,r1 mem_start
	loda,r0 test_ins_div_16,r1
	stra,r0 mem_start+5
	loda,r0 test_ins_div_16,r1+
	strz r2
	loda,r0 test_ins_div_16,r1+
	strz r3
	loda,r1 mem_start+5
	bsta,3 div_16x8
	ppsl PSL_BANK
	lodz r2
	cpsl PSL_BANK
	bsta,3 print_hex
	ppsl PSL_BANK
	lodz r3
	cpsl PSL_BANK
	bsta,3 print_hex
	lodi,r0 ' '
	wrtd,r0
	bsta,un uart_delay
	
	ppsl PSL_BANK
	loda,r1 mem_start
	adda,r1 mem_start
	loda,r0 test_results_div_16,r1
	comz r2
	bcfr,0 incorrect_res_div_16
	loda,r0 test_results_div_16,r1+
	comz r3
	bcfr,0 incorrect_res_div_16
	lodi,r0 50
	bsta,3 set_console_color
	lodi,r0 226
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x9C
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x93
	wrtd,r0
	bsta,un uart_delay
	bctr,3 correct_res_div_16
incorrect_res_div_16:
	lodi,r0 49
	stra,r0 mem_start+22
	bsta,3 set_console_color
	lodi,r0 'X'
	wrtd,r0
	bsta,un uart_delay
correct_res_div_16:
	cpsl PSL_BANK
	bsta,3 reset_console_color
	bsta,3 print_newline
	
	loda,r0 mem_start
	addi,r0 1
	comi,r0 16
	bcfa,0 test_loop_div_16
	
	loda,r0 mem_start+22
	bcfr,0 tests_pass
	lodi,r1 255
	bctr,3 tests_fail
tests_pass:
	lodi,r1 error_string-pass_string-1
tests_fail:
print_loop:
	loda,r0 pass_string,r1+
	bctr,0 print_loop_exit
	wrtc,r0
	bctr,3 print_loop
print_loop_exit:
	
	ppsu 0b01000000
end_loop:
	nop
	;tpsu 0b10000000
	db 182 ;Same instruction, different encoding
	db 0b10000000
	bctr,0 end_loop
	bcta,3 programentry

mul_8x8_8:
	spsl
	stra,r0 mem_start+1
	lodi,r1 8
	eorz r0
	ppsl PSL_WITH_CARRY
mul_8x8_8_loop:
	rrr,r2
	;tpsl PSL_CARRY_FLAG
	db 183 ;Same instruction, but alternative encoding
	db 1
	bcfr,0 mul_8x8_8_no_carry
	cpsl PSL_CARRY_FLAG
	addz r3
mul_8x8_8_no_carry:
	rrl,r3
	andi,r3 254
	bdrr,r1 mul_8x8_8_loop
	strz r1
	loda,r0 mem_start+1
	lpsl
	lodz r1
	retc,3
	
mul_8x8_16:
	spsl
	stra,r0 mem_start+2
	lodi,r1 8
	lodz r3
	ppsl PSL_BANK
	strz r3
	eorz r0
	strz r1
	strz r2
	cpsl PSL_BANK
	ppsl PSL_WITH_CARRY
mul_8x8_16_loop:
	rrr,r2
	tpsl PSL_CARRY_FLAG
	ppsl PSL_BANK
	bcfr,0 mul_8x8_16_no_carry
	stra,r3 mem_start+1
	cpsl PSL_CARRY_FLAG
	adda,r1 mem_start+1
	addz r2
mul_8x8_16_no_carry:
	rrl,r3
	rrl,r2
	andi,r3 254
	cpsl PSL_BANK
	bdrr,r1 mul_8x8_16_loop
	ppsl PSL_BANK
	strz r2
	lodz r1
	strz r3
	loda,r0 mem_start+2
	lpsl
	retc,3
	
div_8x8:
	spsl
	stra,r0 mem_start+2
	cpsl PSL_BANK+PSL_CARRY_FLAG
	stra,r3 mem_start+1
	lodz r2
	strz r3
	loda,r0 mem_start+1
	lodi,r2 0
	lodi,r1 8
	ppsl PSL_BANK+PSL_LOGICAL_COMP+PSL_WITH_CARRY
	lodi,r1 0
div_8x8_loop:
	ppsl PSL_BANK
	rrl,r1
	cpsl PSL_BANK
	
	rrl,r3
	rrl,r2 ; Carry will be 0 after this, always
	
	comz r2
	bctr,1 div_8x8_comp
	ppsl PSL_CARRY_FLAG
	suba,r2 mem_start+1
	ppsl PSL_BANK+PSL_CARRY_FLAG
	addi,r1 0
	cpsl PSL_BANK
div_8x8_comp:
	bdrr,r1 div_8x8_loop
	ppsl PSL_BANK
	stra,r1 mem_start+1
	loda,r0 mem_start+2
	lpsl
	loda,r0 mem_start+1
	retc,3
	
div_16x8:
	spsl
	stra,r0 mem_start+2
	cpsl PSL_BANK+PSL_CARRY_FLAG
	stra,r3 mem_start+1
	lodz r1
	stra,r2 mem_start+3
	strz r2
	loda,r3 mem_start+3
	
	lodi,r1 0
	ppsl PSL_BANK+PSL_WITH_CARRY+PSL_LOGICAL_COMP
	eorz r0
	strz r3
	strz r2
	lodi,r1 16
	loda,r0 mem_start+1
div_16x8_loop:
	rrl,r3
	rrl,r2
	cpsl PSL_BANK
	
	rrl,r3
	rrl,r2
	rrl,r1 ; Carry will be 0 after this, always
	tpsl PSL_CARRY_FLAG
	bctr,0 div_16x8_special
	
	comz r1
	bctr,1 div_16x8_comp
div_16x8_special:
	ppsl PSL_CARRY_FLAG
	suba,r1 mem_start+1
	ppsl PSL_BANK+PSL_CARRY_FLAG
	addi,r3 0
div_16x8_comp:
	ppsl PSL_BANK
	bdrr,r1 div_16x8_loop
	loda,r0 mem_start+2
	lpsl
	retc,3
	
print_hex:
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
	retc,3
	
regdump:
	stra,r0 mem_start+44
	stra,r3 mem_start+45
	bstr,3 print_hex
	lodz r1
	bstr,3 print_hex
	lodz r2
	bstr,3 print_hex
	loda,r0 mem_start+45
	bstr,3 print_hex
	loda,r0 mem_start+44
	loda,r3 mem_start+45
	retc,3
	
print_newline: ; Prints a "\r\n"
	lodi,r0 0x0D
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x0A
	wrtd,r0
	bsta,un uart_delay
	retc,3
	
set_console_color:
	lodi,r1 27
	wrtd,r1
	bsta,un uart_delay
	lodi,r1 91
	wrtd,r1
	bsta,un uart_delay
	lodi,r1 51
	wrtd,r1
	bsta,un uart_delay
	wrtd,r0
	bsta,un uart_delay
	lodi,r1 109
	wrtd,r1
	bsta,un uart_delay
	lodi,r1 0
	wrtd,r1
	bsta,un uart_delay
	wrtd,r1
	bsta,un uart_delay
	wrtd,r1
	bsta,un uart_delay
	retc,3
	
reset_console_color:
	lodi,r1 27
	wrtd,r1
	bsta,un uart_delay
	lodi,r1 91
	wrtd,r1
	bsta,un uart_delay
	lodi,r1 48
	wrtd,r1
	bsta,un uart_delay
	lodi,r1 109
	wrtd,r1
	bsta,un uart_delay
	lodi,r1 0
	wrtd,r1
	bsta,un uart_delay
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
	
test_ins:
	db 5,8
	db 12,12
	db 8,22
	db 2,2
	db 1,1
	db 1,200
	db 200,1
	db 0,22
	db 22,0
	db 0,0
	db 22,11
	db 33,6
	db 33,33
	db 255,255
	db 127,2
	db 21,8
	
test_results:
	db 40
	db 144
	db 176
	db 4
	db 1
	db 200
	db 200
	db 0
	db 0
	db 0
	db 242
	db 198
	db 65
	db 1
	db 254
	db 168
	
test_ins_16:
	db 5,8
	db 22,33
	db 255,255
	db 0,200
	db 220,0
	db 0,0
	db 200,1
	db 1,200
	db 200,200
	db 32,8
	db 7,7
	db 22,99
	db 126,38
	db 128,128
	db 129,66
	db 77,8
	
test_results_16:
	db 0,40
	db 2,214
	db 254,1
	db 0,0
	db 0,0
	db 0,0
	db 0,200
	db 0,200
	db 156,64
	db 1,0
	db 0,49
	db 8,130
	db 18,180
	db 64,0
	db 33,66
	db 2,104
	
test_ins_div:
	db 5,8
	db 22,3
	db 222,1
	db 1,222
	db 0,22
	db 37,8
	db 179,3
	db 179,9
	db 179,11
	db 255,5
	db 128,33
	db 55,44
	db 66,7
	db 99,66
	db 7,7
	db 1,1
	
test_results_div:
	db 0
	db 7
	db 222
	db 0
	db 0
	db 4
	db 59
	db 19
	db 16
	db 51
	db 3
	db 1
	db 9
	db 1
	db 1
	db 1
	
test_ins_div_16:
	db 100,77,88
	db 218,192,200
	db 39,16,200
	db 0,55,6
	db 0,7,1
	db 0,1,22
	db 86,206,222
	db 255,255,255
	db 131,232,100
	db 225,200,1
	db 142,205,35
	db 0,99,7
	db 125,134,179
	db 19,136,33
	db 2,0,32
	db 0,32,32

test_results_div_16:
	db 1,35
	db 1,24
	db 0,50
	db 0,9
	db 0,7
	db 0,0
	db 0,100
	db 1,1
	db 1,81
	db 225,200
	db 4,20
	db 0,14
	db 0,179
	db 0,151
	db 0,16
	db 0,1
	
hex:
	db "0123456789ABCDEF"
pass_string:
	db "All pass!"
	db 0x0D
	db 0x0A
	db 0
error_string:
	db "Test failures detected!"
	db 0x0D
	db 0x0A
	db 0
end
