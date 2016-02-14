.arm

.macro call func
    ldr r6, =\func
    blx r6
.endm

.include "common.asm"
.equ base_addr,     0xA3B800

test:
     @Compensate for removing code
     add lr, #0x4
     ldrh r0, [r0]
     sub sp, sp, #0x10
     
     push {r0-r6,lr}
         ldr r4, storage
         str r2, [r4, #0x34]
         mov r4, r1
         ldr r3, storage
         ldrh R0, [R2]
         strh R0, [r3,#0x8]
         ldr  R1, [r3,#0x8]
         mov  R0, r3
         call referenced_by_ls_init
         ldr r1, [r0, #0x4]
         ldr r3, storage
         str r1, [r3, #0x30]
         str r0, [r3, #0x38]
     pop  {r0-r6,lr}
     
     push {r0-r6,lr}
         call crit_this
         call crit_init
         
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
     pop  {r0-r6,lr}
     
     push {r0-r8,lr}
         mov r5, r1
         ldr r0, storage
         str r2, [r0, #0x28]
         str r7, [r0, #0x40]
         
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
         
         push {r0-r6,lr}
            mov r0, r7
            call crc
            mov r6, r0
            ldr r0, cache
            ldr r0, [r0]
            cmp r0, #0x0
            beq alloc_cache
begin_crc_check:
            ldr r3, [r0, #0x0] @number of crcs
            ldr r4, =0xF00FF00F
            cmp r3, r4
            beq end_loop_success
            mov r4, #0x1 @count
loop:
            cmp r4, r3
            bgt end_loop
            lsl r2, r4, #0x2
            ldr r1, [r0, r2]
            cmp r6, r1
            beq end_loop_success
            add r4, r4, #0x1
            b loop
end_loop:
            mov r0, #0x0
            ldr r1, cache
            str r0, [r1, #0x4]
            b exit_crc
end_loop_success:
            mov r0, #0x1
            ldr r1, cache
            str r0, [r1, #0x4]
            b exit_crc
alloc_cache:
            ldr r0, =0x8000
            call liballoc
            ldr r1, cache
            str r0, [r1]
            mov r0, r8
            call IFile_Init
             
            mov r0, r8
            ldr r1, =cache_bin+base_addr
            mov r2, #0x1
            call IFile_Open
            cmp r0, #0x0
            beq empty_cache
            mov r0, r8
            call IFile_GetSize
             
            ldr r1, cache
            ldr r1, [r1] @dst
            mov r2, r0 @len
            ldr r3, storage
            add r3, r3, #0x14 @bytes_read
            mov r0, r8 @file
            call IFile_Read
            mov r0, r8
            call IFile_Close 
            b begin_crc_check
            
empty_cache:            
            ldr r1, cache
            ldr r0, [r1]
            ldr r1, =0xF00FF00F
            str r1, [r0]
            b begin_crc_check
exit_crc:
         pop  {r0-r6,lr}
         ldr r0, cache
         ldr r0, [r0, #0x4]
         cmp r0, #0x0
         beq close 
         
         add r7, r8, #0x20
         
         ldr r0, =mod_path+base_addr
         call strlen
         mov r2, r0
         mov r0, r7
         ldr r1, =mod_path+base_addr
         call memcpy
               
         mov r0, r8
         call IFile_Init
         
         mov r0, r8
         mov r1, r7
         mov r2, #0x1
         call IFile_Open
         cmp r0, #0x0
         beq close_and_end @ SD file doesn't exist, exit and pretend it never happened.
         
         ldr r4, storage
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
         
         ldr r4, storage
         ldr r1, [r4, #0x38]
         ldr r0, =something_resource_lock
         ldr r0, [r0]
         call idk @ Not sure, but needed to deallocate
         
         ldr r4, storage
         ldr r1, [r4, #0x30]
         ldr r1, [r1, #0xc]
         call res_deallocate @ Force out existing resource so we can load a new one in
     
skip_clear:        
         mov r0, r8
         call IFile_GetSize
         ldr r3, storage
         str r0, [r3, #0x10]
         
         cmp r5, #0x1
         beq end_read_sd @ Don't allocate if it's just a check-in
         
         mov r1, r0
         ldr r0, =something_resource_lock
         ldr r0, [r0]
         mov r2, #0x80
         ldr r4, storage
         ldr r3, [r4, #0x38]
         call resalloc
         
         ldr r3, storage
         str r0, [r3, #0x18]        
read_in:               
         cmp r5, #0x1
         beq end_read_sd @ Don't read if it's just a check-in
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
     pop  {r0-r8,lr}
   
     @removed code
     push {r0-r6,lr}
         ldr r4, storage
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
     
     ldr r0, storage
     ldr r0, [r0, #0x18]
     
     b exit
     
close_and_end:
        mov r0, r8
        call IFile_Close     
close:
     mov r0, r8
     call libdealloc
     pop  {r0-r8,lr}
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
         ldr  R1, =something_resource_lock
         mov  R2, R4
         ldr  R3, [R1]
         mov  R1, R0
         mov  R0, R3
         call read_dtls
         
         @ Stow pointer away
         ldr r3, storage
         str r0, [r3, #0x20]
     pop  {r0-r6,lr}
    
     ldr r3, storage
     ldr r0, [r3, #0x20]
     
exit:
     ldr lr, =lock_exit
     bx lr
     
close_with_existing:
        mov r0, r8
        call IFile_Close   
     mov r0, r8
     call libdealloc
     pop  {r0-r8,lr}

     ldr r4, storage
     ldr r1, [r4, #0x30]
     ldr r0, [r1, #0xc]
     
     b exit
    
.pool

storage: .long 0xC7CD00
sdmc_on:     .long 0xC7CD80
cache:     .long 0xC7CD84
res_str:     .long 0xC7C700

.align 4
cache_bin:   .asciz "sdmc:/saltysd/smash/cache.bin"
sdmc:       .asciz "sdmc:"
sdmc_short:       .asciz "sd_:"
mod_path:   .asciz "sdmc:/saltysd/smash/"
