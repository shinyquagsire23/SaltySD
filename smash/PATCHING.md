### Smash dt/ls SD Redirect

These edits redirect the romfs:/dt and romfs:/ls files to load straight from sdmc:/saltysd/smash, allowing for modifications on any file without the need to repack or alter existing archives. SD loaded files take first priority, with update files next followed by the original content. Current hooks and payloads are adjusted for Sm4sh 1.1.4, however it may be automated or ported to different versions in the future. All addresses in the patching instructions are 3DS virtual addresses, if you are creating a modified update CIA or HANS codebin you must make sure your code.bin is decompressed.

**Patching Instructions**

 * Obtain a code.bin of the desired version of Smash to patch and place it in the same directory as the Makefile.
 * Build with Makefile provided. The code.bin will be scanned and patched to code_saltysd.bin
 
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
 * Non-update versions (Demo, 1.0.1) have not been tested with SaltySD and are unlikely to work yet, versions past those but under 1.1.3 may not work, but are more likely to work. In addition to this, the Smash Demo does not have SDMC access in it's exheader, so SaltySD would never work with the Demo without a modified version to grant permissions.
