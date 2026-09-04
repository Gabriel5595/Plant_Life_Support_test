.global aciona_bomba
.global aciona_luz
.global inicializa_atuadores
.extern gpio_write
.extern gpio_set_output

.equ GPIO_BOMBA, 17
.equ GPIO_LUZ,   27

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

aciona_bomba:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    mov w2, w1
    mov w1, #GPIO_BOMBA
    bl gpio_write
    ldp x29, x30, [sp], 16
    ret

aciona_luz:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    mov w2, w1
    mov w1, #GPIO_LUZ
    bl gpio_write
    ldp x29, x30, [sp], 16
    ret
