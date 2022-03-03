CPP_SOURCES=$(wildcard kernel/*.cpp)
ASM_SOURCES=$(wildcard kernel/*.asm)
BOOT_SOURCES=$(wildcard boot/boot1/*.asm boot/boot2/*.asm)
CPP_OBJS=${CPP_SOURCES:.cpp=.o}
ASM_OBJS=${ASM_SOURCES:.asm=.oa}
BUILD=build
%.o: %.cpp
	@echo "Compiling $<..."
	$(COMPILER) -c $< $(COMPILER_FLAGS) -o $@
%.oa: %.asm
	@echo "Assembling $<..."
	$(ASSEMBLER) $< $(ASSEMBLER_FLAGS_ELF) -o $@

COMPILER=x86_64-elf-gcc
LINKER=x86_64-elf-ld
ASSEMBLER=nasm
ASSEMBLER_FLAGS_BIN=-f bin
ASSEMBLER_FLAGS_ELF=-f elf64
COMPILER_FLAGS=-ffreestanding -mno-red-zone
LINKER_FLAGS=-T$(LINKER_FILE)
LINKER_FILE=target/linker.ld
OBJCOPY=objcopy
OBJCOPY_FLAGS=--format binary
COPIER=cat
OS-IMAGE=deltaos-amd64.osi

.PHONY: buildenv
buildenv:
	mkdir boot/ ; mkdir boot/boot1/ ; mkdir boot/boot2
	mkdir kernel/
	mkdir target/
	mkdir build/
	cd boot/boot1 ; wget https://raw.githubusercontent.com/IHaydot/DeltaOSres/master/boot/boot1/boot1.asm 
	cd boot/boot2 ; wget https://raw.githubusercontent.com/IHaydot/DeltaOSres/master/boot/boot2/boot2.asm
	cd target/ ; wget https://raw.githubusercontent.com/IHaydot/DeltaOSres/master/target/linker.ld
	cd kernel/ ; wget https://raw.githubusercontent.com/IHaydot/DeltaOSres/master/kernel/kernel.cpp

.PHONY: build
build: $(ASM_OBJS) $(CPP_OBJS) $(BOOT_SOURCES)
	@echo "Assembling boot/boot1/boot1.asm..."
	$(ASSEMBLER) boot/boot1/boot1.asm $(ASSEMBLER_FLAGS_BIN) -o $(BUILD)/boot1.bin
	@echo "Assembling boot/boot2/boot2.asm..."
	$(ASSEMBLER) boot/boot2/boot2.asm $(ASSEMBLER_FLAGS_ELF) -o $(BUILD)/boot2.o
	@echo "Linking the kernel with the bootloader..."
	$(LINKER) $(LINKER_FLAGS) $(BUILD)/boot2.o $(ASM_OBJS) $(CPP_OBJS) 
	@echo "Copying to binary..."
	$(OBJCOPY) $(OBJCOPY_FLAGS) $(BUILD)/kernel.tmp $(BUILD)/kernel.bin
	@echo "Linking stage 1 of the boot process with the kernel..."
	$(COPIER) $(BUILD)/boot1.bin $(BUILD)/kernel.bin > $(OS-IMAGE)
	make clean
run: build
	@echo "Running the os in qemu..."
	qemu-system-x86_64 -drive format=raw,file=$(OS-IMAGE) -d cpu_reset -D qemu-logs

DOCKER_IMAGE=deltaos-buildenv

buildenv_docker:
	sudo docker build buildenv -t $(DOCKER_IMAGE)
run_docker:
	sudo docker run --rm -it -v $(pwd):/root/env $(DOCKER_IMAGE)

.PHONY: clean
clean:
	rm -rf $(BUILD)/*
	rm -rf $(CPP_OBJS)
	rm -rf $(ASM_OBJS)
	


