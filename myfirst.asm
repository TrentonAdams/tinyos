BITS 16

%macro print 1
  pusha
	mov si, %1	        ; Put string position into SI
	call print_string	    ; Call our string-printing routine
	popa
%endmacro

%macro print_hex 1
; should be for debugging only, as it uses a fair amount of extra space
; for printing a single byte.
  push di
  push si
  mov di, buf_16
  mov al, %1
  call stor_hex
  sw 0x0d0a
  sb 0x00
  print buf_16
  pop si
  pop di
%endmacro

%macro to_hex 1
  mov al, %1
  call stor_hex
%endmacro

%macro sb 1
  mov al, %1
  stosb
%endmacro

%macro sw 1
  mov ax, %1
  stosw
%endmacro

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax      ; data segment source used with ds:si
	mov es, ax      ; extra segment for es:di

	mov [boot_drive], dl  ; store the boot drive in the one byte buffer
;	print_hex [boot_drive]

	call read_disk_stats

  print boot_msg
  print crlf

	call read_first_byte  ; read first byte of disk.
	hlt

read_disk_stats:
  pusha
  ;;print stats
;  print dbg
;;  print_hex [boot_drive]
  mov ah, 8
;  mov dl, [boot_drive]
  stc
  int 13h
  jz ds_rf
  print stats_complete

  mov di, buf_16              ; store results of int 13h f8 (ah = 08)
  sb bl
  xchg cl,ch                  ; store them in sequence, not little endian
  xchg dl,dh
  sw cx
  sw dx

  mov cx, 5                   ; loop length
  mov si, buf_16              ; int 13h results at buf_16, convert to ascii hex
  mov di, buffer              ; and store in buffer
results:
  lodsb
  call stor_hex
  sb 0x20
  loop results                ; <-- decrement cx and loop if cx not 0

  sb 0x00                     ; terminate string
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
  mov dl, 0x80       ; drive 0
  stc
  int 13h
  jc reset_fail      ; return, we're a failure
;  print dbg
  jmp reset_success
reset_fail:
  call int13_show_error
  jmp disk_return
reset_success:
  mov bx, stage2        ; place in memory 512 bytes past where the MBR is loaded.
  mov ah, 0x02 ; function
  mov al, 0x01 ; sectors to read
  mov ch, 0x00 ; track/cyl
  mov cl, 0x02 ; sector start
  mov dh, 0x00 ; head
  mov dl, [boot_drive] ; drive
  stc
  int 13h
  jc rs_fail

  print_hex [stage2]
  print_hex [stage2 + 1]
  jmp stage2
  ;jmp disk_return
rs_fail:
  call int13_show_error

;;  mov ds, es
;;  mov si, 512       ; prep lodsb
;;  lodsb             ; load the first byte of the disk sector read - sector 2
disk_return:
  popa
  ret

int13_show_error:
  pusha
  mov dl, ah
;  print int13_call_fail
  print int13_read_status
  cld

  mov di, buffer

  sw 0x7830                  ; store ascii '0x' at the buffer
  to_hex dl                  ; al already setup by int13, store in buffer
  sb 0                       ; end string with null 0x00
  print buffer
  print crlf
  
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

print_key:
  mov ah, 0         ; 16h read key function
  int 16h           ; al now has character from keyboard
  mov ah, 0Eh       ; TTY output, ah had scan code, we discard
  int 10h           ; prints character in ah
  ret


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

	buf_16 times 16 db 0x00

 	reg_16 db 0x00,0x00   ; temporary 16 bit storage for a register
 	
 	dbg db ' --> debug <-- ',0x0a,0x0d,0x00

	boot_drive db 0x00
	cyls db 0x00
	heads db 0x00
	sectors db 0x00

	; hex to ascii table
	hex_ascii db '0123456789ABCDEF',0

	buffer times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature

stage2:
	mov si, text_string	  ; Put string position into SI
	call print_string	    ; Call our string-printing routine
	mov si, crlf	        ; Put string position into SI
	call print_string	    ; Call our string-printing routine
	call read_keys
	jmp $

read_keys:
  mov ah, 01h       ; detect key
  int 16h
  jnz print_key     ; only print if key in buffer
	call read_keys			; Jump to read_keys - infinite loop!

	text_string db 'Kernel loaded!', 0
  buffer2 times 1024-($-$$) db 0

