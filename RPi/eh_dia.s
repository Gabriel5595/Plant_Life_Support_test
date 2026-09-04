
.global eh_dia
.extern obtem_timestamp

.equ OFFSET_UTC_SEGUNDOS, 7200
.equ HORA_INICIO_DIA, 7
.equ HORA_FIM_DIA,    21

.section .text

eh_dia:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    bl obtem_timestamp

    mov x1, #OFFSET_UTC_SEGUNDOS
    add x0, x0, x1
    ldr x1, =86400
    udiv x2, x0, x1
    msub x0, x2, x1, x0

    mov x1, #3600
    udiv x0, x0, x1

    mov x1, #HORA_INICIO_DIA
    cmp x0, x1
    blt fim_eh_dia_noite

    mov x1, #HORA_FIM_DIA
    cmp x0, x1
    bge fim_eh_dia_noite

    mov x0, #1
    b fim_eh_dia

fim_eh_dia_noite:
    mov x0, #0

fim_eh_dia:
    ldp x29, x30, [sp], 16
    ret
