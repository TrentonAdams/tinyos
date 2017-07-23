	s_int13_read_status db 'Call status: ', 0
	s_crlf db 0x0a,0x0d,0
 	reg_16 db 0x00,0x00   ; temporary 16 bit storage for a register
 	; use "print s_dbg" anywhere to get an idea where you are when debugging
 	s_dbg db ' --> debug <-- ',0x0a,0x0d,0x00
	boot_drive db 0x00
	; hex to ascii table
	s_hex_ascii db '0123456789ABCDEF',0

