### Pokemon Sun and Moon SD Redirect v1.1

These edits redirect the all files to sd:/saltysd/SunMoon. SD loaded files take first priority, then normal files. Because this patch redirects nn::fs::TryOpenFile, it can also optionally redirect extdata and savedata, although writing has not been tested (but should work). Since files are only redirected in the event of the existence of a file on SD, a savefile can be redirected by placing main at sd:/saltysd/SunMoon/main.

**Patching Instructions**

 * Install armips and any other necessary build tools
 * Obtain a code.bin of either Sun or Moon and place it in the same directory as the Makefile.
 * Build with Makefile provided. The code.bin will be patched to code_saltysd.bin

**Notes**

 * Since these patches are fairly generic, it is most likely feasibly possible to port to other games.
 * Current patches are for Sun and Moon v1.1. For older versions, checkout older commits.
