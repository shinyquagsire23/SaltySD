### Smash dt/ls SD Redirect

These edits redirect the romfs:/dt and romfs:/ls files to load straight from sdmc:/saltysd/smash, allowing for modifications on any file without the need to repack or alter existing archives. SD loaded files take first priority, with update files next followed by the original content. Current hooks and payloads are adjusted for Sm4sh 1.1.4, however it may be automated or ported to different versions in the future. All addresses in the patching instructions are 3DS virtual addresses, if you are creating a modified update CIA or HANS codebin you must make sure your code.bin is decompressed and adjust the addresses 0x100000 lower (ie 0x13F4B8 becomes 0x3F4B8 in the code.bin) when editing.

**Patching Instructions**

 * Build the hooks and payloads with the Makefile provided. 
 * Place the assembled lib::Resource::data_size hook (hookdatasize.bin) at 0x16F0D0, and the payload (datasize.bin) at 0xA3C800. 
 * The assembled lib::Resource::lock hook (hooklock.bin) must be placed at 0x181708, with the payload (lock.bin) at 0xA3B800. 
 * Place the assembled lib::Resource::is_exist hook (hookexist.bin) at 0x159EBC, with the payload (exist.bin) at 0xA3E800.  
 * Write PUSH {R4-R6,LR} (70 40 2D E9) to 0x159EB8 and POP {R4-R6,PC} (70 80 BD E8) to 0x159F10 for the lib::Resource::is_exist hook.
 * lib::Resource::load must nullsub'd by writing bx lr (1E FF 2F E1) at 0x13F4B8, and lib::Resource::is_loaded must always return 1 (01 00 A0 E3 1E FF 2F E1) at 0x140DC0.
 * To patch BGM sound to load from SD, write sdsound.bin to 0xA3D800, and then write 0xA3D800 to 0x7BC0EC (00 D8 A3 00) and 0xB769BF to 0x7BC108 (BF 69 B7 00). BGM sounds will then be able to be loaded from sdmc:/saltysd/smash/sound/bgm/.
 
**Caching**

Caching allows the game to know exactly which files are to be overriden on the SD card. Currently, a CRC cache must be created on a PC through the cachegen.py script as follows:
```
python2 cachegen.py /path/to/sdmc/saltysd/smash/
```
A cache.bin file will then be placed at /path/to/sdmc/saltysd/smash/cache.bin, containing the number of files and a CRC32 hash of every file to be overridden. This allows the hook overrides a quick method to test the need to override a file.

If a cache.bin file is *not* generated, the payloads will fall back to checking every recieved Resource for it's existence in the SD override directory, reducing performance.

**Notes**

 * Without creating a cache.bin, loading screens and character selection will be laggy due to constantly opening files to check for existence.
 * Loading screens sometimes will not have the loading Smash ball and will just be black.
