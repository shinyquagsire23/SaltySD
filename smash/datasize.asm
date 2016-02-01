.arm

.macro call func
    ldr r6, =\func
    blx r6
.endm

.equ base_addr,     0xA1C800
.equ mount_sdmc,    0x28FEF4
.equ IFile_Init,    0x12A2F0
.equ IFile_Open,    0x12A218
.equ IFile_GetSize, 0x1182CC
.equ IFile_Read,    0x13EEB8
.equ IFile_Close,   0x12A35C
.equ strcat,        0x1003F0
.equ strcpy,        0x2FEBD8
.equ strlen,        0x2FEB2C
.equ liballoc,      0x157760
.equ libdealloc,    0x167038
.equ memcpy,        0x3009E0
.equ crit_this,     0x11DAA4

test:
     @Compensate for removing code
     add lr, #0x4
     sub sp, sp, #0x18
     ldrh r1, [r0]
     mov r2, r0
     
     push {r0-r8,lr}
         ldr r0, storage
         str r2, [r0, #0x28]
         
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
         ldr r3, =0x181814 @lib::Resource::path_str(char* out, Resource* res)
         blx r3
         add r7, r8, #0x20

         call crit_this
         ldr r3, =0x161F10 @nn::os::CriticalSection::Initialize()
         blx r3
         
         ldr r0, =mod_path+base_addr
         call strlen
         mov r2, r0
         mov r0, r7
         ldr r1, =mod_path+base_addr
         call memcpy
         
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
         mov r0, r8
         call IFile_Init
         
         mov r0, r8
         mov r1, r7
         mov r2, #0x1
         call IFile_Open
         cmp r0, #0x0
         beq close_and_end @ SD file doesn't exist, exit and pretend it never happened.
     
skip_clear:
         
         mov r0, r8
         call IFile_GetSize
         ldr r3, storage
         str r0, [r3, #0x10]
         
         mov r0, r8
         call IFile_Close 
end_read_sd:  
     mov r0, r8
     call libdealloc
     pop  {r0-r8,lr}
   
     ldr r3, storage
     ldr r0, [r3, #0x10]
     
     b exit
     
close_and_end:
        mov r0, r8
        call IFile_Close     
close:
     mov r0, r8
     call libdealloc
     pop  {r0-r8,lr}
continue:   
     mov r0, #0x0  
     ldr lr, =0x16F0A0
     bx lr
     
exit:
     ldr lr, =0x16F0FC
     bx lr
    
.pool

storage: .long 0xC68D00
sdmc_on:     .long 0xC68D80
res_str:     .long 0xC68700
new_res_str: .long 0xC68A00
something_resource_lock: .long 0xC57218

.align 4
sdmc:       .asciz "sdmc:"
mod_path:   .asciz "sdmc:/saltysd/smash/"
