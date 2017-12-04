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
	@cd resource_mod && $(MAKE)
	@$(AS) "resource_mod/hookresource.asm"
	@$(OBJCOPY) -O binary a.out "bin/hookresource.bin"
	@rm a.out
	@$(AS) "resource_mod/incalloc.asm"
	@$(OBJCOPY) -O binary a.out "bin/incalloc.bin"
	@rm a.out
	@$(AS) "hookthread.asm"
	@$(OBJCOPY) -O binary a.out "bin/hookthread.bin"
	@rm a.out
	@$(AS) "hooknorm.asm"
	@$(OBJCOPY) -O binary a.out "bin/hooknorm.bin"
	@rm a.out
	@$(AS) "threadload.asm"
	@$(OBJCOPY) -O binary a.out "bin/threadload.bin"
	@rm a.out
	@$(AS) "normload.asm"
	@$(OBJCOPY) -O binary a.out "bin/normload.bin"
	@rm a.out
	@$(AS) "sdsound.asm"
	@$(OBJCOPY) -O binary a.out "bin/sdsound.bin"
	@rm a.out
	@python patch.py code.bin
	@armips cro_redir.asm
