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
.equ referenced_by_ls_init, 0x195C00

test:
     @Compensate for removing code
     add lr, #0x4
     sub sp, sp, #0x18
     ldrh r1, [r0]
     
     b continue
     push {r0-r6,lr}
         ldr r4, file_handle
         str r2, [r4, #0x34]
         mov r4, r1
         ldr r3, file_handle
         ldrh R0, [R2]
         strh R0, [r3,#0x8]
         ldr  R1, [r3,#0x8]
         mov  R0, r3
         call referenced_by_ls_init
         ldr r1, [r0, #0x4]
         ldr r3, file_handle
         str r1, [r3, #0x30]
         str r0, [r3, #0x38] 
     pop  {r0-r6,lr}
     
     
     push {r0-r7,lr}
         ldr r0, file_handle
         mov r1, r2
         str r2, [r0, #0x28]
         ldr r0, res_str
         ldr r3, =0x181814 @lib::Resource::path_str(char* out, Resource* res)
         blx r3

         ldr r0, file_handle
         ldr r3, =0x161F10 @nn::os::CriticalSection::Initialize()
         blx r3
         
         ldr r0, new_res_str
         ldr r1, =mod_path+base_addr
         call strcpy
         
         
         @strcat refuses to work :/
         ldr r0, new_res_str
         call strlen
         ldr r2, new_res_str
         add r0, r0, r2
         ldr r1, res_str
         add r1, #0x4
         call strcpy
         ldr r3, file_handle
         
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
         ldr r0, file_handle
         call IFile_Init
         
         ldr r0, file_handle
         ldr r1, new_res_str
         mov r2, #0x1
         call IFile_Open
         cmp r0, #0x0
         beq close_and_end @ SD file doesn't exist, exit and pretend it never happened.
     
skip_clear:
         
         ldr r0, file_handle
         call IFile_GetSize
         ldr r3, file_handle
         str r0, [r3, #0x10]
         
         ldr r0, file_handle
         call IFile_Close 
end_read_sd:  
     pop  {r0-r7,lr}
   
     ldr r3, file_handle
     ldr r0, [r3, #0x10]
     
     b exit
     
close_and_end:
        ldr r0, file_handle
        call IFile_Close     
close:
     pop  {r0-r7,lr}
continue:   
     mov r0, #0x0  
     ldr lr, =0x16F0A0
     bx lr
     
exit:
     ldr lr, =0x16F0FC
     bx lr
    
.pool

file_handle: .long 0xC68D00
sdmc_on:     .long 0xC68D80
res_str:     .long 0xC68700
new_res_str: .long 0xC68A00
something_resource_lock: .long 0xC57218

.align 4
sdmc:       .asciz "sdmc:"
mod_path:   .asciz "sdmc:/saltysd/smash/"
