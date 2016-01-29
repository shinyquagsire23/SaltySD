### Smash dt/ls SD Redirect

These edits redirect the romfs:/dt and romfs:/ls files to load straight from sdmc:/saltysd/smash, allowing for modifications on any file without the need to repack or alter existing archives. SD loaded files take first priority, with update files next followed by the original content. Current hooks and payloads are adjusted for Sm4sh 1.1.3, however it may be automated or ported to different versions in the future. All addresses in the patching instructions are 3DS virtual addresses, if you are creating a modified update CIA or HANS codebin you must make sure your code.bin is decompressed and adjust the addresses 0x100000 lower (ie 0x13F4B8 becomes 0x3F4B8 in the code.bin) when editing.

**Patching Instructions**

Build the hooks and payloads with the Makefile provided. Placed the assembled lib::Resource::data_size hook (hookdatasize.bin) at 0x13F4B8, and the payload (datasize.bin) at 0xA1C800. The assembled lib::Resource::lock hook (hooklock.bin) must be placed at 0x1816CC, with the payload (lock.bin) at 0xA1B800. Finally, lib::Resource::load must nullsub'd by writing bx lr (1E FF 2F E1) at 0x13F4B4, and lib::Resource::is_loaded must always return 1 (01 00 A0 E3 1E FF 2F E1) at 0x140DBC.

**Notes**

 * The current payloads do not redirect rom:/sound/bgm or rex:/sound/bgm, this will be added in the future.
 * Loading screens take much longer, due to testing the existence of files on SD. To be fixed, a cached list of all SD overrided files needs to be made and checked. These longer loading screens do not break multiplayer.
 * The character select screen is laggier than normal, due to constantly checking for SD files. The solution to this is the same as above.
 * Loading screens sometimes will not have the loading Smash ball and will just be black.
