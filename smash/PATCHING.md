### Smash dt/ls SD Redirect

These edits redirect the romfs:/dt and romfs:/ls files to load straight from sdmc:/saltysd/smash, allowing for modifications on any file without the need to repack or alter existing archives. SD loaded files take first priority, with update files next followed by the original content. All addresses are found automatically based on the code.bin and the payloads adjusted accordingly. If you are creating a modified update CIA or HANS codebin you must make sure your code.bin is decompressed.

**Patching Instructions**

 * Obtain a code.bin of the desired version of Smash to patch and place it in the same directory as the Makefile.
 * Build with Makefile provided. The code.bin will be scanned and patched to code_saltysd.bin
 
**Caching**

Caching is no longer used as of SaltySD 0.9

**Notes**

 * Non-update versions (Demo, 1.0.1) have not been tested with SaltySD and are unlikely to work yet, versions past those but under 1.1.3 may not work, but are more likely to work. In addition to this, the Smash Demo does not have SDMC access in it's exheader, so SaltySD would never work with the Demo without a modified version to grant permissions.
 * New files still are not supported as of SaltySD 0.9, however they will be coming coon.
