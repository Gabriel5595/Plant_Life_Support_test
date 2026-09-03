// ============================================================
// teste_lcd.s
//
// Teste isolado, so' pra diagnostico: inicializa o LCD e
// preenche as 2 linhas inteiras com o caractere 0xFF (bloco
// solido no set de caracteres padrao do HD44780). Nao depende de
// GPIO/SPI/FPGA - so' do LCD via I2C, useful especificamente pra
// separar "hardware/protocolo do LCD funcionando" de "conteudo
// de texto formatado nao aparecendo por outro motivo".
//
// Compilar e rodar sozinho (nao faz parte do main real):
//   aarch64-linux-gnu-as -g -o teste_lcd.o teste_lcd.s
//   aarch64-linux-gnu-ld -o teste_lcd teste_lcd.o usa_lcd.o recebe_info.o \
//       converte_temp.o converte_luz.o converte_umidade_ar.o \
//       converte_umidade_solo.o coeficientes_calibracao.o \
//       tabelas_amostras.o gpio.o apresenta_info_em_tela.o
//   sudo ./teste_lcd
// ============================================================

.global _start
.extern lcd_inicializa
.extern lcd_posiciona_cursor
.extern lcd_escreve_string

.section .data
.align 8
buffer_blocos: .skip 16

.section .text
_start:
    bl lcd_inicializa

    // preenche o buffer com 16 bytes de 0xFF
    ldr x0, =buffer_blocos
    mov w1, #0xFF
    mov x2, #0
loop_preenche:
    strb w1, [x0, x2]
    add x2, x2, #1
    cmp x2, #16
    blt loop_preenche

    mov x0, #0
    mov x1, #0
    bl lcd_posiciona_cursor

    ldr x0, =buffer_blocos
    mov x1, #16
    bl lcd_escreve_string

    mov x0, #1
    mov x1, #0
    bl lcd_posiciona_cursor

    ldr x0, =buffer_blocos
    mov x1, #16
    bl lcd_escreve_string

    // fica rodando pra dar tempo de olhar a tela (Ctrl+C pra sair)
loop_infinito:
    b loop_infinito
