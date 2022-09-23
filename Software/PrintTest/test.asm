; Small test program to make sure the UART works

mem_start equ 4096
r0_back equ 4096+256
uart_delay_loops equ 250

org 0
programentry:
	eorz,r0
	lpsl
	wrtc,r0
	lodi,r0 0b00100000
	lpsu
	bstr,3 init_8251
	lodi,r1 0
copy_loop:
	loda,r0 data-1,r1+
	stra,r0 mem_start-1,r1
	bcfr,0 copy_loop
wait_for_sense:
	tpsu 0b10000000
	bctr,0 wait_for_sense
loop:
	bstr,3 prints
	tpsu 0b01000000
	cpsu 0b01000000
	bctr,0 loop
	ppsu 0b01000000
	bctr,3 loop
	
prints:
	lodi,r1 0
print_loop:
	loda,r0 mem_start-1,r1+
	retc,0
	wrtd,r0
	bstr,3 uart_delay
	bctr,3 print_loop

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
	lodi,r0 0b01001101 ; 1 stop bit, no parity, 8-bit, 1X baud rate divisor
	wrtd,r0
	; Send command word
	lodi,r0 0b00010011 ; Enable TX, but no RX (yet)
	wrtd,r0
	eorz,r0
	; Put in data mode
	wrtc,r0
	nop
	nop
	retc,3

uart_delay:
	stra,r0 r0_back
	lodi,r0 uart_delay_loops
uart_delay_loop:
	nop
	bdrr,r0 uart_delay_loop
	loda,r0 r0_back
	retc,3
	
data:
	db "I am a cute and soft Avali, I am a bird from outer space! I am a cute and soft Avali, lalalalala, underfloofs!"
	db 0x0D
	db 0x0A
	db 0
end
