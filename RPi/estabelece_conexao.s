
.global estabelece_conexao
.extern gpio_map
.extern gpio_set_output
.extern gpio_set_input
.extern gpio_write
.extern gpio_read

.equ SYS_NANOSLEEP, 101

.equ SCLK_GPIO, 5
.equ CS_GPIO,   6
.equ MOSI_GPIO, 12
.equ MISO_GPIO, 13

.equ TAMANHO_FRAME_DESCARTE, 44

.section .data
.align 8
tempo_espera_descarte:
    .quad 0
    .quad 10000

.section .text

estabelece_conexao:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    bl gpio_map
    cmp x1, #0
    b.ne conexao_erro

    mov x19, x0

    mov x0, x19
    mov w1, #SCLK_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #SCLK_GPIO
    mov w2, #0
    bl gpio_write

    mov x0, x19
    mov w1, #CS_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #CS_GPIO
    mov w2, #1
    bl gpio_write

    mov x0, x19
    mov w1, #MOSI_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #MOSI_GPIO
    mov w2, #0
    bl gpio_write

    mov x0, x19
    mov w1, #MISO_GPIO
    bl gpio_set_input

    mov x0, x19
    mov w1, #CS_GPIO
    mov w2, #0
    bl gpio_write

    bl atraso_curto_descarte

    mov x20, #0

loop_bytes_descarte:
    cmp x20, #TAMANHO_FRAME_DESCARTE
    b.ge fim_bytes_descarte

    mov x21, #0

loop_bits_descarte:
    cmp x21, #8
    b.ge fim_bits_byte_descarte

    mov x0, x19
    mov w1, #SCLK_GPIO
    mov w2, #1
    bl gpio_write

    bl atraso_curto_descarte

    mov x0, x19
    mov w1, #MISO_GPIO
    bl gpio_read

    mov x0, x19
    mov w1, #SCLK_GPIO
    mov w2, #0
    bl gpio_write

    bl atraso_curto_descarte

    add x21, x21, #1
    b loop_bits_descarte

fim_bits_byte_descarte:
    add x20, x20, #1
    b loop_bytes_descarte

fim_bytes_descarte:
    mov x0, x19
    mov w1, #CS_GPIO
    mov w2, #1
    bl gpio_write

    mov x0, x19
    mov x1, #0
    ldp x29, x30, [sp], 16
    ret

conexao_erro:
    mov x0, #0
    mov x1, #1
    ldp x29, x30, [sp], 16
    ret

atraso_curto_descarte:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    ldr x0, =tempo_espera_descarte
    mov x1, #0
    mov x8, #SYS_NANOSLEEP
    svc #0
    ldp x29, x30, [sp], 16
    ret
