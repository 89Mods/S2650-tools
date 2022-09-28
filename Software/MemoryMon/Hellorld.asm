org 0x1100
program:
	lodi,r1 255					; Load immediate r0 with 255
loop:
	loda,r0 text,r1+			; Load absolute r0 from (text), indexed by incremented r1 (r1 is incremented BEFORE the load)
	retc,0							; Return from subroutine on condition true, CC 0 (returns if byte loaded by loda is equal to 0)
	wrtd,r0							; Write to I/O port D (P8251 responds to this one)
	bsta,un *6138			; Branch on condition true absolute, indirect 6138 (RAM contains a table of function pointers at the end. This one leads to "wait for TX buffer empty")
	bctr,un loop				; Branch on condition true relative, unconditional, to "loop"
text:
	db "Hellorld!"
	db 0x0D
	db 0x0A
	db 0
