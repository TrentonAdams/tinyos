# vi: set noexpandtab:
all: kernel.bin

# macro defining that we want EXTRAs.  In the case of a bootloader, we
# may want to strip things down a bit.
EXTRA =-d EXTRA

drive.bin:
	dd if=/dev/zero of=drive.bin bs=1M count=3
	mkfs.msdos -R 10 drive.bin ; 
boot.bin:  boot.asm drive.bin
	nasm ${EXTRA} -f elf -g -o boot.elf boot.asm
	objcopy -O binary boot.elf boot.bin
	dd status=noxfer conv=notrunc if=boot.bin of=drive.bin bs=1 count=450 skip=62 seek=62; 

# straight up kernel bootstrapping from within the boot.asm
bootstrap.bin: boot.bin
	od -x -Ax -N 512 drive.bin

# separate kernel.asm
kernel.bin: boot.bin
	nasm ${EXTRA} -f elf -g -o kernel.elf kernel.asm
	objcopy -O binary kernel.elf kernel.bin
	dd status=noxfer conv=notrunc if=kernel.bin of=drive.bin seek=2 bs=512
	od -x -Ax -N 512 drive.bin

nokernel:   bootstrap.bin
#	qemu-system-x86_64 -hdachs 40,15,17 -hda boot.bin
	qemu-system-x86_64 -hda drive.bin

kernel:	kernel.bin
	qemu-system-x86_64 -hda drive.bin

clean:
	rm -rf *.bin *.elf

