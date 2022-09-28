PSL_CC1          equ 0b10000000
PSL_CC0          equ 0b01000000
PSL_IDC          equ 0b00100000
PSL_BANK         equ 0b00010000
PSL_WITH_CARRY   equ 0b00001000
PSL_OVERFLOW     equ 0b00000100
PSL_LOGICAL_COMP equ 0b00000010
PSL_CARRY_FLAG   equ 0b00000001

mem_start equ 4096

R0_BACK       equ mem_start
R1_BACK       equ mem_start+1
R2_BACK       equ mem_start+2
R3_BACK       equ mem_start+3
OUTPUT_SHADOW equ mem_start+4
PRINT_PTR     equ mem_start+5 ; 2 bytes
USR_ADDR      equ mem_start+7 ; 2 bytes
IN_BUFF       equ mem_start+9 ; 8 bytes
INPUT_LEN     equ mem_start+17
WR_ADDR       equ mem_start+18 ; 2 bytes

TBL_UART_READ equ mem_start+2046
TBL_UART_WRITE equ mem_start+2044
TBL_UART_WAIT equ mem_start+2042
TBL_PRINT_STR equ mem_start+2040

org 0
programentry:
	eorz,r0
	lpsl
	wrtc,r0
	lodi,r0 0b00100000
	lpsu
	bsta,3 init_8251
	ppsl PSL_LOGICAL_COMP
	cpsl PSL_WITH_CARRY

	eorz,r0
	strz,r1
	strz,r2
	strz,r3
	ppsl PSL_BANK
	strz,r1
	strz,r2
	strz,r3
	cpsl PSL_BANK

	lodi,r0 write_8251>>8
	stra,r0 TBL_UART_READ
	lodi,r0 write_8251%256
	stra,r0 TBL_UART_READ+1

	lodi,r0 read_8251>>8
	stra,r0 TBL_UART_WRITE
	lodi,r0 read_8251%256
	stra,r0 TBL_UART_WRITE+1

	lodi,r0 uart_delay>>8
	stra,r0 TBL_UART_WAIT
	lodi,r0 uart_delay%256
	stra,r0 TBL_UART_WAIT+1

	lodi,r0 print_text>>8
	stra,r0 TBL_PRINT_STR
	lodi,r0 print_text%256
	stra,r0 TBL_PRINT_STR+1

	lodi,r0 text_init>>8
	stra,r0 PRINT_PTR
	lodi,r0 text_init%256
	stra,r0 PRINT_PTR+1
	bsta,un print_text

	ppsu 64
cmd_finish:
	bsta,un newline
	lodi,r0 '#'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
loop:
	nop
	bsta,un read_8251
	comi,r0 0
	bctr,eq loop
	comi,r0 'r'
	bcta,eq cmd_regdump
	comi,r0 'i'
	bcta,eq cmd_inspect
	comi,r0 'w'
	bcta,eq cmd_write
	comi,r0 'x'
	bcta,eq cmd_execute
	bctr,un loop

halt:
	bctr,un halt

cmd_inspect:
	lodi,r0 73
	bsta,un write_8251
	bsta,un newline
	bsta,un get_mem_addr_from_user
	comi,r0 0
	bcfa,eq i_abort_cmd
	
	bsta,un newline
	lodi,r0 text_instructions_1>>8
	stra,r0 PRINT_PTR
	lodi,r0 text_instructions_1%256
	stra,r0 PRINT_PTR+1
	bsta,un print_text
	bsta,un newline
	
i_print_bytes:
	loda,r0 USR_ADDR
	bsta,un print_hex
	loda,r0 USR_ADDR+1
	bsta,un print_hex
	lodi,r0 ' '
	bsta,un write_8251
	lodi,r0 '|'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	lodi,r3 255
i_print_bytes_loop:
	loda,r0 *USR_ADDR,r3+
	bsta,un print_hex
	lodi,r0 ' '
	bsta,un write_8251
	comi,r3 15
	bcfr,eq i_print_bytes_loop
	
	lodi,r0 '|'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	loda,r0 USR_ADDR
	stra,r0 PRINT_PTR
	loda,r0 USR_ADDR+1
	stra,r0 PRINT_PTR+1
	lodi,r0 15
	stra,r0 INPUT_LEN
	bsta,un dump_bytes
	bsta,un newline
	
i_wait_for_confirm:
	bsta,un read_8251
	comi,r0 0
	bctr,eq i_wait_for_confirm
	comi,r0 0x0D
	bctr,eq print_next_bytes
	comi,r0 'q'
	bcta,eq cmd_finish
	bctr,un i_wait_for_confirm
	
i_abort_cmd:
	stra,r3 R3_BACK
	lodi,r0 text_abort>>8
	stra,r0 PRINT_PTR
	lodi,r0 text_abort%256
	stra,r0 PRINT_PTR+1
	bsta,un print_text
	bcta,un cmd_finish
	
print_next_bytes:
	loda,r0 USR_ADDR+1
	addi,r0 16
	stra,r0 USR_ADDR+1
	loda,r0 USR_ADDR
	ppsl PSL_WITH_CARRY
	addi,r0 0
	stra,r0 USR_ADDR
	cpsl PSL_WITH_CARRY
	bcta,un i_print_bytes

cmd_write:
	lodi,r0 87
	bsta,un write_8251
	bsta,un newline
	bsta,un get_mem_addr_from_user
	comi,r0 0
	bcfa,eq i_abort_cmd
	
	bsta,un newline
	lodi,r0 text_instructions_2>>8
	stra,r0 PRINT_PTR
	lodi,r0 text_instructions_2%256
	stra,r0 PRINT_PTR+1
	bsta,un print_text
	bsta,un newline
	
	loda,r0 USR_ADDR
	stra,r0 WR_ADDR
	loda,r0 USR_ADDR+1
	stra,r0 WR_ADDR+1
	
w_write_bytes:
	loda,r0 WR_ADDR
	bsta,un print_hex
	loda,r0 WR_ADDR+1
	bsta,un print_hex
	lodi,r0 ' '
	bsta,un write_8251
	lodi,r0 '|'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	lodi,r3 255
w_write_bytes_loop:
	lodi,r2 1
	bsta,un hex_input
	comi,r0 0
	bcfa,eq w_end_write
	lodi,r0 ' '
	bsta,un write_8251
	loda,r0 USR_ADDR+1
	stra,r0 *WR_ADDR,r3+
	comi,r3 15
	bcfr,eq w_write_bytes_loop
	
	lodi,r0 '|'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	
	loda,r0 WR_ADDR+1
	stra,r0 PRINT_PTR+1
	addi,r0 16
	stra,r0 WR_ADDR+1
	loda,r0 WR_ADDR
	stra,r0 PRINT_PTR
	ppsl PSL_WITH_CARRY
	addi,r0 0
	cpsl PSL_WITH_CARRY
	stra,r0 WR_ADDR
	lodi,r0 15
	stra,r0 INPUT_LEN
	bsta,un dump_bytes
	bsta,un newline
	bcta,un w_write_bytes
w_end_write:
	comi,r3 255
	bctr,eq w_no_exit_dump
	stra,r3 INPUT_LEN
	lodi,r0 15
	subz,r3
	strz,r3
	addz,r3
	addz,r3
	strz,r3
w_space_print_loop:
	lodi,r0 ' '
	bsta,un write_8251
	bdrr,r3 w_space_print_loop
	
	lodi,r0 '|'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	loda,r0 WR_ADDR
	stra,r0 PRINT_PTR
	loda,r0 WR_ADDR+1
	stra,r0 PRINT_PTR+1
	bsta,un dump_bytes
w_no_exit_dump:
	bsta,un newline
	bcta,un cmd_finish

cmd_execute:
	lodi,r0 88
	bsta,un write_8251
	bsta,un newline
	bsta,un newline
	bsta,un get_mem_addr_from_user
	comi,r0 0
	bcfa,eq i_abort_cmd
	bsta,un newline
	
	bsta,un *USR_ADDR

	bcta,un cmd_finish
	
	; INPUT_LEN: amount of bytes to dump - 1
dump_bytes:
	stra,r3 R3_BACK
	lodi,r3 255
print_chars_loop:
	loda,r0 *PRINT_PTR,r3+
	comi,r0 31
	bctr,lt not_printable_char
	comi,r0 127
	bctr,gt not_printable_char
	bctr,un print_char
not_printable_char:
	lodi,r0 '.'
print_char:
	bsta,un write_8251
	
	coma,r3 INPUT_LEN
	bcfr,eq print_chars_loop
	loda,r3 R3_BACK
	retc,un

get_mem_addr_from_user:
	lodi,r0 text_addr>>8
	stra,r0 PRINT_PTR
	lodi,r0 text_addr%256
	stra,r0 PRINT_PTR+1
	bsta,un print_text
	lodi,r2 2
	
	; Options in r2:
	; 0: CLEAR_ON_ABORT
	; 1: READ_WORD
hex_input:
	stra,r3 R3_BACK
	lodz,r2
	andi,r0 2
	addi,r0 2
	stra,r0 INPUT_LEN
	strz,r3
uart_read_loop:
	bsta,un read_8251
	comi,r0 0
	bctr,eq uart_read_loop
	comi,r0 'q'
	bcta,eq input_abort
	comi,r0 127
	bcfr,eq no_backspace
	coma,r3 INPUT_LEN
	bctr,eq uart_read_loop
is_backspace:
	lodi,r0 8
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	lodi,r0 8
	bsta,un write_8251
	addi,r3 1
	bctr,un uart_read_loop
no_backspace:
	comi,r0 '0'
	bctr,lt uart_read_loop
	comi,r0 'f'
	bctr,gt uart_read_loop
	comi,r0 58
	bctr,lt is_num
	comi,r0 96
	bctr,gt is_letter
	bctr,un uart_read_loop
is_num:
	bsta,un write_8251
	ppsl PSL_CARRY_FLAG
	subi,r0 '0'
	bctr,un put_in_buffer
is_letter:
	ppsl PSL_CARRY_FLAG
	subi,r0 'a'
	strz,r1
	addi,r0 65
	bsta,un write_8251
	addi,r1 10
	lodz,r1
put_in_buffer:
	stra,r0 IN_BUFF-1,r3
	bdra,r3 uart_read_loop

wait_for_confirm:
	bsta,un read_8251
	comi,r0 0
	bctr,eq wait_for_confirm
	comi,r0 'q'
	bcta,eq input_abort
	comi,r0 127
	bcta,eq is_backspace
	comi,r0 0x0D
	bcfr,eq wait_for_confirm
	
	loda,r3 R3_BACK

	loda,r0 IN_BUFF+1
	rrl,r0
	rrl,r0
	rrl,r0
	rrl,r0
	andi,r0 0xF0
	iora,r0 IN_BUFF
	stra,r0 USR_ADDR+1
	loda,r0 INPUT_LEN
	comi,r0 4
	eorz,r0
	retc,lt

	loda,r0 IN_BUFF+3
	rrl,r0
	rrl,r0
	rrl,r0
	rrl,r0
	andi,r0 0xF0
	iora,r0 IN_BUFF+2
	stra,r0 USR_ADDR

	eorz,r0
	retc,un
input_abort:
	andi,r2 1
	bctr,0 no_clear_input
clear_input_loop:
	coma,r3 INPUT_LEN
	bctr,eq no_clear_input
	addi,r3 1
	lodi,r0 8
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	lodi,r0 8
	bsta,un write_8251
	bctr,un clear_input_loop
	
no_clear_input:
	loda,r3 R3_BACK
	lodi,r1 1
	retc,un

cmd_regdump:
	lodi,r0 82
	bsta,un write_8251
	bsta,un newline
	bsta,un regdump
	bsta,un newline
	ppsl PSL_BANK
	bsta,un regdump
	cpsl PSL_BANK
	bcta,un cmd_finish

newline:
	lodi,r0 0x0D
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x0A
	wrtd,r0
	bsta,un uart_delay
	retc,un

print_hex:
	stra,r3 R3_BACK
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
	
	loda,r3 R3_BACK
	retc,3

regdump:
	stra,r0 R0_BACK

	lodi,r0 '0'
	bsta,un write_8251
	lodi,r0 ':'
	bsta,un write_8251
	bstr,3 print_hex

	lodi,r0 ' '
	bsta,un write_8251
	lodi,r0 '1'
	bsta,un write_8251
	lodi,r0 ':'
	bsta,un write_8251
	lodz r1
	bsta,3 print_hex

	lodi,r0 ' '
	bsta,un write_8251
	lodi,r0 '2'
	bsta,un write_8251
	lodi,r0 ':'
	bsta,un write_8251
	lodz r2
	bsta,3 print_hex

	lodi,r0 ' '
	bsta,un write_8251
	lodi,r0 '3'
	bsta,un write_8251
	lodi,r0 ':'
	bsta,un write_8251
	lodz,r3
	bsta,3 print_hex
	loda,r0 R0_BACK
	retc,3

print_text:
	lodi,r1 255
print_text_loop:
	loda,r0 *PRINT_PTR,r1+
	comi,r0 0
	retc,eq
	wrtd,r0
	bsta,un uart_delay
	bctr,un print_text_loop

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

write_8251:
	wrtd,r0
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

data:
text_init:
	db "S2650 Microcomputer v2.1 - https://tholin.dev"
	db 0x0D
	db 0x0A
	db 0
text_addr:
	db "Address? "
	db 0
text_instructions_1:
	db "ENTER for next 16 bytes, Q to quit"
	db 0x0D
	db 0x0A
	db 0
text_instructions_2:
	db "ENTER to confirm current input, Q to quit"
	db 0x0D
	db 0x0A
	db 0
text_abort:
	db 0x0D
	db 0x0A
	db "Abort!"
	db 0x0D
	db 0x0A
	db 0
hex:
	db "0123456789ABCDEF"
