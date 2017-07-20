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

	mov [boot_drive], dl  ; store the boot drive in the one byte buffer

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
  mov dl, boot_drive       ; drive 0
  int 13h
  jz reset_fail      ; return, we're a failure
  jmp reset_success
reset_fail:
  jmp read_fail
reset_success:
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
  ; make subroutine to handle all int 13h failures
  ;
  push ax
  print int13_read_fail
  pop ax
  print int13_read_status

  mov bx, hex_ascii           ; lookup table
  mov dl, ah                  ; store int13 status for later (high byte of ax)
	mov ah, al                  ; copy high nibble to ah
	shr ah, 4                   ; same
	and al, 0x0f                ; mask off high nibble in al
	xlat                        ; lookup low nibble in table pointed to by bx.
	xchg al, ah                 ; swap the high/low nibble
	xlat                        ; lookup high nibble in table pointed to by bx.
	xchg al, ah                 ; swap ascii representations back to proper pos
	lea bx, [gsb]               ; general status buffer
	mov [bx+2], ax                ; store ax (ascii hex of AX) in the buffer
	mov ax, 0x0000              ; null bytes
	mov [bx + 4],ax             ;     for end of string
	mov ax, '0x'                ; prefix entire
	mov [bx],ax                 ;     string with 0x
	print gsb                   ; print gsb string
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

	text_string db 'Bootstrapping is sexy...', 0
	int13_read_fail db 'Disk read failure!',0x0a,0x0d, 0
	int13_read_status db 'Read status: ', 0
	crlf db 0x0a,0x0d,0

	boot_drive db 0x00

	; general status buffer
	gsb times 64 db 0

	; hex to ascii table
	hex_ascii db '0123456789ABCDEF',0

	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
