// ============================================================
// apresenta_info_em_tela.s
//
// Monta e escreve as 2 linhas do LCD 16x2 com os 4 valores
// convertidos (temperatura, umidade do ar, luminosidade, umidade
// do solo - pressao fica de fora, decisao de engenharia ja
// documentada). Layout combinado:
//   Linha 1: T:26.8C U:58%
//   Linha 2: L:60lux S:65%
// Cada linha usa 13 dos 16 caracteres disponiveis, com folga.
//
// Precisao reduzida deliberadamente em relacao ao terminal (que
// mostra 2 casas decimais): aqui so' 1 casa pra temperatura e
// nenhuma pras porcentagens/luz, pra caber no espaco fisico do
// display. Isso e' so' apresentacao - os valores completos
// continuam sendo usados sem perda de precisao em todo o resto
// do sistema (tabelas de amostra, decisao da FSM).
//
// Nao recebe mais gpio_base: o LCD agora fala com o kernel via
// /dev/i2c-1 (usa_lcd.s), nao mexe em GPIO bruto.
// ============================================================

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

// ============================================================
// apresenta_info_em_tela
// Entrada: x0 = temperatura (centesimos de grau)
//          x1 = umidade do ar (centesimos de %)
//          x2 = luminosidade (decilux, lux*10)
//          x3 = umidade do solo (centesimos de %)
// ============================================================
apresenta_info_em_tela:
    stp x29, x30, [sp, -64]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]
    str x23, [sp, 48]

    mov x19, x0        // temperatura
    mov x20, x1        // umidade do ar
    mov x21, x2        // luminosidade
    mov x22, x3        // umidade do solo

    // ---- Linha 1: "T:26.8C U:58%" ----
    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    mov w2, #0
    str w2, [x1]

    ldr x2, =string_T_lcd
    mov x3, #2
    bl lcd_buffer_escreve

    // temperatura vem em centesimos (2 casas implicitas) - divide
    // por 10 pra mostrar so' 1 casa decimal no display compacto
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

    mov x0, #0             // linha 0
    mov x1, #0             // coluna 0
    bl lcd_posiciona_cursor

    ldr x0, =buffer_linha_lcd
    mov x1, #16
    bl lcd_escreve_string

    // ---- Linha 2: "L:60lux S:65%" ----
    ldr x0, =buffer_linha_lcd
    ldr x1, =pos_linha_lcd
    mov w2, #0
    str w2, [x1]

    ldr x2, =string_L_lcd
    mov x3, #2
    bl lcd_buffer_escreve

    // luminosidade vem em decilux - divide por 10 pra pegar o lux inteiro
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

    mov x0, #1             // linha 1
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
