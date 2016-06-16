#include <3ds.h>
#include <stdarg.h>
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
static int (*vsnprintf)(char * s, size_t n, const char * format, va_list arg ) = (void*)vsnprintf_ADDR;

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

char *dumb_strcpy(char *dest, char *src)
{
    dest[0] = 0;
    return dumb_strcat(dest, src);
}

char *dumb_strncpy(char *dest, char *src, size_t len)
{
    dest[0] = 0;
    return dumb_strncat(dest, src, len);
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

u32 len_to(char *str, char chr)
{
    u32 count = 0;
    while(1)
    {
        if(str[count] == 0)
            return -1;
         
        if(str[count++] == chr)
            break;
    }
    return count;
}

u32 count_chars(char *str, char chr)
{
    u32 i = 0;
    u32 count = 0;
    while(1)
    {
        if(str[i] == 0)
            break;
         
        if(str[i++] == chr)
            count++;
    }
    return count;
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
                    dumb_wcscat(new_dir, (u16*)L"/");
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
                    //printf("List: %s", file);
                    
                    files[num_files] = file;
                    file_sizes[num_files] = dir_entry->file_size & 0xFFFFFFFF;
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
    u32 last_str_addr = 0;
    for(int i = 0; i < header->resourceentry_amt; i++)
    {
        u32 string_offset_all = (*entries)[i].string_offs;
        u32 string_offset = string_offset_all & 0x000FFFFF;
        u8 extension = (string_offset_all >> 24);
        
        if(string_offset > last_str_addr)
            last_str_addr = string_offset;
        
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
                    
                    //By overriding the compressed size, our files are forced into only one hook
                    (*entries)[i].comp_size = file_sizes[j];
                    (*entries)[i].decomp_size = file_sizes[j];
                }
            }
        }
    }
    
    //Add new files to RF
    last_str_addr = ((*entries)[header->resourceentry_amt-1].string_offs & 0xFFFFF) + 0x80;
    for(int i = 0; i < num_files; i++)
    {
        if(files[i] == NULL)
            continue;
        
        printf("Adding file %s", files[i]);
        
        u32 entry_to_shift = 1; 
        u8 entered_packed = 0;
        u8 level_target = 1;
        char *substr = malloc(0x101);
        
        u32 seed_len = len_to(files[i], '/');
        if(seed_len == -1)
        {
            entry_to_shift = header->resourceentry_amt;

            dumb_strcpy(substr, files[i]);
            seed_len = strlen(substr);
        }
        else
            dumb_strncpy(substr, files[i], seed_len);
        
        for(; entry_to_shift < header->resourceentry_amt; entry_to_shift++)
        {
            u8 nesting_level = (*entries)[entry_to_shift].flags & 0xFF;
            
            //We're a file but the next object at the same level is a folder, break here
            if(level_target == nesting_level && len_to(substr, '/') == -1 && (*entries)[entry_to_shift].flags & 0x200)
                break;
            
            //We're a file and the next entry isn't even at the same nesting level, break    
            if(level_target != nesting_level && len_to(substr, '/') == -1)
                break;
            
            //We're a higher folder and we descended a folder, obviously this folder is new
            if(level_target > nesting_level && len_to(substr, '/') != -1)
                break;
            
            //Don't look at deeper folders while trying to find our current level
            if(level_target < nesting_level && len_to(substr, '/') != -1)
                continue;
            
            //We're a folder, pay no mind to the file order since files come before folders
            if(len_to(substr, '/') != -1 && !((*entries)[entry_to_shift].flags & 0x200))
                continue;
        
            u32 string_offset_all = (*entries)[entry_to_shift].string_offs;
            u32 string_offset = string_offset_all & 0x000FFFFF;

            char *string = blocks[string_offset / 0x2000] + (string_offset & 0x1FFF);
            
            if(string_offset_all & 0x00800000)
            {
                u16 reference = *(u16*)string;
                u32 ref_len = (reference & 0x1f) + 4;
                u32 ref_reloff = (reference & 0xe0) >> 6 << 8 | (reference >> 8);
                u32 final_offset = string_offset - ref_reloff;
                char *ref_string = blocks[final_offset / 0x2000] + (final_offset & 0x1FFF);
                
                dumb_strncpy(full_name, ref_string, ref_len);
                dumb_strcat(full_name, string+sizeof(u16));
            }
            else
                dumb_strcpy(full_name, string);         
            
            //Folder is part of our path, advance level target and look for next folder
            //or the spot to place our file    
            if(!strcmp(full_name, substr) && len_to(substr, '/') != -1)
            {
                printf("%x %x %s", entry_to_shift, level_target, full_name);
                u32 len = len_to(files[i]+seed_len, '/');
                if(len != -1)
                {
                    dumb_strncpy(substr, files[i]+seed_len, len);
                    seed_len += len;
                }
                else
                {
                    dumb_strcpy(substr, files[i]+seed_len);
                    seed_len += strlen(substr);
                }
                
                if((*entries)[entry_to_shift].flags & 0x1000)
                {
                    entered_packed = 1;
                    printf("entered packed"); 
                }   
                level_target++;
            }
            else if(strcmp(full_name, substr) > 0 && level_target != 1)
            {
                //Greater alphabetically, break here
                printf("larger %x %x %s", entry_to_shift, level_target, full_name);
                break;
            }
        }
        
        printf("entry comp %x %x %x", &(*entries)[entry_to_shift], &(*entries)[header->resourceentry_amt-1], (u32)&(*entries)[header->resourceentry_amt-1] - (u32)&(*entries)[entry_to_shift]);
        u32 entries_to_make = count_chars(files[i]+seed_len-strlen(substr), '/')+1;
        
        printf("adding %x entries after %x (%s)", entries_to_make, entry_to_shift, files[i]+seed_len-strlen(substr));
        
        if(entry_to_shift != header->resourceentry_amt)
            memmove(&(*entries)[entry_to_shift+entries_to_make], &(*entries)[entry_to_shift], (u32)&(*entries)[header->resourceentry_amt] - (u32)&(*entries)[entry_to_shift]);
            
        memclr(&(*entries)[entry_to_shift], 0x18*entries_to_make);
        
        //Create all our new folders
        for(int j = 0; j < entries_to_make-1; j++)
        {
            //Stay within our blocks
            if((last_str_addr & 0x1FFF) + strlen(substr) >= 0x2000)
                last_str_addr = (last_str_addr + 0x1FFF) & (0xFFFFFFFF - 0x1FFF);
        
            char *new_str = blocks[last_str_addr / 0x2000] + (last_str_addr & 0x1FFF);
            dumb_strcpy(new_str, substr);
            printf("folder: %s", new_str);
        
            (*entries)[entry_to_shift].chunk_offs = (*entries)[entry_to_shift-1].chunk_offs;
            (*entries)[entry_to_shift].string_offs = last_str_addr;
            (*entries)[entry_to_shift].comp_size = 0x80;
            (*entries)[entry_to_shift].decomp_size = 0x80;
            (*entries)[entry_to_shift].timestamp = 0;
            (*entries)[entry_to_shift].flags = 0xA00 | level_target;
            last_str_addr += strlen(substr)+1;
            header->resourceentry_amt++;
            header->entrysection_size += 0x18;
            entry_to_shift++;
            
            printf("%x %x %s", entry_to_shift-1, level_target, substr);
            
            u32 len = len_to(files[i]+seed_len, '/');
            if(len != -1)
            {
                dumb_strncpy(substr, files[i]+seed_len, len);
                seed_len += len;
            }
            else
            {
                dumb_strcpy(substr, files[i]+seed_len);
            }
            level_target++;
        }
        
        u32 len = len_to(substr, '.');
        char *file_ext = malloc(0x10);
        if(len != -1)
        {
            dumb_strcpy(file_ext, &substr[len-1]);
        
            substr[len-1] = 0;
            seed_len += len-1;
        }

        //Find our extension ID
        printf("%x %x %s", entry_to_shift, level_target, substr);
        u8 ext_num = 0;
        
        for(int j = 0; j < *(u32*)extensions_block; j++)
        {
            if(!strcmp(extensions[j], file_ext))
            {
                printf("extnum %x %s", j, extensions[j]);
                ext_num = j;
                break;
            }
        }
        
        //New extension...
        if(ext_num == 0 && len && *(u32*)extensions_block < 0x3E)
        {
            //Stay within our blocks
            if((last_str_addr & 0x1FFF) + strlen(substr) >= 0x2000)
                last_str_addr = (last_str_addr + 0x1FFF) & (0xFFFFFFFF - 0x1FFF);
                
            char *new_str = blocks[last_str_addr / 0x2000] + (last_str_addr & 0x1FFF);
            dumb_strcpy(new_str, file_ext);
            printf("adding ext %s", new_str);
            
            *(u32*)(extensions_block + sizeof(u32) + *(u32*)extensions_block*sizeof(u32)) = last_str_addr;
            ext_num = *(u32*)extensions_block;
            extensions[*(u32*)extensions_block] = new_str;
            *(u32*)extensions_block += 1;
            
            last_str_addr += strlen(new_str)+1;
        }
        
        free(file_ext);
        
        //Stay within our blocks
        if((last_str_addr & 0x1FFF) + strlen(substr) >= 0x2000)
            last_str_addr = (last_str_addr + 0x1FFF) & (0xFFFFFFFF - 0x1FFF);
        
        char *new_str = blocks[last_str_addr / 0x2000] + (last_str_addr & 0x1FFF);
        dumb_strcpy(new_str, substr);
        
        //Add new file entry
        (*entries)[entry_to_shift].chunk_offs = (*entries)[entry_to_shift-1].chunk_offs;
        (*entries)[entry_to_shift].string_offs = last_str_addr | ext_num << 24;
        (*entries)[entry_to_shift].comp_size = file_sizes[i];
        (*entries)[entry_to_shift].decomp_size = file_sizes[i];
        (*entries)[entry_to_shift].timestamp = 0;
        (*entries)[entry_to_shift].flags = 0xC00 | level_target;
        last_str_addr += strlen(substr)+1;
        header->resourceentry_amt++;
        header->entrysection_size += 0x18;
        
        printf("flags: %x, %s", (*entries)[entry_to_shift].flags, entered_packed ? "entered packed" : "didn't enter packed");
        
        free(files[i]);
    }
    
    free(full_name);
    free(files);
    free(extensions);
    free(blocks);
    unmount_path("sd");
    
    return;
}
