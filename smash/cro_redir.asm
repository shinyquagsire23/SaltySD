.arm.little

.open "code_saltysd.bin","code_saltysd_cro.bin",0x100000

.include "common.armips.asm"

.org cro_load_hook_loc
   bl cro_extend

; Extend the msg buffer size
.org cro_msg_hook_loc-8
mov r0, #0x60

.org cro_msg_hook_loc+4
    nop
.org cro_msg_hook_loc+0xC
   bl cro_msg_extend
cro_msg_return:

.org cro_load_hook_loc_2
   bl cro_extend

; Extend the msg buffer size
.org cro_msg_hook_loc_2-8
mov r0, #0x60

.org cro_msg_hook_loc_2+4
    nop
.org cro_msg_hook_loc_2+0xC
   bl cro_msg_extend
cro_msg_return_2:

.org cro_file_size_hook_loc-0xC
cro_file_size_hook:
   b cro_file_size_intercept
cro_file_size_return:

.org cro_file_size_hook_loc+0xC
cro_file_size_skip:

.org cro_file_hook_loc-0x1C
cro_file_hook:
   b cro_file_intercept
cro_file_return:
.org cro_file_hook_loc
cro_sarc_skip:

.org 0xA36C00

; Keep a pointer to our string in r8 for later
cro_extend:
   mov r8, r1
   ldr r5, [r0]

   ; Debug print
   push {r0-r1}
      mov r0, r1
      mov r1, #0xff
      swi 0x3D
   pop {r0-r1}

   bx lr

; With the allocation size increased, copy our string from r8
; to the buffer which will be sent to the CRO thread
cro_msg_extend:
   ; Copy our string
   push {r0-r4, lr}
      mov r0, r4
      add r0, #0x20
      mov r1, r8
      mov r2, #0x40
      bl memcpy
   pop {r0-r4, lr}
   
   ; Debug print
   push {r0-r1}
      add r0, r4, #0x20
      mov r1, #0xff
      swi 0x3D
   pop {r0-r1}
   
   mov r8, #0x0
   str r8, [r4]
   
   bx lr
   
STACK_SHIFT equ (0x40)   

FILE_HANDLE equ (STACK_SHIFT-0x0)
ORIG_SIZE equ (STACK_SHIFT-0x4)
CRO_ALLOC equ (STACK_SHIFT-0x8)
CRO_SIZE equ (STACK_SHIFT-0xC)
CRO_PATH equ (STACK_SHIFT-0x10)
FILE_PATH equ (STACK_SHIFT-0x14)
BYTES_READ equ (STACK_SHIFT-0x18)

cro_file_size_intercept:
   push {r1-r6, lr}
      sub sp, sp, #STACK_SHIFT

      ; Get a pointer to our CRO sarc path
      add r1, r4, #0x20
      str r1, [sp, #CRO_PATH]
      
      ldr r0, =0x404
      bl liballoc
      str r0, [sp, #FILE_HANDLE]
      add r0, r0, #0x100
      str r0, [sp, #FILE_PATH]
      ldr r1, =mod_path
      bl strcpy
      
      ldr r0, [sp, #FILE_PATH]
      ldr r1, [sp, #CRO_PATH]
      ldr r2, =strcat+1
      blx r2
      
      ; Print the string to debug console
      ldr r0, [sp, #FILE_PATH]
      mov r1, #0xff
      swi 0x3D
   
      ldr r0, [sp, #FILE_HANDLE]
      bl IFile_Init
         
      ldr r0, =sdmc
      bl mount_sdmc
        
      ldr r0, [sp, #FILE_HANDLE]
      ldr r1, [sp, #FILE_PATH]
      mov r2, #0x1
      bl IFile_Open
      cmp r0, #0x0
      beq size_close_and_end ; SD file doesn't exist, exit and pretend it never happened.
      
      ; Debug print that we've got a file
      mov r1, #0xff
      ldr r0, =meme
      swi 0x3D
      
      ldr r0, [sp, #FILE_HANDLE]
      bl IFile_GetSize
      add r0, #0x1000
      str r0, [sp, #ORIG_SIZE]

      ldr r0, [sp, #FILE_HANDLE]
      bl IFile_Close 
      b size_close_and_bypass
   
size_close_and_bypass:
      ldr r0, [sp, #FILE_HANDLE]
      bl libdealloc
      
      ldr r0, [sp, #ORIG_SIZE]
      add sp, sp, #STACK_SHIFT
   pop {r1-r6, lr}
   b cro_file_size_skip

size_close_and_end:
      ldr r0, [sp, #FILE_HANDLE]
      bl libdealloc
      
      add sp, sp, #STACK_SHIFT
   pop {r1-r6, lr}

   ldr r1, [r4, #0xC]
   add r0, r6, #0x18
   b cro_file_size_return
   
; In the CRO thread, check if our file exists at all and load
; it into the game if it does
cro_file_intercept:
   push {r0-r4, lr}
      sub sp, sp, #STACK_SHIFT
      
      ; Get a pointer to our CRO sarc path
      add r1, r4, #0x20
      str r1, [sp, #CRO_PATH]
      str r9, [sp, #CRO_ALLOC]
      
      ldr r0, =0x404
      bl liballoc
      str r0, [sp, #FILE_HANDLE]
      add r0, r0, #0x100
      str r0, [sp, #FILE_PATH]
      ldr r1, =mod_path
      bl strcpy
      
      ldr r0, [sp, #FILE_PATH]
      ldr r1, [sp, #CRO_PATH]
      ldr r2, =strcat+1
      blx r2
      
      ; Print the string to debug console
      ldr r0, [sp, #FILE_PATH]
      mov r1, #0xff
      swi 0x3D
   
      ldr r0, [sp, #FILE_HANDLE]
      bl IFile_Init
        
      ldr r0, [sp, #FILE_HANDLE]
      ldr r1, [sp, #FILE_PATH]
      mov r2, #0x1
      bl IFile_Open
      cmp r0, #0x0
      beq close_and_end ; SD file doesn't exist, exit and pretend it never happened.
      
      ; Debug print that we've got a file
      mov r1, #0xff
      ldr r0, =meme2
      swi 0x3D
      
      ldr r0, [sp, #FILE_HANDLE]
      bl IFile_GetSize
      str r0, [sp, #CRO_SIZE]
      
      ldr r1, [sp, #CRO_ALLOC] ; dst
      ldr r2, [sp, #CRO_SIZE]  ; size
      add r3, sp, #BYTES_READ ; bytes read
      ldr r0, [sp, #FILE_HANDLE]
      bl IFile_Read
      
      ldr r0, [sp, #FILE_HANDLE]
      bl IFile_Close 
      ldr r0, [sp, #FILE_HANDLE]
      bl libdealloc
      
      add sp, sp, #STACK_SHIFT
   pop {r0-r4, lr}

   b cro_sarc_skip      
close_and_end: 
      ldr r0, [sp, #FILE_HANDLE]
      bl libdealloc
      
      add sp, sp, #STACK_SHIFT
   pop {r0-r4, lr}
   mov r1, r7
   b cro_file_return

.align 4
sdmc:       .ascii "sdmc:",0
.align 4
mod_path:   .ascii "sdmc:/saltysd/smash/cro/"
mod_path_end: .byte 0
.align 4
meme: .ascii "file exists",0
.align 4
meme2: .ascii "file override",0
.pool

.Close
