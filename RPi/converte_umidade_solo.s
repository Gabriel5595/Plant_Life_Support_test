
.global converte_umidade_solo

.section .data
.align 8
LIMIAR_SECO_VALOR:    .word 644
LIMIAR_MOLHADO_VALOR: .word 130

.section .text

converte_umidade_solo:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov w9, w0

    ldr x1, =LIMIAR_SECO_VALOR
    ldr w10, [x1]
    ldr x1, =LIMIAR_MOLHADO_VALOR
    ldr w11, [x1]

    cmp w9, w10
    bgt satura_seco_solo
    cmp w9, w11
    blt satura_molhado_solo

    sub w12, w10, w9
    sub w13, w10, w11
    mov w14, #10000
    mul w12, w12, w14
    udiv w0, w12, w13
    b fim_conversao_solo

satura_seco_solo:
    mov w0, #0
    b fim_conversao_solo

satura_molhado_solo:
    mov w0, #10000

fim_conversao_solo:
    sxtw x0, w0
    ldp x29, x30, [sp], 16
    ret
