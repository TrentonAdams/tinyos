BITS 16

%macro print 1
	mov si, %1	        ; Put string position into SI
	call print_string	    ; Call our string-printing routine
%endmacro

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax

  print text_string
  print crlf
  
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
  jnz disk_fail      ; return, we're a failure
  mov ax, 0x0201     ; int 13h 02 = read disk  and 01 = sectors to read
  mov cx, 0x0002     ; first track second sector - one past boot
  mov dx, 0x0080     ; 00 = head number + 80 = first drive
  mov bx, 512        ; place in memory 512 bytes past where the MBR is loaded.
  int 0x13
  jz read_fail

;;  mov ds, es
;;  mov si, 512       ; prep lodsb
;;  lodsb             ; load the first byte of the disk sector read - sector 2
  jmp disk_return

read_fail:
  push ax
  print int13_read_fail
  pop ax
  print int13_read_status

	mov bx, ax
  mov al, [hex_ascii + bx]
  mov ah, 0EH
  int 0x10
  print crlf
  jmp disk_return

disk_fail:

disk_return:
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
	int13_read_fail db 'Disk read failure!',0x0a,0x0d, 0
	int13_read_status db '0x02 read status: ', 0
	crlf db 0x0a,0x0d,0

	; hex to ascii table
	hex_ascii db '0123456789ABCDEF',0

	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
