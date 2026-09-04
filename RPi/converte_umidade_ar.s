
.global converte_umidade_ar
.extern t_fine_global
.extern dig_h1_valor
.extern bloco_h2_h6_valor

.section .text

converte_umidade_ar:
    stp x29, x30, [sp, -80]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]
    stp x23, x24, [sp, 48]
    stp x25, x26, [sp, 64]

    mov w19, w0

    ldr x1, =dig_h1_valor
    ldrb w20, [x1]

    ldr x1, =bloco_h2_h6_valor
    ldrb w2, [x1, #0]
    ldrb w3, [x1, #1]
    ldrb w4, [x1, #2]
    ldrb w5, [x1, #3]
    ldrb w6, [x1, #4]
    ldrb w7, [x1, #5]
    ldrb w8, [x1, #6]

    lsl w21, w3, #8
    orr w21, w21, w2
    sxth w21, w21

    mov w22, w4

    and w9, w6, #0xF
    lsl w23, w5, #4
    orr w23, w23, w9
    lsl w23, w23, #20
    asr w23, w23, #20

    lsr w9, w6, #4
    lsl w24, w7, #4
    orr w24, w24, w9
    lsl w24, w24, #20
    asr w24, w24, #20

    sxtb w25, w8

    ldr x1, =t_fine_global
    ldr w26, [x1]

    ldr w9, =76800
    sub w26, w26, w9

    lsl w9, w19, #14
    lsl w10, w23, #20
    sub w9, w9, w10
    mul w11, w24, w26
    sub w9, w9, w11
    add w9, w9, #16384
    asr w9, w9, #15

    mul w12, w26, w25
    asr w12, w12, #10
    mul w13, w26, w22
    asr w13, w13, #11
    add w13, w13, #32768
    mul w12, w12, w13
    asr w12, w12, #10
    add w12, w12, #2097152
    mul w12, w12, w21
    add w12, w12, #8192
    asr w12, w12, #14

    mul w14, w9, w12

    asr w15, w14, #15
    mul w16, w15, w15
    asr w16, w16, #7
    mul w16, w16, w20
    asr w16, w16, #4
    sub w14, w14, w16

    cmp w14, #0
    bge nao_negativo_umid
    mov w14, #0
nao_negativo_umid:
    ldr w17, =419430400
    cmp w14, w17
    ble nao_estoura_umid
    mov w14, w17
nao_estoura_umid:

    lsr w0, w14, #12

    mov w1, #100
    mul w0, w0, w1
    mov w1, #1024
    udiv w0, w0, w1

    ldp x25, x26, [sp, 64]
    ldp x23, x24, [sp, 48]
    ldp x21, x22, [sp, 32]
    ldp x19, x20, [sp, 16]
    ldp x29, x30, [sp], 80
    ret
