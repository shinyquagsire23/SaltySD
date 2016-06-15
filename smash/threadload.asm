.arm

.macro call func
    ldr r6, =\func
    blx r6
.endm

.include "common.asm"
.equ base_addr,     0xA35000

test:
     @Compensate for removing code
     sub sp, sp, #0x8
     mov r6, r0
     ldr r0, [r2, #0x4]

     @ Stash to-load address
     push {r0-r6,lr}
        ldr r4, storage
        str r1, [r4, #0x18]
     pop {r0-r6,lr}
     
     push {r0-r8,lr}
         ldr r0, storage
         str r2, [r0, #0x28] @r2 is a pointer to our resource u16
         
         ldr r0, =0x404
         call liballoc
         mov r8, r0
         add r7, r8, #0x20
         
         ldr r0, =mod_path+base_addr
         call strlen
         add r7, r7, r0
         
         ldr r0, storage
         ldr r1, [r0, #0x28]
         mov r0, r7
         sub r0, r0, #0x4
         call path_str
                  
         add r7, r8, #0x20
         
         ldr r0, =mod_path+base_addr
         call strlen
         mov r2, r0
         mov r0, r7
         ldr r1, =mod_path+base_addr
         call memcpy
               
         mov r0, r8
         call IFile_Init
         
         ldr r0, =sdmc+base_addr
         call mount_sdmc
         
         mov r0, r8
         mov r1, r7
         mov r2, #0x1
         call IFile_Open
         cmp r0, #0x0
         beq close_and_end @ SD file doesn't exist, exit and pretend it never happened.
         
         mov r0, r8
         call IFile_GetSize
         ldr r3, storage
         str r0, [r3, #0x10]
         
         ldr r0, storage
         ldr r1, [r0, #0x18] @dst
         ldr r2, [r0, #0x10] @size
         add r3, r0, #0x14 @bytes_read
         mov r0, r8 @file
         call IFile_Read
end_read_sd:         
         mov r0, r8
         call IFile_Close 
         mov r0, r8
         call libdealloc
         ldr r0, =sdmc_+base_addr
        call unmount_path
     pop  {r0-r8,lr}
     
     b skip
     
close_and_end:
        mov r0, r8
        call IFile_Close     
close:
     mov r0, r8
     call libdealloc
     ldr r0, =sdmc_+base_addr
     call unmount_path
     pop  {r0-r8,lr}
     
exit:
     add lr, lr, #0x4
     bx lr
     
skip:
    add sp, sp, #0x8
    pop {r4-r8,lr}
    
skip_end:
    bx lr
    
.pool

storage: .long 0xC7CD00

.align 4
sdmc:       .asciz "sdmc:"
.align 4
sdmc_:      .asciz "sdmc"
.align 4
mod_path:   .asciz "sdmc:/saltysd/smash/"
