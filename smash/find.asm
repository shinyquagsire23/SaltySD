.arm

.macro call func
    ldr r6, =\func
    blx r6
.endm

.equ base_addr,     0xA1CF00
.equ mount_sdmc,    0x28FEF4
.equ IFile_Init,    0x12A2F0
.equ IFile_Open,    0x12A218
.equ IFile_Exists,  0x863020
.equ IFile_GetSize, 0x1182CC
.equ IFile_Read,    0x13EEB8
.equ IFile_Close,   0x12A35C
.equ strcat,        0x1003F0
.equ strcpy,        0x2FEBD8
.equ strlen,        0x2FEB2C
.equ liballoc,      0x157760
.equ libdealloc,    0x167038
.equ crit_this,      0x11DAA4

test:
     ldr r3, =0x16efb4
     cmp lr, r3
     moveq r3, #0x2 @find
     movne r3, #0x1 @findf
     
     push {r0-r7,lr}
         mov r5, r2

         ldr r0, =0x204
         call liballoc
         mov r7, r0

         call crit_this
         ldr r3, =0x161F10 @nn::os::CriticalSection::Initialize()
         blx r3
         
         add r0, r7, #0x4
         ldr r1, =mod_path+base_addr
         call strcpy
         
         @strcat refuses to work :/
         add r0, r7, #0x4
         call strlen
         add r2, r7, #0x4
         add r0, r0, r2
         mov r1, r5
         add r1, #0x4
         call strcpy
         
         ldr r0, sdmc_on
         ldr r0, [r0]
         cmp r0, #0x0
         bne skip_sdmc_mount
         ldr r0, =sdmc+base_addr
         call mount_sdmc
         ldr r0, sdmc_on
         mov r1, #0x1
         str r1, [r0]
         
skip_sdmc_mount:   
         mov r0, r7
         call IFile_Init
         add r1, r7, #0x0 
         cmp r0, r1
         bne skip_sdmc_mount
         @str r0, [r1, #0x58-0x20]
         ldr r1, =0xBE2E50
         cmp r0, r1
         beq close_and_end
         
         mov r0, r7
         add r1, r7, #0x4
         mov r2, #0x1
         call IFile_Exists
         cmp r0, #0x0
         beq close_and_end @ SD file doesn't exist, exit and pretend it never happened.
         mov r0, r7
         call IFile_Close 
         mov r0, r7
         call libdealloc
     pop  {r0-r7,lr}
     cmp r3, #0x2
     beq exit_find
     bne exit_findf  
exit_find:
     ldrh r1, [r0] @ Load some fake file ID, since other functions will see SD file first anyways
     ldr r1, =0xFFFFFFFF
     strh r1, [r0]
     ldr lr, =0x16EFE4
     bx lr

exit_findf:
     ldrh r0, [r4] @ Load some fake file ID, since other functions will see SD file first anyways
     ldr r0, =0xFFFFFFFF
     strh r0, [r4]
     ldr lr, =0x9E1F80
     bx lr
     
close_and_end:
        mov r0, r7
        call IFile_Close     
close:
     mov r0, r7
     call libdealloc
     pop  {r0-r7,lr}
     cmp r3, #0x2
     beq continue_find
     bne continue_findf
     
continue_find: 
     sub sp, sp, #0xc
     ldrh r1, [r1]
     mov r4, r0  
     ldr lr, =0x16EFB8
     bx lr
     
continue_findf:
    strh r0, [sp, #0x4]
    mov r3, #0x1
    add r1, sp, #0x4
    ldr lr, =0x9E1F64
    bx lr
    
.pool

storage: .long 0xC68D20
sdmc_on:     .long 0xC68D80
res_str:     .long 0xC68700
new_res_str: .long 0xC68A00
something_resource_lock: .long 0xC57218

.align 4
sdmc:       .asciz "sdmc:"
mod_path:   .asciz "sdmc:/saltysd/smash/"
