.global recebe_info
.global rx_frame
.global imprime_valor_fixo
.global obtem_timestamp
.global converte_num_para_string
.extern gpio_write
.extern gpio_read
.extern converte_temp
.extern converte_luz
.extern converte_umidade_ar
.extern converte_umidade_solo
.extern armazena_amostra
.extern tabela_temp
.extern indice_temp
.extern tabela_umidade_ar
.extern indice_umidade_ar
.extern tabela_luz
.extern indice_luz
.extern tabela_solo
.extern indice_solo

.equ SYS_WRITE, 64
.equ SYS_NANOSLEEP, 101

// 🆕 SYS_CLOCK_GETTIME e CLOCK_REALTIME: nao ensinados em nenhuma
// aula (nem Assembly, nem Projeto de Bloco). Testado e confirmado
// via qemu-aarch64 antes de usar aqui:
//   clock_gettime(clockid_t clk_id, struct timespec *tp)
//   numero da syscall (ARM64): 113
//   clk_id = 0 (CLOCK_REALTIME - relogio de parede do sistema)
//   tp aponta pra uma struct de 16 bytes, MESMO LAYOUT que ja
//   usamos no nanosleep: { int64 tv_sec; int64 tv_nsec; }
//   tv_sec  = segundos desde 1/1/1970 (epoch Unix) - e' isso que usamos
//   tv_nsec = nanosegundos dentro do segundo atual - nao usado aqui
.equ SYS_CLOCK_GETTIME, 113
.equ CLOCK_REALTIME,    0

.equ SCLK_GPIO, 5
.equ CS_GPIO,   6

.section .data

// De volta a 12 bytes: pressao(3)+temperatura(3)+umidade(2)+
// luminosidade(2)+umidade_solo(2). Coeficientes de calibracao do
// BME280 NAO SAO MAIS transmitidos pelo FPGA - ficam fixos em
// coeficientes_calibracao.s (sao constantes, nao mudam nunca).
rx_frame: .byte 0,0,0,0,0,0,0,0,0,0,0,0

.align 8
buffer_timespec:
    .quad 0
    .quad 0

msg_cabecalho_prefixo: .asciz "\n--- Iteracao "
msg_cabecalho_prefixo_fim = . - msg_cabecalho_prefixo - 1

msg_timestamp_prefixo: .asciz " (t="
msg_timestamp_prefixo_fim = . - msg_timestamp_prefixo - 1

msg_timestamp_sufixo: .asciz ")"
msg_timestamp_sufixo_fim = . - msg_timestamp_sufixo - 1

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

msg_temp_convertida: .asciz "Temperatura: "
msg_temp_convertida_fim = . - msg_temp_convertida - 1

msg_graus_c: .asciz " °C\n"
msg_graus_c_fim = . - msg_graus_c - 1

msg_umidade_ar_convertida: .asciz "Umidade do ar: "
msg_umidade_ar_convertida_fim = . - msg_umidade_ar_convertida - 1

msg_percent: .asciz " %\n"
msg_percent_fim = . - msg_percent - 1

msg_luz_convertida: .asciz "Luminosidade: "
msg_luz_convertida_fim = . - msg_luz_convertida - 1

msg_lux: .asciz " lux\n"
msg_lux_fim = . - msg_lux - 1

msg_umidade_solo_convertida: .asciz "Umidade do solo: "
msg_umidade_solo_convertida_fim = . - msg_umidade_solo_convertida - 1

msg_ponto: .asciz "."
msg_zero: .asciz "0"

.align 8
buffer_iteracao: .skip 20   // ate 20 digitos (cobre qualquer uint64)
buffer_hex:      .byte 0,0

.align 8
tempo_espera:
    .quad 0
    .quad 10000

.section .text

recebe_info:
    stp x29, x30, [sp, -64]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]
    stp x23, x24, [sp, 48]

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
    ldr x1, =msg_timestamp_prefixo
    mov x2, #msg_timestamp_prefixo_fim
    mov x8, #SYS_WRITE
    svc #0

    bl obtem_timestamp
    bl converte_num_para_string
    mov x2, x1
    mov x1, x0
    mov x0, #1
    mov x8, #SYS_WRITE
    svc #0

    mov x0, #1
    ldr x1, =msg_timestamp_sufixo
    mov x2, #msg_timestamp_sufixo_fim
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

    // ---- Temperatura convertida (usa converte_temp) ----
    ldr x1, =rx_frame
    ldrb w2, [x1, #3]
    ldrb w3, [x1, #4]
    ldrb w4, [x1, #5]
    lsl w2, w2, #16
    lsl w3, w3, #8
    orr w2, w2, w3
    orr w2, w2, w4          // w2 = temperatura_bruta (24 bits)
    asr w0, w2, #4          // adc_T = temperatura_bruta >> 4
    bl converte_temp
    mov x21, x0             // guarda T (centesimos de grau) - persiste ate' o fim da funcao

    mov x0, #1
    ldr x1, =msg_temp_convertida
    mov x2, #msg_temp_convertida_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x21
    mov x1, #100
    mov x2, #2
    bl imprime_valor_fixo

    mov x0, #1
    ldr x1, =msg_graus_c
    mov x2, #msg_graus_c_fim
    mov x8, #SYS_WRITE
    svc #0

    // grava a amostra convertida na tabela de 5 minutos
    mov x0, x21
    ldr x1, =tabela_temp
    ldr x2, =indice_temp
    bl armazena_amostra

    // ---- Umidade do ar convertida (usa converte_umidade_ar) ----
    // Precisa rodar DEPOIS de converte_temp (usa t_fine_global,
    // que so fica valido apos aquela chamada).
    ldr x1, =rx_frame
    ldrb w2, [x1, #6]
    ldrb w3, [x1, #7]
    lsl w2, w2, #8
    orr w0, w2, w3          // w0 = umidade_bruta (16 bits) = adc_H
    bl converte_umidade_ar
    mov x22, x0             // guarda umidade em centesimos de %

    mov x0, #1
    ldr x1, =msg_umidade_ar_convertida
    mov x2, #msg_umidade_ar_convertida_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x22
    mov x1, #100
    mov x2, #2
    bl imprime_valor_fixo

    mov x0, #1
    ldr x1, =msg_percent
    mov x2, #msg_percent_fim
    mov x8, #SYS_WRITE
    svc #0

    // grava a amostra convertida na tabela de 5 minutos
    mov x0, x22
    ldr x1, =tabela_umidade_ar
    ldr x2, =indice_umidade_ar
    bl armazena_amostra

    // ---- Luminosidade convertida (usa converte_luz) ----
    ldr x1, =rx_frame
    ldrb w2, [x1, #8]
    ldrb w3, [x1, #9]
    lsl w2, w2, #8
    orr w0, w2, w3          // w0 = luminosidade_bruta (16 bits)
    bl converte_luz
    mov x23, x0             // guarda lux*10

    mov x0, #1
    ldr x1, =msg_luz_convertida
    mov x2, #msg_luz_convertida_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x23
    mov x1, #10
    mov x2, #1
    bl imprime_valor_fixo

    mov x0, #1
    ldr x1, =msg_lux
    mov x2, #msg_lux_fim
    mov x8, #SYS_WRITE
    svc #0

    // grava a amostra convertida na tabela de 5 minutos
    mov x0, x23
    ldr x1, =tabela_luz
    ldr x2, =indice_luz
    bl armazena_amostra

    // ---- Umidade do solo convertida (usa converte_umidade_solo) ----
    ldr x1, =rx_frame
    ldrb w2, [x1, #10]
    ldrb w3, [x1, #11]
    lsl w2, w2, #8
    orr w0, w2, w3          // w0 = umidade_solo_bruta (16 bits, so os 10 baixos usados)
    bl converte_umidade_solo
    mov x24, x0             // guarda umidade do solo em centesimos de %

    mov x0, #1
    ldr x1, =msg_umidade_solo_convertida
    mov x2, #msg_umidade_solo_convertida_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x24
    mov x1, #100
    mov x2, #2
    bl imprime_valor_fixo

    mov x0, #1
    ldr x1, =msg_percent
    mov x2, #msg_percent_fim
    mov x8, #SYS_WRITE
    svc #0

    // grava a amostra convertida na tabela de 5 minutos
    mov x0, x24
    ldr x1, =tabela_solo
    ldr x2, =indice_solo
    bl armazena_amostra

    ldp x23, x24, [sp, 48]
    ldp x21, x22, [sp, 32]
    ldp x19, x20, [sp, 16]
    ldp x29, x30, [sp], 64
    ret

// ============================================================
// imprime_valor_fixo
// Imprime um inteiro escalado como numero com ponto decimal,
// com zeros a esquerda na parte fracionaria quando necessario
// (ex.: valor=2684, divisor=100, casas=2 -> "26.84";
//       valor=205,  divisor=100, casas=2 -> "2.05", nao "2.5").
// Entrada: x0 = valor (inteiro, nao-negativo, ja escalado)
//          x1 = divisor (potencia de 10: 100, 10, etc.)
//          x2 = quantidade de casas decimais a imprimir
// ============================================================
imprime_valor_fixo:
    stp x29, x30, [sp, -48]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]

    mov x19, x1              // divisor
    mov x20, x2              // casas decimais desejadas

    udiv x9, x0, x19
    msub x21, x9, x19, x0    // resto - guardado em x21, NAO em x10, porque
                              // converte_num_para_string usa x9/x10/x11/x12
                              // internamente e os destroi ao ser chamada

    mov x0, x9
    bl converte_num_para_string
    mov x2, x1
    mov x1, x0
    mov x0, #1
    mov x8, #SYS_WRITE
    svc #0

    mov x0, #1
    ldr x1, =msg_ponto
    mov x2, #1
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x21              // resto, ainda intacto em x21
    bl converte_num_para_string
    mov x21, x0              // ponteiro pros digitos da fracao (resto ja foi consumido, reaproveita x21)
    mov x22, x1              // quantidade de digitos gerados

    subs x3, x20, x22
    ble imprime_fracao_fixo

loop_zeros_fixo:
    mov x0, #1
    ldr x1, =msg_zero
    mov x2, #1
    mov x8, #SYS_WRITE
    svc #0
    subs x3, x3, #1
    bgt loop_zeros_fixo

imprime_fracao_fixo:
    mov x0, #1
    mov x1, x21
    mov x2, x22
    mov x8, #SYS_WRITE
    svc #0

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

// ============================================================
// obtem_timestamp
// Le o relogio do sistema (clock_gettime, CLOCK_REALTIME) e
// devolve os segundos desde 1/1/1970 (epoch Unix). Validado via
// qemu-aarch64 contra o "date +%s" do sistema antes de usar.
// Saida: x0 = tv_sec (segundos desde a epoch, uint64)
// ============================================================
obtem_timestamp:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov x0, #CLOCK_REALTIME
    ldr x1, =buffer_timespec
    mov x8, #SYS_CLOCK_GETTIME
    svc #0

    ldr x0, =buffer_timespec
    ldr x0, [x0]          // tv_sec e' o primeiro campo (offset 0)

    ldp x29, x30, [sp], 16
    ret

.section .data
msg_quebra: .asciz "\n"
