### Pokemon Ultra Sun and Moon SD Redirect v1.0

These edits redirect the all files to sd:/saltysd/UltraSunMoon. SD loaded files take first priority, then normal files. Because this patch redirects nn::fs::TryOpenFile, it can also possibly redirect extdata and savedata with some work.

**Patching Instructions**

 * Install armips and any other necessary build tools
 * Obtain a code.bin of either Sun or Moon and place it in the same directory as the Makefile.
 * Build with Makefile provided. The code.bin will be patched to code_saltysd.bin

**Notes**

 * Since these patches are fairly generic, it is most likely feasibly possible to port to other games.
 * Current patches are for Ultra Sun and Moon v1.0. For older versions, checkout older commits.
