; Test indirect addressing

mem_start equ 4096
value_loc equ mem_start
addr_loc  equ mem_start+1024
addr_loc_2 equ mem_start+2000

org 0
programentry:
	lodi,r0 0
	lpsl
	lodi,r0 32
	lpsu
	
	lodi,r0 value_loc>>8
	stra,r0 addr_loc
	lodi,r0 value_loc%256
	stra,r0 addr_loc+1
	
	lodi,r3 4
	lodi,r0 5
	stra,r0 value_loc,r3-
	lodi,r0 3
	stra,r0 value_loc,r3-
	lodi,r0 0
	stra,r0 value_loc,r3-
	lodi,r0 9
	stra,r0 value_loc,r3-
	
	lodi,r0 print_loop>>8
	stra,r0 addr_loc_2
	lodi,r0 print_loop%256
	stra,r0 addr_loc_2+1
	lodi,r2 252
	lodi,r3 255
print_loop:
	lodi,r0 '0'
	adda,r0 *addr_loc,r3+
	wrtd,r0
	bira,r2 *addr_loc_2

	lodi,r1 0x0D
	wrtd,r1
	lodi,r1 0x0A
	wrtd,r1

	lodi,r3 255
print_loop_2:
	loda,r0 text,r3+
	bctr,0 end_loop
	wrtd,r0
	bctr,un print_loop_2
org 79
addr_loc_3:
	db 0,81
end_loop:
	ppsu 64
	nop
	nop
	cpsu 64
	bctr,un *addr_loc_3
text:
	db "If you see the numbers '9035' above, it worked!"
	db 0x0D
	db 0x0A
	db 0
end
