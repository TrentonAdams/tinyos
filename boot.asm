BITS 16
;; Started with the basic myfirst.asm at
;; http://mikeos.sourceforge.net/write-your-own-os.html

%include "macros.asm"

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax      ; data segment source used with ds:si
	mov es, ax      ; extra segment for es:di

	mov [boot_drive], dl  ; store the boot drive in the one byte buffer
	print s_drive_found
	print_hex [boot_drive]

	jmp start_kernel  ; read first byte of disk.
	hlt

start_kernel:
  mov ah, 0             ; reset disk
  mov dl, [boot_drive]  ; drive 0
  stc
  int 13h
  jc load_fail      ; return, we're a failure
reset_success:
  mov bx, [sector2]       ; place in memory [sector2] bytes past where the MBR is loaded.
  mov ah, 0x02 ; function
  mov al, 0x04 ; sectors to read
  mov ch, 0x00 ; track/cyl
  mov cl, 0x02 ; sector start
  mov dh, 0x00 ; head
  mov dl, [boot_drive] ; drive

  stc
  int 13h
  jc load_fail

  mov al, 0xB8                ; op code for mov, looking good so far
  cmp al, [stage2]
  jnz bad_kern

  ;print s_dbg

  mov dx, [sector2]               ; 2nd sector
  add dx, 0x200                   ; 3rd sector
  shr dx, 4                       ; convert to whatever weirdness the
  add dx, 0x7C0                   ;   initial data segment expects, see top of file
  print_hex dh
  print_hex dl
  mov ax, dx

  cmp ax, [stage2 + 1]            ; kernel is 0x200 past 2nd sector
  jnz bad_kern
  xor dl,dl

  mov dl,[boot_drive]
  jmp stage2

;; bad kernel, show the first 3 bytes loaded from sector 2.
bad_kern:
  call p_show_first_bytes
  jmp $

;; simple disk read failure
load_fail:
  call p_int13_show_error
  jmp $                         ; super failure, halt.

p_show_first_bytes:
;; Shows the first 3 bytes of the kernel sector for diagnostics purposes.
  pusha
  ;; copying s_first_byte into buffer, then continue printing 3 bytes
  ;; of the 2nd sector in hex.
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
  mov di, dst_buf
  repnz movsb

  sw 0x7830                   ; store ascii '0x' at the buffer
  to_hex_buf [stage2]         ; should be BE, the mov opcode.
  sb 0x20
  sw 0x7830                   ; store ascii '0x' at the buffer
  to_hex_buf [stage2 + 2]
  to_hex_buf [stage2 + 1]
  sw 0x0d0a
  sb 0x00
  print dst_buf
  print s_no_kernel

  popa
  ret

  %include "common.asm"

  %include "common_vars.asm"

	s_drive_found db 'Booting... 0x', 0

	s_no_kernel db 'Halting, no kernel sector?', 0x0a, 0x0d, 0x00
  s_first_byte db 'First byte: ', 0x00

  sector2 dw 0x200

	buffer times 510-($-$$) db 0xff	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature

  dst_buf times 256 db 0xff
  src_buf times 256 db 0xff

  ;pad times 512 db 0x00ee

stage2:
