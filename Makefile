# vi: set noexpandtab:
all: myfirst.flp

myfirst.bin:  myfirst.asm
	nasm -f bin -o myfirst.bin myfirst.asm

myfirst.flp:	myfirst.bin
	dd status=noxfer conv=notrunc if=myfirst.bin of=myfirst.flp

test:   myfirst.flp
	qemu-system-x86_64 -fda myfirst.flp

clean:
	rm -rf myfirst.flp myfirst.bin

