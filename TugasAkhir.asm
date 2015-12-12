;***************************************************************************
;*
;* Tugas Akhir POK
;*
;* Sistem Absensi (Attendance Record)
;* -------------------------------------------------------------------------
;* Sistem yang mencatat absensi, dapat digunakan dalam beberapa hal 
;* (contohnya: kelas, ujian dll)
;* Orang yang ingin absen harus memasukkan nomor pengenalnya ke dalam 
;* program dan kemudian program memberikan feedback berupa orang tersebut 
;* terlambat atau tidak
;*
;* Fitur:
;*   - informasi mengenai keterlambatan kepada pengguna
;*   - pengaturan waktu dimulai (lama waktu dalam menit dari dimulai)
;*   - laporan berapa orang yang terlambat / tidak terlambat
;*
;* Diimplementasikan dengan AVR ATMega16
;*	 - LCD, untuk menampilkan informasi dalam bentuk text
;*   - LED, status
;*   - Button, button digunakan untuk ON/OFF program dan juga keperluan 
;*     		   "enter"/"OK" pada kondisi tertentu
;*   - Keypad, untuk input dari pengguna (menggunakan keypad 3x4)
;*   - Timer Interrupt, untuk melakukan shutdown setelah user menekan off
;*	
;* Kelompok:
;*	 - Alva Thomson      | 1406527500
;*	 - Ferdinand         | 1406573923
;*	 - Kustiawanto Halim | 1406573763
;*
;***************************************************************************

.include "m8515def.inc"

;***** Constants
.equ data_addr = $60
.equ end =$13
.equ middle =$08
.equ last =0b11010011
.equ block1 = $60
.equ toChar = $30

;***** Interupt segment
.org $00
	rjmp RESET				; reset handle
.org $07
	; do for overflow interupt
.org $0E
	; do for compare interupt

;***** Define segment

;***** Defines
.def temp           = R16
.def data_num       = R17
.def data_counter   = R18
.def parameter      = R19
.def ret_status     = R20
.def EW 			= R21	; for PORTA
.def PB 			= R22	; for PORTB
.def status         = R23
.def keyval         = R24
.def counter        = R25


;***** Setting
; PORTC as DATA
; PORTA.0 as EN
; PORTA.1 as RS
; PORTA.2 as RW
; PORTB for Keypad
; PORTD for LED


;***** Code
reset:	
	ldi	temp,low(RAMEND)
	out	SPL,temp			;init Stack Pointer		
	ldi	temp,high(RAMEND)
	out	SPH,temp

	rcall INIT_LCD

	ldi	temp,$ff
	out	DDRA,temp	; Set port A as output
	out	DDRC,temp	; Set port C as output
	
	rcall clear_lcd

	ldi data_num, 0
	ldi data_counter, 0
	ldi ret_status, 0
	ldi status, 99

	ldi parameter, 100
	rcall init_ram

; *** set up Direction Registers *** 
	ldi temp, 0b11110000
	out DDRB, temp
	ldi temp, 0b00001111
	out PORTB, temp

	ldi YL, low(block1)
	ldi YH, high(block1)

	rjmp loop

;**** keypad checking
loop:
	ldi temp,0b00001111 
	out PORTB,temp    
	nop  
    nop  
	in temp,PINB     
	ori temp,0b11110000 
	cpi temp,0b11111111 
	brne check_col      
	rjmp loop

check_col:
	ldi data_counter, 0b00001000
	ldi keyval, 0
	
	do_check_col:	 
		inc keyval
		lsl data_counter
		tst data_counter
		breq loop

		ldi temp, $FF
		eor temp, data_counter
		out PORTB, temp        
		nop  
		nop  
		in temp, PINB          
		ori temp, 0b11110000  
		cpi temp, 0b11111111 
		brne check_row
		breq do_check_col

check_row:
	ldi data_counter, 0b00010000
	subi keyval, 4			; prepare keyval for 0 + col

	do_check_row:
		subi keyval, -4
		lsr data_counter
		tst data_counter
		breq loop
		
		in temp, PINB           
		andi temp, 0b00001111
		ldi R26, $0F
		eor R26, data_counter
		cp temp, R26
		brne do_check_row
		rjmp result

start:
	ldi	ZH,high(2*message_welcome)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_welcome)	; Load low part of byte address into ZL
	rcall write_text
	rcall make_end

	rcall clear_lcd

	ldi	ZH,high(2*message_to)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_to)	; Load low part of byte address into ZL
	rcall write_text
	rcall make_end

	rcall clear_lcd

	ldi	ZH,high(2*message_desc)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_desc)	; Load low part of byte address into ZL
	rcall write_text
	rcall make_end

main_menu:
	ldi status,0
	rcall clear_lcd

	ldi	ZH,high(2*message_menu1)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_menu1)	; Load low part of byte address into ZL
	rcall write_text

	rcall move_sec_line

	ldi	ZH,high(2*message_menu2)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_menu2)	; Load low part of byte address into ZL
	rcall write_text

	rjmp loop

back_to_main:
	rjmp main_menu

shut_down:
	ldi status,99
	rcall clear_lcd
	rjmp loop

result:
	cpi status, 99
	brne shutdown_action
	cpi keyval,4
	breq start
	
	shutdown_action:
		cpi keyval,8
		breq shut_down
		
	cpi status, 99
	brne back_actions
	rjmp actions_input

	back_actions:
		cpi keyval,12
		breq back_to_main

	actions_input:
		cpi keyval,15
		breq finish
		cpi keyval,13
		breq clear

	; keypad mapping
	cpi keyval, 14
	brne check_four
	ldi keyval, 0

	check_four:
		cpi keyval, 4
		breq check_status
		brmi check_status
		dec keyval
		
		cpi keyval, 8
		breq check_status
		brmi check_status
		dec keyval
	
	check_status:
		cpi status, 99
		breq clear
		cpi status,0
		brne write
		cpi keyval,1
		breq absence
		cpi keyval,2
		breq insert2
		cpi keyval,3
		breq delete_menu

clear:
	cpi status,1
	breq absence
	cpi status,2
	breq insert2
	cpi status,3
	breq delete_menu
	cpi status,4
	breq absence_npm
	rjmp loop

absence:
	ldi status,1
	rcall clear_lcd
	ldi	ZH,high(2*message_absence_time)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_absence_time)	; Load low part of byte address into ZL
	rcall write_text
	rcall move_sec_line
	rcall wait_lcd
	rjmp loop

write:
	mov parameter,keyval
	ldi temp,48
	add parameter,temp
	rcall WRITE_CHAR
	rjmp loop

insert2 :
	ldi status,2
	rcall clear_lcd
	ldi	ZH,high(2*message_insert)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_insert)	; Load low part of byte address into ZL
	rcall write_text
	rcall move_sec_line
	rcall wait_lcd
	rjmp loop

delete_menu:
	ldi status,3
	rcall clear_lcd
	ldi	ZH,high(2*message_delete)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_delete)	; Load low part of byte address into ZL
	rcall write_text
	rcall move_sec_line
	rcall wait_lcd
	rjmp loop

finish:
	cpi status,1
	breq absence_npm;label untuk method simpen waktunya
	cpi status,2
	breq forever;label untuk method simpen npm yang mau diinsert
	cpi status,3
	breq forever;label untuk method simpen npm yang mau didelete
	cpi status,4
	breq forever;label untuk method absen dia di kelas
	 

absence_npm:
	ldi status,4
	rcall clear_lcd
	ldi	ZH,high(2*message_absence_npm)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_absence_npm)	; Load low part of byte address into ZL
	rcall write_text
	rcall move_sec_line
	rcall wait_lcd
	rjmp loop
	;label untuk method simpen waktunya:
	

forever:
	ldi	ZH,high(2*message_finish)	; Load high part of byte address into ZH
	ldi	ZL,low(2*message_finish)	; Load low part of byte address into ZL
	rcall clear_lcd
	rcall write_text
	cpi status,4
	breq absence_npm
	cpi status,2
	breq insert2
	cpi status,3
	breq delete_menu
	rcall clear_lcd
	rjmp loop

	bef_blink:
	ldi PB,$0C
	ldi temp, 0b00000100

	BLINK:
	cbi PORTA,1	; CLR RS
	eor PB, temp	; MOV DATA,0x0E --> disp ON, cursor OFF, blink OFF
	out PORTC,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD	
	rjmp BLINK

	make_end:
	ldi counter,0
	end_loop:
	cbi PORTA,1	; CLR RS
	ldi PB,0x1C	; MOV DATA,0x18 --> shift left
	out PORTC,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	inc counter
	cpi counter,end
	brne end_loop
	ret

	move_sec_line:
	cbi PORTA,1	; CLR RS
	ldi PB,0b10100111	; MOV DATA, --> move cursor to second line
	out PORTC,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall wait_lcd
	ldi parameter,$20
	rcall write_char
	ret

	WAIT_LCD:
	ldi	r20, 1
	ldi	r21, 69
	ldi	r22, 69
	CONT:	dec	r22
	brne	CONT
	dec	r21
	brne	CONT
	dec	r20
	brne	CONT
	ret

	INIT_LCD:
	cbi PORTA,1 ; CLR RS
	ldi PB,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTC,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall WAIT_LCD
	cbi PORTA,1 ; CLR RS
	ldi PB,$0F ; MOV DATA,0x0E --> disp ON, cursor OFF, blink OFF
	out PORTC,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall WAIT_LCD
	rcall CLEAR_LCD ; CLEAR LCD
	cbi PORTA,1 ; CLR RS
	ldi PB,$06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTC,PB
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall WAIT_LCD
	ret

	CLEAR_LCD:
	cbi PORTA,1	; CLR RS
	ldi PB,$01	; MOV DATA,0x01
	out PORTC,PB
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	ret

	WRITE_CHAR:
	inc counter
	sbi PORTA,1	; SETB RS
	out PORTC, parameter
	sbi PORTA,0	; SETB EN
	cbi PORTA,0	; CLR EN
	rcall WAIT_LCD
	ret

	WRITE_TEXT:
	lpm	; Load byte from program memory into r0
	tst	r0	; Check if we've reached the end of the message
	breq quit	; If so, go
	mov parameter, r0	; Put the character onto Port B
	rcall WRITE_CHAR
	adiw ZL,1	; Increase Z registers
	rjmp WRITE_TEXT

	quit: ret


;*******************************
;*
;* Init Ram
;* 		mengosongkan array
;*		
;* @param parameter (R19), banyak element yang ingin dihapus
;* 
;* @return void
;*******************************
init_ram:
	ldi data_counter, 1

	ldi  YH, high(data_addr)		; inisialisasi address counter
	ldi  YL, low(data_addr)			; inisialisasi address counter

	init_ram_do:
		cp parameter, data_counter
		brmi init_ram_return

		ldi temp, $FF					; load $FF
		st  Y, temp						; store $$FF ke address Y
		adiw YL, 1						; increase address counter
		inc data_counter				; tambahkan data_counter
		rjmp init_ram_do				; loop back

	init_ram_return:
		ldi data_num, 0
		ret

;*******************************
;*
;* Search
;* 		mencari elemen dalam array
;*		
;* @param parameter (R19), elemen yang ingin dicari
;*	
;* @return ret_status (R20), pada register ...
;*				0: gagal, karena elemen tidak ditemukan
;*				1: berhasil menemukan elemen, index element yang dikembalikan
;*******************************
search:
	ldi data_counter, 1				; inisialisasi counter
	ldi ret_status, 0				; inisialisasi, ret_status = 0
	
	ldi  YH, high(data_addr)		; inisialisasi address counter
	ldi  YL, low(data_addr)			; inisialisasi address counter
	
	search_do:
		cp data_num, data_counter		; cek apakah sudah berada di akhir data
		brmi search_return

		ld temp, Y						; load data dari data memory
		cp parameter, temp				; cek apakah data ditemukan
		breq search_status				; jika ditemukan ubah status

		inc data_counter				; jika tidak ditemukan, increase data_counter
		rjmp search_do					; loop back

	search_status:
		ldi ret_status, 1

	search_return:
		ret

;*******************************
;*
;* Insert
;* 		insert elemen dalam array
;*		
;* @param parameter (R19), elemen yang ingin diinsert
;*	
;* @return ret_status (R20), pada register ...
;*				0: gagal, karena elemen sudah ada dalam sebelumnya (data harus unik)
;*				1: insert berhasil
;*******************************
insert:
	rcall search					; search terlebih dahulu, apakah data sudah ada atau belum
	
	tst ret_status					; cek apakah data sudah ada atau belum
	breq insert_init				; jika belum ada lakukan proses insert

	ldi ret_status, 0				; jika data sudah ada, ubah return status menjadi 0
	ret								; dan langsung return (tanpa insert)

	insert_init:
		mov data_counter, data_num		; inisialisasi counter
		ldi ret_status, 0				; inisialisasi, ret_status = 0
	
		ldi  YH, high(data_addr)		; inisialisasi address counter
		ldi  YL, low(data_addr)			; inisialisasi address counter
		add YL, data_num				; tambahkand dengan data_num (sekarang ada di paling belakang array
		dec  YL							; decrease (1-based index)

	insert_do:
		tst data_counter			; jika sudah sampai di paling depan,
		breq insert_ret				; langsung insert dan return
		 
		ld temp, Y					; load data di index sekarang
		cp temp, parameter			; compare data sekarang dengan parameter
		brmi insert_ret				; jika lebih besar maka shifting selesai, insert lalu return
	
		insert_shift:				; intinya melakukan data[Y + 1] = data[Y]
			inc YL					; increase YL terlebih dahulu
			st  Y, temp				; store ke data[Y + 1]
			dec YL					; kembalikan ke Y
			dec YL					; decrease Y (ke data sebelumnya, mulai loop baru)
			dec data_counter		; decrease data_counter
			rjmp insert_do			; loop back
						

	insert_ret:
		ldi ret_status, 1			; ubah ret_status
		inc data_num				; tambahkan data_num
		inc YL						; increase YL terlebih dahulu
		st Y, parameter				; insert data sebelum return
		ret							; return
		
;*******************************
;*
;* Delete
;* 		menghapus elemen dalam array
;*		
;* @param parameter (R19), elemen yang ingin dihapus
;*	
;* @return ret_status (R20), pada register ...
;*				0: gagal, karena elemen tidak ditemukan
;*				1: penghapusan berhasil
;*******************************
delete:
	ldi data_counter, 1		; inisialisasi counter
	ldi ret_status, 0		; inisialisasi, ret_status = 0
	ldi YH, high(data_addr)	; inisialisasi counter
	ldi YL, low(data_addr)	; inisialisasi counter
		
	delete_do:
		cp data_num, data_counter		; cek apakah sudah berada di akhir data
		brmi delete_return

		tst ret_status					; cek apakah sudah ditemukan atau belum
		brne delete_now					; jika sudah, lakukan shifting data

		ld temp, Y						; load ke temp
		cp parameter, temp				; cek apakah elemen sama dengan parameter yang diberikan
		breq delete_now					; jika sama lakukan proses delete

		adiw YL, 1						; tambahkan address Y
		inc data_counter				; tambah data_counter
		rjmp delete_do					; loop back

		delete_now:						
			tst ret_status
			brne delete_shift			
			
			ldi ret_status, 1		 	; ubah status found menjadi 1
			dec data_num				; decrease jumlah data (sudah men-delete data pada index sekarang)
			rjmp delete_do				; shifting data pertama kali akan dilakukan pada loop selanjutnya			

			delete_shift:				; intinya melakukan: data[Y] = data[Y + 1]
				adiw YL, 1				; ke address Y + 1
				ld temp, Y				; ambil data dari address Y + 1
				subi YL, 1				; kembali ke address Y
				st Y, temp				; store di address Y mula-mula
				adiw Y, 1				; tambahkan address counter
				inc data_counter		; tambahkan data_counter
				rjmp delete_do			; loop back

	delete_return:
		ret	

;***** Data
message_welcome:
.db "WELCOME"
.db	0
message_to:
.db "to"
.db 0
message_desc:
.db "Absence Program"
.db 0
message_menu1:
.db "Menu:   1Absence"
.db 0
message_menu2:
.db "2Insert 3Delete"
.db 0

message_absence_time:
.db "Input Time :"
.db 0

message_insert:
.db "Insert NPM :"
.db 0

message_delete:
.db "Delete NPM :"
.db 0

message_absence_npm:
.db "Input NPM :"
.db 0

message_finish:
.db "Finish"
.db 0

