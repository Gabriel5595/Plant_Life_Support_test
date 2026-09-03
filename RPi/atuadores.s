// ============================================================
// atuadores.s
//
// Controle dos atuadores placeholder: LED azul em GPIO17 (agua)
// e LED amarelo em GPIO27 (luz), no lugar da bomba G328 e da luz
// de crescimento reais, por enquanto.
// ============================================================

.global aciona_bomba
.global aciona_luz
.global inicializa_atuadores
.extern gpio_write
.extern gpio_set_output

.equ GPIO_BOMBA, 17
.equ GPIO_LUZ,   27

// ============================================================
// inicializa_atuadores - configura GPIO17 e GPIO27 como saida.
// Precisa rodar uma vez, antes de qualquer aciona_bomba/aciona_luz
// - sem isso, gpio_write nao tem efeito eletrico nenhum no pino
// (gpio_write so mexe em GPSET/GPCLR, nunca na direcao do pino;
// a direcao e' responsabilidade exclusiva de gpio_set_output,
// que nunca era chamado pra esses dois pinos ate agora).
// Entrada: x0 = gpio_base
// ============================================================
inicializa_atuadores:
    stp x29, x30, [sp, -32]!
    mov x29, sp
    str x19, [sp, 16]
    mov x19, x0

    mov w1, #GPIO_BOMBA
    bl gpio_set_output

    mov x0, x19
    mov w1, #GPIO_LUZ
    bl gpio_set_output

    ldr x19, [sp, 16]
    ldp x29, x30, [sp], 32
    ret

// ============================================================
// aciona_bomba
// Entrada: x0 = gpio_base
//          x1 = 0 (desliga) ou 1 (liga)
// ============================================================
aciona_bomba:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    mov w2, w1
    mov w1, #GPIO_BOMBA
    bl gpio_write
    ldp x29, x30, [sp], 16
    ret

// ============================================================
// aciona_luz
// Entrada: x0 = gpio_base
//          x1 = 0 (desliga) ou 1 (liga)
// ============================================================
aciona_luz:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    mov w2, w1
    mov w1, #GPIO_LUZ
    bl gpio_write
    ldp x29, x30, [sp], 16
    ret
