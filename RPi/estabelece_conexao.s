// ============================================================
// estabelece_conexao.s
//
// Mapeia o GPIO via /dev/gpiomem e configura direcao/nivel
// inicial dos 4 pinos usados no SPI por bit-banging. Depois de
// configurar os pinos, faz uma transacao de descarte (leitura de
// 44 bytes, o mesmo tamanho do frame real usado em
// recebe_info.s) antes de retornar - joga o resultado fora, so
// serve pra absorver o transiente eletrico da primeira mudanca
// de direcao dos GPIOs.
//
// Motivo confirmado em captura real: sem essa transacao de
// descarte, a primeira leitura de verdade (Iteracao 1) saia com
// o frame inteiro de 352 bits deslocado 1 bit para a direita -
// cada campo aparecia como (valor_real / 2), com o bit menos
// significativo perdido. A partir da Iteracao 2 tudo ja saia
// certo. A transacao de descarte abaixo absorve esse soluco
// antes que a primeira leitura real aconteca.
//
// Saida:
//   x0 = base mapeada (se sucesso)
//   x1 = status (0 = OK, 1 = erro)
// ============================================================

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

// Mesmo tamanho do frame real (rx_frame em recebe_info.s). Se o
// frame mudar de tamanho de novo no futuro, atualizar aqui tambem.
.equ TAMANHO_FRAME_DESCARTE, 44

.section .data
.align 8
tempo_espera_descarte:
    .quad 0
    .quad 10000    // 10us - mesmo timing de bit usado em recebe_info.s

.section .text

estabelece_conexao:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    bl gpio_map
    cmp x1, #0
    b.ne conexao_erro

    mov x19, x0

    // SCLK: saida, nivel inicial baixo (ocioso, Modo SPI 0)
    mov x0, x19
    mov w1, #SCLK_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #SCLK_GPIO
    mov w2, #0
    bl gpio_write

    // CS: saida, nivel inicial alto (ocioso, ativo em baixo)
    mov x0, x19
    mov w1, #CS_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #CS_GPIO
    mov w2, #1
    bl gpio_write

    // MOSI: saida, fixo em baixo (nao usado nesta etapa)
    mov x0, x19
    mov w1, #MOSI_GPIO
    bl gpio_set_output
    mov x0, x19
    mov w1, #MOSI_GPIO
    mov w2, #0
    bl gpio_write

    // MISO: entrada
    mov x0, x19
    mov w1, #MISO_GPIO
    bl gpio_set_input

    // ------------------------------------------------------------
    // Transacao de descarte: uma leitura completa de 44 bytes,
    // igual ao frame real, mas sem guardar nem imprimir nada. So
    // absorve o transiente eletrico da primeira mudanca de
    // direcao dos GPIOs, antes que a primeira leitura de verdade
    // (em recebe_info.s) aconteca.
    // ------------------------------------------------------------
    mov x0, x19
    mov w1, #CS_GPIO
    mov w2, #0
    bl gpio_write

    bl atraso_curto_descarte

    mov x20, #0   // contador de bytes

loop_bytes_descarte:
    cmp x20, #TAMANHO_FRAME_DESCARTE
    b.ge fim_bytes_descarte

    mov x21, #0   // contador de bits

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
    // resultado descartado de proposito - e essa a ideia

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

// ============================================================
// atraso_curto_descarte
// Mesmo atraso de 10us usado em recebe_info.s, duplicado aqui
// para manter estabelece_conexao.s autossuficiente (nao depende
// de nenhum simbolo de recebe_info.s).
// ============================================================
atraso_curto_descarte:
    stp x29, x30, [sp, -16]!
    mov x29, sp
    ldr x0, =tempo_espera_descarte
    mov x1, #0
    mov x8, #SYS_NANOSLEEP
    svc #0
    ldp x29, x30, [sp], 16
    ret
