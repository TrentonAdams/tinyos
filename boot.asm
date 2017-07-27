BITS 16
;; Started with the basic myfirst.asm at
;; http://mikeos.sourceforge.net/write-your-own-os.html

%include "macros.asm"

  ;jmp start       ; if we want to use FAT, we need reserved space, jump past

  ; hard code 3 bytes for jump start.  "jmp start" is only 2
  jmp start

  xtra db 0x00                    ; FAT boot sector expects 3 bytes for jmp
  manufacturer times 8 db 0x00    ; os or tool that initialized disk
  bytesPerSector dw 0x0000        ; we use the bios
  clusterSize db 0x00             ; sectors per allocation unit
  reservedSectors dw 0x0000       ; total sectors for boot staging
  fatCopies db 0x00               ; redundant copies, including original
  roots dw 0x0000                 ; number of root dir copies
  totalSectors dw 0x0000          ; in entire disk
  mediumType db 0x00              ; FAT first byte
  sectorsPerFat dw 0x0000         ; hello!
  sectorsPerTrack dw 0x0000       ; we use the bios
  numberOfHeads dw 0x0000         ; we use the bios
  hiddenSectors dd 0x00000000     ; don't care?
  totalSectorsHD dd 0x00000000    ; drives > 32M instead of totalSectors
  physicalDriveNum db 0x00        ; 0x80 for HD, 0x01 for floppy, etc.
  reserved db 0x00                ; just that, reserved for something
  bootSig db 0x00                 ; some sort of signature
  volumeId dd 0x00000000          ; 32-bit volume binary ID
  label times 11 db 0x00          ; the label of the disk
  reserved2 times 8 db 0x00       ; again, just that, reserved for something
  ;FAT_RESERVED times 0x3C db 0xff ; 0x3E fat reserved - 3 bytes jmp codes
  
start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax      ; data segment source used with ds:si
	mov es, ax      ; extra segment for es:di

	mov [boot_drive], dl  ; store the boot drive in the one byte buffer

	jmp start_kernel  ; read first byte of disk.
	hlt

start_kernel:
  mov ah, 0             ; reset disk
  mov dl, [boot_drive]  ; drive 0
  stc
  int 13h
  jc load_fail      ; return, we're a failure
  mov bx, [sector2]       ; place in memory [sector2] bytes past where the MBR is loaded.
  mov ah, 0x02 ; function
  mov al, 0x02 ; sectors to read
  mov ch, 0x00 ; track/cyl
  mov cl, 0x02 ; sector start
  mov dh, 0x00 ; head
  mov dl, [boot_drive] ; drive

  stc
  int 13h
  jc load_fail

  mov ax, [kernel_signature]              ; kernel signature

  cmp ax, [stage2]            ; kernel is multiples of 0x200 past 1st sector
  jnz bad_kern
  xor dl,dl

  mov dl,[boot_drive]
  ; segment adjustment prior to kernel start.  The kernel needs not know where
  ; it will be.
  mov ax, 0x800
  mov ds, ax
  mov es, ax
  add ax, 288
  jmp 0x800:0x0002            ; two bytes in due to kernel signature.

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
%ifdef EXTRA
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
  mov si, s_first_byte        ;   to repnz
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
%endif
  print s_no_kernel
  popa
  ret

  %include "common.asm"
  %include "extra.asm"

	s_no_kernel db 'No Kern-Sig 0xAA55?', 0x0a, 0x0d, 0x00
  s_first_byte db 'First byte: ', 0x00
  kernel_signature dw 0x1234

  sector2 dw 0x200
  
  %include "common_vars.asm"

	buffer times 510-($-$$) db 0xff	; Pad remainder of boot sector with 0s
	dw 0xAA55		                    ; The standard PC boot signature

  dst_buf times 256 db 0xff
  src_buf times 256 db 0xff

  ;pad times 512 db 0x00ee

stage2:
