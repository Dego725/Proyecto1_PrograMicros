;************************************************************  
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Lab1.asm
; Autor  : Diego Alexander Rodriguez Garay
; Proyecto: Proyecto 1 Reloj
; Hardware: ATmega328P
; Creado  : 11/02/2025
;************************************************************  
;-----------------------------------------------------------------------
; Definición de variables y registros
.include "M328PDEF.inc"  ; Incluir archivo de definiciones para el ATmega328P
.def ledstilt = R0       ; Definir R0 como "ledstilt" (registro para el estado de los LEDs)
.def displaytilt = R1    ; Definir R1 como "displaytilt" (registro para el estado de la visualización)
.def displaytilt2 = R2   ; Definir R2 como "displaytilt2" (registro para el segundo estado de visualización)
.def ledsmodo = R3       ; Definir R3 como "ledsmodo" (registro para el modo de LEDs)
.def counter1f = R4      ; Definir R4 como "counter1f" (contador de visualización de segundos)
.def counter2f = R5      ; Definir R5 como "counter2f" (segundo contador de visualización)
.def counter3f = R6      ; Definir R6 como "counter3f" (tercer contador de visualización)
.def counter4f = R7      ; Definir R7 como "counter4f" (cuarto contador de visualización)
.def counter1h = R8      ; Definir R8 como "counter1h" (contador alto de visualización)
.def counter2h = R9      ; Definir R9 como "counter2h" (segundo contador alto de visualización)
.def counter3h = R10     ; Definir R10 como "counter3h" (tercer contador alto de visualización)
.def counter4h = R11     ; Definir R11 como "counter4h" (cuarto contador alto de visualización)
.def counter1a = R12     ; Definir R12 como "counter1a" (contador de ajuste)
.def counter2a = R13     ; Definir R13 como "counter2a" (segundo contador de ajuste)
.def counter3a = R14     ; Definir R14 como "counter3a" (tercer contador de ajuste)
.def counter4a = R15     ; Definir R15 como "counter4a" (cuarto contador de ajuste)
.def seldisplay = R31     ; Definir R31 como "seldisplay" (registro para seleccionar la visualización)
.def modo = R25          ; Definir R25 como "modo" (registro para el modo de operación)
.def counter = R16       ; Definir R16 como "counter" (contador de interrupciones de Timer0)
.def counter1 = R17      ; Definir R17 como "counter1" (contador principal de visualización)
.def counter2 = R22      ; Definir R22 como "counter2" (segundo contador)
.def counter3 = R23      ; Definir R23 como "counter3" (tercer contador)
.def counter4 = R24      ; Definir R24 como "counter4" (cuarto contador)
.def temp = R18          ; Definir R18 como "temp" (registro temporal para operaciones intermedias)
.def alarm = R19         ; Definir R19 como "alarm" (bandera para el estado de la alarma)
;.def dectrue = R20      ; Definir R20 como "dectrue" (bandera para decremento)
.def switch = R21        ; Definir R21 como "switch" (registro para controlar la visualización de datos)
.equ T1VALUEH = 0xFE    ; Definir T1VALUEH como 0xFE (valor alto para Timer1)
.equ T1VALUEL = 0x17    ; Definir T1VALUEL como 0x17 (valor bajo para Timer1)

;-----------------------------------------------------------------------
; Configuración de vectores de interrupción
.org 0x0000              ; Establecer el origen del programa en la dirección 0x0000 (vector de reset)
    RJMP start           ; Saltar a la etiqueta "start"
.org PCI1addr            ; Dirección del vector de interrupción de cambio de pines (PCINT1)
    JMP ISR_INT0         ; Saltar a la rutina de interrupción ISR_INT0
;.org OVF2addr           ; Dirección del vector de interrupción por desbordamiento de Timer2
    ;JMP displays         ; Saltar a la rutina de manejo del contador principal
.org OVF1addr            ; Dirección del vector de interrupción por desbordamiento de Timer1
    JMP loop_cuenta      ; Saltar a la rutina de manejo del contador principal
.org OVF0addr            ; Dirección del vector de interrupción por desbordamiento de Timer0
    JMP displays          ; Saltar a la rutina de manejo del contador principal
;-----------------------------------------------------------------------
; Inicio del programa
start:
    ; Inicializar el stack pointer
    LDI R16, LOW(RAMEND)  ; Cargar el byte bajo de la dirección final de la RAM en R16
    OUT SPL, R16          ; Escribir en SPL (Stack Pointer Low)
    LDI R16, HIGH(RAMEND) ; Cargar el byte alto de la dirección final de la RAM en R16
    OUT SPH, R16          ; Escribir en SPH (Stack Pointer High)

;-----------------------------------------------------------------------
; Configuración inicial del microcontrolador
main:
    CLI                   ; Deshabilitar interrupciones globales mientras se configura

    ; Configurar pines de salida (PB0-PB5)
    LDI temp, 0x3F       ; Configurar PB0-PB5 como salidas
    OUT DDRB, temp       ; Escribir configuración en DDRB

    ; Configurar pines de salida (PC0-PC1)
    SBI DDRC, PC5        ; Configurar PC5 como salida
    SBI DDRC, PC0        ; Configurar PC0 como salida

    ; Configurar pines de salida (PD0-PD7)
    LDI temp, 0xFF       ; Configurar PD0-PD7 como salidas
    OUT DDRD, temp       ; Escribir configuración en DDRD

    ; Configurar pines de entrada en PC
    CBI DDRC, PC1        ; Configurar PC1 como entrada (Botón Incremento)
    CBI DDRC, PC2        ; Configurar PC2 como entrada (Botón Decremento)
    CBI DDRC, PC3        ; Configurar PC3 como entrada (Botón Decremento)
    CBI DDRC, PC4        ; Configurar PC4 como entrada (Botón Incremento)

    ; Habilitar resistencias de pull-up en los botones
    SBI PORTC, PC1       ; Activar resistencia de pull-up en PC1
    SBI PORTC, PC2       ; Activar resistencia de pull-up en PC2
    SBI PORTC, PC3       ; Activar resistencia de pull-up en PC3
    SBI PORTC, PC4       ; Activar resistencia de pull-up en PC4

    ; Inicializar contadores
    LDI counter1, 0x00   ; Inicializar counter1 con 0x00
    OUT PORTB, counter1   ; Mostrar counter1 en PB0-PB4

    LDI temp, (1 << CLKPCE) ; Configurar el prescaler global
    STS CLKPR, temp      ; Aplicar configuración del prescaler
    LDI temp, 0b00000100 ; Configurar el prescaler a 4
    STS CLKPR, temp      ; Aplicar configuración del prescaler

    ; Configurar Timer0 con prescaler
    LDI temp, (1<<CS01) | (1<<CS00) ; Configurar prescaler del Timer0 a 64
    OUT TCCR0B, temp     ; Aplicar configuración en TCCR0B
    LDI temp, 230        ; Cargar valor inicial del Timer0
    OUT TCNT0, temp      ; Escribir en TCNT0

    ; Habilitar interrupciones del Timer0
    LDI temp, (1 << TOIE0) ; Habilitar interrupción por desbordamiento
    STS TIMSK0, temp     ; Configurar en TIMSK0
	
    ; Configurar Timer1 con prescaler
    LDI temp, (1<<CS12) | (1<<CS10) ; Configurar prescaler del Timer1 a 1024
    STS TCCR1B, temp     ; Aplicar configuración en TCCR1B
    LDI temp, T1VALUEH   ; Cargar valor inicial del Timer1 (alto)
    STS TCNT1H, temp     ; Escribir en TCNT1H
    LDI temp, T1VALUEL   ; Cargar valor inicial del Timer1 (bajo)
    STS TCNT1L, temp     ; Escribir en TCNT1L

    ; Habilitar interrupciones del Timer1
    LDI temp, (1 << TOIE1) ; Habilitar interrupción por desbordamiento
    STS TIMSK1, temp     ; Configurar en TIMSK1

    ; Habilitar interrupciones de cambio de estado en PC2 y PC3
    LDI temp, (1<<PCIE1) ; Habilitar interrupciones en PCINT[14:8]
    STS PCICR, temp
    LDI temp, 0b00011000 ; Habilitar interrupciones en PC1, PC2, PC3 y PC4
    STS PCMSK1, temp

    ; Inicializar los contadores en memoria
    LDI XH, 0x01         ; Cargar el byte alto de la dirección de memoria en XH (0x0100)
    LDI XL, 0x00         ; Cargar el byte bajo de la dirección de memoria en XL (0x0100)
    LDI temp, 0x7E       ; Cargar el valor 0x7E en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x30       ; Cargar el valor 0x30 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x6D       ; Cargar el valor 0x6D en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x79       ; Cargar el valor 0x79 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x33       ; Cargar el valor 0x33 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x5B       ; Cargar el valor 0x5B en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x5F       ; Cargar el valor 0x5F en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x70       ; Cargar el valor 0x70 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x7F       ; Cargar el valor 0x7F en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x7B       ; Cargar el valor 0x7B en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x77       ; Cargar el valor 0x77 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x1F       ; Cargar el valor 0x1F en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x4E       ; Cargar el valor 0x4E en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x3D       ; Cargar el valor 0x3D en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x4F       ; Cargar el valor 0x4F en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0x47       ; Cargar el valor 0x47 en temp
    ST X, temp           ; Almacenar temp en la dirección apuntada por X
    LDI XH, 0x02         ; Cargar el byte alto de la dirección de memoria en XH (0x0100)
    LDI XL, 0x01         ; Cargar el byte bajo de la dirección de memoria en XL (0x0100)
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 8          ; Cargar el valor 8 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0          ; Cargar el valor 0 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0          ; Cargar el valor 0 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0          ; Cargar el valor 0 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0          ; Cargar el valor 0 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0          ; Cargar el valor 0 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 0          ; Cargar el valor 0 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 1          ; Cargar el valor 1 en temp
    ST X, temp           ; Almacenar temp en la dirección apuntada por X
    LDI XH, 0x03         ; Cargar el byte alto de la dirección de memoria en XH (0x0100)
    LDI XL, 0x01         ; Cargar el byte bajo de la dirección de memoria en XL (0x0100)
    LDI temp, 3          ; Cargar el valor 3 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 2          ; Cargar el valor 2 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 3          ; Cargar el valor 3 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 3          ; Cargar el valor 3 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 3          ; Cargar el valor 3 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 3          ; Cargar el valor 3 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 3          ; Cargar el valor 3 en temp
    ST X+, temp          ; Almacenar temp en la dirección apuntada por X y luego incrementar X
    LDI temp, 3          ; Cargar el valor 3 en temp
    ST X, temp           ; Almacenar temp en la dirección apuntada por X
    LDI XH, 0x01         ; Cargar el byte alto de la dirección de memoria en XH (0x0100)
    LDI XL, 0x00         ; Cargar el byte bajo de la dirección de memoria en XL (0x0100)
	
    LDI counter1, 0x00   ; Inicializar counter1 con 0x00
    LDI counter2, 0x00   ; Inicializar counter2 con 0x00
    LDI counter3, 0x00   ; Inicializar counter3 con 0x00
    LDI counter4, 0x00   ; Inicializar counter4 con 0x00
    CLR counter1h        ; Limpiar el registro counter1h
    CLR counter2h        ; Limpiar el registro counter2h
    CLR counter3h        ; Limpiar el registro counter3h
    CLR counter4h        ; Limpiar el registro counter4h
    CLR counter1a        ; Limpiar el registro counter1a
    CLR counter2a        ; Limpiar el registro counter2a
    CLR counter3a        ; Limpiar el registro counter3a
    CLR counter4a        ; Limpiar el registro counter4a
    CLR alarm             ; Limpiar la bandera de alarma
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    CLR counter2f        ; Limpiar el registro counter2f
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter3f, temp  ; Mover el valor de temp a counter3f
    CLR counter4f        ; Limpiar el registro counter4f
    LDI switch, 0x01     ; Inicializar switch con 0x01
    LDI modo, 1          ; Inicializar modo con 1
    LDI seldisplay, 4    ; Inicializar seldisplay con 4
    CLR displaytilt       ; Limpiar el registro displaytilt
    LDI temp, (1<<PB5)   ; Cargar el valor para el modo de LEDs
    MOV ledsmodo, temp    ; Mover el valor de temp a ledsmodo

    SEI                   ; Habilitar interrupciones globales

;-----------------------------------------------------------------------
; Bucle principal
main_loop:
    CPI modo, 1          ; Comparar modo con 1
    BREQ modo_mostrar     ; Si es igual, saltar a modo_mostrar
    CPI modo, 2          ; Comparar modo con 2
    BREQ modo_mostrar     ; Si es igual, saltar a modo_mostrar
    CPI modo, 3          ; Comparar modo con 3
    BREQ modo_confi      ; Si es igual, saltar a modo_confi
    CPI modo, 4          ; Comparar modo con 4
    BREQ modo_confi_fecha ; Si es igual, saltar a modo_confi_fecha
    CPI modo, 5          ; Comparar modo con 5
    BREQ modo_confi_alarm ; Si es igual, saltar a modo_confi_alarm
    CPI modo, 6          ; Comparar modo con 6
    BREQ modo_alarm      ; Si es igual, saltar a modo_alarm

modo_mostrar:
    CPI counter, 120     ; Comparar counter con 120
    BRNE main_loop       ; Si no es 120, continuar en el bucle
    CLR counter          ; Reiniciar counter
    RCALL increment1     ; Llamar a la subrutina de incremento
    RJMP main_loop       ; Repetir el bucle

modo_confi:
    SBIS PINC, PC1      ; Si PC1 está en bajo (presionado)
    RCALL check_inc      ; Llamar a la subrutina de incremento
    SBIS PINC, PC2      ; Si PC2 está en bajo (presionado)
    RCALL check_dec      ; Llamar a la subrutina de decremento
    RJMP main_loop       ; Volver al bucle principal

modo_confi_fecha:
    SBIS PINC, PC1      ; Si PC1 está en bajo (presionado)
    RCALL check_inc_fecha ; Llamar a la subrutina de incremento de fecha
    SBIS PINC, PC2      ; Si PC2 está en bajo (presionado)
    RCALL check_dec_fecha ; Llamar a la subrutina de decremento de fecha
    RJMP main_loop       ; Volver al bucle principal

modo_confi_alarm:
    SBIS PINC, PC1      ; Si PC1 está en bajo (presionado)
    RCALL check_inc_alarm ; Llamar a la subrutina de incremento de alarma
    SBIS PINC, PC2      ; Si PC2 está en bajo (presionado)
    RCALL check_dec_alarm ; Llamar a la subrutina de decremento de alarma
    RJMP main_loop       ; Volver al bucle principal

modo_alarm:
    SBIS PINC, PC1      ; Si PC1 está en bajo (presionado)
    RCALL alarm_onoff    ; Llamar a la subrutina para activar/desactivar la alarma
    RJMP main_loop       ; Volver al bucle principal

;-----------------------------------------------------------------------
; Rutina de interrupción por desbordamiento de Timer0
loop_cuenta:
    IN temp, SREG       ; Guardar el estado del registro de estado
    PUSH temp           ; Almacenar el estado en la pila
    CPI modo, 1         ; Comparar modo con 1
    BREQ loop_cuenta1   ; Si es igual, saltar a loop_cuenta1
    CPI modo, 2         ; Comparar modo con 2
    BREQ loop_cuenta1   ; Si es igual, saltar a loop_cuenta1
    CPI modo, 3         ; Comparar modo con 3
    BREQ mandar_loop_cuenta3 ; Si es igual, saltar a mandar_loop_cuenta3
    CPI modo, 4         ; Comparar modo con 4
    BREQ mandar_loop_cuenta3 ; Si es igual, saltar a mandar_loop_cuenta3
    CPI modo, 5         ; Comparar modo con 5
    BREQ mandar_loop_cuenta3 ; Si es igual, saltar a mandar_loop_cuenta3
    CPI modo, 6         ; Comparar modo con 6
    BREQ loop_cuenta1   ; Si es igual, saltar a loop_cuenta1

mandar_loop_cuenta3:
    JMP loop_cuenta3    ; Saltar a loop_cuenta3

loop_cuenta1:
    SBI TIFR1, TOV1      ; Limpiar la bandera de desbordamiento del Timer1
    LDI temp, T1VALUEH   ; Cargar valor alto inicial del Timer1
    STS TCNT1H, temp     ; Escribir en TCNT1H
    LDI temp, T1VALUEL   ; Cargar valor bajo inicial del Timer1
    STS TCNT1L, temp     ; Escribir en TCNT1L
    IN temp, SREG        ; Recuperar el estado del registro de estado
    PUSH temp            ; Almacenar el estado en la pila
    INC counter          ; Incrementar el contador
    LDI temp, (1 << PD7) ; Cargar la máscara para PD7
    MOV ledstilt, temp   ; Mover la máscara a ledstilt
    IN temp, PORTD      ; Leer el estado actual de PORTD
    EOR temp, ledstilt   ; Aplicar XOR para alternar el bit PD7
    OUT PORTD, temp      ; Escribir el nuevo valor en PORTD
    ANDI temp, 0x80      ; Aislar el bit más significativo
    MOV ledstilt, temp   ; Mover el resultado a ledstilt
    CP counter4a, counter4h ; Comparar counter4a con counter4h
    BREQ check_sound1    ; Si son iguales, saltar a check_sound1
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

check_sound1:
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    IN temp, SREG        ; Leer el estado del registro de estado
    PUSH temp            ; Almacenar el estado en la pila
    CP counter3a, counter3h ; Comparar counter3a con counter3h
    BREQ check_sound2    ; Si son iguales, saltar a check_sound2
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

check_sound2:
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    IN temp, SREG        ; Leer el estado del registro de estado
    PUSH temp            ; Almacenar el estado en la pila
    CP counter2a, counter2h ; Comparar counter2a con counter2h
    BREQ check_sound3    ; Si son iguales, saltar a check_sound3
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

check_sound3:
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    IN temp, SREG        ; Leer el estado del registro de estado
    PUSH temp            ; Almacenar el estado en la pila
    CP counter1a, counter1h ; Comparar counter1a con counter1h
    BREQ check_sound4    ; Si son iguales, saltar a check_sound4
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

check_sound4:
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    IN temp, SREG        ; Leer el estado del registro de estado
    PUSH temp            ; Almacenar el estado en la pila
    LDI temp, 0          ; Cargar el valor 0 en temp
    CPSE alarm, temp     ; Comparar alarm con 0, si son iguales, saltar
    SBI PORTC, PB5       ; Activar el sonido en PB5
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

loop_cuenta3:
    SBI TIFR1, TOV1      ; Limpiar la bandera de desbordamiento del Timer1
    LDI temp, T1VALUEH   ; Cargar valor alto inicial del Timer1
    STS TCNT1H, temp     ; Escribir en TCNT1H
    LDI temp, T1VALUEL   ; Cargar valor bajo inicial del Timer1
    STS TCNT1L, temp     ; Escribir en TCNT1L
    IN temp, SREG        ; Leer el estado del registro de estado
    PUSH temp            ; Almacenar el estado en la pila
    CPI seldisplay, 1    ; Comparar seldisplay con 1
    BREQ tiltcounter1    ; Si es igual, saltar a tiltcounter1
    CPI seldisplay, 2    ; Comparar seldisplay con 2
    BREQ tiltcounter2    ; Si es igual, saltar a tiltcounter2
    CPI seldisplay, 3    ; Comparar seldisplay con 3
    BREQ tiltcounter3    ; Si es igual, saltar a tiltcounter3
    CPI seldisplay, 4    ; Comparar seldisplay con 4
    BREQ tiltcounter4    ; Si es igual, saltar a tiltcounter4
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

tiltcounter1:
    LDI temp, 0x01       ; Cargar la máscara para el bit 0 (PD0)
    EOR displaytilt, temp ; Aplicar XOR para alternar el bit correspondiente en displaytilt
    ;OUT PORTB, temp      ; Escribir el nuevo valor en PORTB (descomentado si se necesita)
    LDI temp, 0x01       ; Cargar la máscara para el bit 0
    AND displaytilt, temp ; Aislar el bit 0 de displaytilt
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

tiltcounter2:
    LDI temp, 0x02       ; Cargar la máscara para el bit 1 (PD1)
    EOR displaytilt, temp ; Aplicar XOR para alternar el bit correspondiente en displaytilt
    ;OUT PORTB, temp      ; Escribir el nuevo valor en PORTB (descomentado si se necesita)
    LDI temp, 0x02       ; Cargar la máscara para el bit 1
    AND displaytilt, temp ; Aislar el bit 1 de displaytilt
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

tiltcounter3:
    LDI temp, 0x04       ; Cargar la máscara para el bit 2 (PD2)
    EOR displaytilt, temp ; Aplicar XOR para alternar el bit correspondiente en displaytilt
    ;OUT PORTB, temp      ; Escribir el nuevo valor en PORTB (descomentado si se necesita)
    LDI temp, 0x04       ; Cargar la máscara para el bit 2
    AND displaytilt, temp ; Aislar el bit 2 de displaytilt
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

tiltcounter4:
    LDI temp, 0x08       ; Cargar la máscara para el bit 3 (PD3)
    EOR displaytilt, temp ; Aplicar XOR para alternar el bit correspondiente en displaytilt
    ;OUT PORTB, temp      ; Escribir el nuevo valor en PORTB (descomentado si se necesita)
    LDI temp, 0x08       ; Cargar la máscara para el bit 3
    AND displaytilt, temp ; Aislar el bit 3 de displaytilt
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RJMP exit_loop_cuenta3 ; Retornar de la interrupción

exit_loop_cuenta3:
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RETI                  ; Retornar de la interrupción

displays:
    SBI TIFR0, TOV0      ; Limpiar la bandera de desbordamiento del Timer0
    LDI temp, 230        ; Recargar Timer0 con un valor inicial
    OUT TCNT0, temp      ; Escribir el valor en TCNT0
    IN temp, SREG        ; Leer el estado del registro de estado
    PUSH temp            ; Almacenar el estado en la pila
    CPI switch, 1        ; Comparar switch con 1
    BREQ print1          ; Si es igual, saltar a print1
    CPI switch, 2        ; Comparar switch con 2
    BREQ print2          ; Si es igual, saltar a print2
    CPI switch, 3        ; Comparar switch con 3
    BREQ print3          ; Si es igual, saltar a print3
    CPI switch, 4        ; Comparar switch con 4
    BREQ print4          ; Si es igual, saltar a print4

print1:
    SBRC displaytilt, PC0 ; Si el bit PC0 de displaytilt está en 0, continuar
    CLR displaytilt2      ; Limpiar displaytilt2
    LDI temp, 0x01       ; Cargar la máscara para el bit 0
    ;AND displaytilt, temp ; (Descomentado si se necesita)
    AND temp, displaytilt2 ; Aislar el bit 0 de displaytilt2
    OR temp, ledsmodo    ; Combinar con ledsmodo
    OUT PORTB, temp      ; Escribir el nuevo valor en PORTB
    MOV XL, counter1     ; Mover el valor de counter1 a XL
    LD temp, X           ; Cargar el valor apuntado por X en temp
    OR temp, ledstilt    ; Combinar con ledstilt
    OUT PORTD, temp      ; Escribir el nuevo valor en PORTD
    LDI switch, 2        ; Cambiar el switch a 2
    LDI temp, 0x0F       ; Cargar el valor 0x0F en temp
    MOV displaytilt2, temp ; Mover el valor a displaytilt2
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RETI                  ; Retornar de la interrupción

print2:
    SBRC displaytilt, PC1 ; Si el bit PC1 de displaytilt está en 0, continuar
    CLR displaytilt2      ; Limpiar displaytilt2
    LDI temp, 0x02       ; Cargar la máscara para el bit 1
    ;AND displaytilt, temp ; (Descomentado si se necesita)
    AND temp, displaytilt2 ; Aislar el bit 1 de displaytilt2
    OR temp, ledsmodo    ; Combinar con ledsmodo
    OUT PORTB, temp      ; Escribir el nuevo valor en PORTB
    MOV XL, counter2     ; Mover el valor de counter2 a XL
    LD temp, X           ; Cargar el valor apuntado por X en temp
    OR temp, ledstilt    ; Combinar con ledstilt
    OUT PORTD, temp      ; Escribir el nuevo valor en PORTD
    LDI switch, 3        ; Cambiar el switch a 3
    LDI temp, 0x0F       ; Cargar el valor 0x0F en temp
    MOV displaytilt2, temp ; Mover el valor a displaytilt2
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RETI                  ; Retornar de la interrupción

print3:
    SBRC displaytilt, PC2 ; Si el bit PC2 de displaytilt está en 0, continuar
    CLR displaytilt2      ; Limpiar displaytilt2
    LDI temp, 0x04       ; Cargar la máscara para el bit 2
    ;AND displaytilt, temp ; (Descomentado si se necesita)
    AND temp, displaytilt2 ; Aislar el bit 2 de displaytilt2
    OR temp, ledsmodo    ; Combinar con ledsmodo
    OUT PORTB, temp      ; Escribir el nuevo valor en PORTB
    MOV XL, counter3     ; Mover el valor de counter3 a XL
    CBI PORTB, PB3      ; Limpiar el bit PB3 en PORTB
    LD temp, X           ; Cargar el valor apuntado por X en temp
    OR temp, ledstilt    ; Combinar con ledstilt
    OUT PORTD, temp      ; Escribir el nuevo valor en PORTD
    LDI switch, 4        ; Cambiar el switch a 4
    LDI temp, 0x0F       ; Cargar el valor 0x0F en temp
    MOV displaytilt2, temp ; Mover el valor a displaytilt2
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RETI                  ; Retornar de la interrupción

print4:
    SBRC displaytilt, PC3 ; Si el bit PC3 de displaytilt está en 0, continuar
    CLR displaytilt2      ; Limpiar displaytilt2
    LDI temp, 0x08       ; Cargar la máscara para el bit 3
    ;AND displaytilt, temp ; (Descomentado si se necesita)
    AND temp, displaytilt2 ; Aislar el bit 3 de displaytilt2
    OR temp, ledsmodo    ; Combinar con ledsmodo
    OUT PORTB, temp      ; Escribir el nuevo valor en PORTB
    MOV XL, counter4     ; Mover el valor de counter4 a XL
    LD temp, X           ; Cargar el valor apuntado por X en temp
    OR temp, ledstilt    ; Combinar con ledstilt
    OUT PORTD, temp      ; Escribir el nuevo valor en PORTD
    LDI switch, 1        ; Cambiar el switch a 1
    LDI temp, 0x0F       ; Cargar el valor 0x0F en temp
    MOV displaytilt2, temp ; Mover el valor a displaytilt2
    POP temp             ; Recuperar el estado del registro de estado
    OUT SREG, temp       ; Restaurar el estado del registro de estado
    RETI                  ; Retornar de la interrupción

check_inc:
    CPI seldisplay, 1    ; Comparar seldisplay con 1
    BREQ inccounter1     ; Si es igual, saltar a inccounter1
    CPI seldisplay, 2    ; Comparar seldisplay con 2
    BREQ inccounter2     ; Si es igual, saltar a inccounter2
    CPI seldisplay, 3    ; Comparar seldisplay con 3
    BREQ inccounter3     ; Si es igual, saltar a inccounter3
    CPI seldisplay, 4    ; Comparar seldisplay con 4
    BREQ inccounter4     ; Si es igual, saltar a inccounter4

inccounter1:
    INC counter1h        ; Incrementar el contador alto 1
    LDI temp, 10         ; Cargar el valor 10 en temp
    CP counter1h, temp   ; Comparar counter1h con 10
    BRNE wait_increment   ; Si no es igual, saltar a wait_increment
    CLR counter1h        ; Reiniciar counter1h a 0
    RJMP wait_increment   ; Saltar a wait_increment

inccounter2:
    INC counter2h        ; Incrementar el contador alto 2
    LDI temp, 6          ; Cargar el valor 6 en temp
    CP counter2h, temp   ; Comparar counter2h con 6
    BRNE wait_increment   ; Si no es igual, saltar a wait_increment
    CLR counter2h        ; Reiniciar counter2h a 0
    RJMP wait_increment   ; Saltar a wait_increment

inccounter3:
    LDI temp, 2          ; Cargar el valor 2 en temp
    CP counter4h, temp   ; Comparar counter4h con 2
    BREQ top_increment    ; Si son iguales, saltar a top_increment
    INC counter3h        ; Incrementar el contador alto 3
    LDI temp, 10         ; Cargar el valor 10 en temp
    CP counter3h, temp   ; Comparar counter3h con 10
    BRNE wait_increment   ; Si no es igual, saltar a wait_increment
    CLR counter3h        ; Reiniciar counter3h a 0
    RJMP wait_increment   ; Saltar a wait_increment

inccounter4:
    INC counter4h        ; Incrementar el contador alto 4
    LDI temp, 1          ; Cargar el valor 1 en temp
    CPSE counter4h, temp ; Si counter4h es igual a 1, saltar
    CLR counter3h        ; Reiniciar counter3h a 0
    LDI temp, 3          ; Cargar el valor 3 en temp
    CP counter4h, temp   ; Comparar counter4h con 3
    BRNE wait_increment   ; Si no es igual, saltar a wait_increment
    CLR counter4h        ; Reiniciar counter4h a 0
    CLR counter3h        ; Reiniciar counter3h a 0
    RJMP wait_increment   ; Saltar a wait_increment

top_increment:
    INC counter3h        ; Incrementar el contador alto 3
    LDI temp, 4          ; Cargar el valor 4 en temp
    CP counter3h, temp   ; Comparar counter3h con 4
    BRNE wait_increment   ; Si no es igual, saltar a wait_increment
    CLR counter3h        ; Reiniciar counter3h a 0
    RJMP wait_increment   ; Saltar a wait_increment

; Esperar a que se suelte el botón
wait_increment:
    SBIS PINC, PC1       ; Esperar hasta que PC1 esté en alto (botón liberado)
    RJMP wait_increment   ; Repetir el bucle si el botón no está liberado
    MOV counter1, counter1h ; Mover el valor de counter1h a counter1
    MOV counter2, counter2h ; Mover el valor de counter2h a counter2
    MOV counter3, counter3h ; Mover el valor de counter3h a counter3
    MOV counter4, counter4h ; Mover el valor de counter4h a counter4
    RET                   ; Retornar

;------------------------------------------------------------------
check_dec:
    CPI seldisplay, 1    ; Comparar seldisplay con 1
    BREQ deccounter1     ; Si es igual, saltar a deccounter1
    CPI seldisplay, 2    ; Comparar seldisplay con 2
    BREQ deccounter2     ; Si es igual, saltar a deccounter2
    CPI seldisplay, 3    ; Comparar seldisplay con 3
    BREQ deccounter3     ; Si es igual, saltar a deccounter3
    CPI seldisplay, 4    ; Comparar seldisplay con 4
    BREQ deccounter4     ; Si es igual, saltar a deccounter4

deccounter1:
    DEC counter1h        ; Decrementar el contador alto 1
    MOV temp, counter1h  ; Mover el valor de counter1h a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement   ; Si no es igual, saltar a wait_decrement
    LDI temp, 0x09      ; Cargar el valor 9 en temp
    MOV counter1h, temp  ; Mover el valor de temp a counter1h
    RJMP wait_decrement   ; Saltar a wait_decrement

deccounter2:
    DEC counter2h        ; Decrementar el contador alto 2
    MOV temp, counter2h  ; Mover el valor de counter2h a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement   ; Si no es igual, saltar a wait_decrement
    LDI temp, 0x05      ; Cargar el valor 5 en temp
    MOV counter2h, temp  ; Mover el valor de temp a counter2h
    RJMP wait_decrement   ; Saltar a wait_decrement

deccounter3:
    LDI temp, 2          ; Cargar el valor 2 en temp
    CP counter4h, temp   ; Comparar counter4h con 2
    BREQ top_decrement    ; Si son iguales, saltar a top_decrement
    DEC counter3h        ; Decrementar el contador alto 3
    MOV temp, counter3h  ; Mover el valor de counter3h a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement   ; Si no es igual, saltar a wait_decrement
    LDI temp, 0x09      ; Cargar el valor 9 en temp
    MOV counter3h, temp  ; Mover el valor de temp a counter3h
    RJMP wait_decrement   ; Saltar a wait_decrement

deccounter4:
    DEC counter4h        ; Decrementar el contador alto 4
    LDI temp, 1          ; Cargar el valor 1 en temp
    CPSE counter4h, temp ; Si counter4h es igual a 1, saltar
    CLR counter3h        ; Reiniciar counter3h a 0
    MOV temp, counter4h  ; Mover el valor de counter4h a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement   ; Si no es igual, saltar a wait_decrement
    LDI temp, 0x02      ; Cargar el valor 2 en temp
    MOV counter4h, temp  ; Mover el valor de temp a counter4h
    CLR counter3h        ; Reiniciar counter3h a 0
    RJMP wait_decrement   ; Saltar a wait_decrement

top_decrement:
    DEC counter3h        ; Decrementar el contador alto 3
    MOV temp, counter3h  ; Mover el valor de counter3h a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement   ; Si no es igual, saltar a wait_decrement
    LDI temp, 0x03      ; Cargar el valor 3 en temp
    MOV counter3h, temp  ; Mover el valor de temp a counter3h
    RJMP wait_decrement   ; Saltar a wait_decrement

; Esperar a que se suelte el botón
wait_decrement:
    SBIS PINC, PC2       ; Esperar hasta que PC2 esté en alto (botón liberado)
    RJMP wait_decrement   ; Repetir el bucle si el botón no está liberado
    MOV counter1, counter1h ; Mover el valor de counter1h a counter1
    MOV counter2, counter2h ; Mover el valor de counter2h a counter2
    MOV counter3, counter3h ; Mover el valor de counter3h a counter3
    MOV counter4, counter4h ; Mover el valor de counter4h a counter4
    RET                   ; Retornar

check_inc_fecha:
    CPI seldisplay, 1    ; Comparar seldisplay con 1
    BREQ inccounter1_fecha ; Si es igual, saltar a inccounter1_fecha
    CPI seldisplay, 2    ; Comparar seldisplay con 2
    BREQ inccounter2_fecha ; Si es igual, saltar a inccounter2_fecha
    CPI seldisplay, 3    ; Comparar seldisplay con 3
    BREQ inccounter3_fecha ; Si es igual, saltar a inccounter3_fecha
    CPI seldisplay, 4    ; Comparar seldisplay con 4
    BREQ inccounter4_fecha ; Si es igual, saltar a inccounter4_fecha

inccounter1_fecha:
    LDI temp, 3          ; Cargar el valor 3 en temp
    CP counter2f, temp   ; Comparar counter2f con 3
    BREQ top_increment_fecha ; Si son iguales, saltar a top_increment_fecha
    INC counter1f        ; Incrementar el contador de fecha 1
    LDI temp, 10         ; Cargar el valor 10 en temp
    CP counter1f, temp   ; Comparar counter1f con 10
    BRNE wait_increment_fecha ; Si no es igual, saltar a wait_increment_fecha
    CLR counter1f        ; Reiniciar counter1f a 0
    RJMP wait_increment_fecha ; Saltar a wait_increment_fecha

inccounter2_fecha:
    INC counter2f        ; Incrementar el contador de fecha 2
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    LDI temp, 4          ; Cargar el valor 4 en temp
    CP counter2f, temp   ; Comparar counter2f con 4
    BRNE wait_increment_fecha ; Si no es igual, saltar a wait_increment_fecha
    CLR counter2f        ; Reiniciar counter2f a 0
    RJMP wait_increment_fecha ; Saltar a wait_increment_fecha

inccounter3_fecha:
    LDI temp, 1          ; Cargar el valor 1 en temp
    CP counter4f, temp   ; Comparar counter4f con 1
    BREQ top_increment_fecha2 ; Si son iguales, saltar a top_increment_fecha2
    INC counter3f        ; Incrementar el contador de fecha 3
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    CLR counter2f        ; Reiniciar counter2f a 0
    LDI temp, 10         ; Cargar el valor 10 en temp
    CP counter3f, temp   ; Comparar counter3f con 10
    BRNE wait_increment_fecha ; Si no es igual, saltar a wait_increment_fecha
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter3f, temp  ; Mover el valor de temp a counter3f
    RJMP wait_increment_fecha ; Saltar a wait_increment_fecha

inccounter4_fecha:
    INC counter4f        ; Incrementar el contador de fecha 4
    LDI temp, 0          ; Cargar el valor 0 en temp
    CPSE counter4f, temp ; Si counter4f es igual a 0, saltar
    CLR counter3f        ; Reiniciar counter3f a 0
    LDI temp, 2          ; Cargar el valor 2 en temp
    CP counter4f, temp   ; Comparar counter4f con 2
    BRNE wait_increment_fecha ; Si no es igual, saltar a wait_increment_fecha
    CLR counter4f        ; Reiniciar counter4f a 0
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter3f, temp  ; Mover el valor de temp a counter3f
    RJMP wait_increment_fecha ; Saltar a wait_increment_fecha

top_increment_fecha:
    INC counter1f        ; Incrementar el contador de fecha 1
    LDI temp, 2          ; Cargar el valor 2 en temp
    CP counter1f, temp   ; Comparar counter1f con 2
    BRNE wait_increment_fecha ; Si no es igual, saltar a wait_increment_fecha
    CLR counter1f        ; Reiniciar counter1f a 0
    RJMP wait_increment_fecha ; Saltar a wait_increment_fecha

top_increment_fecha2:
    INC counter3f        ; Incrementar el contador de fecha 3
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    CLR counter2f        ; Reiniciar counter2f a 0
    LDI temp, 3          ; Cargar el valor 3 en temp
    CP counter3f, temp   ; Comparar counter3f con 3
    BRNE wait_increment_fecha ; Si no es igual, saltar a wait_increment_fecha
    CLR counter3f        ; Reiniciar counter3f a 0
    RJMP wait_increment_fecha ; Saltar a wait_increment_fecha

wait_increment_fecha:
    SBIS PINC, PC1       ; Esperar hasta que PC1 esté en alto (botón liberado)
    RJMP wait_increment_fecha ; Repetir el bucle si el botón no está liberado
    MOV counter1, counter1f ; Mover el valor de counter1f a counter1
    MOV counter2, counter2f ; Mover el valor de counter2f a counter2
    MOV counter3, counter3f ; Mover el valor de counter3f a counter3
    MOV counter4, counter4f ; Mover el valor de counter4f a counter4
    RET                   ; Retornar

;---------------------------------------------------------------------

check_dec_fecha:
    CPI seldisplay, 1    ; Comparar seldisplay con 1
    BREQ deccounter1_fecha ; Si es igual, saltar a deccounter1_fecha
    CPI seldisplay, 2    ; Comparar seldisplay con 2
    BREQ deccounter2_fecha ; Si es igual, saltar a deccounter2_fecha
    CPI seldisplay, 3    ; Comparar seldisplay con 3
    BREQ deccounter3_fecha ; Si es igual, saltar a deccounter3_fecha
    CPI seldisplay, 4    ; Comparar seldisplay con 4
    BREQ deccounter4_fecha ; Si es igual, saltar a deccounter4_fecha

deccounter1_fecha:
    LDI temp, 3          ; Cargar el valor 3 en temp
    CP counter2f, temp   ; Comparar counter2f con 3
    BREQ top_decrement_fecha ; Si son iguales, saltar a top_decrement_fecha
    DEC counter1f        ; Decrementar el contador de fecha 1
    MOV temp, counter1f  ; Mover el valor de counter1f a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_fecha ; Si no es igual, saltar a wait_decrement_fecha
    LDI temp, 9          ; Cargar el valor 9 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    RJMP wait_decrement_fecha ; Saltar a wait_decrement_fecha

deccounter2_fecha:
    DEC counter2f        ; Decrementar el contador de fecha 2
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    MOV temp, counter2f  ; Mover el valor de counter2f a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_fecha ; Si no es igual, saltar a wait_decrement_fecha
    LDI temp, 3          ; Cargar el valor 3 en temp
    MOV counter2f, temp  ; Mover el valor de temp a counter2f
    RJMP wait_decrement_fecha ; Saltar a wait_decrement_fecha

deccounter3_fecha:
    LDI temp, 1          ; Cargar el valor 1 en temp
    CP counter4f, temp   ; Comparar counter4f con 1
    BREQ top_decrement_fecha2 ; Si son iguales, saltar a top_decrement_fecha2
    DEC counter3f        ; Decrementar el contador de fecha 3
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    CLR counter2f        ; Reiniciar counter2f a 0
    LDI temp, 0          ; Cargar el valor 0 en temp
    CP counter3f, temp   ; Comparar counter3f con 0
    BRNE wait_decrement_fecha ; Si no es igual, saltar a wait_decrement_fecha
    LDI temp, 9          ; Cargar el valor 9 en temp
    MOV counter3f, temp  ; Mover el valor de temp a counter3f
    RJMP wait_decrement_fecha ; Saltar a wait_decrement_fecha

deccounter4_fecha:
    DEC counter4f        ; Decrementar el contador de fecha 4
    LDI temp, 0          ; Cargar el valor 0 en temp
    CPSE counter4f, temp ; Si counter4f es igual a 0, saltar
    CLR counter3f        ; Reiniciar counter3f a 0
    LDI temp, 2          ; Cargar el valor 2 en temp
    CP counter4f, temp   ; Comparar counter4f con 2
    BRNE wait_decrement_fecha ; Si no es igual, saltar a wait_decrement_fecha
    CLR counter4f        ; Reiniciar counter4f a 0
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter3f, temp  ; Mover el valor de temp a counter3f
    RJMP wait_decrement_fecha ; Saltar a wait_decrement_fecha

top_decrement_fecha:
    DEC counter1f        ; Decrementar el contador de fecha 1
    MOV temp, counter1f  ; Mover el valor de counter1f a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_fecha ; Si no es igual, saltar a wait_decrement_fecha
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    RJMP wait_decrement_fecha ; Saltar a wait_decrement_fecha

top_decrement_fecha2:
    DEC counter3f        ; Decrementar el contador de fecha 3
    LDI temp, 1          ; Cargar el valor 1 en temp
    MOV counter1f, temp  ; Mover el valor de temp a counter1f
    CLR counter2f        ; Reiniciar counter2f a 0
    MOV temp, counter3f  ; Mover el valor de counter3f a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_fecha ; Si no es igual, saltar a wait_decrement_fecha
    LDI temp, 2          ; Cargar el valor 2 en temp
    MOV counter3f, temp  ; Mover el valor de temp a counter3f
    RJMP wait_decrement_fecha ; Saltar a wait_decrement_fecha

wait_decrement_fecha:
    SBIS PINC, PC2       ; Esperar hasta que PC2 esté en alto (botón liberado)
    RJMP wait_decrement_fecha ; Repetir el bucle si el botón no está liberado
    MOV counter1, counter1f ; Mover el valor de counter1f a counter1
    MOV counter2, counter2f ; Mover el valor de counter2f a counter2
    MOV counter3, counter3f ; Mover el valor de counter3f a counter3
    MOV counter4, counter4f ; Mover el valor de counter4f a counter4
    RET                   ; Retornar

check_inc_alarm:
    CPI seldisplay, 1    ; Comparar seldisplay con 1
    BREQ inccounter1_alarm ; Si es igual, saltar a inccounter1_alarm
    CPI seldisplay, 2    ; Comparar seldisplay con 2
    BREQ inccounter2_alarm ; Si es igual, saltar a inccounter2_alarm
    CPI seldisplay, 3    ; Comparar seldisplay con 3
    BREQ inccounter3_alarm ; Si es igual, saltar a inccounter3_alarm
    CPI seldisplay, 4    ; Comparar seldisplay con 4
    BREQ inccounter4_alarm ; Si es igual, saltar a inccounter4_alarm

inccounter1_alarm:
    INC counter1a        ; Incrementar el contador de alarma 1
    LDI temp, 10         ; Cargar el valor 10 en temp
    CP counter1a, temp   ; Comparar counter1a con 10
    BRNE wait_increment_alarm ; Si no es igual, saltar a wait_increment_alarm
    CLR counter1a        ; Reiniciar counter1a a 0
    RJMP wait_increment_alarm ; Saltar a wait_increment_alarm

inccounter2_alarm:
    INC counter2a        ; Incrementar el contador de alarma 2
    LDI temp, 6          ; Cargar el valor 6 en temp
    CP counter2a, temp   ; Comparar counter2a con 6
    BRNE wait_increment_alarm ; Si no es igual, saltar a wait_increment_alarm
    CLR counter2a        ; Reiniciar counter2a a 0
    RJMP wait_increment_alarm ; Saltar a wait_increment_alarm

inccounter3_alarm:
    LDI temp, 2          ; Cargar el valor 2 en temp
    CP counter4a, temp   ; Comparar counter4a con 2
    BREQ top_increment_alarm ; Si son iguales, saltar a top_increment_alarm
    INC counter3a        ; Incrementar el contador de alarma 3
    LDI temp, 10         ; Cargar el valor 10 en temp
    CP counter3a, temp   ; Comparar counter3a con 10
    BRNE wait_increment_alarm ; Si no es igual, saltar a wait_increment_alarm
    CLR counter3a        ; Reiniciar counter3a a 0
    RJMP wait_increment_alarm ; Saltar a wait_increment_alarm

inccounter4_alarm:
    INC counter4a        ; Incrementar el contador de alarma 4
    LDI temp, 1          ; Cargar el valor 1 en temp
    CPSE counter4a, temp ; Si counter4a es igual a 1, saltar
    CLR counter3a        ; Reiniciar counter3a a 0
    LDI temp, 3          ; Cargar el valor 3 en temp
    CP counter4a, temp   ; Comparar counter4a con 3
    BRNE wait_increment_alarm ; Si no es igual, saltar a wait_increment_alarm
    CLR counter4a        ; Reiniciar counter4a a 0
    CLR counter3a        ; Reiniciar counter3a a 0
    RJMP wait_increment_alarm ; Saltar a wait_increment_alarm

top_increment_alarm:
    INC counter3a        ; Incrementar el contador de alarma 3
    LDI temp, 4          ; Cargar el valor 4 en temp
    CP counter3a, temp   ; Comparar counter3a con 4
    BRNE wait_increment_alarm ; Si no es igual, saltar a wait_increment_alarm
    CLR counter3a        ; Reiniciar counter3a a 0
    RJMP wait_increment_alarm ; Saltar a wait_increment_alarm

; Esperar a que se suelte el botón
wait_increment_alarm:
    SBIS PINC, PC1       ; Esperar hasta que PC1 esté en alto (botón liberado)
    RJMP wait_increment_alarm ; Repetir el bucle si el botón no está liberado
    MOV counter1, counter1a ; Mover el valor de counter1a a counter1
    MOV counter2, counter2a ; Mover el valor de counter2a a counter2
    MOV counter3, counter3a ; Mover el valor de counter3a a counter3
    MOV counter4, counter4a ; Mover el valor de counter4a a counter4
    RET                   ; Retornar

;------------------------------------------------------------------
check_dec_alarm:
    CPI seldisplay, 1    ; Comparar seldisplay con 1
    BREQ deccounter1_alarm ; Si es igual, saltar a deccounter1_alarm
    CPI seldisplay, 2    ; Comparar seldisplay con 2
    BREQ deccounter2_alarm ; Si es igual, saltar a deccounter2_alarm
    CPI seldisplay, 3    ; Comparar seldisplay con 3
    BREQ deccounter3_alarm ; Si es igual, saltar a deccounter3_alarm
    CPI seldisplay, 4    ; Comparar seldisplay con 4
    BREQ deccounter4_alarm ; Si es igual, saltar a deccounter4_alarm

deccounter1_alarm:
    DEC counter1a        ; Decrementar el contador de alarma 1
    MOV temp, counter1a  ; Mover el valor de counter1a a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_alarm ; Si no es igual, saltar a wait_decrement_alarm
    LDI temp, 0x09      ; Cargar el valor 9 en temp
    MOV counter1a, temp  ; Mover el valor de temp a counter1a
    RJMP wait_decrement_alarm ; Saltar a wait_decrement_alarm

deccounter2_alarm:
    DEC counter2a        ; Decrementar el contador de alarma 2
    MOV temp, counter2a  ; Mover el valor de counter2a a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_alarm ; Si no es igual, saltar a wait_decrement_alarm
    LDI temp, 0x05      ; Cargar el valor 5 en temp
    MOV counter2a, temp  ; Mover el valor de temp a counter2a
    RJMP wait_decrement_alarm ; Saltar a wait_decrement_alarm

deccounter3_alarm:
    LDI temp, 2          ; Cargar el valor 2 en temp
    CP counter4a, temp   ; Comparar counter4a con 2
    BREQ top_decrement_alarm ; Si son iguales, saltar a top_decrement_alarm
    DEC counter3a        ; Decrementar el contador de alarma 3
    MOV temp, counter3a  ; Mover el valor de counter3a a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_alarm ; Si no es igual, saltar a wait_decrement_alarm
    LDI temp, 0x09      ; Cargar el valor 9 en temp
    MOV counter3a, temp  ; Mover el valor de temp a counter3a
    RJMP wait_decrement_alarm ; Saltar a wait_decrement_alarm

deccounter4_alarm:
    DEC counter4a        ; Decrementar el contador de alarma 4
    LDI temp, 1          ; Cargar el valor 1 en temp
    CPSE counter4a, temp ; Si counter4a es igual a 1, saltar
    CLR counter3a        ; Reiniciar counter3a a 0
    MOV temp, counter4a  ; Mover el valor de counter4a a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_alarm ; Si no es igual, saltar a wait_decrement_alarm
    LDI temp, 0x02      ; Cargar el valor 2 en temp
    MOV counter4a, temp  ; Mover el valor de temp a counter4a
    CLR counter3a        ; Reiniciar counter3a a 0
    RJMP wait_decrement_alarm ; Saltar a wait_decrement_alarm

top_decrement_alarm:
    DEC counter3a        ; Decrementar el contador de alarma 3
    MOV temp, counter3a  ; Mover el valor de counter3a a temp
    NEG temp             ; Negar el valor en temp
    CPI temp, 1          ; Comparar temp con 1
    BRNE wait_decrement_alarm ; Si no es igual, saltar a wait_decrement_alarm
    LDI temp, 0x03      ; Cargar el valor 3 en temp
    MOV counter3a, temp  ; Mover el valor de temp a counter3a
    RJMP wait_decrement_alarm ; Saltar a wait_decrement_alarm

; Esperar a que se suelte el botón
wait_decrement_alarm:
    SBIS PINC, PC2       ; Esperar hasta que PC2 esté en alto (botón liberado)
    RJMP wait_decrement_alarm ; Repetir el bucle si el botón no está liberado
    MOV counter1, counter1a ; Mover el valor de counter1a a counter1
    MOV counter2, counter2a ; Mover el valor de counter2a a counter2
    MOV counter3, counter3a ; Mover el valor de counter3a a counter3
    MOV counter4, counter4a ; Mover el valor de counter4a a counter4
    RET                   ; Retornar

increment1:
    INC counter1h         ; Incrementar counter1h
    LDI temp, 10          ; Cargar el valor 10 en temp
    CP counter1h, temp    ; Comparar counter1h con 10
    BRNE show             ; Si no es igual, saltar a show
    CLR counter1h         ; Reiniciar counter1h a 0
    INC counter2h         ; Incrementar counter2h
    LDI temp, 6           ; Cargar el valor 6 en temp
    CP counter2h, temp    ; Comparar counter2h con 6
    BRNE show             ; Si no es igual, saltar a show
    CLR counter2h         ; Reiniciar counter2h a 0
    LDI temp, 2           ; Cargar el valor 2 en temp
    CP counter4h, temp    ; Comparar counter4h con 2
    BREQ show2            ; Si son iguales, saltar a show2
    INC counter3h         ; Incrementar counter3h
    LDI temp, 10          ; Cargar el valor 10 en temp
    CP counter3h, temp    ; Comparar counter3h con 10
    BRNE show1            ; Si no es igual, saltar a show1
    CLR counter3h         ; Reiniciar counter3h a 0
    INC counter4h         ; Incrementar counter4h
    LDI temp, 3           ; Cargar el valor 3 en temp
    CP counter4h, temp    ; Comparar counter4h con 3
    BRNE show1            ; Si no es igual, saltar a show1

show2:
    INC counter3h         ; Incrementar counter3h
    LDI temp, 4           ; Cargar el valor 4 en temp
    CP counter3h, temp    ; Comparar counter3h con 4
    BRNE show1            ; Si no es igual, saltar a show1
    CLR counter3h         ; Reiniciar counter3h a 0
    INC counter4h         ; Incrementar counter4h
    LDI temp, 3           ; Cargar el valor 3 en temp
    CP counter4h, temp    ; Comparar counter4h con 3
    BRNE show1            ; Si no es igual, saltar a show1
    CLR counter4h         ; Reiniciar counter4h a 0

increment_dias:
    CLR temp              ; Limpiar temp
    CP counter4f, temp    ; Comparar counter4f con 0
    BRNE increment_dias2  ; Si no es igual, saltar a increment_dias2
    LDI XH, 0x03          ; Cargar el byte alto de la dirección en X
    MOV temp, counter3f   ; Mover el valor de counter3f a temp
    MOV XL, temp          ; Mover el valor de temp a XL
    LD temp, X            ; Cargar el valor apuntado por X en temp
    CP counter2f, temp    ; Comparar counter2f con el valor en temp
    BREQ increment_top     ; Si son iguales, saltar a increment_top 
    INC counter1f         ; Incrementar counter1f
    LDI temp, 10          ; Cargar el valor 10 en temp
    CP counter1f, temp    ; Comparar counter1f con 10
    BRNE show1            ; Si no es igual, saltar a show1
    CLR counter1f         ; Reiniciar counter1f a 0
    INC counter2f         ; Incrementar counter2f
    RJMP show1            ; Saltar a show1

show:
    JMP show1             ; Saltar a show1

increment_top:
    INC counter1f         ; Incrementar counter1f
    LDI XH, 0x02          ; Cargar el byte alto de la dirección en X
    LD temp, X            ; Cargar el valor apuntado por X en temp
    INC temp              ; Incrementar el valor en temp
    CP counter1f, temp    ; Comparar counter1f con el valor en temp
    BRNE show1            ; Si no es igual, saltar a show1
    LDI temp, 1           ; Cargar el valor 1 en temp
    MOV counter1f, temp   ; Mover el valor de temp a counter1f
    CLR counter2f         ; Reiniciar counter2f a 0
    RJMP increment_mes     ; Saltar a increment_mes	

increment_dias2:
    LDI temp, 0x09        ; Cargar el valor 9 en temp
    ADD counter4f, temp   ; Sumar temp a counter4f
    CLR temp              ; Limpiar temp
    LDI XH, 0x03          ; Cargar el byte alto de la dirección en X
    ADD temp, counter3f   ; Sumar counter3f a temp
    ADD temp, counter4f   ; Sumar counter4f a temp
    MOV XL, temp          ; Mover el valor de temp a XL
    LDI temp, 0x09        ; Cargar el valor 9 en temp
    SBC counter4f, temp   ; Restar temp de counter4f
    LD temp, X            ; Cargar el valor apuntado por X en temp
    CP counter2f, temp    ; Comparar counter2f con el valor en temp
    BREQ increment_top     ; Si son iguales, saltar a increment_top 
    INC counter1f         ; Incrementar counter1f
    LDI temp, 10          ; Cargar el valor 10 en temp
    CP counter1f, temp    ; Comparar counter1f con 10
    BRNE show1            ; Si no es igual, saltar a show1
    CLR counter1f         ; Reiniciar counter1f a 0
    INC counter2f         ; Incrementar counter2f
    RJMP show1            ; Saltar a show1	

show1:
    LDI XH, 0x01          ; Cargar el byte alto de la dirección en X
    CPI modo, 1           ; Comparar modo con 1
    BREQ show_hora        ; Si es igual, saltar a show_hora
    CPI modo, 2           ; Comparar modo con 2
    BREQ show_fecha       ; Si es igual, saltar a show_fecha

increment_mes:
    LDI temp, 1           ; Cargar el valor 1 en temp
    CP counter4f, temp    ; Comparar counter4f con 1
    BREQ increment_mes2    ; Si son iguales, saltar a increment_mes2
    INC counter3f         ; Incrementar counter3f
    LDI temp, 10          ; Cargar el valor 10 en temp
    CP counter3f, temp    ; Comparar counter3f con 10
    BRNE show1            ; Si no es igual, saltar a show1
    CLR counter3f         ; Reiniciar counter3f a 0
    INC counter4f         ; Incrementar counter4f
    LDI temp, 2           ; Cargar el valor 2 en temp
    CP counter4f, temp    ; Comparar counter4f con 2
    BRNE show1            ; Si no es igual, saltar a show1

increment_mes2:
    INC counter3f         ; Incrementar counter3f
    LDI temp, 3           ; Cargar el valor 3 en temp
    CP counter3f, temp    ; Comparar counter3f con 3
    BRNE show1            ; Si no es igual, saltar a show1
    CLR counter3f         ; Reiniciar counter3f a 0
    INC counter4f         ; Incrementar counter4f
    LDI temp, 2           ; Cargar el valor 2 en temp
    CP counter4f, temp    ; Comparar counter4f con 2
    BRNE show1            ; Si no es igual, saltar a show1
    LDI temp, 1           ; Cargar el valor 1 en temp
    MOV counter3f, temp   ; Mover el valor de temp a counter3f
    CLR counter4f         ; Reiniciar counter4f a 0
    RJMP show1            ; Saltar a show1

show_hora:
    MOV counter1, counter1h ; Mover el valor de counter1h a counter1
    MOV counter2, counter2h ; Mover el valor de counter2h a counter2
    MOV counter3, counter3h ; Mover el valor de counter3h a counter3
    MOV counter4, counter4h ; Mover el valor de counter4h a counter4
    RET                   ; Retornar

show_fecha:
    MOV counter1, counter1f ; Mover el valor de counter1f a counter1
    MOV counter2, counter2f ; Mover el valor de counter2f a counter2
    MOV counter3, counter3f ; Mover el valor de counter3f a counter3
    MOV counter4, counter4f ; Mover el valor de counter4f a counter4
    RET                   ; Retornar

alarm_onoff:
    SBIS PINC, PC1       ; Esperar hasta que PC1 esté en alto (botón liberado)
    RJMP alarm_onoff     ; Repetir el bucle si el botón no está liberado
    LDI temp, (1 << PC0) ; Cargar la máscara para el bit PC0
    EOR alarm, temp      ; Aplicar XOR para alternar el estado de la alarma
    CPI alarm, 1         ; Comparar alarm con 1
    BREQ alarm_on        ; Si alarm es 1, saltar a alarm_on
    RJMP alarm_off       ; Si no, saltar a alarm_off

alarm_on:
    SBI PORTC, PC0       ; Activar la alarma (encender el LED en PC0)
    RET                   ; Retornar

alarm_off:
    CBI PORTC, PC0       ; Desactivar la alarma (apagar el LED en PC0)
    RET                   ; Retornar

;-----------------------------------------------------------------------

ISR_INT0:
    PUSH temp             ; Guardar el registro temporal
    IN temp, SREG         ; Guardar el registro de estado
    PUSH temp             ; Almacenar el estado en la pila

    ; Lógica de la interrupción
    IN temp, PINC         ; Leer estado de los pines
    SBRS temp, PC4        ; Si PC4 está en bajo (presionado)
    RCALL cambio_modo     ; Llamar a la subrutina de cambio de modo
    SBRS temp, PC3        ; Si PC3 está en bajo (presionado)
    RCALL switch_display   ; Llamar a la subrutina de cambio de visualización

    POP temp              ; Restaurar el registro de estado
    OUT SREG, temp        ; Restaurar el registro de estado
    POP temp              ; Restaurar el registro temporal
    RETI                  ; Retornar de la interrupción

cambio_modo:
    PUSH temp             ; Guardar el registro temporal
    IN temp, SREG         ; Guardar el registro de estado
    PUSH temp             ; Almacenar el estado en la pila
    INC modo              ; Incrementar el modo
    CPI modo, 1           ; Comparar si modo es 1
    BREQ modo1            ; Si es 1, saltar a modo1
    CPI modo, 2           ; Comparar si modo es 2
    BREQ modo2            ; Si es 2, saltar a modo2
    CPI modo, 3           ; Comparar si modo es 3
    BREQ modo3            ; Si es 3, saltar a modo3
    CPI modo, 4           ; Comparar si modo es 4
    BREQ modo4            ; Si es 4, saltar a modo4
    CPI modo, 5           ; Comparar si modo es 5
    BREQ modo5            ; Si es 5, saltar a modo5
    CPI modo, 6           ; Comparar si modo es 6
    BREQ modo6            ; Si es 6, saltar a modo6
    LDI modo, 1           ; Reiniciar modo a 1 si excede 6

modo1:
    MOV counter1, counter1h ; Mover el valor de counter1h a counter1
    MOV counter2, counter2h ; Mover el valor de counter2h a counter2
    MOV counter3, counter3h ; Mover el valor de counter3h a counter3
    MOV counter4, counter4h ; Mover el valor de counter4h a counter4
    CLR ledsmodo           ; Limpiar el estado de los LEDs
    LDI temp, (1<<PB5)    ; Cargar la máscara para PB5
    MOV ledsmodo, temp     ; Mover el valor de temp a ledsmodo
    CLR counter            ; Reiniciar el contador
    LDI temp, 0x00        ; Cargar 0 en temp
    MOV displaytilt, temp  ; Limpiar displaytilt
    RJMP exit              ; Saltar a exit

modo2: 
    MOV counter1, counter1f ; Mover el valor de counter1f a counter1
    MOV counter2, counter2f ; Mover el valor de counter2f a counter2
    MOV counter3, counter3f ; Mover el valor de counter3f a counter3
    MOV counter4, counter4f ; Mover el valor de counter4f a counter4
    CLR ledsmodo           ; Limpiar el estado de los LEDs
    LDI temp, (1<<PB4)    ; Cargar la máscara para PB4
    MOV ledsmodo, temp     ; Mover el valor de temp a ledsmodo
    CLR displaytilt        ; Limpiar displaytilt
    RJMP exit              ; Saltar a exit

modo3:
    MOV counter1, counter1h ; Mover el valor de counter1h a counter1
    MOV counter2, counter2h ; Mover el valor de counter2h a counter2
    MOV counter3, counter3h ; Mover el valor de counter3h a counter3
    MOV counter4, counter4h ; Mover el valor de counter4h a counter4
    CLR ledsmodo           ; Limpiar el estado de los LEDs
    LDI temp, (1<<PB5)    ; Cargar la máscara para PB5
    MOV ledsmodo, temp     ; Mover el valor de temp a ledsmodo
    CLR ledstilt           ; Limpiar el estado de ledstilt
    CLR displaytilt        ; Limpiar displaytilt
    LDI seldisplay, 4      ; Establecer seldisplay a 4
    RJMP exit              ; Saltar a exit

modo4:
    MOV counter1, counter1f ; Mover el valor de counter1f a counter1
    MOV counter2, counter2f ; Mover el valor de counter2f a counter2
    MOV counter3, counter3f ; Mover el valor de counter3f a counter3
    MOV counter4, counter4f ; Mover el valor de counter4f a counter4
    CLR ledsmodo           ; Limpiar el estado de los LEDs
    LDI temp, (1<<PB4)    ; Cargar la máscara para PB4
    MOV ledsmodo, temp     ; Mover el valor de temp a ledsmodo
    CLR ledstilt           ; Limpiar el estado de ledstilt
    CLR displaytilt        ; Limpiar displaytilt
    LDI seldisplay, 4      ; Establecer seldisplay a 4
    RJMP exit              ; Saltar a exit

modo5:
    MOV counter1, counter1a ; Mover el valor de counter1a a counter1
    MOV counter2, counter2a ; Mover el valor de counter2a a counter2
    MOV counter3, counter3a ; Mover el valor de counter3a a counter3
    MOV counter4, counter4a ; Mover el valor de counter4a a counter4
    CLR ledsmodo           ; Limpiar el estado de los LEDs
    CLR ledstilt           ; Limpiar el estado de ledstilt
    CLR displaytilt        ; Limpiar displaytilt
    RJMP exit              ; Saltar a exit

modo6:
    MOV counter1, counter1a ; Mover el valor de counter1a a counter1
    MOV counter2, counter2a ; Mover el valor de counter2a a counter2
    MOV counter3, counter3a ; Mover el valor de counter3a a counter3
    MOV counter4, counter4a ; Mover el valor de counter4a a counter4
    CLR ledsmodo           ; Limpiar el estado de los LEDs
    CLR ledstilt           ; Limpiar el estado de ledstilt
    CLR displaytilt        ; Limpiar displaytilt
    LDI seldisplay, 4      ; Establecer seldisplay a 4
    RJMP exit              ; Saltar a exit

switch_display:
    IN temp, SREG          ; Guardar el registro de estado
    PUSH temp              ; Almacenar el estado en la pila
    CPI modo, 1            ; Comparar modo con 1
    BREQ sound_off         ; Si es igual, saltar a sound_off
    CPI modo, 2            ; Comparar modo con 2
    BREQ sound_off         ; Si es igual, saltar a sound_off
    CPI modo, 3            ; Comparar modo con 3
    BREQ switch_display1    ; Si es igual, saltar a switch_display1
    CPI modo, 4            ; Comparar modo con 4
    BREQ switch_display1    ; Si es igual, saltar a switch_display1
    CPI modo, 5            ; Comparar modo con 5
    BREQ switch_display1    ; Si es igual, saltar a switch_display1

switch_display1:
    POP temp               ; Restaurar el registro de estado
    OUT SREG, temp         ; Restaurar el registro de estado
    PUSH temp              ; Guardar el registro temporal
    IN temp, SREG          ; Guardar el registro de estado
    PUSH temp              ; Almacenar el estado en la pila
    DEC seldisplay         ; Decrementar seldisplay
    CPI seldisplay, 0      ; Comparar seldisplay con 0
    BRNE exit              ; Si no es igual, saltar a exit
    LDI seldisplay, 4      ; Reiniciar seldisplay a 4
    RJMP exit              ; Saltar a exit

sound_off:
    POP temp               ; Restaurar el registro de estado
    OUT SREG, temp         ; Restaurar el registro de estado
    PUSH temp              ; Guardar el registro temporal
    IN temp, SREG          ; Guardar el registro de estado
    PUSH temp              ; Almacenar el estado en la pila
    CBI PORTC, PC5        ; Apagar el sonido en PC5
    CBI PORTC, PC0        ; Apagar el LED de alarma en PC0
    CLR alarm              ; Limpiar la bandera de alarma
    RJMP exit              ; Saltar a exit

exit:
    POP temp               ; Restaurar el registro de estado
    OUT SREG, temp         ; Restaurar el registro de estado
    POP temp               ; Restaurar el registro temporal
    RET                    ; Retornar a la rutina de interrupci