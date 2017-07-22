BITS 16
;; Started with the basic myfirst.asm at
;; http://mikeos.sourceforge.net/write-your-own-os.html

%macro print 1
  pusha
	mov si, %1	        ; Put string position into SI
	call p_print_string	    ; Call our string-printing routine
	popa
%endmacro

%macro print_hex 1
  mov al, %1
  call p_prn_hex
%endmacro

%macro to_hex_buf 1
  mov al, %1
  call p_store_hex
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
	print drive_found
	print_hex [boot_drive]

	jmp start_kernel  ; read first byte of disk.
	hlt

start_kernel:
  mov ah, 0             ; reset disk
  mov dl, [boot_drive]  ; drive 0
  stc
  int 13h
  jc kern_fail      ; return, we're a failure
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
  jc kern_fail

  mov al, 0xB8                ; op code for mov
  cmp al, [stage2]
  jnz bad_kern

  ;print dbg

  mov ax, 0x07e0              ; 0x07e0, the start address for the
  cmp ax, [stage2 + 1]        ; kernel
  jnz bad_kern

  jmp stage2

bad_kern:
  call p_show_first_bytes
  jmp $

kern_fail:
  call p_int13_show_error
  jmp $                         ; super failure, halt.

p_show_first_bytes:
;; Shows the first 3 bytes of the kernel sector for diagnostics purposes.
  pusha
  cld                         ; set direction flag for going forward
  mov di, s_first_byte        ; setup destination index for string scan
  mov al, 0x00                ; looking for null byte
  mov cx, 0x00ff              ; outrageous maximum length to scan for.
  repne scasb

  mov ax, di                  ; position found
  sub ax, s_first_byte        ; subtract original position
  dec ax                      ; string length minus null byte
  ;print_hex al

  mov cx, ax                  ; cx is str length now, so we know how many times
  mov si, s_first_byte        ; to repnz
  mov di, buffer
  repnz movsb

  sw 0x7830                   ; store ascii '0x' at the buffer
  to_hex_buf [stage2]         ; should be BE, the move byte.
  sb 0x20
  sw 0x7830                   ; store ascii '0x' at the buffer
  to_hex_buf [stage2 + 2]
  to_hex_buf [stage2 + 1]
  sb 0x0a
  sb 0x0d
  sb 0x00
  print buffer
  print s_no_kernel

  popa
  ret
  
p_int13_show_error:
  pusha
  mov dl, ah
;  print int13_call_fail
  print int13_read_status
  cld

  mov di, buffer

  sw 0x7830                  ; store ascii '0x' at the buffer
  to_hex_buf dl                  ; al already setup by int13, store in buffer
  sb 0                       ; end string with null 0x00
  print buffer
  print crlf
  
  popa
  ret

p_store_hex:
;; Takes al, and converts it into two byte ascii hex, and stores the results
;; at [di] and [di + 1]
;; 
;; al = byte to convert to 2 bytes of hex  e.g. 0x2D would now be a two
;; byte '2D' string, without a null byte.  
;; 
;; es:di = your buffer
;;
;; return: es:di = end of your buffer (i.e. next byte where you can store 0x00
;; to make it a string).  if al was 0x2D, the buffer will now contain two ascii
;; bytes representing 0x2D as '2D'. If you want it to be a string, store
;; a 0x00 at [di] (stosb 0x00)
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
	stosw                       ; store ax (ascii hex of orig al) in the buffer
	mov [reg_16],di             ; save di for the pop

	popa
	mov di, [reg_16]            ; restore di for return, for continued use
  ret

p_print_string:			; Routine: output string in SI to screen
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

p_prn_hex:
  pusha
  mov di, buf_16
  call p_store_hex
  sw 0x0d0a
  sb 0x00
  print buf_16
  popa
  ret

	int13_call_fail db 'Disk failure!',0x0a,0x0d, 0
	int13_read_status db 'Call status: ', 0
	drive_found db 'Booting... 0x', 0
	crlf db 0x0a,0x0d,0

	s_no_kernel db 'Halting, no kernel 2nd sector?', 0x0a, 0x0d, 0x00
  s_first_byte db 'First byte: ', 0x00

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
