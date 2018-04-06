#include "p12f629.inc"

    __FUSES _FOSC_INTRCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _BOREN_OFF & _CP_OFF & _CPD_OFF

RAMINI0		equ	0x20

RELAY		equ	RAMINI0 + 0
PULSE		equ	RAMINI0 + 1
PULSE_LEN	equ	4		; number of overflows of256 prescaled timer, cca 1/3 sec

RES_VECT  CODE    0x0000                  ; processor reset vector
          GOTO    START                   ; go to beginning of program

MAIN_PROG CODE                      ; let linker place main program

START: 
       ; TODO Step #5 - Insert Your Program Here
       CLRF	STATUS 
       CLRF	INTCON
       CLRF	PCLATH
       goto	MAIN

WAIT_PULSE:
       movwf	PULSE_LEN
       movwf	PULSE

       clrf	TMR0

WAIT_PULSE_LOOP:
       btfsc	INTCON,T0IF
       goto	WAIT_PULSE_LOOP
       decfsz	PULSE
       goto	WAIT_PULSE_LOOP
       return

MAIN:
       BANKSEL	TMR0
       CLRWDT
       BANKSEL	OPTION_REG
       MOVLW	b'01000000'
       ANDWF	OPTION_REG,w

       ; GPPU - enabled
       ; INTEDG - unchanged
       ; TOCS = 0, internal clock
       ; TOSE = 0, unused
       ; PSA = 0, prescaler for TMR0
       ; PS2-0 = 111, 1 :256 prescaler
       ; 4Mhz clock, divided / 4,
       IORLW	b'00000111'
       MOVWF	OPTION_REG

       ; GIE = 1 (global interrupts on)
       ; PEIE = 0 (peripheral off)
       ; T0IE = 0 (timer off)
       ; INTE = 0 (GP2 ext interrupt off)
       ; GPIE = 0 (port change interrupt off)
       ; T0IF = 0 (interrupt flag off)
       ; INTF = 0 (ext interrupt flag)
       ; GPIF = 0 (port change flag)
       MOVLW	b'10000000'
       MOVWF 	INTCON

       call	0x3ff		    ; get the OSCCAL value
       movwf	OSCCAL

       movlw	b'001000'	    ; GP5 input, all other outputs
       movwf	TRISIO		    ; internal pull-up enable
       movwf	WPU

POWERON:
       BANKSEL	GPIO

       movlw	b'0'		    ; switch all off
       movwf	GPIO
       call	WAIT_PULSE
       call	WAIT_PULSE

       movlw	b'111110'	    ; switch on branch relays, leave off the master relay
       movwf	GPIO
       call	WAIT_PULSE

       ;   now waited for the PULSE_LEN, all the branch relays are on and power to branches cut off.
       movlw	b'111111'
       movwf	GPIO
       call	WAIT_PULSE

       movlw	b'111101'
       andwf	GPIO, f
       call	WAIT_PULSE

       movlw	b'111001'
       andwf	GPIO, f
       call	WAIT_PULSE

       movlw	b'101001'
       andwf	GPIO, f
       call	WAIT_PULSE

       movlw	b'001001'
       andwf	GPIO, f
       call	WAIT_PULSE

       ; all set
MAIN_LOOP:
       movlw	b'001000'
       andwf	GPIO,w
       btfsc	STATUS, Z
       goto	MAIN_LOOP
       goto        POWERON

       ORG		0x100


       END
