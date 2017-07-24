# vi: set noexpandtab:
all: kernel.bin

boot.bin:  boot.asm
	nasm -f elf -g -o boot.elf boot.asm
	objcopy -O binary boot.elf boot.bin

boot.flp:	boot.bin
	dd if=/dev/zero of=boot.flp bs=512 count=10000
	dd status=noxfer conv=notrunc if=boot.bin of=boot.flp

# straight up kernel bootstrapping from within the boot.asm
bootstrap.bin: boot.flp
	od -x -Ax boot.flp

# separate kernel.asm
kernel.bin: boot.flp
	nasm -f elf -g -o kernel.elf kernel.asm
	objcopy -O binary kernel.elf kernel.bin
	dd status=noxfer conv=notrunc if=kernel.bin of=boot.flp seek=1 bs=512
	od -x -Ax boot.flp

nokernel:   bootstrap.bin
#	qemu-system-x86_64 -hdachs 40,15,17 -hda boot.flp
	qemu-system-x86_64 -hda boot.flp

kernel:	kernel.bin
	qemu-system-x86_64 -hda boot.flp

clean:
	rm -rf boot.flp boot.bin kernel kernel.bin

