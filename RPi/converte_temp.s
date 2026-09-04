
.global converte_temp
.global t_fine_global
.extern dig_t1_valor
.extern dig_t2_valor
.extern dig_t3_valor

.section .data
.align 8
t_fine_global: .quad 0

.section .text

converte_temp:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov w9, w0

    ldr x10, =dig_t1_valor
    ldrh w10, [x10]
    ldr x11, =dig_t2_valor
    ldrsh w11, [x11]
    ldr x12, =dig_t3_valor
    ldrsh w12, [x12]

    asr w13, w9, #3
    lsl w14, w10, #1
    sub w13, w13, w14
    mul w13, w13, w11
    asr w13, w13, #11

    asr w14, w9, #4
    sub w14, w14, w10
    mul w15, w14, w14
    asr w15, w15, #12
    mul w15, w15, w12
    asr w15, w15, #14

    add w16, w13, w15

    sxtw x16, w16
    ldr x17, =t_fine_global
    str x16, [x17]

    mov w0, #5
    mul w0, w16, w0
    add w0, w0, #128
    asr w0, w0, #8
    sxtw x0, w0

    ldp x29, x30, [sp], 16
    ret
