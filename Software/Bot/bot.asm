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
STR_PTR       equ mem_start+5 ; 2 bytes
PARSE_BUFF equ mem_start+7 ; 4 bytes
USR_ADDR equ mem_start+11 ; 2 bytes
TARG_COUNT equ mem_start+13

TBL_UART_READ equ mem_start+2046
TBL_UART_WRITE equ mem_start+2044
TBL_UART_WAIT equ mem_start+2042
TBL_PRINT_STR equ mem_start+2040
IN_BUFF       equ mem_start+1784 ; 256 bytes

org 0
programentry:
	eorz,r0
	lpsl
	wrtc,r0
	lodi,r0 0b00100000
	lpsu
	bsta,3 init_8251
	ppsl PSL_LOGICAL_COMP
	
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

	lodi,r0 print_str>>8
	stra,r0 TBL_PRINT_STR
	lodi,r0 print_str%256
	stra,r0 TBL_PRINT_STR+1

bot_loop_entry:
	lodi,r3 255
	; Put incoming characters into the buffer until a 1 is received
loop:
	bsta,un read_8251
	comi,r0 0
	bctr,eq loop
	; ---- Replace the 1 here with 0x0D for offline debugging
	comi,r0 1
	; ----
	bctr,eq cmd_received
	stra,r0 IN_BUFF,r3+
	bctr,un loop
cmd_received:
	eorz,r0
	stra,r0 IN_BUFF,r3+
	; Command received. Turn it into all lowercase, for easier parsing
	bsta,un to_lower
	; Now we can check what it is
	
	; Ping?
	lodi,r0 text_ping>>8
	stra,r0 STR_PTR
	lodi,r0 text_ping%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_ping
	
	; stats?
	lodi,r0 text_stats>>8
	stra,r0 STR_PTR
	lodi,r0 text_stats%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_stats

	; help inspect?
	lodi,r0 text_cmd_help_inspect>>8
	stra,r0 STR_PTR
	lodi,r0 text_cmd_help_inspect%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_help_inspect

	; inspect?
	lodi,r0 text_cmd_inspect>>8
	stra,r0 STR_PTR
	lodi,r0 text_cmd_inspect%256
	stra,r0 STR_PTR+1
	bsta,un comp_verb
	comi,r2 0
	bcta,eq cmd_inspect

	; regs?
	lodi,r0 text_regs>>8
	stra,r0 STR_PTR
	lodi,r0 text_regs%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_regs

	; sense?
	lodi,r0 text_sense>>8
	stra,r0 STR_PTR
	lodi,r0 text_sense%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_sense

	; flag?
	lodi,r0 text_flag>>8
	stra,r0 STR_PTR
	lodi,r0 text_flag%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_flag

	; help write?
	lodi,r0 text_cmd_help_write>>8
	stra,r0 STR_PTR
	lodi,r0 text_cmd_help_write%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_help_write

	; write?
	lodi,r0 text_cmd_write>>8
	stra,r0 STR_PTR
	lodi,r0 text_cmd_write%256
	stra,r0 STR_PTR+1
	bsta,un comp_verb
	comi,r2 0
	bcta,eq cmd_write

	; help exec?
	lodi,r0 text_cmd_help_exec>>8
	stra,r0 STR_PTR
	lodi,r0 text_cmd_help_exec%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_help_exec

	; exec?
	lodi,r0 text_cmd_exec>>8
	stra,r0 STR_PTR
	lodi,r0 text_cmd_exec%256
	stra,r0 STR_PTR+1
	bsta,un comp_verb
	comi,r2 0
	bcta,eq cmd_exec

	; halt?
	lodi,r0 text_halt>>8
	stra,r0 STR_PTR
	lodi,r0 text_halt%256
	stra,r0 STR_PTR+1
	bsta,un comp_buff
	comi,r2 0
	bcta,eq cmd_halt

	; Send command not recognized message
	lodi,r0 text_invalid_command>>8
	stra,r0 STR_PTR
	lodi,r0 text_invalid_command%256
	stra,r0 STR_PTR+1
	bcta,un string_resp

cmd_halt:
	lodi,r0 text_halt_resp>>8
	stra,r0 STR_PTR
	lodi,r0 text_halt_resp%256
	stra,r0 STR_PTR+1
	bsta,un print_str
	lodi,r0 0
	bcta,un write_8251
halt:
	nop
	nop
	nop
	nop
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
	bctr,un halt

cmd_sense:
	lodi,r0 text_sense_is>>8
	stra,r0 STR_PTR
	lodi,r0 text_sense_is%256
	stra,r0 STR_PTR+1
	bsta,un print_str

	tpsu 0b10000000
	bctr,0 c_sense_low
c_sense_high:
	lodi,r0 text_high>>8
	stra,r0 STR_PTR
	lodi,r0 text_high%256
	stra,r0 STR_PTR+1
	bcta,un string_resp
c_sense_low:
	lodi,r0 text_low>>8
	stra,r0 STR_PTR
	lodi,r0 text_low%256
	stra,r0 STR_PTR+1
	bcta,un string_resp

cmd_flag:
	tpsu 0b01000000
	cpsu 0b01000000
	bctr,0 c_flag_off
	ppsu 0b01000000
c_flag_on:
	lodi,r0 text_light_on>>8
	stra,r0 STR_PTR
	lodi,r0 text_light_on%256
	stra,r0 STR_PTR+1
	bcta,un string_resp
c_flag_off:
	lodi,r0 text_light_off>>8
	stra,r0 STR_PTR
	lodi,r0 text_light_off%256
	stra,r0 STR_PTR+1
	bcta,un string_resp

cmd_regs:
	bsta,un code_box
	lodi,r0 0x0A
	bsta,un write_8251
	bsta,un regdump
	lodi,r0 0x0A
	bsta,un write_8251
	ppsl PSL_BANK
	bsta,un regdump
	cpsl PSL_BANK
	lodi,r0 0x0A
	bsta,un write_8251
	bsta,un code_box
	lodi,r0 0
	bsta,un write_8251
	bcta,un bot_loop_entry

cmd_exec:
	lodi,r2 1
	bsta,un parse_hex
	comi,r0 0
	bcfa,eq cmd_format_error

	lodi,r0 text_executing>>8
	stra,r0 STR_PTR
	lodi,r0 text_executing%256
	stra,r0 STR_PTR+1
	bsta,un print_str

	bsta,un *USR_ADDR

	lodi,r0 0
	bsta,un write_8251
	bcta,un bot_loop_entry

cmd_write:
	lodi,r2 1
	bsta,un parse_hex
	comi,r0 0
	bcfa,eq cmd_format_error
	loda,r0 IN_BUFF,r3+
	comi,r0 ' '
	bcfa,eq cmd_format_error
	loda,r0 USR_ADDR
	stra,r0 STR_PTR
	loda,r0 USR_ADDR+1
	stra,r0 STR_PTR+1
	lodi,r1 255
c_write_loop:
	lodi,r2 0
	bsta,un parse_hex
	comi,r0 0
	bcfa,eq cmd_format_error
	loda,r0 USR_ADDR+1
	stra,r0 *STR_PTR,r1+
	loda,r0 IN_BUFF,r3+
	comi,r0 0
	bctr,eq c_write_done
	comi,r0 ' '
	bcfa,eq cmd_format_error
	bctr,eq c_write_loop

c_write_done:
	lodi,r0 text_write_success>>8
	stra,r0 STR_PTR
	lodi,r0 text_write_success%256
	stra,r0 STR_PTR+1
	bcta,un string_resp

cmd_inspect:
	lodi,r2 1
	bsta,un parse_hex
	comi,r0 0
	bcfa,eq cmd_format_error
	loda,r0 IN_BUFF,r3+
	comi,r0 ' '
	bcfa,eq cmd_format_error
	loda,r0 USR_ADDR
	stra,r0 STR_PTR
	loda,r0 USR_ADDR+1
	stra,r0 STR_PTR+1
	lodi,r2 0
	bsta,un parse_hex
	comi,r0 0
	bcfa,eq cmd_format_error
	loda,r0 IN_BUFF,r3+
	comi,r0 0
	bcfa,eq cmd_format_error
	eorz,r0
	coma,r0 USR_ADDR+1
	bcta,eq cmd_format_error

	bsta,un code_box
	lodi,r2 0
	lodi,r0 15
	stra,r0 TARG_COUNT
i_print_bytes:
	loda,r0 STR_PTR
	bsta,un print_hex
	loda,r0 STR_PTR+1
	bsta,un print_hex
	lodi,r0 ' '
	bsta,un write_8251
	lodi,r0 '|'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	lodi,r3 255
i_print_bytes_loop:
	loda,r0 *STR_PTR,r3+
	bsta,un print_hex
	lodi,r0 ' '
	bsta,un write_8251
	addi,r2 1
	coma,r2 USR_ADDR+1
	bcta,eq i_pad
	comi,r3 15
	bcfr,eq i_print_bytes_loop
	lodi,r0 '|'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	bsta,un dump_bytes
	lodi,r0 0x0A
	bsta,un write_8251
	loda,r0 STR_PTR+1
	addi,r0 16
	stra,r0 STR_PTR+1
	loda,r0 STR_PTR
	ppsl PSL_WITH_CARRY
	addi,r0 0
	cpsl PSL_WITH_CARRY
	stra,r0 STR_PTR
	bcta,un i_print_bytes

i_pad:
	lodi,r0 15
	ppsl PSL_CARRY_FLAG
	subz,r3
	comi,r0 0
	bctr,eq i_no_pad
	strz,r2
	addz,r2
	addz,r2
	strz,r2
i_pad_loop:
	lodi,r0 ' '
	bsta,un write_8251
	bdrr,r2 i_pad_loop
i_no_pad:
	lodi,r0 '|'
	bsta,un write_8251
	lodi,r0 ' '
	bsta,un write_8251
	stra,r3 TARG_COUNT
	bsta,un dump_bytes
	lodi,r0 0x0A
	bsta,un write_8251
i_return:
	bsta,un code_box
	lodi,r0 0
	bsta,un write_8251
	bcta,un bot_loop_entry
cmd_format_error:
	lodi,r0 text_invalid_cmd_fmt>>8
	stra,r0 STR_PTR
	lodi,r0 text_invalid_cmd_fmt%256
	stra,r0 STR_PTR+1
	bctr,un string_resp

cmd_help_exec:
	lodi,r0 text_help_exec>>8
	stra,r0 STR_PTR
	lodi,r0 text_help_exec%256
	stra,r0 STR_PTR+1
	bctr,un string_resp

cmd_help_write:
	lodi,r0 text_help_write>>8
	stra,r0 STR_PTR
	lodi,r0 text_help_write%256
	stra,r0 STR_PTR+1
	bctr,un string_resp

cmd_help_inspect:
	lodi,r0 text_help_write>>8
	stra,r0 STR_PTR
	lodi,r0 text_help_write%256
	stra,r0 STR_PTR+1
	bctr,un string_resp

cmd_stats:
	lodi,r0 text_stats_resp>>8
	stra,r0 STR_PTR
	lodi,r0 text_stats_resp%256
	stra,r0 STR_PTR+1
	bctr,un string_resp
    
	; Respond to a "!s ping" with "Pong"
cmd_ping:
	lodi,r0 text_pong>>8
	stra,r0 STR_PTR
	lodi,r0 text_pong%256
	stra,r0 STR_PTR+1
	; bctr,un string_resp ; Just gonna let this fall through to the subroutine below #optimization

	; Respond with a single string result
string_resp:
	lodi,r3 255
string_resp_loop: ; Note that this will send the 0 at the end of the string, to complete the response
	loda,r0 *STR_PTR,r3+
	bsta,un write_8251
	comi,r0 0
	bcfr,eq string_resp_loop
	bcta,un bot_loop_entry

	; Prints a string without ending the current command
print_str:
	lodi,r3 255
print_str_loop:
	loda,r0 *STR_PTR,r3+
	comi,r0 0
	retc,eq
	bsta,un write_8251
	bctr,un print_str_loop

	; TARG_COUNT: amount of bytes to dump - 1
dump_bytes:
	stra,r3 R3_BACK
	lodi,r3 255
print_chars_loop:
	loda,r0 *STR_PTR,r3+
	comi,r0 31
	bctr,lt not_printable_char
	comi,r0 127
	bctr,gt not_printable_char
	bctr,un print_char
not_printable_char:
	lodi,r0 '.'
print_char:
	bsta,un write_8251

	coma,r3 TARG_COUNT
	bcfr,eq print_chars_loop
	loda,r3 R3_BACK
	retc,un

code_box:
	lodi,r0 '`'
	bsta,un write_8251
	lodi,r0 '`'
	bsta,un write_8251
	lodi,r0 '`'
	bsta,un write_8251
	retc,un
	
	; Parses a hex word from the input buffer, starting at r3+1.
	; r2 = 0: Parse one byte, r2 = 1: Parse two bytes
	; r0 is 0 when parse successful, 1 otherwise
parse_hex:
	rrl,r2
	andi,r2 2
	lodz,r2
	addi,r0 2
	stra,r0 TARG_COUNT
	strz,r2
hex_parse_loop:
	loda,r0 IN_BUFF,r3+
	comi,r0 0
	bcta,eq hex_parse_error
	comi,r0 '0'
	bcta,lt hex_parse_error
	comi,r0 'f'
	bcta,gt hex_parse_error
	comi,r0 58
	bctr,lt is_num
	comi,r0 96
	bctr,gt is_letter
	bctr,un hex_parse_error
is_num:
	ppsl PSL_CARRY_FLAG
	subi,r0 '0'
	bctr,un put_in_buffer
is_letter:
	ppsl PSL_CARRY_FLAG
	subi,r0 87 ; 87 = 'a' - 10
put_in_buffer:
	stra,r0 PARSE_BUFF-1,r2
	bdrr,r2 hex_parse_loop

	loda,r0 PARSE_BUFF+1
	rrl,r0
	rrl,r0
	rrl,r0
	rrl,r0
	andi,r0 0xF0
	iora,r0 PARSE_BUFF
	stra,r0 USR_ADDR+1
	loda,r2 TARG_COUNT
	eorz,r0
	comi,r2 4
	retc,lt

	loda,r0 PARSE_BUFF+3
	rrl,r0
	rrl,r0
	rrl,r0
	rrl,r0
	andi,r0 0xF0
	iora,r0 PARSE_BUFF+2
	stra,r0 USR_ADDR

	eorz,r0
	retc,un

hex_parse_error:
	lodi,r0 1
	retc,un
    
	; Compares the input with a string pointed to by STR_PTR
	; Used to check input against list of commands
	; Result is in r2. 1 = No match, 0 = Yes match 
comp_buff:
	lodi,r3 255
	lodi,r2 1
comp_loop:
	loda,r0 IN_BUFF,r3+
	coma,r0 *STR_PTR,r3
	bcfr,eq comp_ret
	comi,r0 0
	bcfr,eq comp_loop
	lodi,r2 0
comp_ret:
	retc,un

	; Compares the input buffer with a string pointed to by STR_PTR
	; Returns 0 in r2 if the buffer starts with the given string, followed by space
	; Position of the space character will be in r3
comp_verb:
	lodi,r3 255
	lodi,r2 1
comp_verb_loop:
	loda,r0 IN_BUFF,r3+
	coma,r0 *STR_PTR,r3
	bcfr,eq comp_ret
	comi,r0 0
	bctr,eq comp_ret
	comi,r0 ' '
	bcfr,eq comp_verb_loop
	lodi,r2 0
	retc,un
	
	; Convert all uppercase letters in the input buffer to their lowercase variant
to_lower:
	lodi,r3 255
to_lower_loop:
	loda,r0 IN_BUFF,r3+
	comi,r0 0
	retc,eq
	comi,r0 65 ; 'A'
	bctr,lt to_lower_loop
	comi,r0 90 ; 'Z'
	bctr,gt to_lower_loop
	addi,r0 32 ; 97 - 65 ('a' - 'A')
	stra,r0 IN_BUFF,r3
	bctr,un to_lower_loop
    
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
	
text:
text_ping:
	db "ping"
	db 0
text_pong:
	db "Pong"
	db 0
text_stats:
	db "stats"
	db 0
text_regs:
	db "regs"
	db 0
text_sense:
	db "sense"
	db 0
text_flag:
	db "flag"
	db 0
text_halt:
	db "halt"
	db 0
text_stats_resp:
	db "Computer specs:"
	db 0x0A
	db "Signetics 2650 8-bit CPU @ 1.42MHz"
	db 0x0A
	db "4K ROM, 2K RAM"
	db 0x0A
	db "P8251 serial, 14.4K"
	db 0x0A
	db "8-bit wide generic output port"
	db 0
text_invalid_command:
	db "Command not recognized"
	db 0
text_cmd_help_inspect:
	db "help inspect"
	db 0
text_help_inspect:
	db "!s inspect [addr] [count] - All values in hex. Max count is FF. Count must not be 0!"
	db 0
text_cmd_inspect:
	db "inspect "
text_cmd_help_write:
	db "help write"
	db 0
text_help_write:
	db "!s write [addr] [up to 81 bytes] - All values in hex."
	db 0
text_cmd_write:
	db "write "
text_write_success:
	db "Data written successfully!"
	db 0
text_cmd_help_exec:
	db "help exec"
	db 0
text_help_exec:
	db "!s exec [addr] - Make sure the code you entered actually returns if you wanna see a response. Don't brick the bot pls."
	db 0
text_cmd_exec:
	db "exec "
text_executing:
	db "Executing..."
	db 0x0A
	db 0
text_invalid_cmd_fmt:
	db "Invalid command format!"
	db 0
text_sense_is:
	db "Sense is "
	db 0
text_high:
	db "high!"
	db 0
text_low:
	db "low."
	db 0
text_light_on:
	db "Flag is now on!"
	db 0
text_light_off:
	db "Flag is now off."
	db 0
text_halt_resp:
	db "Goodbye!"
	db 0
hex:
	db "0123456789ABCDEF"
