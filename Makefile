# vi: set noexpandtab:
all: hello.bin

myfirst.bin:  myfirst.asm
	nasm -f bin -o myfirst.bin myfirst.asm

myfirst.flp:	myfirst.bin
	dd if=/dev/zero of=myfirst.flp bs=512 count=10000
	dd status=noxfer conv=notrunc if=myfirst.bin of=myfirst.flp

kernel.bin: myfirst.flp
# ultimately want to use C
#	gcc hello.c -o hello
#	objcopy -O binary ./hello hello.bin
	nasm -f bin -o kernel.bin kernel.asm
#	dd status=noxfer conv=notrunc if=kernel.bin of=myfirst.flp seek=1 bs=512
	od -x -Ax myfirst.flp
#	dd status=noxfer conv=notrunc if=hello.bin of=myfirst.flp seek=1 bs=512

test:   kernel.bin
#	qemu-system-x86_64 -hdachs 40,15,17 -hda myfirst.flp
	qemu-system-x86_64 -hda myfirst.flp

clean:
	rm -rf myfirst.flp myfirst.bin kernel kernel.bin

