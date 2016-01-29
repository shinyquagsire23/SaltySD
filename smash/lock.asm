.arm

.macro call func
    ldr r6, =\func
    blx r6
.endm

.equ base_addr,     0xA1B800
.equ mount_sdmc,    0x28FEF4
.equ IFile_Init,    0x12A2F0
.equ IFile_Open,    0x12A218
.equ IFile_GetSize, 0x1182CC
.equ IFile_Read,    0x13EEB8
.equ IFile_Close,   0x12A35C
.equ strcat,        0x1003F0
.equ strcpy,        0x2FEBD8
.equ strlen,        0x2FEB2C
.equ resalloc,      0x178744
.equ res_deallocate, 0x192CE8
.equ idk, 0x178DA8
.equ referenced_by_ls_init, 0x195C00

test:
     @Compensate for removing code
     add lr, #0x4
     ldrh r0, [r0]
     sub sp, sp, #0x10
     
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
         mov r5, r1
         mov r1, r2
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
         
         ldr r4, file_handle
         ldr r4, [r4, #0x30]
         cmp r4, #0x0
         beq close_and_end
         
         ldr r1, [r4, #0xc]
         cmp r1, #0x0
         beq skip_clear @ No data pointer, probably safe to allocate space and load in
         
         ldrh r1, [r4, #0x8]
         tst r1, #0x4000
         bne close_with_existing @ Our flag is set, just exit because we have it loaded
         tst r1, #0x8
         bne close_with_existing @ Resource is loaded, exit
         
         ldr r4, file_handle
         ldr r1, [r4, #0x38]
         ldr r0, something_resource_lock
         ldr r0, [r0]
         call idk @ Not sure, but needed to deallocate
         
         ldr r4, file_handle
         ldr r1, [r4, #0x30]
         ldr r1, [r1, #0xc]
         call res_deallocate @ Force out existing resource so we can load a new one in
     
skip_clear:
         
         ldr r0, file_handle
         call IFile_GetSize
         ldr r3, file_handle
         str r0, [r3, #0x10]
         
         cmp r5, #0x1
         beq end_read_sd @ Don't allocate if it's just a check-in
         
         mov r1, r0
         ldr r0, something_resource_lock
         ldr r0, [r0]
         mov r2, #0x80
         call resalloc
         ldr r3, file_handle
         str r0, [r3, #0x18]
         
read_in:         
         cmp r5, #0x1
         beq end_read_sd @ Don't read if it's just a check-in
         ldr r0, file_handle @file
         ldr r1, [r0, #0x18] @dst
         ldr r2, [r0, #0x10] @size
         add r3, r0, #0x14 @bytes_read
         call IFile_Read
         
         ldr r0, file_handle
         call IFile_Close 
end_read_sd:  
     pop  {r0-r7,lr}
   
     @removed code
     push {r0-r6,lr}
         ldr r4, file_handle
         ldr r1, [r4, #0x30]
         ldr r2, [r4, #0x18]
         str r2, [r1, #0xC] @Set our alloc'd address
         mov r2, #0x80
         cmp r5, #0x1
         addne r2, #0x1
         strb r2, [r1, #0x16] @Set our resource as locked
         ldr r2, =0x4408
         strneh r2, [r1, #0x8] @Set our resource as loaded, with our SD flag
     pop  {r0-r6,lr}
     
     ldr r0, file_handle
     ldr r0, [r0, #0x18]
     
     b exit
     
close_and_end:
        ldr r0, file_handle
        call IFile_Close     
close:
     pop  {r0-r7,lr}
continue:     
     @removed code
     mov r4, r1
     strh R0, [SP,#0x8]
     ldr  R1, [SP,#0x8]
     mov  R0, #0
     strh R0, [SP,#0x8]
     uxth R1, R1
     cmp  R1, R0
     beq  exit
     ldrh R0, [R2]
     strh R0, [SP,#0x8]
     ldr  R1, [SP,#0x8]
     mov  R0, SP
     push {r0-r6,lr}
         call referenced_by_ls_init
         ldr  R1, something_resource_lock
         mov  R2, R4
         ldr  R3, [R1]
         mov  R1, R0
         mov  R0, R3
         call   0x137EBC
         
         @ Stow pointer away
         ldr r3, file_handle
         str r0, [r3, #0x20]
     pop  {r0-r6,lr}
    
     ldr r3, file_handle
     ldr r0, [r3, #0x20]
     
exit:
     ldr lr, =0x181720
     bx lr
     
close_with_existing:
        ldr r0, file_handle
        call IFile_Close     
     pop  {r0-r7,lr}

     ldr r4, file_handle
     ldr r1, [r4, #0x30]
     ldr r0, [r1, #0xc]
     str r0, [r4, #0x54]
     
     b exit
    
.pool

file_handle: .long 0xC68D00
sdmc_on:     .long 0xC68D80
res_str:     .long 0xC68700
new_res_str: .long 0xC68A00
something_resource_lock: .long 0xC57218

.align 4
sdmc:       .asciz "sdmc:"
mod_path:   .asciz "sdmc:/saltysd/smash/"
