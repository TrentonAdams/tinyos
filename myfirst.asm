BITS 16

%macro print 1
  pusha
	mov si, %1	        ; Put string position into SI
	call print_string	    ; Call our string-printing routine
	popa
%endmacro

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax      ; data segment source
	mov es, ax      ; extra se

	mov [boot_drive], dl  ; store the boot drive in the one byte buffer
	call read_disk_stats

  print boot_msg
  print crlf
  
	call read_first_byte  ; read first byte of disk.
	call read_keys
	jmp $

read_disk_stats:
  pusha
  ;;print stats
;;  xor ax, ax
;;  xor dx, dx
  mov ah, 8
  mov dl, [boot_drive]
  int 13h
  jz ds_rf
  print stats_complete

  mov di, buffer
  mov ax, 0x7830             ; store ascii '0x' at the buffer
  stosw
  mov al, bl
  call stor_hex
  mov al, 0x20               ; space
  stosb
  
  mov ax, 0x7830             ; store ascii '0x' at the buffer
  stosw
  mov al, ch
  call stor_hex
  mov al, 0x20                ; space
  stosb

  mov ax, 0x7830             ; store ascii '0x' at the buffer
  stosw
  mov al, cl
  call stor_hex
  mov al, 0x20                ; space
  stosb

  mov ax, 0x7830             ; store ascii '0x' at the buffer
  stosw
  mov al, dh
  and al, 0x0f
  call stor_hex
  mov al, 0x20                ; space
  stosb

  mov ax, 0x7830             ; store ascii '0x' at the buffer
  stosw
  mov al, dl
  call stor_hex
  mov al, 0x20                ; space
  stosb

  mov al, 0x00
  stosb
  print buffer
  print crlf
  jmp ds_done
ds_rf:
  call int13_show_error
ds_done:
  popa
  ret

read_first_byte:
  pusha
  mov ah, 0         ; reset disk
  mov dl, [boot_drive]       ; drive 0
  int 13h
  jz reset_fail      ; return, we're a failure
  jmp reset_success
reset_fail:
  call int13_show_error
  jmp disk_return
reset_success:
  mov ax, 0x0201     ; int 13h 02 = read disk  and 01 = sectors to read
  mov cx, 0x0002     ; first track second sector - one past boot
  mov dx, 0x0080     ; 00 = head number + 80 = first drive
  mov bx, 512        ; place in memory 512 bytes past where the MBR is loaded.
  int 0x13
  jz rs_fail
rs_fail:
  call int13_show_error
  jmp disk_return

;;  mov ds, es
;;  mov si, 512       ; prep lodsb
;;  lodsb             ; load the first byte of the disk sector read - sector 2
  jmp disk_return

int13_show_error:
  pusha
  push ax
  print int13_call_fail
  print int13_read_status
  pop ax
  cld

  mov di, buffer

  push ax
  mov ax, 0x7830             ; store ascii '0x' at the buffer
  stosw
  pop ax

  xchg al, ah
  call stor_hex              ; al already setup by int13, store in buffer
  xchg al, ah
  call stor_hex              ; store ah in buffer
  mov al, 0                  ; end string with null 0x00
  stosb
  print buffer
  
  print crlf
  popa
  ret

disk_fail:

disk_return:
  popa
  ret


stor_hex:
;; al = nibble to convert to 2 bytes of hex  e.g. 0x2D would now be a two
;; byte '2D' string, without a null byte.
;; es:di = your buffer
;; return: es:di = end of your buffer (i.e. next byte)
  pusha
;; make hex display callable/reusable
  mov bx, hex_ascii           ; lookup table
	mov ah, al                  ; copy high nibble
	shr ah, 4                   ;     to ah
	and al, 0x0f                ; mask off low nibble in al
	and ah, 0x0f                ; mask off high nibble in ah
	xlat                        ; lookup low nibble in table pointed to by bx.
	xchg al, ah                 ; swap the high/low nibble
	xlat                        ; lookup high nibble in table pointed to by bx.
	stosw                       ; store ax (ascii hex of AL) in the buffer
	mov [reg_16],di             ; save di for the pop

	popa
	mov di, [reg_16]            ; restore di for return
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

	boot_msg db 'Bootstrapping is sexy...', 0
	int13_call_fail db 'Disk failure!',0x0a,0x0d, 0
	int13_read_status db 'Call status: ', 0
	stats_complete db 'Boot drive found', 0x0a, 0x0d,0
	stats db 'read stats', 0x0a, 0x0d,0
	crlf db 0x0a,0x0d,0

 	reg_16 db 0x0000   ; temporary 16 bit storage for a register

	boot_drive db 0x00
	cyls db 0x00
	heads db 0x00
	sectors db 0x00

	; hex to ascii table
	hex_ascii db '0123456789ABCDEF',0

	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature

buffer: