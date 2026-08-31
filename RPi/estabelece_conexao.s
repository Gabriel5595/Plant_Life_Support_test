// ============================================================
// estabelece_conexao.s
//
// Mapeia o GPIO via /dev/gpiomem e configura direcao/nivel
// inicial dos 4 pinos usados no SPI por bit-banging.
//
// Saida:
//   x0 = base mapeada (se sucesso)
//   x1 = status (0 = OK, 1 = erro)
// ============================================================

.global estabelece_conexao
.extern gpio_map
.extern gpio_set_output
.extern gpio_set_input
.extern gpio_write

.equ SCLK_GPIO, 5
.equ CS_GPIO,   6
.equ MOSI_GPIO, 12
.equ MISO_GPIO, 13

.section .text

estabelece_conexao:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    bl gpio_map
    cmp x1, #0
    b.ne conexao_erro

    mov x19, x0

    // SCLK: saida, nivel inicial baixo (ocioso, Modo SPI 0)
    mov x0, x19
    mov w1, #SCLK_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #SCLK_GPIO
    mov w2, #0
    bl gpio_write

    // CS: saida, nivel inicial alto (ocioso, ativo em baixo)
    mov x0, x19
    mov w1, #CS_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #CS_GPIO
    mov w2, #1
    bl gpio_write

    // MOSI: saida, fixo em baixo (nao usado nesta etapa)
    mov x0, x19
    mov w1, #MOSI_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #MOSI_GPIO
    mov w2, #0
    bl gpio_write

    // MISO: entrada
    mov x0, x19
    mov w1, #MISO_GPIO
    bl gpio_set_input

    mov x0, x19
    mov x1, #0
    ldp x29, x30, [sp], 16
    ret

conexao_erro:
    mov x0, #0
    mov x1, #1
    ldp x29, x30, [sp], 16
    ret
