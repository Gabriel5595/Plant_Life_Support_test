.global calcula_media

.section .text

calcula_media:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr w9, [x1]
    cmp w9, #0
    beq media_vazia

    mov x10, #0
    mov w11, #0

soma_loop:
    cmp w11, w9
    bge soma_pronta
    ldr w12, [x0, x11, lsl #2]
    sxtw x12, w12
    add x10, x10, x12
    add w11, w11, #1
    b soma_loop

soma_pronta:
    sxtw x9, w9
    sdiv x0, x10, x9
    b zera_indice_media

media_vazia:
    mov x0, #0

zera_indice_media:
    mov w9, #0
    str w9, [x1]

    ldp x29, x30, [sp], 16
    ret
