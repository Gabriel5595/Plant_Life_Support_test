
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

loop_infinito:
    b loop_infinito
