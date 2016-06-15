#include <3ds.h>
#include <stdarg.h>
#include "../../common.h"

typedef struct __attribute__((__packed__))
{
  u16 magic;
  u16 version;
  u32 num_entries;
} ls_header;

typedef struct __attribute__((__packed__))
{
    u32 crc;
    u32 start;
    u32 size;
    u16 dt_index;
    u16 unk;
} ls_entry;

typedef struct __attribute__((__packed__))
{
    u16 path[0x106];
    char shortpath[10];
    char pathext[4];
    u8 valid_path;
    u8 unk;
    u8 is_directory;
    u8 is_hidden;
    u8 is_archive;
    u8 is_readonly;
    u64 file_size;
} DirectoryEntry;

static void (*memcpy)(void *dest, const void *src, size_t n) = (void*)memcpy_ADDR;
static void (*memmove)(void *dest, const void *src, size_t n) = (void*)memmove_ADDR;
static void* (*malloc)(size_t size) = (void*)liballoc_ADDR;
static void (*free)(void* ptr) = (void*)libdealloc_ADDR;
static void (*memclr)(void *ptr, size_t size) = (void*)memclr_ADDR;
static int (*strlen)(char *str) = (void*)strlen_ADDR;
static int (*strcmp)(const char *str1, const char *str2) = (void*)strcmp_ADDR;
static int (*vsnprintf)(char * s, size_t n, const char * format, va_list arg ) = (void*)0x102434+1;

static void* (*crit_this)(void) = (void*)crit_this_ADDR;
static void* (*crit_init)(void* crit_inst) = (void*)crit_init_ADDR;
static u32 (*mount_sdmc)(char *mount_path) = (void*)mount_sdmc_ADDR;
static u32 (*unmount_path)(char *mount_path) = (void*)unmount_path_ADDR;

static u32 (*OpenDirectory)(void **handle, u16 *path) = (void*)OpenDirectory_ADDR;
static u32 (*ReadDirectory)(u32 *num_dirs, void *handle, void *out, u32 num_entries_toload) = (void*)ReadDirectory_ADDR;
static u32 (*CloseDirectory)(void *handle) = (void*)CloseDirectory_ADDR;

u32 crc32(u32 crc, void *buf, size_t size)
{
    u32 crc_tab_ADDR = *(u32*)(crc_ADDR+0x44);
    u32 *crc32_tab = (u32*)(crc_tab_ADDR);
    
	const u8 *p;

	p = buf;
	crc = crc ^ ~0U;

	while (size--)
		crc = crc32_tab[(crc ^ *p++) & 0xFF] ^ (crc >> 8);

	return crc ^ ~0U;
}

u32 weird_crc(char *str)
{
    u32 size = strlen(str);
    char *invert = malloc(0x121);
    memcpy(invert, str, size+sizeof(char));
    
    for(int i = 0; i < 4; i++)
        invert[i] ^= 0xFF;
        
    u32 ret = crc32(0, invert, size);
    free(invert);
    return ret;
}

int dumb_wcslen(u16 *str)
{
    u32 len = 0;
    while(1)
    {
        if(str[len] == 0)
            return len;
        len++;
    }
}

char *dumb_strncat(char *dest, char *src, u32 len)
{
    void *copyinto = dest+strlen(dest);
    memcpy(copyinto, src, len);
    *(u8*)(copyinto+len) = 0;
    return dest;
}

char *dumb_strcat(char *dest, char *src)
{
    return dumb_strncat(dest, src, strlen(src));
}

u16 *dumb_wcsncat(u16 *dest, u16 *src, u32 len)
{
    void *copyinto = dest+dumb_wcslen(dest);
    memcpy(copyinto, src, len*sizeof(u16));
    *(u16*)(copyinto+(len*sizeof(u16))) = 0;
    return dest;
}

u16 *dumb_wcscat(u16 *dest, u16 *src)
{
    return dumb_wcsncat(dest, src, dumb_wcslen(src));
}

u16 *dumb_mbstowcs(u16 *dest, char *src)
{
    u32 count = 0;
    while(1)
    {
        dest[count] = src[count];
        if(src[count] == 0)
            break;
        count++;
    }
    return dest;
}

char *dumb_wcstombs(char *dest, u16 *src)
{
    u32 count = 0;
    while(1)
    {
        dest[count] = (u8)(src[count] & 0xFF);
        if(src[count] == 0)
            break;
        count++;
    }
    return dest;
}

void debug_print(char *str)
{
    __asm__("svc 0x3D");
}

void printf(char *format, ...)
{
    char *str = malloc(0x400);

    va_list argptr;
    va_start(argptr,format);
    vsnprintf(str, 0x400, format, argptr);
    va_end(argptr);
    
    dumb_strcat(str, "");
    debug_print(str);
    free(str);
}

void _main(ls_header* header, ls_entry (*entries)[], char *region)
{
    crit_init(crit_this());
    mount_sdmc("sd:");
    
    //Iterate through sd:/saltysd/smash for every single file
    u32 num_directories = 1;
    u32 num_files = 0;
    void *dir_entries = malloc(0x40*sizeof(DirectoryEntry));
    void *dir_handle;
    u16 *dir_path = malloc(0x101*sizeof(u16));
    dumb_mbstowcs(dir_path, "sd:/saltysd/smash");
    
    u16 **dirs = malloc(0x1000*sizeof(u16*));
    char **files = malloc(0x4000*sizeof(char*));
    u32 *file_sizes = malloc(0x4000*sizeof(u32));
    dirs[0] = dir_path;
    
    for(int i = 0; i < num_directories; i++)
    {
        u32 num_files_folders = 0;
        if((OpenDirectory(&dir_handle, dirs[i]) & 0x80000000) == 0)
        {
            ReadDirectory(&num_files_folders, dir_handle, dir_entries, 0x40);
            CloseDirectory(dir_handle);
            
            for(int j = 0; j < num_files_folders; j++)
            {
                DirectoryEntry *dir_entry = dir_entries + j*sizeof(DirectoryEntry);
            
                if(dir_entry->is_directory)
                {
                    u16 *new_dir = malloc(0x101*sizeof(u16));
                    new_dir[0] = 0;
                    
                    dumb_wcscat(new_dir, dirs[i]);
                    dumb_wcscat(new_dir, L"/");
                    dumb_wcscat(new_dir, dir_entry->path);
                    dirs[num_directories] = new_dir;
                    num_directories++;
                }
                else
                {
                    char *file = malloc(0x101);
                    file[0] = 0;
                    if(i != 0)
                    {
                        dumb_wcstombs(file, dirs[i]+sizeof("sd:/saltysd/smash/")-1);
                        dumb_strcat(file, "/");
                    }
                    dumb_wcstombs(file+strlen(file), dir_entry->path);
                    
                    files[num_files] = file;
                    file_sizes[num_files] = (u32)(dir_entry->file_size & 0xFFFFFFFF);
                    num_files++;
                }
            }
        }
        
        free(dirs[i]);
    }
    
    free(dirs);
    free(dir_entries);
    
    //TODO: New Files!
    char *path_craft = malloc(0x121);
    for(int i = 0; i < num_files; i++)
    {
        bool found = false;
        bool found_local = false;
        
        path_craft[0] = 0;
        dumb_strcat(path_craft, "data/");
        dumb_strcat(path_craft, files[i]);
        u32 filecrc = weird_crc(path_craft);
        
        for(int j = 0; j < header->num_entries; j++)
        {
            if((*entries)[j].crc == filecrc)
            {
                found = true;
                printf("ls exists: %s %x", path_craft, filecrc);
            }
        }
        
        path_craft[0] = 0;
        dumb_strcat(path_craft, "data(");
        dumb_strcat(path_craft, region);
        dumb_strcat(path_craft, ")/");
        dumb_strcat(path_craft, files[i]);
        u32 filecrc_local = weird_crc(path_craft);
        
        for(int j = 0; j < header->num_entries; j++)
        {
            if((*entries)[j].crc == filecrc_local)
            {
                found_local = true;
                printf("ls exists: %s %x", path_craft, filecrc_local);
            }
        }
        
        if(!found && !found_local)
        {
            (*entries)[header->num_entries].crc = filecrc;
            (*entries)[header->num_entries].start = 0;
            (*entries)[header->num_entries].size = file_sizes[i];
            (*entries)[header->num_entries].dt_index = 0;
            (*entries)[header->num_entries].unk = 0;
            header->num_entries++;
        }
        
        free(files[i]);
        files[i] = NULL;
    }
    free(path_craft);
    
    free(file_sizes);
    free(files);
    unmount_path("sd");
    
    return;
}
