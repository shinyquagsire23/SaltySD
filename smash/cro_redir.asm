.arm.little

.open "code_saltysd.bin",0x100000

.include "common.armips.asm"

LOAD_OBJECT_LIST equ (0x8)
BUFFER_LOAD_ADDR equ (0x0)
BUFFER_PPREV equ (0x18)
BUFFER_PNEXT equ (0x1C)
BUFFER_CRO_NAME equ (0x20)
CRO_CODE_START equ (0xB0)
CRO_NAMED_EXPORT_PTR equ (0xD0)
CRO_NAMED_EXPORT_NUM equ (0xD4)

; Expand the CRO load object to 8 from 4
.org cro_load_object_adj_loc
    mov r0, #0x8

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

; Patch CRO object new function
.org cro_fighter_new
   push {r2-r8, lr}
      mov r4, r0
      ldrb r0, [r4, #0x2B0] ; get type
      cmp r0, #0x1
      bgt failed
   
      ldr r0, =cro_load_object
      ldr r0, [r0]
      ldr r0, [r0]
      ldr r5, [r0, #LOAD_OBJECT_LIST]

      ldr r0, [r4, #0x2B4] ; get ID
      ldrb r1, [r4, #0x2B0] ; get type
      bl cro_get_size_str
      mov r6, r0
      
      add r0, r0, #0x4
      mov r1, r5
      bl cro_list_find_func
      push {r0-r3}
         mov r0, r6
         bl libdealloc
      pop {r0-r3}
      cmp r0, #0x0
      beq failed
      blx r0
      
      bl liballoc
      mov r8, r0

      ldr r0, [r4, #0x2B4] ; get ID
      ldrb r1, [r4, #0x2B0] ; get type
      bl cro_get_new_str
      mov r6, r0
      
      add r0, r0, #0x4
      mov r1, r5
      bl cro_list_find_func
      push {r0-r3}
         mov r0, r6
         bl libdealloc
      pop {r0-r3}
      cmp r0, #0x0
      beq failed
      
      mov r1, r0
      mov r0, r8
      blx r1

failed:
      mov r1, r0
      add r0, r4, #0x4
   pop {r2-r8, lr}

   cmp r1, #0x0
   moveq r0, #0x0
   bxeq lr

   push {r4-r6, lr}
      mov r4, r0
      ldr r0, [r0, #0x8]
      mov r5, r1
      cmp r0, #0x0
      beq new_is_good
      
      bl cro_unk_1
      ldr r0, [r4, #0x8]
      bl libdealloc
new_is_good:
      mov r0, #0x1
      str r5, [r4, #0x8]
  pop {r4-r6, pc}

; r0=string, r1=CRO
cro_find_func:
   push {r1-r7, lr}
      push {r0-r1}
      mov r1, #0xFF
      swi 0x3D
      pop {r0-r1}
      mov r5, r0
      mov r4, r1
      
      ldr r6, [r4, #CRO_NAMED_EXPORT_PTR]
      ldr r7, [r4, #CRO_NAMED_EXPORT_NUM]

symbol_loop:
      ldr r0, [r6, #0x0]
      mov r1, r5
      bl strcmp
      cmp r0, #0x0
      ldreq r0, [r6, #0x4]
      lsreq r0, r0, #0x4
      ldreq r1, [r4, #CRO_CODE_START]
      addeq r0, r0, r1
      beq symbol_success
      
      add r6, r6, #0x8
      sub r7, r7, #0x1
      cmp r7, #0x0
      bne symbol_loop
      
      mov r0, #0x0
symbol_success:
   pop {r1-r7, pc}

; r0=string, r1=message_buffer
cro_list_find_func:
   push {r1-r7, lr}
      mov r5, r1
      mov r6, r0

cro_search_loop:
      push {r0-r1}
         add r0, r5, #BUFFER_CRO_NAME
         mov r1, #0xFF
         swi 0x3D
      pop {r0-r1}

      ldr r1, [r5, #BUFFER_LOAD_ADDR]
      mov r0, r6
      bl cro_find_func
      cmp r0, #0x0
      bne cro_found
      
      ldr r5, [r5, #BUFFER_PNEXT]
      cmp r5, #0x0
      bne cro_search_loop

cro_found:
   pop {r1-r7, pc}

cro_get_new_str:
   cmp r1, #0x0
   beq get_chr_new
   cmp r1, #0x1
   beq get_proj_new
   bx lr

get_proj_new:
   push {r1-r7, lr}
      sub sp, sp, #0x4
      mov r5, r0 ; ID

      ldr r0, =0x100
      bl liballoc
      mov r7, r0
   
      ldr r0, =projectile_table_ptr
      ldr r0, [r0]
      ldr r0, [r0, r5, lsl #2]
      mov r4, r0 ; projectile
      bl strlen
      mov r6, r0
      
      ldr r0, =projectile_prefix_table_ptr
      ldr r0, [r0]
      ldr r0, [r0, r5, lsl #2]
      mov r5, r0 ; character
      bl strlen
      add r0, r0, #0x4
      add r0, r0, r6
      
      str r4, [sp]
      mov r3, r5
      mov r2, r0
      ldr r1, =proj_new_format
      mov r0, r7
      bl sprintf

      mov r0, r7
      add sp, sp, #0x4
   pop {r1-r7, pc}

get_chr_new:
   push {r1-r7, lr}
      mov r5, r0 ; character ID

      ldr r0, =0x100
      bl liballoc
      mov r7, r0
   
      mov r0, r5
      bl character_id_to_lowercase
      mov r6, r0
      bl strlen
      add r0, r0, #0x3
      
      mov r3, r6
      mov r2, r0
      ldr r1, =chr_new_format
      mov r0, r7
      bl sprintf

      mov r0, r7
   pop {r1-r7, pc}

cro_get_size_str:
   cmp r1, #0x0
   beq get_chr_size
   cmp r1, #0x1
   beq get_proj_size
   bx lr

get_proj_size:
   push {r1-r7, lr}
      sub sp, sp, #0x4
      mov r5, r0 ; ID

      ldr r0, =0x100
      bl liballoc
      mov r7, r0
   
      ldr r0, =projectile_table_ptr
      ldr r0, [r0]
      ldr r0, [r0, r5, lsl #2]
      mov r4, r0 ; projectile
      bl strlen
      mov r6, r0
      
      ldr r0, =projectile_prefix_table_ptr
      ldr r0, [r0]
      ldr r0, [r0, r5, lsl #2]
      mov r5, r0 ; character
      bl strlen
      add r0, r0, #0x8
      add r0, r0, r6
      
      str r4, [sp]
      mov r3, r5
      mov r2, r0
      ldr r1, =proj_size_format
      mov r0, r7
      bl sprintf

      mov r0, r7
      add sp, sp, #0x4
   pop {r1-r7, pc}

get_chr_size:
   push {r1-r7, lr}
      mov r5, r0 ; ID

      ldr r0, =0x100
      bl liballoc
      mov r7, r0
   
      mov r0, r5
      bl character_id_to_lowercase ; get char name
      mov r6, r0
      bl strlen
      add r0, r0, #0x7
      
      mov r3, r6
      mov r2, r0
      ldr r1, =chr_size_format
      mov r0, r7
      bl sprintf

      mov r0, r7
   pop {r1-r7, pc}

.align 4
chr_new_format: .ascii "_Z%uNew%sPv",0
.align 4
chr_size_format: .ascii "_Z%uGetSize%sv",0

.align 4
proj_new_format: .ascii "_Z%uNew%s_%sPv",0
.align 4
proj_size_format: .ascii "_Z%uGetSize%s_%sv",0

.pool

FIGHTER_DATA_SHIFT equ (0x20)
FIGHTER_DATA_OUT equ (FIGHTER_DATA_SHIFT-0x0)
FIGHTER_DATA_ID equ (FIGHTER_DATA_SHIFT-0x4)
FIGHTER_DATA_UNK equ (FIGHTER_DATA_SHIFT-0x8)
FIGHTER_DATA_STR equ (FIGHTER_DATA_SHIFT-0xC)
FIGHTER_DATA_CRO equ (FIGHTER_DATA_SHIFT-0x10)
FIGHTER_DATA_FUNC equ (FIGHTER_DATA_SHIFT-0x14)

; Load get_fighter_data_* exports from CROs at runtime
.org get_fighter_data
   push {r1-r8, lr}
      sub sp, sp, #FIGHTER_DATA_SHIFT
      str r0, [sp, #FIGHTER_DATA_OUT]
      str r1, [sp, #FIGHTER_DATA_ID]
      str r2, [sp, #FIGHTER_DATA_UNK]
   
      ldr r0, =cro_load_object
      ldr r0, [r0]
      ldr r0, [r0]
      ldr r0, [r0, #LOAD_OBJECT_LIST]
      str r0, [sp, #FIGHTER_DATA_CRO]

      ldr r0, [sp, #FIGHTER_DATA_ID]
      bl cro_get_fighter_data_str
      str r0, [sp, #FIGHTER_DATA_STR]
      
      add r0, r0, #0x4
      ldr r1, [sp, #FIGHTER_DATA_CRO]
      bl cro_list_find_func
      str r0, [sp, #FIGHTER_DATA_FUNC]
      ldr r0, [sp, #FIGHTER_DATA_STR]
      bl libdealloc
      
      ldr r0, [sp, #FIGHTER_DATA_OUT]
      ldr r1, [sp, #FIGHTER_DATA_ID]
      ldr r2, [sp, #FIGHTER_DATA_UNK]
      ldr r3, [sp, #FIGHTER_DATA_FUNC]
      
      cmp r3, #0x0
      beq fighter_data_failed
      blx r3
      
      add sp, sp, #FIGHTER_DATA_SHIFT
   pop {r1-r8, pc}
   
fighter_data_failed:
      ldr r0, =0x1234567
      str r0, [r0]
      b fighter_data_failed

cro_get_fighter_data_str:
   push {r1-r7, lr}
      mov r5, r0 ; ID

      ldr r0, =0x100
      bl liballoc
      mov r7, r0
   
      mov r0, r5
      bl character_id_to_lowercase ; get char name
      mov r6, r0
      bl strlen
      add r0, r0, #17
      
      mov r3, r6
      mov r2, r0
      ldr r1, =chr_fighter_data_format
      mov r0, r7
      bl sprintf

      mov r0, r7
   pop {r1-r7, pc}

.align 4
chr_fighter_data_format: .ascii "_ZN3app%uget_fighter_data_%sEv",0

.pool

FIGHTER_SPECIALIZER_SHIFT equ (0x20)
FIGHTER_SPECIALIZER_OUT equ (FIGHTER_SPECIALIZER_SHIFT-0x0)
FIGHTER_SPECIALIZER_ID equ (FIGHTER_SPECIALIZER_SHIFT-0x4)
FIGHTER_SPECIALIZER_UNK equ (FIGHTER_SPECIALIZER_SHIFT-0x8)
FIGHTER_SPECIALIZER_STR equ (FIGHTER_SPECIALIZER_SHIFT-0xC)
FIGHTER_SPECIALIZER_CRO equ (FIGHTER_SPECIALIZER_SHIFT-0x10)
FIGHTER_SPECIALIZER_FUNC equ (FIGHTER_SPECIALIZER_SHIFT-0x14)

; Load get_fighter_specializer_* exports from CROs at runtime
.org get_fighter_specializer
   push {r1-r8, lr}
      sub sp, sp, #FIGHTER_SPECIALIZER_SHIFT
      str r0, [sp, #FIGHTER_SPECIALIZER_OUT]
      str r1, [sp, #FIGHTER_SPECIALIZER_ID]
      str r2, [sp, #FIGHTER_SPECIALIZER_UNK]
   
      ldr r0, =cro_load_object
      ldr r0, [r0]
      ldr r0, [r0]
      ldr r0, [r0, #LOAD_OBJECT_LIST]
      str r0, [sp, #FIGHTER_SPECIALIZER_CRO]

      ldr r0, [sp, #FIGHTER_SPECIALIZER_ID]
      bl cro_get_fighter_specializer_str
      str r0, [sp, #FIGHTER_SPECIALIZER_STR]
      
      add r0, r0, #0x4
      ldr r1, [sp, #FIGHTER_SPECIALIZER_CRO]
      bl cro_list_find_func
      str r0, [sp, #FIGHTER_SPECIALIZER_FUNC]
      ldr r0, [sp, #FIGHTER_SPECIALIZER_STR]
      bl libdealloc
      
      ldr r0, [sp, #FIGHTER_SPECIALIZER_OUT]
      ldr r1, [sp, #FIGHTER_SPECIALIZER_ID]
      ldr r2, [sp, #FIGHTER_SPECIALIZER_UNK]
      ldr r3, [sp, #FIGHTER_SPECIALIZER_FUNC]
      
      cmp r3, #0x0
      moveq r0, #0x0
      blxne r3
      
      add sp, sp, #FIGHTER_SPECIALIZER_SHIFT
   pop {r1-r8, pc}

cro_get_fighter_specializer_str:
   push {r1-r7, lr}
      mov r5, r0 ; ID

      ldr r0, =0x100
      bl liballoc
      mov r7, r0
   
      mov r0, r5
      bl character_id_to_lowercase ; get char name
      mov r6, r0
      bl strlen
      add r0, r0, #24
      
      mov r3, r6
      mov r2, r0
      ldr r1, =chr_fighter_specializer_format
      mov r0, r7
      bl sprintf

      mov r0, r7
   pop {r1-r7, pc}

.align 4
chr_fighter_specializer_format: .ascii "_ZN3app%uget_fighter_specializer_%sEv",0

.align 4
get_weapon_proj_name:
   push {r4-r5,lr}
      mov r5, r0

      ldr r0, =projectile_table_ptr
      ldr r0, [r0]
      ldr r0, [r0, r5, lsl #2]

      ; Our giant list of non-compliant names with random differences...
      cmp r5, #3
      ldreq r0, =mario_pump_water
      cmp r5, #4
      ldreq r0, =mario_huge_flame
      cmp r5, #37
      ldreq r0, =zelda_lightingbow_arrow
      cmp r5, #40
      ldreq r0, =dedede_star_missile
      cmp r5, #69
      ldreq r0, =sheik_lightingbow_arrow
      cmp r5, #90
      ldreq r0, =ness_yoyo_head
      cmp r5, #92
      ldreq r0, =link_clawshot_head
      cmp r5, #93
      ldreq r0, =link_clawshot_hand
      cmp r5, #210
      ldreq r0, =toonlink_hookshot_head
      cmp r5, #211
      ldreq r0, =toonlink_hookshot_hand
      ldr r4, =#302
      cmp r5, r4
      ldreq r0, =pacman_firehydrant_water
      ldr r4, =#346
      cmp r5, r4
      ldreq r0, =samus_gbeamall
      ldr r4, =#370
      cmp r5, r4
      ldreq r0, =lucas_himohebiall
      ldr r4, =#373
      cmp r5, r4
      ldreq r0, =roy_sword
   pop {r4-r5, pc}

mario_pump_water: .ascii "pump_water",0
mario_huge_flame: .ascii "huge_flame",0
zelda_lightingbow_arrow: .ascii "lightingbow_arrow",0
dedede_star_missile: .ascii "star_missile",0
sheik_lightingbow_arrow: .ascii "lightingbow_arrow",0
ness_yoyo_head: .ascii "yoyo_head",0
link_clawshot_head: .ascii "clawshot_head",0
link_clawshot_hand: .ascii "clawshot_hand",0
toonlink_hookshot_head: .ascii "hookshot_head",0
toonlink_hookshot_hand: .ascii "hookshot_hand",0
pacman_firehydrant_water: .ascii "firehydrant_water",0
samus_gbeamall: .ascii "gbeamall",0
lucas_himohebiall: .ascii "himohebiall",0
roy_sword: .ascii "sword",0

.pool




WEAPON_DATA_SHIFT equ (0x20)
WEAPON_DATA_THIS equ (WEAPON_DATA_SHIFT-0x0)
WEAPON_DATA_ID equ (WEAPON_DATA_SHIFT-0x4)
WEAPON_DATA_STR equ (WEAPON_DATA_SHIFT-0x8)
WEAPON_DATA_CRO equ (WEAPON_DATA_SHIFT-0xC)
WEAPON_DATA_FUNC equ (WEAPON_DATA_SHIFT-0x10)

; Load get_weapon_data_* exports from CROs at runtime
.org get_weapon_data
   push {r1-r8, lr}
      sub sp, sp, #WEAPON_DATA_SHIFT
      str r0, [sp, #WEAPON_DATA_THIS]
      str r1, [sp, #WEAPON_DATA_ID]
   
      ldr r0, =cro_load_object
      ldr r0, [r0]
      ldr r0, [r0]
      ldr r0, [r0, #LOAD_OBJECT_LIST]
      str r0, [sp, #WEAPON_DATA_CRO]

      ldr r0, [sp, #WEAPON_DATA_ID]
      bl cro_get_weapon_data_str
      str r0, [sp, #WEAPON_DATA_STR]
      
      add r0, r0, #0x4
      ldr r1, [sp, #WEAPON_DATA_CRO]
      bl cro_list_find_func
      str r0, [sp, #WEAPON_DATA_FUNC]
      ldr r0, [sp, #WEAPON_DATA_STR]
      bl libdealloc
      
      ldr r0, [sp, #WEAPON_DATA_THIS]
      ldr r1, [sp, #WEAPON_DATA_ID]
      ldr r3, [sp, #WEAPON_DATA_FUNC]
      
      cmp r3, #0x0
      ldreq r0, =weapon_data_default
      blxne r3
      
      add sp, sp, #WEAPON_DATA_SHIFT
   pop {r1-r8, pc}

cro_get_weapon_data_str:
   push {r1-r7, lr}
      sub sp, sp, #0x4
      mov r5, r0 ; ID

      ldr r0, =0x100
      bl liballoc
      mov r7, r0
   
      mov r0, r5
      bl get_weapon_proj_name

      mov r4, r0 ; projectile
      bl strlen
      mov r6, r0
      
      ldr r0, =projectile_prefix_table_ptr
      ldr r0, [r0]
      ldr r0, [r0, r5, lsl #2]
      mov r5, r0 ; character
      bl strlen
      add r0, r0, #17
      add r0, r0, r6
      
      str r4, [sp]
      mov r3, r5
      mov r2, r0
      ldr r1, =chr_weapon_data_format
      mov r0, r7
      bl sprintf

      mov r0, r7
      add sp, sp, #0x4
   pop {r1-r7, pc}

.align 4
chr_weapon_data_format: .ascii "_ZN3app%uget_weapon_data_%s_%sEv",0

.pool

WEAPON_SPECIALIZER_SHIFT equ (0x20)
WEAPON_SPECIALIZER_THIS equ (WEAPON_SPECIALIZER_SHIFT-0x0)
WEAPON_SPECIALIZER_ID equ (WEAPON_SPECIALIZER_SHIFT-0x4)
WEAPON_SPECIALIZER_STR equ (WEAPON_SPECIALIZER_SHIFT-0x8)
WEAPON_SPECIALIZER_CRO equ (WEAPON_SPECIALIZER_SHIFT-0xC)
WEAPON_SPECIALIZER_FUNC equ (WEAPON_SPECIALIZER_SHIFT-0x10)

; Load get_weapon_specializer_* exports from CROs at runtime
.org get_weapon_specializer
   push {r1-r8, lr}
      sub sp, sp, #WEAPON_SPECIALIZER_SHIFT
      str r0, [sp, #WEAPON_SPECIALIZER_THIS]
      str r1, [sp, #WEAPON_SPECIALIZER_ID]
   
      ldr r0, =cro_load_object
      ldr r0, [r0]
      ldr r0, [r0]
      ldr r0, [r0, #LOAD_OBJECT_LIST]
      str r0, [sp, #WEAPON_SPECIALIZER_CRO]

      ldr r0, [sp, #WEAPON_SPECIALIZER_ID]
      bl cro_get_weapon_specializer_str
      str r0, [sp, #WEAPON_SPECIALIZER_STR]
      
      add r0, r0, #0x4
      ldr r1, [sp, #WEAPON_SPECIALIZER_CRO]
      bl cro_list_find_func
      str r0, [sp, #WEAPON_SPECIALIZER_FUNC]
      ldr r0, [sp, #WEAPON_SPECIALIZER_STR]
      bl libdealloc
      
      ldr r0, [sp, #WEAPON_SPECIALIZER_THIS]
      ldr r1, [sp, #WEAPON_SPECIALIZER_ID]
      ldr r3, [sp, #WEAPON_DATA_FUNC]
      
      cmp r3, #0x0
      beq weapon_specializer_default
      blxne r3
      
      add sp, sp, #WEAPON_SPECIALIZER_SHIFT
   pop {r1-r8, pc}
   
weapon_specializer_default:
      ldr r0, =weapon_specializer_thing1 ; TODO
      ldr r0, [r0]
      tst r0, #1
      bne loc_98309C
      ldr r0, =weapon_specializer_thing1
      blx weapon_specializer_thing4
      cmp r0, #0
      beq loc_98309C
      ldr r0, =weapon_specializer_thing2
      ldr r1, =weapon_specializer_thing3
      str r1, [r0]
      ldr r0, =weapon_specializer_thing1
loc_98309C:
      ldr r0, =weapon_specializer_thing2
   pop {r1-r8, pc}

cro_get_weapon_specializer_str:
   push {r1-r7, lr}
      sub sp, sp, #0x4
      mov r5, r0 ; ID

      ldr r0, =0x100
      bl liballoc
      mov r7, r0
   
      mov r0, r5
      bl get_weapon_proj_name

      mov r4, r0 ; projectile
      bl strlen
      mov r6, r0
      
      ldr r0, =projectile_prefix_table_ptr
      ldr r0, [r0]
      ldr r0, [r0, r5, lsl #2]
      mov r5, r0 ; character
      bl strlen
      add r0, r0, #24
      add r0, r0, r6
      
      str r4, [sp]
      mov r3, r5
      mov r2, r0
      ldr r1, =chr_weapon_specializer_format
      mov r0, r7
      bl sprintf

      mov r0, r7
      add sp, sp, #0x4
   pop {r1-r7, pc}

.align 4
chr_weapon_specializer_format: .ascii "_ZN3app%uget_weapon_specializer_%s_%sEv",0

.pool



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
      add r0, r4, #BUFFER_CRO_NAME
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
