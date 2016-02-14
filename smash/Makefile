#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

include $(DEVKITARM)/ds_rules
export LD	:=	$(CC)

.PHONY: assemble all clean

all: 
	@mkdir -p bin
	@python scan.py code.bin
	@$(AS) "hooklock.asm"
	@$(OBJCOPY) -O binary a.out "bin/hooklock.bin"
	@rm a.out
	@$(AS) "hookdatasize.asm"
	@$(OBJCOPY) -O binary a.out "bin/hookdatasize.bin"
	@rm a.out
	@$(AS) "hookexist.asm"
	@$(OBJCOPY) -O binary a.out "bin/hookexist.bin"
	@rm a.out
	@$(AS) "lock.asm"
	@$(OBJCOPY) -O binary a.out "bin/lock.bin"
	@rm a.out
	@$(AS) "datasize.asm"
	@$(OBJCOPY) -O binary a.out "bin/datasize.bin"
	@rm a.out
	@$(AS) "exist.asm"
	@$(OBJCOPY) -O binary a.out "bin/exist.bin"
	@rm a.out
	@$(AS) "sdsound.asm"
	@$(OBJCOPY) -O binary a.out "bin/sdsound.bin"
	@rm a.out
	@python patch.py code.bin
