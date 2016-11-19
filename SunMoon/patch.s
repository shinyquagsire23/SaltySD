.arm.little

.open "code.bin","code_saltysd.bin",0x100000

mount_sto equ 0x6A251C
mount_phtsd equ 0x16BDE8
alloc equ 0x190D9C
free equ 0x190D74
memcpy equ 0x2FEC20

; stack vars
str_allocation equ 0x0
 
.org 0x1254E0
tryopen_payload:
    mov r6, r0
    cmp r4, #0xBA ;magic check
    beq exit
    push {r0-r12, lr}
        sub sp, sp, #0x20
        mov r7, r1 ;input file path
        mov r8, r2
        
        bl check_mount_sd
        mov r0, r7
        bl print_wchar_path
        
        ; Here we allocate some space for our path,
        ; and then modify it to point to sd_ so that
        ; we can check if it exists
        mov r0, #0x400
        bl alloc
        str r0, [sp, #str_allocation]
        
        ldr r0, [sp, #str_allocation]
        ldr r1, =sdmount_wchar
        mov r2, #(sdmount_wchar_end-sdmount_wchar)
        bl memcpy
        
        ldr r0, [sp, #str_allocation]
        add r0, #(sdmount_wchar_end-sdmount_wchar)
        mov r1, r7
        ldr r3, [r7, #0x0]
        cmp r3, #0x72
        addeq r1, #0x8
        addne r1, #0xA ; Most other archives have 4 letters, ie data:/ vs rom:/
        mov r2, #0x400-(sdmount_wchar_end-sdmount_wchar)
        bl memcpy
        
        
        
        mov r0, r6
        ldr r1, [sp, #str_allocation]
        mov r2, r8
        mov r4, #0xBA ;magic check
        bl 0x168F10
        mov r4, r0
        
        ldr r0, [sp, #str_allocation]
        bl free
        
        ; If we get a 0 result, we have a good file handle
        ; and can return
        cmp r4, #0x0
        beq success
        
        add sp, sp, #0x20
    pop {r0-r12, lr}
exit:
    b 0x168F18
    
success:
    add sp, sp, #0x20
    pop {r0-r12, lr}
    b 0x168F9C
    
check_mount_sd:
    push {r0-r4, lr}
        ldr r0, =mount_sto
        ldr r0, [r0]
        cmp r0, #0x0
        bne skip_mount
        ldr r0, =sdmount
        mov r1, #0xF0000001
        bl mount_phtsd
        ldr r0, =mount_sto
        mov r1, #0x1
        str r1, [r0]
        
skip_mount:
    pop {r0-r4, pc}    

print_wchar_path:
    push {r0-r7, lr}
        sub sp, sp, #0x4
        mov r7, r0
        
        mov r0, #0x200
        bl alloc
        str r0, [sp, #0x0]
        
        mov r3, r0
        mov r1, #0x0
        mov r2, #0x0
strconvloop:
        ldrh r0, [r7, r2]
        strb r0, [r3, r1]
        add r1, #0x1
        add r2, #0x2
        cmp r0, #0x0
        bne strconvloop
        
        ldr r0, [sp, #0x0]
        mov r1, #0x0
        swi 0x3D
        
        ldr r0, [sp, #str_allocation]
        bl free
        add sp, sp, #0x4
    pop {r0-r7, pc}
    
sdmount: .ascii "sd_:"
.byte 0

; there's probably a way better way to do this...
sdmount_wchar:
.ascii "s"
.byte 0
.ascii "d"
.byte 0
.ascii "_"
.byte 0
.ascii ":"
.byte 0
.ascii "/"
.byte 0
.ascii "s"
.byte 0
.ascii "a"
.byte 0
.ascii "l"
.byte 0
.ascii "t"
.byte 0
.ascii "y"
.byte 0
.ascii "s"
.byte 0
.ascii "d"
.byte 0
.ascii "/"
.byte 0
.ascii "S"
.byte 0
.ascii "u"
.byte 0
.ascii "n"
.byte 0
.ascii "M"
.byte 0
.ascii "o"
.byte 0
.ascii "o"
.byte 0
.ascii "n"
.byte 0
sdmount_wchar_end:
.word 0

.pool

; nn::fs::TryOpenFile
.org 0x168F14
    b tryopen_payload
.pool

; No Line
.org 0x41B748
    nop

.Close
