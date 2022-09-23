mem_start equ 4096

R0_BACK equ mem_start
OUTPUT_SHADOW equ mem_start+1

org 0
programentry:
	eorz,r0
	lpsl
	wrtc,r0
	lodi,r0 32
	lpsu
	bsta,un init_8251
	bsta,un uart_delay

	lodi,r0 't'
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 'e'
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 's'
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 't'
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x0D
	wrtd,r0
	bsta,un uart_delay
	lodi,r0 0x0A
	wrtd,r0
	bsta,un uart_delay

loop:
	bsta,un uart_delay
	bsta,un uart_delay

	bsta,un read_8251
	comi,r0 0
	bctr,eq loop
	wrtd,r0
	bsta,un uart_delay
	comi,r0 0x0D
	bcfr,eq loop
	lodi,r0 0x0A
	wrtd,r0
	bsta,un uart_delay

	;lodz,r1
	;rrr,r0
	;rrr,r0
	;rrr,r0
	;rrr,r0
	;andi,r0 15
	;loda,r0 hex,r0
	;wrtd,r0
	;bsta,un uart_delay

	lodz,r1
	andi,r0 15
	loda,r0 hex,r0
	wrtd,r0
	bsta,un uart_delay

	; Blink flag
	tpsu 64
	cpsu 64
	bctr,eq loop
	ppsu 64
	bctr,un loop

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

hex:
	db "0123456789abcdef"
