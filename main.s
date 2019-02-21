;****************** main.s ***************
; Program written by: Rohan Narayanan and Austin Rath
; Date Created: 2/4/2017
; Last Modified: 2/20/2019
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


	LDR R0, =SYSCTL_RCGCGPIO_R				; Sets clock register bits 4 and 5 for Ports E and F
	LDRB R1, [R0]
	ORR R1, #0x30
	STRB R1, [R0]
	
	NOP										; Waits for clock to stabalize
	NOP
	NOP
	NOP
	NOP
	
	
	LDR R0, =GPIO_PORTE_DEN_R				; Sets bits 2 and 3 in the Port E DEN to enable PE2 and PE3
	LDRB R1, [R0]									
	ORR R1, #0x0C
	STRB R1, [R0]
	
	LDR R0, =GPIO_PORTE_DIR_R				; Sets bit 3 in the Port E DIR to make PE3 an output pin  			
	LDRB R1, [R0]							; and keeps bit 2 as a 0 to make PE2 an input pin
	ORR R1, #0x08
	STRB R1, [R0]
	
	LDR R0, =GPIO_PORTF_DEN_R				; Sets bit 4 in the Port F DEN to enable PF4
	LDRB R1, [R0]
	ORR R1, #0x10
	STRB R1, [R0]
	
	LDR R0, =GPIO_PORTF_DIR_R				; Clears bit 4 in the Port F DIR to make PF4 an input pin	
	LDRB R1, [R0]
	AND R1, #0xEF
	STRB R1, [R0]
	
	
	LDR R3, =OFFDELAY						; Loads R3 with the array 'OFFDELAY', which contains the delay values for how long the light should be off during each duty cycle
	LDR R4, =ONDELAY						; Loads R3 with the array 'ONDELAY', which contains the delay values for how long the light should be on during each duty cycle
	
	LDR R1, =GPIO_LOCK_KEY					; Loads R1 with the lock register key value
	LDR R2, =GPIO_PORTF_LOCK_R				; Loads the lock register key value into the lock register for Port F, which unlocks Port F
	STR R1, [R2]
	LDR R1, =GPIO_PORTF_CR_R				; Loads the CR register for Port F with 1s, to enable the unlocked pins
	LDR R0, [R1]
	ORR R0, #0xFF
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_PUR_R				; Enables the pull-up resistor in PF4 by setting bit 4 to 1 in the Port F PUR
	LDRB R0, [R1]
	ORR R0, #0x10
	STRB R0, [R1]
	
	LDR R6, =BREATHEOFF						; Loads R6 with the array 'BREATHEOFF', which contains the delay values for how long the LED should be off when it's in breathe mode (PF4) is pressed
	LDR R7, =BREATHEON						; Loads R6 with the array 'BREATHEON', which contains the delay values for how long the LED should be on when it's in breathe mode (PF4) is pressed

     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts


loop  
; main engine goes here
			
			LDR R0, =GPIO_PORTF_DATA_R		; Isolates bit 4 of the Port F Data register to see if it is a 0, meaning PF4 is pressed
			LDRB R1, [R0]					; If pressed, branches to the subroutine 'Breathe'
			AND R1, #0x10					; If not pressed, falls through to run normal loop with duty cycles
			CMP R1, #0
			BEQ BREATHE
			
	
			LDR R0, =GPIO_PORTE_DATA_R		; Beginning of duty cycle loop 
			LDRB R1, [R0]					; Isolates bit 2 of the Port E Data register to see if PE2 is not pressed
			AND R1, #0x04					; If not pressed, branches to 'Initial' where the duty cycles begin to be implemented
			CMP R1, #0						; If pressed, falls through to where the duty cycle is incremented to the next duty cycle
			BEQ INITIAL
   
			ADD R3, #4						; Increments R3 and R4 by 4, b/c the opcode DCD allots 4 spaces in memory for each value
			ADD R4, #4						; Next value of 'OFFDELAY' is placed in R3, and next value of 'ONDELAY' is placed in R4
			LDR R5, [R4]					; Checks to see if the next value in the array is a 0, meaning it has cycled through all the values in the array
			CMP R5, #0						
			BNE PRESSED						; If not 0, then the values in R3 and R4 are valid, and branches to 'PRESSED' 
			LDR R3, =OFFDELAY				; If value from array placed in R3 and R4 is 0, then reload R3 with the beginning of 'OFFDELAY', and R4 with beginning of 'ONDELAY'
			LDR R4, =ONDELAY
			

PRESSED		LDRB R1, [R0]					; Checks to see if PE2 is still pressed
			AND R1, #0x04					; If still pressed, cycles through this loop until it is released 
			CMP R1, #0						; Once released, will fall through to where the duty cycle is implemented
			BNE PRESSED
			
   
   
INITIAL		LDR R0, [R3]					; Loads R0 with the value in R3, which is the value in 'OFFDELAY'
DELAY		SUBS R0, #1						; Subtracts 1 from this value until it reaches 0
			BNE DELAY						
			LDR R0, =GPIO_PORTE_DATA_R		; Once the value reaches 0, the LED is turned on by setting bit 3 of the Port E Data register to 1
			LDRB R1, [R0]
			ORR R1, #0x08
			STRB R1, [R0]
			
			LDR R0, [R4]					; Loads R0 with the value in R4, which is the value in 'ONDELAY'
DELAY2		SUBS R0, #1						; Subtracts 1 from this value until it reaches 0
			BNE DELAY2						
			LDR R0, =GPIO_PORTE_DATA_R		; Once the value reaches 0, the LED is turned off by clearing bit 3 of the Port E Data register
			LDRB R1, [R0]
			AND R1, #0xF7
			STRB R1, [R0]
			B    loop						; Branches back to the beginning of the main duty cycle loop to check again if PF4 is pressed or not
			
			
			
			
			
			
BREATHE		LDR R0, =GPIO_PORTF_DATA_R		; If PF4 is pressed and the main loop branches to this subroutine, then the Port F Data register must be checked again to see if PF4 is stil pressed
			LDRB R1, [R0]					; If PF4 is still pressed, meaning bit 4 of the Port F Data register is 0, then it falls through to implement the breathing mode of the LED
			AND R1, #0x10					; If PF4 is not still pressed, then branches back to the main duty cycle loop
			CMP R1, #0
			BNE loop
						
			AND R8, #0						; Creates a counter that will be used to determine when the next values of the 'BREATHEOFF' and 'BREATHEON' arrays should be loaded into R6 and R7
			
			
OUTER		LDR R0, =GPIO_PORTE_DATA_R		; First turns off the LED by clearing bit 3 of the Port E Data register
			LDRB R1, [R0]
			AND R1, #0xF7
			STRB R1, [R0]
			
			LDR R0, [R6]					; Loads R0, with the value in R6, which is the value in the 'BREATHEOFF' array
BDELAY		SUBS R0, #1						; Subtracts 1 from this value until it reaches 0
			BNE BDELAY
			LDR R0, =GPIO_PORTE_DATA_R		; Once the value reaches 0, the LED is turned on by setting bit 3 of the Port E Data register to 1
			LDRB R1, [R0]
			ORR R1, #0x08
			STRB R1, [R0]
				
			LDR R0, [R7]					; Loads R0, with the value in R7, which is the value in the 'BREATHEON' array
BDELAY2		SUBS R0, #1						; Subtracts 1 from this value until it reaches 0
			BNE BDELAY2
			ADD R8, #1						; Adds 1 to the counter R8, which needs to reach 30 before the next values of 'BREATHEOFF' and 'BREATHEON' are stored in R^ and R7 respectively
			CMP R8, #30						
			BNE OUTER						; If R8 has not reached 30 yet, falls through to where R6 and R7 are incremented to the next values of 'BREATHEOFF' AND 'BREATHEON' respectively
			
			ADD R6, #4						; Increments R6 to next value in 'BREATHEOFF'
			ADD R7, #4						; Increments R7 to next value in 'BREATHEON'
			
			LDR R0, [R7]					; Checks to see if the values in 'BREATHEOFF' and 'BREATHEON' are 0 meaning it has reached the end of the array
			CMP R0, #0
			BNE BREATHE						; If not 0, branches back to beginning of the Breathe loop to check if PF4 is still pressed
			LDR R6, =BREATHEOFF				; If 0, R6 is reloaded with the beginning of 'BREATHEOFF' and R7 is reloaded with the beginning of 'BREATHEON'
			LDR R7, =BREATHEON
			
			
			
			B BREATHE						; Branches back to beginning of Breathe loop to check if PF4 is still pressed
			
			
; Runs 2Hz on the simulator
			
;OFFDELAY	DCD 7000000, 5000000, 3000000, 1000000, 9000000, 0     
	
;ONDELAY		DCD 3000000, 5000000, 7000000, 9000000, 1000000, 0

; Runs 2 Hz on the board
	
OFFDELAY	DCD 4644549, 3317535, 4644549, 663507, 5971536, 0
	
ONDELAY		DCD 1991150, 3317535, 1991150, 5971536, 663507, 0
	
BREATHEOFF  DCD 99999, 99999, 90000, 80000, 70000, 60000, 50000, 40000, 30000, 20000, 10000, 1, 1, 10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 0

BREATHEON   DCD 1,1, 10000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000, 99999, 99999, 90000, 80000, 70000, 60000, 50000, 40000, 30000, 20000, 10000, 0
      
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file
		 

