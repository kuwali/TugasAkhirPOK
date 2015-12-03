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

.include "m16def.inc"

;***** Interupt segment

.org $00
	rjmp RESET				; reset handle
.org $07
	; do for overflow interupt
.org $0E
	; do for compare interupt

;***** Define segment

.def temp0 = r16
.def temp1 = r17
	
main:

;***** Code

RESET:
	ldi	temp,low(RAMEND)
	out	SPL,temp			;init Stack Pointer		
	ldi	temp,high(RAMEND)
	out	SPH,temp
	rjmp main

;***** Infinite Loop

forever:
	rjmp forever

;***** Data

.db
; some data
