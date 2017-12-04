### Smash dt/ls SD Redirect v1.2

These edits redirect the romfs:/dt and romfs:/ls files to load straight from sdmc:/saltysd/smash, allowing for modifications and additions of any file without the need to repack or alter existing archives. SD loaded files take first priority, with update files next followed by the original content. All addresses are found automatically based on the code.bin and the payloads adjusted accordingly. If you are creating a modified update CIA or HANS codebin you must make sure your code.bin is decompressed.

**Patching Instructions**

 * Obtain a code.bin of the desired version of Smash to patch and place it in the same directory as the Makefile.
 * Grab the latest armips from [here](https://buildbot.orphis.net/armips/) and make sure it is in this folder or your PATH.
 * Build with Makefile provided. The code.bin will be scanned and patched to code_saltysd.bin

**CRO Override**

 * SaltySD v1.2 has support for loading CROs from the SD card. CROs are stored in the same heirarchy as they are in `rom:/cro.sarc`/`rex:/cro.sarc`, ie `fighter/falco` would be overridden on SD as `sdmc:/saltysd/smash/cro/fighter/falco`.

**Caching**

Caching is no longer used as of SaltySD 0.9

**Notes**

 * Non-update versions (Demo, 1.0.1) have not been tested with SaltySD and are unlikely to work yet, versions past those but under 1.1.3 may not work, but are more likely to work. In addition to this, the Smash Demo does not have SDMC access in it's exheader, so SaltySD would never work with the Demo without a modified version to grant permissions.
 * Creating modified CIAs is not advised, as Citra and Luma CFW both support code.bin override and Luma CFW has support for IPS patching.
