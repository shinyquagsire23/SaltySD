@ Hitbox display test (1.1.5)
@ Compile this and place it at 0xA2B800
@ Replace entries 0x17, 0x2D, 0x30, 0x32, 0x34 in the animcmd function table with 0xA2B800

.arm

.macro call func
    ldr r9, =\func
    blx r9
.endm

main:
    ldr r6, [sp]
    ldr r6, [r6, #-0x4]
    cmp r6, #0x17
    beq remove_display

    push {r0-r12,lr}
        sub sp, sp, #0x38
        
        ldr r1, [sp, #((14*4)+0x38)]
        ldrb r2, [r3, #0x8]
        cmp r2, #0x0
        beq nope
        
        @ no hitbox damage
        @mov r2, #0x0
        @str r2, [r1, #(3*4)]
        
        ldr r2, =0x1000013
        str r2, [sp, #0x4]  @ graphic
        ldr r2, [r1, #(2*4)]    
        str r2, [sp, #0x8]  @ bone
        ldr r2, [r1, #(9*4)] 
        str r2, [sp, #0xC]  @ z
        ldr r2, [r1, #(10*4)] 
        str r2, [sp, #0x10] @ y
        ldr r2, [r1, #(11*4)] 
        str r2, [sp, #0x14] @ x
        
        mov r2, #0x0
        str r2, [sp, #0x18] @ rotx
        str r2, [sp, #0x1C] @ roty
        str r2, [sp, #0x20] @ rotz
        vldr.f32 s0, [r1, #(8*4)]
        vldr.f32 s1, ten
        vdiv.f32 s0, s0, s1
        vmov.f32 r2, s0
        
        str r2, [sp, #0x24] @ size
        ldr r2, =0x1
        str r2, [sp, #0x28] @ terminate
        
        @ set up msc args correctly
        add r3, sp, #0x30
        mov r2, #0xB
        str sp, [r3, #0x0]
        str r2, [r3, #0x4]
        ldr r2, =0x2712
        str r2, [sp]

        ldr r0, [r0, #0xA4]
        ldr r1, [r0]
        ldr r2, [r1, #0x174]
        mov r1, r3
        blx r2
        
nope:
        add sp, sp, #0x38
    pop {r0-r12,lr}

    ldr r6, [sp]
    ldr r6, [r6, #-0x4]
    cmp r6, #0x2D
    beq hitbox
    cmp r6, #0x30
    beq extended
    cmp r6, #0x32
    beq special
    cmp r6, #0x34
    beq extended_special
    cmp r6, #0x17
    beq remove_all
    bx lr
 
 
remove_display:
    push {r0-r12,lr}
    sub sp, sp, #0x38
        ldr r0, [r0, #0xA4]
        ldr r1, =0x1000013
        mov r2, #0x0
        mov r3, #0x0
        call 0x55E05C @ app::EffectModuleSimple::kill_kind(int, bool, bool)
    add sp, sp, #0x38
    pop {r0-r12,lr}
    b remove_all
    
hitbox:
    ldr r7, =0x7053C8
    bx r7
    
extended:
    ldr r7, =0x6F86E8
    bx r7
    
special:
    ldr r7, =0x7069CC
    bx r7
    
extended_special:
    ldr r7, =0x6FC3F4
    bx r7
    
remove_all:
    ldr r7, =0x6F5610
    bx r7

ten:
    .word 0x41200000    
.pool
