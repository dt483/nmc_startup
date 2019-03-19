#!/bin/bash -e

#env NEURO must be set to NeuroMatrix sdk 
# 
#Build dir:
BUILDDIR=./Debug/

# --- Defining build tools ---
# nm c/cpp compiler
NMCPP  = $(NEURO)/bin/nmcpp
# nm assembler		
ASM    = $(NEURO)/bin/asm
# nm linker		
LINKER = $(NEURO)/bin/linker
# nm exec file decoder 
NMDUMP = $(NEURO)/bin/nmdump


# --- COMPILER SETTINGS ---
# --- Defining include pathes ---
#NM_=$(NEURO)/
#NM_inc=$(NEURO)/include/
#LLS_inc=$(NEURO)/lowlevel_sync/include/
#DSPPU_inc=$(NEURO)/DSPPU/include/
#PU_inc=$(NEURO)/PU/include/
#FFT_inc=$(NEURO)/nmfft/libfft/include/
#NMPP_inc=$(NEURO)/NMPP1/include/
## add additional include pathes here ***
#INCLUDE_PATH = -I$(NM_) -I$(NM_inc) -I$(LLS_inc) -I$(DSPPU_inc) -I$(PU_inc) -I$(FFT_inc) -I$(NMPP_inc)

OPT_LEVEL = 2 #optimization level (0-2)

# --- LINKER SETTINGS ---
# --- Defining library pathes ---
#NM_libc_lib=$(NEURO)/lib/libc05.lib
#NM_libint_lib=$(NEURO)/lib/libint_soc.lib
#LLS_lib=$(NEURO)/lowlevel_sync/lib/liblls.lib
#DSPPU_lib=$(NEURO)/DSPPU/lib/DSPPU.lib
#PU_lib=$(NEURO)/PU/lib/PU.lib
#FFT_lib=$(NEURO)/nmfft/libfft/lib/fft_soc.lib
#NMPP_lib=$(NEURO)/NMPP1/lib/nmpp_nmc3.lib
## add additional library pathes here ***
#LIBS=  $(NM_libc_lib) $(NM_libint_lib) $(LLS_lib) $(DSPPU_lib) $(PU_lib) $(FFT_lib) $(NMPP_lib)


LINKER_CONFIG= mc7601_init.cfg
HEAP_SETTINGS= #-heap=0xC000 -heap1=0xC000


DIRS=$(sort $(dir $(wildcard ./*/)))
CPP_SOURCES= $(foreach dir,$(DIRS),$(wildcard $(dir)*.cpp))
ASM_SOURCES=$(foreach dir,$(DIRS),$(wildcard $(dir)*.asm) )
		 
ELFS=$(CPP_SOURCES:.cpp=.elf) $(ASM_SOURCES:.asm=.elf)
EXECUTABLE=$(BUILDDIR)initnmc_mini.abs
DUMP=$(BUILDDIR)initnmc_mini_abs.dump
HEADER=$(BUILDDIR)initnmc_mini_abs.h
HEXDUMP=$(BUILDDIR)initnmc_mini_abs_dump.hex
MAP=$(BUILDDIR)initnmc_mini_abs.map

all: echo1 $(EXECUTABLE) $(DUMP)  $(HEADER) $(HEXDUMP) clean_elf

echo1: #for Makefile debug
	@echo " ------------------------------------------------------------- "
	@echo "-- Found directories: $(DIRS)                                  "
	@echo "-- Found cpp sources: $(CPP_SOURCES)                          "
	@echo "-- Found asm sources: $(ASM_SOURCES)                           "
	@echo " ------------------------------------------------------------- "
	@echo "-- Building object: $(EXECUTABLE) from Intermediate ELF's:     "
	@echo "		{ $(ELFS) } with config $(LINKER_CONFIG)                  "
	@echo " ------------------------------------------------------------- "
	
	

$(EXECUTABLE):$(ELFS)
	@echo "*** Linking to $@ ***"
	$(LINKER) -o$@ $(ELFS) $(LIBS) -c$(LINKER_CONFIG) $(HEAP_SETTINGS)	-m$(MAP)
		
%.elf: %.asm
	@echo "*** Building object $@ ***"
	$(ASM) -soc $< -o$@	
				
%.asm: %.cpp
	@echo "*** Compiling $@ ****"
	$(NMCPP) $< -O$@ -6405 -OPT$(OPT_LEVEL) $(INCLUDE_PATH)

$(DUMP): $(EXECUTABLE)
	@echo "*** Creating dump to $@ ***"
	$(NMDUMP) $< > $@ 

$(HEADER): $(EXECUTABLE)
	@echo "*** Creating c-header to $@ ***"
	xxd -i $< > $@
	
clean_elf:
	@echo "*** Clean intermediate ELF's ***"
	$(foreach dir,$(DIRS),rm -f $(dir)*.elf);
	
$(HEXDUMP): $(EXECUTABLE)
	@echo "*** Creating hex dump to $@ ***"
	xxd $< > $@

#.PHONY: clean
clean: 
	@echo "*** Cleaning $(BUILDDIR) folder ***"
	rm $(BUILDDIR)* -f; 
	




