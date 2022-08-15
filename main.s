;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Luis Pablo Carranza
; Compilador: PIC-AS (v2.4), MPLAB X IDE (v6.00)
; Proyecto: Laboratorio 3 Interrupciones
; Hardware PIC16F887
; Creado: 08/08/22
; Última Modificación: 09/08/22
; ******************************************************************************

PROCESSOR 16F887
#include <xc.inc> 
; ******************************************************************************
; Palabra de configuración
; ******************************************************************************
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSC oscillator 
				; without clock out)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and 
				; can be enabled by SWDTEN bit of the WDTCON 
				; register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR 
				; pin function is digital input, MCLR internally 
				; tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code 
				; protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code 
				; protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/
				; External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit 
				; (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin 
				; has digital I/O, HV on MCLR must be used for 
				; programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset 
				; set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits 
				; (Write protection off)

; ******************************************************************************
; Variables
; ******************************************************************************
				
PSECT udata_shr
 W_TEMP:
    DS 1
 STATUS_TEMP:
    DS 1
 CONT1:
    DS 1
 CONT20MS:
    DS 1
 bandera1:
    DS 1
    
; ******************************************************************************
; Vector Reset
; ******************************************************************************
    
PSECT CODE, delta=2, abs
 ORG 0x0000
    GOTO MAIN
    
; ******************************************************************************
; Vector Interrupciones
; ******************************************************************************
    
PSECT CODE, delta=2, abs
 ORG 0x0004
 
PUSH:
    MOVWF W_TEMP
    SWAPF STATUS, W
    MOVWF STATUS_TEMP
    
ISR:
    BTFSC INTCON, 0
    GOTO RRBIF
    BTFSC INTCON, 2
    GOTO RTMR0
    GOTO POP

RTMR0:
    BCF INTCON, 2
    BANKSEL TMR0
    INCF CONT20MS
    MOVLW 178
    MOVWF TMR0
    GOTO POP
    
RRBIF:
    BANKSEL PORTB
    BTFSS PORTB, 6
    INCF PORTA
    BTFSS PORTB, 7
    DECF PORTA
    BCF INTCON, 0
    GOTO POP
    
POP: 
    SWAPF STATUS_TEMP, W
    MOVWF STATUS
    SWAPF W_TEMP, F
    SWAPF W_TEMP, W
    RETFIE
        
; ******************************************************************************
; Código Principal
; ******************************************************************************
PSECT CODE, delta=2, abs
 ORG 0x0100
    
MAIN:	
    BANKSEL OSCCON  ; Configuración del oscilador 4MHz
    BSF OSCCON, 6   ; IRCF2
    BSF OSCCON, 5   ; IRCF1
    BCF OSCCON, 4   ; IRCF0
    
    BSF OSCCON, 0   ; SCS Reloj Interno
    
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH	    ; Todas las I/O son digitales
    
    BANKSEL TRISB
    //BSF TRISB, 7    ; RB7 configurado como entrada
    //BSF TRISB, 6    ; RB6 configurado como entrada
    MOVLW 11000000B
    MOVWF TRISB
    CLRF TRISA
    CLRF TRISC
    CLRF TRISD
    CLRF TRISE	    ; El resto de puertos configurados como salidas
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 5	; T0CS FOSC/4 modo temporizador
    BCF OPTION_REG, 3	; PSA asignar presscaler para TMR0
    
    BSF OPTION_REG, 2	
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0	; Prescaler 1:256
    
    BCF OPTION_REG, 7	; NO RBPU
    
    BANKSEL PORTB
    CLRF PORTA
    CLRF PORTB
    CLRF PORTC
    CLRF PORTD
    CLRF PORTE	    ; Iniciar todos los puertos en 0

    BANKSEL INTCON
    BSF INTCON, 7   ; GIE Habilitar interrupciones globales
    BSF INTCON, 5   ; Habilitar interrupción de TMR0
    BSF INTCON, 3   ; RBIE Habilitar interrupciones de PORTB
    BCF INTCON, 2
    BCF INTCON, 0
    
    BANKSEL WPUB
    MOVLW 11000000B
    MOVWF IOCB
    MOVWF WPUB
    
    BANKSEL TMR0
    MOVLW 178
    MOVWF TMR0	    ; Se carga el valor de TMR0
    
    CLRF CONT20MS
    
LOOP:
    INCF PORTB, F

VERIFICACION:
    MOVF CONT20MS, W
    SUBLW 50
    BTFSS STATUS, 2
    GOTO VERIFICACION
    CLRF CONT20MS

    GOTO LOOP
    
;   PRUEBA CON BANDERA    
;    BTFSC bandera1, 0
;    CALL Incremento
;    BTFSC bandera1, 1
;    CALL Decremento
    
; SUBRUTINAS PARA BANDERA DE CONTADOR
;Incremento:
;    INCF PORTA, F
;    CLRF bandera1
;    RETURN
;    
;Decremento:
;    DECF PORTA, F
;    CLRF bandera1
;    RETURN
    
;*******************************************************************************
; FIN DEL CÓDIGO
;******************************************************************************* 
END

