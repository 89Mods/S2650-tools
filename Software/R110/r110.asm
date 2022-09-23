; Simple implementation of Rule110. Can run in state sizes of up to 256.

PSL_CC1          equ 0b10000000
PSL_CC0          equ 0b01000000
PSL_IDC          equ 0b00100000
PSL_BANK         equ 0b00010000
PSL_WITH_CARRY   equ 0b00001000
PSL_OVERFLOW     equ 0b00000100
PSL_LOGICAL_COMP equ 0b00000010
PSL_CARRY_FLAG   equ 0b00000001

mem_start        equ 4096

STATE_SIZE       equ 29
BUFF_LOC         equ mem_start+2048-STATE_SIZE-1
PSL_BACK         equ mem_start+0
CNTR             equ mem_start+1
OUTPUT_SHADOW equ mem_start+2
R0_BACK equ mem_start+2

org 0
programentry:
	lodi,r0 0
	wrtc,r0
    lpsl
    lodi,r0 32
    lpsu
    bsta,3 init_8251
    
    ; Init buffer
    lodi,r1 STATE_SIZE
    lodi,r2 255
init_loop:
	loda,r0 32,r2+
	comi,r0 0
	bctr,0 init_loop
    stra,r0 BUFF_LOC,r2
	bdrr,r1 init_loop
    lodi,r0 255
    stra,r0 BUFF_LOC+STATE_SIZE
    
main_loop:
	nop
    bstr,3 r110_update
    bsta,3 print_state
    
    db 182
	db 0b01000000
	cpsu 0b01000000
	bctr,0 main_loop
	ppsu 0b01000000
    bctr,3 main_loop
    
r110_update:
	spsl
    stra,r0 PSL_BACK
	ppsl PSL_WITH_CARRY+PSL_LOGICAL_COMP
    cpsl PSL_BANK
	lodi,r3 STATE_SIZE
    lodi,r2 STATE_SIZE-1
r110_byte_loop:
	lodz r2
	ppsl PSL_BANK
    strz r1
    loda,r0 BUFF_LOC,r1-
    strz r2
    loda,r0 BUFF_LOC,r1+
    strz r3
    loda,r0 BUFF_LOC,r1+
    strz r1
    rrl,r1
    lodz r3
    rrl,r0
    andi,r0 7
    loda,r0 rules,r0
    
    lodi,r1 8
    stra,r1 CNTR
    lodi,r1 0
    bctr,3 r110_update_loop_entry
r110_update_loop:
	stra,r0 CNTR
    cpsl PSL_CARRY_FLAG
    rrr,r2
    rrr,r3
    lodz r3
    andi,r0 7
    loda,r0 rules,r0
r110_update_loop_entry:
    iorz r1
    strz r1
    cpsl PSL_CARRY_FLAG
    rrl,r1
    loda,r0 CNTR
    bdrr,r0 r110_update_loop
    
    lodz r1
    cpsl PSL_BANK
    stra,r0 BUFF_LOC,r2
    
    ppsl PSL_CARRY_FLAG
    subi,r2 1
	bdra,r3 r110_byte_loop
	
    loda,r0 PSL_BACK
    lpsl
    retc,3
    
print_state:
	spsl
    stra,r0 PSL_BACK
    loda,r0 print_chars+2
    wrtd,r0
    bsta,un uart_delay
    cpsl PSL_BANK
    ppsl PSL_WITH_CARRY
	lodi,r1 STATE_SIZE
    lodi,r2 255
print_state_byte_loop:
	loda,r0 BUFF_LOC,r2+
    ppsl PSL_BANK
    lodi,r1 8
    strz r2
print_state_bit_loop:
	eorz r0
	rrl,r2
    rrl,r0
    loda,r0 print_chars,r0
    wrtd,r0
    bsta,un uart_delay
	bdrr,r1 print_state_bit_loop
    cpsl PSL_BANK
    
    bdrr,r1 print_state_byte_loop
    loda,r0 print_chars+2
    wrtd,r0
    bsta,un uart_delay
    lodi,r0 13
    wrtd,r0
    bsta,un uart_delay
    lodi,r0 10
    wrtd,r0
    bsta,un uart_delay
    loda,r0 PSL_BACK
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

rules:
	db 0,1,1,1,0,1,1,0
print_chars:
	db " #|"
end
