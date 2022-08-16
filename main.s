;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Luis Pablo Carranza
; Compilador: PIC-AS (v2.4), MPLAB X IDE (v6.00)
; Proyecto: Laboratorio 3 Interrupciones
; Hardware PIC16F887
; Creado: 09/08/22
; Última Modificación: 15/08/22
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
 W_TEMP:	; Variable para almacenar W durante interrupciones
    DS 1
 STATUS_TEMP:	; Variable para almacenar STATUS durante interrupciones
    DS 1
 CONT1:		; Variable que se utiliza para controlar 1 display
    DS 1
 CONT2:		; Variable auxiliar para el aumento en el display
    DS 1
 CONT20MS:	; Variable para TMR0
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
 
PUSH:			; Almacenar temporalmente W y STATUS
    MOVWF W_TEMP	
    SWAPF STATUS, W
    MOVWF STATUS_TEMP
    
ISR:
    BTFSC INTCON, 0	; Revisa la bandera de interrupción en puerto B
    GOTO RRBIF		; Si está encendida llama la etiqueta
    BTFSC INTCON, 2	; Revisa la bandera de interrupción en TMR0
    GOTO RTMR0		; si está encendida llama la etiqueta
    GOTO POP

RTMR0:
    BCF INTCON, 2	; Limpia la bandera de interrupción
    BANKSEL TMR0	
    INCF CONT20MS	; Incrementa la variable del TMR0
    MOVLW 179		; Carga el valor de n al TMR0
    MOVWF TMR0		
    GOTO POP
    
RRBIF:
    BANKSEL PORTB
    BTFSS PORTB, 6	; Revisa si se presionó el botón de incremento
    INCF PORTA		; Incrementa el puerto A
    BTFSS PORTB, 7	; Revisa si se presionó el botón de decremento
    DECF PORTA		; Decrementa el peurto A
    BCF INTCON, 0	; Limpia la bandera de interrupción del puerto B
    GOTO POP
    
POP:			    ; Regresar valores de W y de STATUS
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
    MOVLW 11000000B ; El bit 6 y 7 son entradas, el resto salidas
    MOVWF TRISB		
    CLRF TRISA
    CLRF TRISC
    CLRF TRISD	    ; El resto de puertos configurados como salidas
    
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
    CLRF PORTD
    CLRF PORTC
    CLRF PORTE	    ; Iniciar todos los puertos en 0
;    MOVLW 11111111B ; El puerto C inicia en 1 ya que usa ánodo común
;    MOVWF PORTC

    BANKSEL INTCON
    BSF INTCON, 7   ; GIE Habilitar interrupciones globales
    BSF INTCON, 5   ; Habilitar interrupción de TMR0
    BSF INTCON, 3   ; RBIE Habilitar interrupciones de PORTB
    BCF INTCON, 2   ; Bandera T0IF apagada
    BCF INTCON, 0   ; Bandera de interrupción de puerto B apagada
    
    BANKSEL WPUB
    MOVLW 11000000B ; Solo bit 7 y 6 son entradas con pull-up e ITO
    MOVWF IOCB
    MOVWF WPUB
    
    BANKSEL TMR0
    MOVLW 179	    
    MOVWF TMR0	    ; Se carga el valor de TMR0
    
    CLRF CONT20MS
    CLRF CONT1
    CLRF CONT2
    
LOOP:
    INCF PORTB, F   ; Incrementa el contador del TMR0
    GOTO CONTDIS    ; Se dirige a la etiqueta del contador del display

VERIFICACION:
    MOVF CONT20MS, W	; Carga el valor de la variable a W
    SUBLW 50		; Resta el valor a 50
    BTFSS STATUS, 2	; Revisa si el resultado es 0
    GOTO VERIFICACION	; Si no es 0 regresa a verificación
    CLRF CONT20MS	; Si es 0 limpia la variable y vuelve al loop
    GOTO LOOP
    
; ******************************************************************************
; Subrutinas para contador del display
; ******************************************************************************  

CONTDIS:
    BCF STATUS, 2	; Limpia el bit 2 de STATUS
    MOVF PORTB, W	; Carga el valor de PORTB a W
    ANDLW 0x0F		; Realiza un AND para asegurarse que no está fuera del 
			; rango
    SUBLW 10		; Resta el valor a 10
    BTFSC STATUS, 2	; Si el resultado es 0 llama a la subrutina para el otro
			; display
    CALL CONTDIS2	
    MOVF PORTB, W	; Mueve el valor de PORTB a W
    CALL Table		
    MOVWF PORTD		; Carga el valor que regresó la tabla a PORTD
    GOTO VERIFICACION

CONTDIS2:
    CLRF PORTB		; Limpia puerto B 
    BCF STATUS, 2	; Limpia el bit 2 de STATUS
    INCF CONT1, F	; Incrementa la variable para el segundo display
    MOVF CONT1, W	; Mueve el valor de la variable a W
    SUBLW 6		; Le resta el valor a 6
    BTFSC STATUS, 2	; Si el resultado es 0 llama a subrutina LIMPIAR
    CALL LIMPIAR
    MOVF CONT1, W	; Mueve el valor del CONT1 a W
    CALL Table		
;    MOVWF CONT2		; Carga el valor de la tabla a CONT2
;    COMF CONT2, W	; Cátodo común necesita utilizar el complemento
    MOVWF PORTC		; Carga el valor a PORTC
    RETURN
    
LIMPIAR:
    CLRF PORTD
    CLRF CONT1
    CLRF PORTC
    CLRF CONT2	; Limpia todos los puertos y las variables
    RETURN
    
; ******************************************************************************
; Tablas
; ******************************************************************************   
Table:
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0F
    ADDWF PCL
    RETLW 00111111B ; Regresa 0
    RETLW 00000110B ; Regresa 1
    RETLW 01011011B ; Regresa 2
    RETLW 01001111B ; Regresa 3
    RETLW 01100110B ; Regresa 4
    RETLW 01101101B ; Regresa 5
    RETLW 01111101B ; Regresa 6
    RETLW 00000111B ; Regresa 7
    RETLW 01111111B ; Regresa 8
    RETLW 01101111B ; Regresa 9    
    RETLW 01110111B ; Regresa A
    RETLW 01111111B ; Regresa B
    RETLW 00111001B ; Regresa C
    RETLW 00111111B ; Regresa D
    RETLW 01111001B ; Regresa E
    RETLW 01110001B ; Regresa F
    
;*******************************************************************************
; FIN DEL CÓDIGO
;******************************************************************************* 
END

