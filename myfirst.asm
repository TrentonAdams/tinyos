BITS 16

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax


	mov si, text_string	; Put string position into SI
	call print_string	; Call our string-printing routine
	call read_first_byte  ; read first byte of disk.
	call read_keys
	jmp $


read_first_byte:
  push ax
  push bx 
  push cx
  push dx
  mov ah, 0         ; reset disk
  mov dl, 80h       ; drive 0
  int 13h
  jnz disk_fail     ; return, we're a failure
  mov ax, 0201h     ; int 13h 02 = read disk  and 01 = sectors to read
  mov cx, 0002h     ; first track second sector - one past boot
  mov dx, 0080h     ; 00 = head number + 80 = first drive
  mov bx, 512      ; place in memory 512 bytes past where the MBR is loaded.
  int 13h

;;  mov ds, es
  mov si, 512       ; prep lodsb
  lodsb             ; load the first byte of the disk sector read - sector 2
	and ax, 000fh      ; just clear the top of the byte
	mov bx, ax        ; move byte read into base register
	mov ax, 2         ; multiply by 2
	mul bx
	add bx, hex_ascii ;
  mov si, bx
  call print_string

disk_fail:
  pop dx
  pop cx
  pop bx 
  pop ax
  ret

read_keys:
  mov ah, 01h       ; detect key
  int 16h
  jnz print_key     ; only print if key in buffer
	jmp read_keys			; Jump to read_keys - infinite loop!

print_key:
  mov ah, 0         ; 16h read key function
  int 16h           ; al now has character from keyboard
  mov ah, 0Eh       ; TTY output, ah had scan code, we discard
  int 10h           ; prints character in ah
  jmp read_keys

print_string:			; Routine: output string in SI to screen
  push ax
	mov ah, 0Eh		; int 10h 'print char' function

.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h			; Otherwise, print it
	jmp .repeat

.done:
  pop ax
	ret

	text_string db 'This is my cool new OS!', 0
	hex_ascii db '0',0
	db '1',0
	db '2',0
	db '3',0
	db '4',0
	db '5',0
	db '6',0
	db '7',0
	db '8',0
	db '9',0
	db 'A',0
	db 'B',0
	db 'C',0
	db 'D',0
	db 'E',0
	db 'F',0

	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
