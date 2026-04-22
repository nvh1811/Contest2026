/*
struct tree
	main.c: initial and main loop function
	PFPA.c: set P3.1/P3.2 are UART0 UTXD/URXD
	GPIO.c: initial gpio pin
	 WDT.c: initial watchdog with 250ms reset while do nothing
   uart0.c: initial uart0 peripheral 
 utility.c: delay
 
 keyscan.c:	scan key matrix
 segment.c:	display R/W eeprom addr
  eeprom.c: eeprom R/W process
  
  function:
	1. keyscan input R/W addr
	   KEY1~KEY10: input data 0~9 with BCD format
	   KEY13:	reset R/W addr with 0
	   KEY12:	read eeprom
	   KEY16:	write eeprom
	   
	2. display R/W eeprom addr with BCD format
	
	note: limit R/W eeprom addr less than 256
	
 
*/