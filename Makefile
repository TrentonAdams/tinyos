# vi: set noexpandtab:
all: hello.bin

myfirst.bin:  myfirst.asm
	nasm -f bin -o myfirst.bin myfirst.asm

myfirst.flp:	myfirst.bin
	dd if=/dev/urandom of=myfirst.flp bs=512 count=10000
	dd status=noxfer conv=notrunc if=myfirst.bin of=myfirst.flp

hello.bin:
	gcc hello.c -o hello
	objcopy -O binary ./hello hello.bin
#	dd status=noxfer conv=notrunc if=hello.bin of=myfirst.flp seek=1 bs=512

test:   myfirst.flp hello.bin
	qemu-system-x86_64 -hda myfirst.flp

clean:
	rm -rf myfirst.flp myfirst.bin hello hello.bin

