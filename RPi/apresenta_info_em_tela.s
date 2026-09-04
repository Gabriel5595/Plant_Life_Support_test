
.global apresenta_info_em_tela
.extern lcd_posiciona_cursor
.extern lcd_escreve_string
.extern lcd_buffer_escreve
.extern lcd_buffer_completa_espacos
.extern formata_valor_fixo_buffer

.section .data
.align 8
buffer_linha_lcd: .skip 17
pos_linha_lcd:    .word 0

string_T_lcd:       .ascii "T:"
string_C_esp_lcd:   .ascii "C "
string_U_lcd:       .ascii "U:"
string_percent_lcd: .ascii "% "
string_L_lcd:       .ascii "L:"
string_lux_esp_lcd: .ascii "lux "
string_S_lcd:       .ascii "S:"
string_percent2_lcd: .ascii "%"

.section .text

apresenta_info_em_tela:
    stp x29, x30, [sp, -64]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]
    str x23, [sp, 48]

    mov x19, x0
    mov x20, x1
    mov x21, x2
    mov x22, x3

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    mov w2, #0
    str w2, [x1]

    ldr x2, =string_T_lcd
    mov x3, #2
    bl lcd_buffer_escreve

    mov x0, x19
    mov x1, #10
    udiv x0, x0, x1
    mov x1, #10
    mov x2, #1
    ldr x3, =buffer_linha_lcd
    ldr x4, =pos_linha_lcd
    bl formata_valor_fixo_buffer

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    ldr x2, =string_C_esp_lcd
    mov x3, #2
    bl lcd_buffer_escreve

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    ldr x2, =string_U_lcd
    mov x3, #2
    bl lcd_buffer_escreve

    mov x0, x20
    mov x1, #100
    mov x2, #0
    ldr x3, =buffer_linha_lcd
    ldr x4, =pos_linha_lcd
    bl formata_valor_fixo_buffer

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    ldr x2, =string_percent_lcd
    mov x3, #1
    bl lcd_buffer_escreve

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    bl lcd_buffer_completa_espacos

    mov x0, #0
    mov x1, #0
    bl lcd_posiciona_cursor

    ldr x0, =buffer_linha_lcd
    mov x1, #16
    bl lcd_escreve_string

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    mov w2, #0
    str w2, [x1]

    ldr x2, =string_L_lcd
    mov x3, #2
    bl lcd_buffer_escreve

    mov x0, x21
    mov x1, #10
    udiv x0, x0, x1
    mov x1, #1
    mov x2, #0
    ldr x3, =buffer_linha_lcd
    ldr x4, =pos_linha_lcd
    bl formata_valor_fixo_buffer

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    ldr x2, =string_lux_esp_lcd
    mov x3, #4
    bl lcd_buffer_escreve

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    ldr x2, =string_S_lcd
    mov x3, #2
    bl lcd_buffer_escreve

    mov x0, x22
    mov x1, #100
    mov x2, #0
    ldr x3, =buffer_linha_lcd
    ldr x4, =pos_linha_lcd
    bl formata_valor_fixo_buffer

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    ldr x2, =string_percent2_lcd
    mov x3, #1
    bl lcd_buffer_escreve

    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    bl lcd_buffer_completa_espacos

    mov x0, #1
    mov x1, #0
    bl lcd_posiciona_cursor

    ldr x0, =buffer_linha_lcd
    mov x1, #16
    bl lcd_escreve_string

    ldr x23, [sp, 48]
    ldp x21, x22, [sp, 32]
    ldp x19, x20, [sp, 16]
    ldp x29, x30, [sp], 64
    ret
