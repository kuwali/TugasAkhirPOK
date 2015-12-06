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

;***** Code
reset:
	ldi	temp,low(RAMEND)
	out	SPL,temp			;init Stack Pointer		
	ldi	temp,high(RAMEND)
	out	SPH,temp

	ldi data_num, 0
	ldi data_counter, 0
	ldi ret_status, 0

	ldi parameter, 100
	rcall init_ram

main:
	ldi parameter, 20
	rcall insert
	ldi parameter, 5
	rcall insert
	ldi parameter, 5
	rcall insert
	ldi parameter, 10
	rcall insert
	ldi parameter, 11
	rcall delete
	ldi parameter, 5
	rcall search
	ldi parameter, 12
	rcall search
	ldi parameter, 5
	rcall delete
	ldi parameter, 20
	rcall delete
	ldi parameter, 20
	rcall search
	ldi parameter, 10
	rcall search

;***** Infinite Loop

forever:
	rjmp forever

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

input:
	.db 13245, 12345, 32089, 32479, 14335, 32108
