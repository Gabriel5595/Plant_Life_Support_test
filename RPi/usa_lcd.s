
.global lcd_inicializa
.global lcd_posiciona_cursor
.global lcd_escreve_string
.global lcd_buffer_escreve
.global lcd_buffer_completa_espacos
.global formata_valor_fixo_buffer
.extern converte_num_para_string

.equ AT_FDCWD,    -100
.equ O_RDWR,      2
.equ I2C_SLAVE,   0x0703
.equ ENDERECO_LCD, 0x27
.equ SYS_OPENAT,  56
.equ SYS_IOCTL,   29
.equ SYS_WRITE,   64
.equ SYS_NANOSLEEP, 101
.equ RS_COMANDO,  0
.equ RS_DADO,     1

.section .data
i2c_dev_path: .asciz "/dev/i2c-1"
.align 8
fd_lcd: .quad 0
buffer_envio_lcd: .skip 4

.section .text

lcd_abre_dispositivo:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x0, #AT_FDCWD
    ldr x1, =i2c_dev_path
    mov x2, #O_RDWR
    mov x3, #0
    mov x8, #SYS_OPENAT
    svc #0

    ldr x1, =fd_lcd
    str x0, [x1]

    mov x1, #I2C_SLAVE
    mov x2, #ENDERECO_LCD
    mov x8, #SYS_IOCTL
    svc #0

    ldp x29, x30, [sp], 16
    ret

i2c_escreve_retry:
    stp x29, x30, [sp, -32]!
    mov x29, sp
    stp x19, x20, [sp, 16]

    mov x19, x0
    mov x20, x1

loop_retry_i2c:
    ldr x1, =fd_lcd
    ldr x9, [x1]
    mov x0, x9
    mov x1, x19
    mov x2, x20
    mov x8, #SYS_WRITE
    svc #0
    cmp x0, #0
    blt loop_retry_i2c

    ldp x19, x20, [sp, 16]
    ldp x29, x30, [sp], 32
    ret

lcd_espera_us:
    stp x29, x30, [sp, -32]!
    mov x29, sp

    mov x1, #1000
    mul x1, x0, x1
    stp xzr, x1, [sp, 16]
    add x0, sp, #16
    mov x1, #0
    mov x8, #SYS_NANOSLEEP
    svc #0

    ldp x29, x30, [sp], 32
    ret

lcd_envia_nibble_apenas:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    and w1, w0, #0xF
    lsl w1, w1, #4
    orr w1, w1, #0x8

    orr w2, w1, #0x4
    ldr x3, =buffer_envio_lcd
    strb w2, [x3]
    strb w1, [x3, #1]

    mov x0, x3
    mov x1, #1
    bl i2c_escreve_retry

    mov x0, #60
    bl lcd_espera_us

    add x0, x3, #1
    mov x1, #1
    bl i2c_escreve_retry

    mov x0, #60
    bl lcd_espera_us

    ldp x29, x30, [sp], 16
    ret

lcd_envia_byte:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    lsr w2, w0, #4
    and w2, w2, #0xF
    lsl w2, w2, #4
    orr w2, w2, #0x8
    orr w2, w2, w1

    and w3, w0, #0xF
    lsl w3, w3, #4
    orr w3, w3, #0x8
    orr w3, w3, w1

    ldr x4, =buffer_envio_lcd
    orr w5, w2, #0x4
    strb w5, [x4]
    strb w2, [x4, #1]
    orr w5, w3, #0x4
    strb w5, [x4, #2]
    strb w3, [x4, #3]

    mov x0, x4
    mov x1, #1
    bl i2c_escreve_retry

    mov x0, #60
    bl lcd_espera_us

    add x0, x4, #1
    mov x1, #1
    bl i2c_escreve_retry

    mov x0, #60
    bl lcd_espera_us

    add x0, x4, #2
    mov x1, #1
    bl i2c_escreve_retry

    mov x0, #60
    bl lcd_espera_us

    add x0, x4, #3
    mov x1, #1
    bl i2c_escreve_retry

    mov x0, #60
    bl lcd_espera_us

    ldp x29, x30, [sp], 16
    ret

lcd_inicializa:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    bl lcd_abre_dispositivo

    mov x0, #40000
    bl lcd_espera_us

    mov x0, #0x3
    bl lcd_envia_nibble_apenas
    mov x0, #5000
    bl lcd_espera_us

    mov x0, #0x3
    bl lcd_envia_nibble_apenas
    mov x0, #200
    bl lcd_espera_us

    mov x0, #0x3
    bl lcd_envia_nibble_apenas
    mov x0, #200
    bl lcd_espera_us

    mov x0, #0x2
    bl lcd_envia_nibble_apenas
    mov x0, #200
    bl lcd_espera_us

    mov x0, #0x28
    mov x1, #RS_COMANDO
    bl lcd_envia_byte
    mov x0, #100
    bl lcd_espera_us

    mov x0, #0x08
    mov x1, #RS_COMANDO
    bl lcd_envia_byte
    mov x0, #100
    bl lcd_espera_us

    mov x0, #0x01
    mov x1, #RS_COMANDO
    bl lcd_envia_byte
    mov x0, #2000
    bl lcd_espera_us

    mov x0, #0x06
    mov x1, #RS_COMANDO
    bl lcd_envia_byte
    mov x0, #100
    bl lcd_espera_us

    mov x0, #0x0C
    mov x1, #RS_COMANDO
    bl lcd_envia_byte
    mov x0, #100
    bl lcd_espera_us

    ldp x29, x30, [sp], 16
    ret

lcd_posiciona_cursor:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    cmp x0, #0
    beq linha0_cursor
    mov w2, #0x40
    b base_linha_pronta
linha0_cursor:
    mov w2, #0x00
base_linha_pronta:
    add w2, w2, w1
    orr w0, w2, #0x80
    mov x1, #RS_COMANDO
    bl lcd_envia_byte
    mov x0, #100
    bl lcd_espera_us

    ldp x29, x30, [sp], 16
    ret

lcd_escreve_string:
    stp x29, x30, [sp, -48]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    str x21, [sp, 32]

    mov x19, x0
    mov w20, w1
    mov w21, #0

loop_escreve_str:
    cmp w21, w20
    bge fim_escreve_str

    ldrb w0, [x19, x21]
    mov x1, #RS_DADO
    bl lcd_envia_byte
    mov x0, #100
    bl lcd_espera_us

    add w21, w21, #1
    b loop_escreve_str

fim_escreve_str:
    ldr x21, [sp, 32]
    ldp x19, x20, [sp, 16]
    ldp x29, x30, [sp], 48
    ret

lcd_buffer_escreve:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr w4, [x1]
    mov w5, #16
    subs w5, w5, w4
    ble fim_buffer_escreve

    cmp w3, w5
    ble copia_tudo_buffer
    mov w3, w5
copia_tudo_buffer:
    mov w6, #0
loop_copia_buffer:
    cmp w6, w3
    bge fim_copia_buffer
    ldrb w7, [x2, x6]
    add x8, x0, x4
    strb w7, [x8]
    add w4, w4, #1
    add w6, w6, #1
    b loop_copia_buffer
fim_copia_buffer:
    str w4, [x1]

fim_buffer_escreve:
    ldp x29, x30, [sp], 16
    ret

lcd_buffer_completa_espacos:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr w2, [x1]
loop_completa_espacos:
    cmp w2, #16
    bge fim_completa_espacos
    add x3, x0, x2
    mov w4, #0x20
    strb w4, [x3]
    add w2, w2, #1
    b loop_completa_espacos
fim_completa_espacos:
    str w2, [x1]

    ldp x29, x30, [sp], 16
    ret

formata_valor_fixo_buffer:
    stp x29, x30, [sp, -64]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]
    stp x23, x24, [sp, 48]

    mov x19, x1
    mov x20, x2
    mov x23, x3
    mov x24, x4

    udiv x9, x0, x19
    msub x21, x9, x19, x0

    mov x0, x9
    bl converte_num_para_string
    mov x2, x0
    mov x3, x1
    mov x0, x23
    mov x1, x24
    bl lcd_buffer_escreve

    cmp x20, #0
    beq fim_formata_valor_buffer

    mov x0, x23
    mov x1, x24
    ldr x2, =string_ponto_lcd
    mov x3, #1
    bl lcd_buffer_escreve

    mov x0, x21
    bl converte_num_para_string
    mov x21, x0
    mov x22, x1

    subs x9, x20, x22
    ble escreve_fracao_buffer

loop_zero_pad_buffer:
    mov x0, x23
    mov x1, x24
    ldr x2, =string_zero_lcd
    mov x3, #1
    bl lcd_buffer_escreve
    subs x9, x9, #1
    bgt loop_zero_pad_buffer

escreve_fracao_buffer:
    mov x0, x23
    mov x1, x24
    mov x2, x21
    mov x3, x22
    bl lcd_buffer_escreve

fim_formata_valor_buffer:
    ldp x23, x24, [sp, 48]
    ldp x21, x22, [sp, 32]
    ldp x19, x20, [sp, 16]
    ldp x29, x30, [sp], 64
    ret

.section .data
string_ponto_lcd: .ascii "."
string_zero_lcd:  .ascii "0"
