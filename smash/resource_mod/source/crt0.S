.section ".init"
.arm
.align 4
.global _start

_start:
    add lr, lr, #0x4
    
    push {r0-r12,lr}
	blx _main
	pop {r0-r12,lr}
	
	@accomodate for replaced code
	ldrb r1, [r0, #0x2]
	cmp r1, #0x4
	addcc lr, lr, #0x18
	
	bx lr
