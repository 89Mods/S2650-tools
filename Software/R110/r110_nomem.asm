; Simple implementation of Rule110. Runs entire inside the CPU reqisters, requiring no RAM.

PSL_CC1          equ 0b10000000
PSL_CC0          equ 0b01000000
PSL_IDC          equ 0b00100000
PSL_BANK         equ 0b00010000
PSL_WITH_CARRY   equ 0b00001000
PSL_OVERFLOW     equ 0b00000100
PSL_LOGICAL_COMP equ 0b00000010
PSL_CARRY_FLAG   equ 0b00000001

org 0
programentry:
    eorz,r0
    wrtc,r0
    lodi,r0 PSL_WITH_CARRY
    lpsl
    lodi,r0 32
    lpsu
    bsta,3 init_8251
    
    ; Init state
    loda,r2 23
    loda,r3 12
    
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
    cpsl PSL_BANK+PSL_CARRY_FLAG
    
    lodz r3
    andi,r0 3
    rrl,r0
    iori,r0 1
    loda,r0 rules,r0
    lodi,r1 15
    cpsl PSL_CARRY_FLAG
    bctr,3 r110_loop_entry
    
r110_update_loop:
    rrr,r2
    rrr,r3
    cpsl PSL_CARRY_FLAG
    lodz r3
    andi,r0 7
    loda,r0 rules,r0
r110_loop_entry:
    ppsl PSL_BANK
    rrl,r3
    rrl,r2
    iorz r3
    strz r3
    cpsl PSL_BANK+PSL_CARRY_FLAG
    bdrr,r1 r110_update_loop
    
    ppsl PSL_BANK
    lodz r3
    cpsl PSL_BANK
    strz r3
    ppsl PSL_BANK
    lodz r2
    cpsl PSL_BANK
    strz r2
    retc,3
    
print_state:
    loda,r0 print_chars+2
    wrtd,r0
    bsta,un uart_delay
    lodz r2
    bstr,3 print_byte
    lodz r3
    bstr,3 print_byte
    loda,r0 print_chars+2
    wrtd,r0
    bsta,un uart_delay
    lodi,r0 13
    wrtd,r0
    bsta,un uart_delay
    lodi,r0 10
    wrtd,r0
    bsta,un uart_delay
    retc,3

print_byte:
    ppsl PSL_BANK
    strz r1
    lodi,r2 8
print_byte_loop:
    eorz r0
    rrl,r1
    addz r0
    loda,r0 print_chars,r0
    wrtd,r0
    bsta,un uart_delay
    bdrr,r2 print_byte_loop
    cpsl PSL_BANK
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
	; Put in data mode
	wrtc,r0
	nop
	nop
	retc,un

uart_delay:
	lodi,r0 64
	wrtc,r0
uart_delay_loop:
	nop
	nop
	nop
	nop
	redd,r0
	andi,r0 4
	bctr,0 uart_delay_loop

	eorz,r0
	wrtc,r0
	nop
	nop

	retc,un

rules:
	db 0,1,1,1,0,1,1,0
print_chars:
	db " #|"
end
