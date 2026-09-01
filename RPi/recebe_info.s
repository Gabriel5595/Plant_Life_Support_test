.global recebe_info
.extern gpio_write
.extern gpio_read

.equ SYS_WRITE, 64
.equ SYS_NANOSLEEP, 101

.equ SCLK_GPIO, 5
.equ CS_GPIO,   6

.section .data

rx_frame: .byte 0,0,0,0,0,0,0,0,0,0,0,0   // pressao(3)+temperatura(3)+umidade(2)+luminosidade(2)+umidade_solo(2)

msg_cabecalho_prefixo: .asciz "\n--- Iteracao "
msg_cabecalho_prefixo_fim = . - msg_cabecalho_prefixo - 1

msg_cabecalho_meio: .asciz " ---\n"
msg_cabecalho_meio_fim = . - msg_cabecalho_meio - 1

msg_pressao: .asciz "Pressao bruta:     0x"
msg_pressao_fim = . - msg_pressao - 1

msg_temperatura: .asciz "Temperatura bruta: 0x"
msg_temperatura_fim = . - msg_temperatura - 1

msg_umidade: .asciz "Umidade bruta:     0x"
msg_umidade_fim = . - msg_umidade - 1

msg_luminosidade: .asciz "Luminosidade bruta:  0x"
msg_luminosidade_fim = . - msg_luminosidade - 1

msg_umidade_solo: .asciz "Umidade do solo bruta: 0x"
msg_umidade_solo_fim = . - msg_umidade_solo - 1

.align 8
buffer_iteracao: .skip 20   // ate 20 digitos (cobre qualquer uint64)
buffer_hex:      .byte 0,0

.align 8
tempo_espera:
    .quad 0
    .quad 10000

.section .text

recebe_info:
    stp x29, x30, [sp, -48]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]

    mov x19, x0
    mov x20, x1

    mov x0, #1
    ldr x1, =msg_cabecalho_prefixo
    mov x2, #msg_cabecalho_prefixo_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x20
    bl converte_num_para_string
    mov x2, x1
    mov x1, x0
    mov x0, #1
    mov x8, #SYS_WRITE
    svc #0

    mov x0, #1
    ldr x1, =msg_cabecalho_meio
    mov x2, #msg_cabecalho_meio_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x19
    mov w1, #CS_GPIO
    mov w2, #0
    bl gpio_write

    bl atraso_curto

    ldr x23, =rx_frame
    mov x24, #0

loop_bytes:
    cmp x24, #12
    b.ge fim_bytes

    mov x21, #0
    mov x22, #0

loop_bits:
    cmp x22, #8
    b.ge fim_bits_do_byte

    mov x0, x19
    mov w1, #SCLK_GPIO
    mov w2, #1
    bl gpio_write

    bl atraso_curto

    mov x0, x19
    mov w1, #13
    bl gpio_read

    lsl x21, x21, #1
    orr x21, x21, x0

    mov x0, x19
    mov w1, #SCLK_GPIO
    mov w2, #0
    bl gpio_write

    bl atraso_curto

    add x22, x22, #1
    b loop_bits

fim_bits_do_byte:
    and w21, w21, #0xFF
    strb w21, [x23, x24]
    add x24, x24, #1
    b loop_bytes

fim_bytes:
    mov x0, x19
    mov w1, #CS_GPIO
    mov w2, #1
    bl gpio_write

    mov x0, #1
    ldr x1, =msg_pressao
    mov x2, #msg_pressao_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, #0
    mov x1, #3
    bl imprime_bytes_hex_n
    bl imprime_quebra_linha

    mov x0, #1
    ldr x1, =msg_temperatura
    mov x2, #msg_temperatura_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, #3
    mov x1, #3
    bl imprime_bytes_hex_n
    bl imprime_quebra_linha

    mov x0, #1
    ldr x1, =msg_umidade
    mov x2, #msg_umidade_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, #6
    mov x1, #2
    bl imprime_bytes_hex_n
    bl imprime_quebra_linha

    mov x0, #1
    ldr x1, =msg_luminosidade
    mov x2, #msg_luminosidade_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, #8
    mov x1, #2
    bl imprime_bytes_hex_n
    bl imprime_quebra_linha

    mov x0, #1
    ldr x1, =msg_umidade_solo
    mov x2, #msg_umidade_solo_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, #10
    mov x1, #2
    bl imprime_bytes_hex_n
    bl imprime_quebra_linha

    ldp x21, x22, [sp, 32]
    ldp x19, x20, [sp, 16]
    ldp x29, x30, [sp], 48
    ret

// ============================================================
// converte_num_para_string
// Converte um numero (uint64, positivo) para uma string ASCII
// decimal, sem zeros a esquerda, escrevendo no buffer_iteracao
// de tras pra frente.
// Entrada:  x0 = numero
// Saida:    x0 = ponteiro para o primeiro digito da string
//           x1 = quantidade de digitos
// ============================================================
converte_num_para_string:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr x9, =(buffer_iteracao + 20)
    mov x10, #10

converte_loop:
    udiv x11, x0, x10
    msub x12, x11, x10, x0
    add w12, w12, #0x30
    sub x9, x9, #1
    strb w12, [x9]
    mov x0, x11
    cmp x0, #0
    b.ne converte_loop

    ldr x13, =(buffer_iteracao + 20)
    sub x1, x13, x9
    mov x0, x9

    ldp x29, x30, [sp], 16
    ret

// ============================================================
// imprime_bytes_hex_n
// Entrada: x0 = indice inicial em rx_frame, x1 = quantidade de bytes
// ============================================================
imprime_bytes_hex_n:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    mov x14, x0
    mov x15, x1
    ldr x12, =rx_frame
    ldr x13, =buffer_hex

loop_imprime_hex:
    cmp x15, #0
    b.eq fim_imprime_hex

    ldrb w16, [x12, x14]

    lsr w17, w16, #4
    and w17, w17, #0xF
    add w17, w17, #0x30
    cmp w17, #0x3A
    b.lt nibble_alto_ok2
    add w17, w17, #7
nibble_alto_ok2:
    strb w17, [x13]

    and w18, w16, #0xF
    add w18, w18, #0x30
    cmp w18, #0x3A
    b.lt nibble_baixo_ok2
    add w18, w18, #7
nibble_baixo_ok2:
    strb w18, [x13, #1]

    mov x0, #1
    mov x1, x13
    mov x2, #2
    mov x8, #SYS_WRITE
    svc #0

    add x14, x14, #1
    sub x15, x15, #1
    b loop_imprime_hex

fim_imprime_hex:
    ldp x29, x30, [sp], 16
    ret

imprime_quebra_linha:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    mov x0, #1
    ldr x1, =msg_quebra
    mov x2, #1
    mov x8, #SYS_WRITE
    svc #0
    ldp x29, x30, [sp], 16
    ret

atraso_curto:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    ldr x0, =tempo_espera
    mov x1, #0
    mov x8, #SYS_NANOSLEEP
    svc #0
    ldp x29, x30, [sp], 16
    ret

.section .data
msg_quebra: .asciz "\n"
