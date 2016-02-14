.equ mount_sdmc,                0x291BE0
.equ IFile_Init,                0x12A2F4
.equ IFile_Open,                0x12A21C
.equ IFile_Exists,              0x873DA8
.equ IFile_GetSize,             0x1182CC
.equ IFile_Read,                0x13EEBC
.equ IFile_Close,               0x12A360
.equ strcat,                    0x1003F0
.equ strcpy,                    0x2FEB40
.equ strlen,                    0x2FEA94
.equ resalloc,                  0x178780
.equ path_str,                  0x181850 @lib::Resource::path_str(char* out, Resource* res)
.equ res_deallocate,            0x192D24
.equ idk,                       0x178DE4
.equ referenced_by_ls_init,     0x195C3C
.equ read_dtls,                 0x137EBC
.equ liballoc,                  0x157780
.equ libdealloc,                0x167058
.equ memcpy,                    0x300680
.equ crit_this,                 0x11DAA4
.equ crit_init,                 0x161F30 @nn::os::CriticalSection::Initialize()
.equ crc,                       0x6F47A4
.equ something_resource_lock,   0xC6A6B0

.equ lock_exit,                 0x18175C
.equ data_size_continue,        0x16F0DC
.equ data_size_exit,            0x16F138
.equ exist_continue,            0x159EC8
.equ exist_exit,                0x159F0C
