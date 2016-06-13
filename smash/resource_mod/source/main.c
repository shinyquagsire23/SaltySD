#include <3ds.h>
#include "../../common.h"

typedef struct __attribute__((__packed__))
{
  u16 magic;
  u8 props;
  u8 pad;
  u32 contents_start;
  u32 contents_size;
  u32 entrysection_start;
  u32 entrysection_size;
  u32 timestamp;
  u32 compressed_size;
  u32 decompressed_size;
  u32 stringsection_start;
  u32 stringsection_size;
  u32 resourceentry_amt;
    
} rf_header;

typedef struct __attribute__((__packed__))
{
    u32 chunk_offs;
    u32 string_offs;
    u32 comp_size;
    u32 decomp_size;
    u32 timestamp;
    u32 flags;
} rf_entry;

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

static u32 (*IFile_Init)(void *handle) = (void*)IFile_Init_ADDR;
static u32 (*IFile_Open)(void *handle, char *path, u32 mode) = (void*)IFile_Open_ADDR;
static u32 (*IFile_Read)(void *handle, void *dest, size_t size, u32 *bytes_read) = (void*)IFile_Read_ADDR;
static u32 (*IFile_GetSize)(void *handle) = (void*)IFile_GetSize_ADDR;
static u32 (*IFile_Close)(void *handle) = (void*)IFile_Close_ADDR;

static void* (*crit_this)(void) = (void*)crit_this_ADDR;
static void* (*crit_init)(void* crit_inst) = (void*)crit_init_ADDR;
static u32 (*mount_sdmc)(char *mount_path) = (void*)mount_sdmc_ADDR;
static u32 (*unmount_path)(char *mount_path) = (void*)unmount_path_ADDR;

static u32 (*OpenDirectory)(void **handle, u16 *path) = (void*)OpenDirectory_ADDR;
static u32 (*ReadDirectory)(u32 *num_dirs, void *handle, void *out, u32 num_entries_toload) = (void*)ReadDirectory_ADDR;
static u32 (*CloseDirectory)(void *handle) = (void*)CloseDirectory_ADDR;

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

void _main(rf_header* header, void *contents)
{
    const u32 STRING_SHIFT = sizeof(rf_entry)*0x800;
    const u32 EXT_SHIFT = 0x2000*0x8*sizeof(u8);
    void *string_section_current = contents + (header->stringsection_start - header->contents_start);
    void *string_section_next = string_section_current + STRING_SHIFT;
    
    //Move string section to make room for new entries
    memmove(string_section_next, string_section_current, header->stringsection_size);
    memclr(string_section_current,STRING_SHIFT);
    header->stringsection_start += STRING_SHIFT;
    header->decompressed_size += STRING_SHIFT;
    header->contents_size += STRING_SHIFT;
    
    //Move extension chunk to make room for new strings
    memmove(string_section_next + (*(u32*)string_section_next * 0x2000 * sizeof(u8)) + EXT_SHIFT, string_section_next + (*(u32*)string_section_next * 0x2000 * sizeof(u8)), 0x2000);
    memclr(string_section_next + (*(u32*)string_section_next * 0x2000 * sizeof(u8)), EXT_SHIFT);
    header->stringsection_size += EXT_SHIFT;
    header->decompressed_size += EXT_SHIFT;
    header->contents_size += EXT_SHIFT;
    *(u32*)string_section_next += (EXT_SHIFT / 0x2000);
    
    //Set up our array of entries
    rf_entry (*entries)[] = contents + header->entrysection_start - header->contents_start;
    
    //Set up string blocks
    u32 block_size = *(u32*)string_section_next;
    void *extensions_block = string_section_next + sizeof(u32)  + (0x2000*block_size*sizeof(u8));
    void **blocks = malloc(block_size * sizeof(void*));
    for(int i = 0; i < block_size; i++)
    {
        blocks[i] = string_section_next + sizeof(u32) + (0x2000*i*sizeof(u8));
    }
    
    //Set up file extensions
    char **extensions = malloc(*(u32*)extensions_block * sizeof(char*));
    for(int i = 0; i < *(u32*)extensions_block; i++)
    {
        u32 offs = *(u32*)(extensions_block + sizeof(u32) + i*sizeof(u32));
        char *string = blocks[offs / 0x2000] + (offs & 0x1FFF);
        extensions[i] = string;
    }
    
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
                    dumb_wcstombs(file, dirs[i]+sizeof("sd:/saltysd/smash/")-1);
                    dumb_strcat(file, "/");
                    dumb_wcstombs(file+strlen(file), dir_entry->path);
                    
                    files[num_files] = file;
                    num_files++;
                }
            }
        }
        
        free(dirs[i]);
    }
    
    free(dirs);
    free(dir_entries);
    
    char *full_name = malloc(0x400);
    memclr(full_name, 0x400);
    void *ifile_handle = malloc(0x40);
    for(int i = 0; i < header->resourceentry_amt; i++)
    {
        u32 string_offset_all = (*entries)[i].string_offs;
        u32 string_offset = string_offset_all & 0x000FFFFF;
        u8 extension = (string_offset_all >> 24);
        
        u8 nesting_level = (*entries)[i].flags & 0xFF;
        if(nesting_level <= 1)
            full_name[0] = 0;
            
        u8 levels = 1;
        for(int i = 0; i < 0x101; i++)
        {
            if(full_name[i] == 0x0) break;
            
            if(full_name[i] == '/')
                levels++;
                
            if(levels >= nesting_level)
            {
                full_name[i+1] = 0x0;
                break;
            }
        }
        
        char *string = blocks[string_offset / 0x2000] + (string_offset & 0x1FFF);
        
        if(string_offset_all & 0x00800000)
        {
            u16 reference = *(u16*)string;
            u32 ref_len = (reference & 0x1f) + 4;
            u32 ref_reloff = (reference & 0xe0) >> 6 << 8 | (reference >> 8);
            u32 final_offset = string_offset - ref_reloff;
            char *ref_string = blocks[final_offset / 0x2000] + (final_offset & 0x1FFF);
            
            dumb_strncat(full_name, ref_string, ref_len);
            dumb_strcat(full_name, string+sizeof(u16));
        }
        else
            dumb_strcat(full_name, string);
            
        dumb_strcat(full_name, extensions[extension]);
        
        //If we have a file, adjust file sizes
        if(full_name[strlen(full_name)-1] != '/')
        {
            for(int j = 0; j < num_files; j++)
            {
                if(files[j] == NULL)
                    continue;
                    
                if(!strcmp(full_name, files[j]))
                {
                    free(files[j]);
                    files[j] = NULL;
                    
                    IFile_Init(ifile_handle);
                    crit_init(crit_this());
                    mount_sdmc("sd:");
                
                    char *sd_path = malloc(0x101);
                    memclr(sd_path, 0x101);
                    
                    dumb_strcat(sd_path, "sd:/saltysd/smash/");
                    dumb_strcat(sd_path, full_name);
                    
                    if(IFile_Open(ifile_handle, sd_path, 1))
                    {
                        u32 size = IFile_GetSize(ifile_handle);

                        //By overriding the compressed size, our files are forced into only one hook
                        (*entries)[i].comp_size = size;
                        (*entries)[i].decomp_size = size;
                    }
                    IFile_Close(ifile_handle);
                    free(sd_path);
                }
            }
        }
    }
    
    //TODO: New Files!
    for(int i = 0; i < num_files; i++)
    {
        //Free all of our filenames not in RF
        if(files[i] != NULL)
            free(files[i]);
    }
    
    free(ifile_handle);
    free(full_name);
    free(files);
    free(extensions);
    free(blocks);
    unmount_path("sd");
    
    return;
}
