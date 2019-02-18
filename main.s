;****************** main.s ***************
; Program written by: Rohan Narayanan and Austin Rath
; Date Created: 2/4/2017
; Last Modified: 2/14/2019
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE2 is Button input  (1 means pressed, 0 means not pressed)
;  PE3 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE3 an output and make PE2 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608


NUMDELAY 		   EQU 7000000
NUMDELAY2		   EQU 3000000	
       IMPORT  TExaS_Init
       THUMB
       AREA    DATA, ALIGN=2
;global variables go here


       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
     BL  TExaS_Init ; voltmeter, scope on PD3
 ; Initializtion goes here


	LDR R0, =SYSCTL_RCGCGPIO_R
	LDRB R1, [R0]
	ORR R1, #0x30
	STRB R1, [R0]
	
	NOP
	NOP
	NOP
	NOP
	NOP
	
	
	LDR R0, =GPIO_PORTE_DEN_R
	LDRB R1, [R0]
	ORR R1, #0x0C
	STRB R1, [R0]
	
	LDR R0, =GPIO_PORTE_DIR_R
	LDRB R1, [R0]
	ORR R1, #0x08
	STRB R1, [R0]
	
	LDR R0, =GPIO_PORTF_DEN_R
	LDRB R1, [R0]
	ORR R1, #0x10
	STRB R1, [R0]
	
	LDR R0, =GPIO_PORTF_DIR_R
	LDRB R1, [R0]
	AND R1, #0xEF
	STRB R1, [R0]
	
	
	LDR R3, =OFFDELAY
	LDR R4, =ONDELAY
	
	LDR R1, =GPIO_LOCK_KEY
	LDR R2, =GPIO_PORTF_LOCK_R
	STR R1, [R2]
	LDR R1, =GPIO_PORTF_CR_R
	LDR R0, [R1]
	ORR R0, #0xFF
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_PUR_R
	LDRB R0, [R1]
	ORR R0, #0x10
	STRB R0, [R1]
	
	LDR R6, =BREATHEOFF
	LDR R7, =BREATHEON

     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts


loop  
; main engine goes here
			B BREATHE
			
			
			LDR R0, =GPIO_PORTF_DATA_R
			LDRB R1, [R0]
			AND R1, #0x10
			CMP R1, #0
			BEQ BREATHE
			
	
			LDR R0, =GPIO_PORTE_DATA_R
			LDRB R1, [R0]
			AND R1, #0x04
			CMP R1, #0
			BEQ INITIAL
   
			ADD R3, #4
			ADD R4, #4
			LDR R5, [R4]
			CMP R5, #0
			BNE PRESSED
			LDR R3, =OFFDELAY
			LDR R4, =ONDELAY
			

PRESSED		LDRB R1, [R0]
			AND R1, #0x04
			CMP R1, #0
			BNE PRESSED
			
   
   
INITIAL		LDR R0, [R3]
DELAY		SUBS R0, #1
			BNE DELAY
			LDR R0, =GPIO_PORTE_DATA_R
			LDRB R1, [R0]
			ORR R1, #0x08
			STRB R1, [R0]
			
			LDR R0, [R4]
DELAY2		SUBS R0, #1
			BNE DELAY2
			LDR R0, =GPIO_PORTE_DATA_R
			LDRB R1, [R0]
			AND R1, #0xF7
			STRB R1, [R0]
			B    loop
			
			
BREATHE		;LDR R0, =GPIO_PORTF_DATA_R
			;LDRB R1, [R0]
			;AND R1, #0x10
			;CMP R1, #0
			;BNE loop
			
			AND R8, #0
			
			
OUTER		LDR R0, =GPIO_PORTE_DATA_R
			LDRB R1, [R0]
			AND R1, #0xF7
			STRB R1, [R0]
			
			LDR R0, [R6]
BDELAY		SUBS R0, #1
			BNE BDELAY
			LDR R0, =GPIO_PORTE_DATA_R
			LDRB R1, [R0]
			ORR R1, #0x08
			STRB R1, [R0]
			
			LDR R0, [R7]
BDELAY2		SUBS R0, #1
			BNE BDELAY2
			ADD R8, #1
			CMP R8, #30
			BNE OUTER
			
			ADD R6, #4
			ADD R7, #4
			
			LDR R0, [R7]
			CMP R0, #0
			BNE BREATHE
			LDR R6, =BREATHEOFF
			LDR R7, =BREATHEON
			
			
			
			B BREATHE
			
			
			
			
OFFDELAY	DCD 7000000, 5000000, 3000000, 1000000, 9000000, 0
	
ONDELAY		DCD 3000000, 5000000, 7000000, 9000000, 1000000, 0
	
BREATHEOFF  DCD 99999, 99999, 90000, 80000, 70000, 60000, 50000, 40000, 30000, 20000, 10000, 1, 1, 10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 0

BREATHEON   DCD 1,1, 10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 99999, 99999, 90000, 80000, 70000, 60000, 50000, 40000, 30000, 20000, 10000, 0
      
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file
		 

