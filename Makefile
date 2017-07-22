# vi: set noexpandtab:
all: hello.bin

myfirst.bin:  myfirst.asm
	nasm -f elf -g -o myfirst.elf myfirst.asm
	objcopy -O binary myfirst.elf myfirst.bin

myfirst.flp:	myfirst.bin
	dd if=/dev/zero of=myfirst.flp bs=512 count=10000
	dd status=noxfer conv=notrunc if=myfirst.bin of=myfirst.flp

# straight up kernel bootstrapping from within the myfirst.asm
bootstrap.bin: myfirst.flp
	od -x -Ax myfirst.flp

# separate kernel.asm
kernel.bin: myfirst.flp
	nasm -f elf -g -o kernel.elf kernel.asm
	objcopy -O binary kernel.elf kernel.bin
	dd status=noxfer conv=notrunc if=kernel.bin of=myfirst.flp seek=1 bs=512
	od -x -Ax myfirst.flp

test:   bootstrap.bin
#	qemu-system-x86_64 -hdachs 40,15,17 -hda myfirst.flp
	qemu-system-x86_64 -hda myfirst.flp

kernel:	kernel.bin
	qemu-system-x86_64 -hda myfirst.flp

clean:
	rm -rf myfirst.flp myfirst.bin kernel kernel.bin

