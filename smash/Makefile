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
	@$(AS) "hooklock.asm"
	@$(OBJCOPY) -O binary a.out "hooklock.bin"
	@rm a.out
	@$(AS) "hookdatasize.asm"
	@$(OBJCOPY) -O binary a.out "hookdatasize.bin"
	@rm a.out
	@$(AS) "lock.asm"
	@$(OBJCOPY) -O binary a.out "lock.bin"
	@rm a.out
	@$(AS) "datasize.asm"
	@$(OBJCOPY) -O binary a.out "datasize.bin"
	@rm a.out
	@$(AS) "sdsound.asm"
	@$(OBJCOPY) -O binary a.out "sdsound.bin"
	@rm a.out
