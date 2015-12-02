/**
	Tugas Akhir POK
	
	Sistem Absensi (Attendance Record)
		Sistem yang mencatat absensi, dapat digunakan dalam beberapa hal (contohnya: kelas, ujian dll)
		Orang yang ingin absen harus memasukkan nomor pengenalnya ke dalam program dan kemudian program 
			memberikan feedback berupa orang tersebut terlambat atau tidak
	
	Fitur
		- informasi mengenai keterlambatan kepada pengguna
		- pengaturan waktu dimulai (lama waktu dalam menit dari dimulai)
		- laporan berapa orang yang terlambat / tidak terlambat
	
	Diimplementasikan dengan AVR ATMega????
		- LCD, untuk menampilkan informasi dalam bentuk text
		- LED, status
		- Button, button digunakan untuk ON/OFF program dan juga keperluan "enter"/"OK" pada kondisi tertentu
		- Keypad, untuk input dari pengguna (menggunakan keypad 3x4)
		- Timer Interrupt, untuk menghitung waktu keterlambatan
	
	Kelompok
		- Alva Thomson      | 1406527500
		- Ferdinand         | 1406573923
		- Kustiawanto Halim | 1406573763


*/

.include "m8515def.inc"

main:

forever:
	rjmp forever
