
.global fsm_principal
.extern recebe_info
.extern calcula_media
.extern eh_dia
.extern aciona_bomba
.extern aciona_luz
.extern imprime_valor_fixo
.extern converte_num_para_string
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
.extern apresenta_info_em_tela

.equ AMOSTRAS_POR_JANELA, 150
.equ LIMIAR_SOLO_SECO_CENTIPERCENT, 3500

.section .data

luz_ligada: .word 0

.align 8
numero_iteracao_global: .word 1

.align 8
tempo_entre_leituras_fsm:
    .quad 2
    .quad 0

.align 8
tempo_pulso_rega:
    .quad 15
    .quad 0

msg_media_temp: .asciz "\n[DIGERIR_DADOS] Media 5min - Temperatura: "
msg_media_temp_fim = . - msg_media_temp - 1

msg_media_umidade_ar: .asciz "\n[DIGERIR_DADOS] Media 5min - Umidade do ar: "
msg_media_umidade_ar_fim = . - msg_media_umidade_ar - 1

msg_media_luz: .asciz "\n[DIGERIR_DADOS] Media 5min - Luminosidade: "
msg_media_luz_fim = . - msg_media_luz - 1

msg_media_solo: .asciz "\n[DIGERIR_DADOS] Media 5min - Umidade do solo: "
msg_media_solo_fim = . - msg_media_solo - 1

msg_graus_c_fsm: .asciz " °C"
msg_graus_c_fsm_fim = . - msg_graus_c_fsm - 1

msg_percent_fsm: .asciz " %"
msg_percent_fsm_fim = . - msg_percent_fsm - 1

msg_lux_fsm: .asciz " lux\n"
msg_lux_fsm_fim = . - msg_lux_fsm - 1

msg_molhar: .asciz "[DIGERIR_DADOS] Solo seco -> MOLHAR_PLANTA\n"
msg_molhar_fim = . - msg_molhar - 1

msg_iluminar: .asciz "[DIGERIR_DADOS] Escuro de dia -> ILUMINAR_PLANTA\n"
msg_iluminar_fim = . - msg_iluminar - 1

msg_parar_luz: .asciz "[DIGERIR_DADOS] Luz suficiente ou noite -> PARA_DE_ILUMINAR_PLANTA\n"
msg_parar_luz_fim = . - msg_parar_luz - 1

msg_nada_a_fazer: .asciz "[DIGERIR_DADOS] Nenhuma transicao necessaria -> RECEBER_DADOS\n"
msg_nada_a_fazer_fim = . - msg_nada_a_fazer - 1

.section .text

fsm_principal:
    stp x29, x30, [sp, -48]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]

    mov x19, x0

estado_receber_dados:
    mov w20, #0

loop_receber_dados:
    mov x0, x19
    ldr x1, =numero_iteracao_global
    ldr w1, [x1]
    bl recebe_info

    ldr x1, =numero_iteracao_global
    ldr w2, [x1]
    add w2, w2, #1
    str w2, [x1]

    ldr x0, =tempo_entre_leituras_fsm
    mov x1, #0
    mov x8, #SYS_NANOSLEEP
    svc #0

    add w20, w20, #1
    cmp w20, #AMOSTRAS_POR_JANELA
    blt loop_receber_dados

estado_digerir_dados:
    ldr x0, =tabela_temp
    ldr x1, =indice_temp
    bl calcula_media
    mov w21, w0

    mov x0, #1
    ldr x1, =msg_media_temp
    mov x2, #msg_media_temp_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, x21
    mov x1, #100
    mov x2, #2
    bl imprime_valor_fixo
    mov x0, #1
    ldr x1, =msg_graus_c_fsm
    mov x2, #msg_graus_c_fsm_fim
    mov x8, #SYS_WRITE
    svc #0

    ldr x0, =tabela_umidade_ar
    ldr x1, =indice_umidade_ar
    bl calcula_media
    mov w22, w0

    mov x0, #1
    ldr x1, =msg_media_umidade_ar
    mov x2, #msg_media_umidade_ar_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, x22
    mov x1, #100
    mov x2, #2
    bl imprime_valor_fixo
    mov x0, #1
    ldr x1, =msg_percent_fsm
    mov x2, #msg_percent_fsm_fim
    mov x8, #SYS_WRITE
    svc #0

    ldr x0, =tabela_luz
    ldr x1, =indice_luz
    bl calcula_media
    mov w23, w0

    mov x0, #1
    ldr x1, =msg_media_luz
    mov x2, #msg_media_luz_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, x23
    mov x1, #10
    mov x2, #1
    bl imprime_valor_fixo
    mov x0, #1
    ldr x1, =msg_lux_fsm
    mov x2, #msg_lux_fsm_fim
    mov x8, #SYS_WRITE
    svc #0

    ldr x0, =tabela_solo
    ldr x1, =indice_solo
    bl calcula_media
    mov w24, w0

    mov x0, #1
    ldr x1, =msg_media_solo
    mov x2, #msg_media_solo_fim
    mov x8, #SYS_WRITE
    svc #0
    mov x0, x24
    mov x1, #100
    mov x2, #2
    bl imprime_valor_fixo
    mov x0, #1
    ldr x1, =msg_percent_fsm
    mov x2, #msg_percent_fsm_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x21
    mov x1, x22
    mov x2, x23
    mov x3, x24
    bl apresenta_info_em_tela

    cmp w24, #LIMIAR_SOLO_SECO_CENTIPERCENT
    blt estado_molhar_planta

    bl eh_dia
    cmp x0, #0
    beq decide_noite

    ldr w9, =5000
    cmp w23, w9
    blt decide_liga_luz
    b decide_desliga_luz_se_ligada

decide_noite:
    b decide_desliga_luz_se_ligada

decide_liga_luz:
    ldr x1, =luz_ligada
    ldr w2, [x1]
    cmp w2, #0
    bne estado_receber_dados_nada
    b estado_iluminar_planta

decide_desliga_luz_se_ligada:
    ldr x1, =luz_ligada
    ldr w2, [x1]
    cmp w2, #0
    beq estado_receber_dados_nada
    b estado_para_de_iluminar_planta

estado_receber_dados_nada:
    mov x0, #1
    ldr x1, =msg_nada_a_fazer
    mov x2, #msg_nada_a_fazer_fim
    mov x8, #SYS_WRITE
    svc #0
    b estado_receber_dados

estado_molhar_planta:
    mov x0, #1
    ldr x1, =msg_molhar
    mov x2, #msg_molhar_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x19
    mov x1, #1
    bl aciona_bomba

    ldr x0, =tempo_pulso_rega
    mov x1, #0
    mov x8, #SYS_NANOSLEEP
    svc #0

    mov x0, x19
    mov x1, #0
    bl aciona_bomba

    mov x0, x21
    mov x1, x22
    mov x2, x23
    mov x3, x24
    bl apresenta_info_em_tela

    b estado_receber_dados

estado_iluminar_planta:
    mov x0, #1
    ldr x1, =msg_iluminar
    mov x2, #msg_iluminar_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x19
    mov x1, #1
    bl aciona_luz

    ldr x1, =luz_ligada
    mov w2, #1
    str w2, [x1]

    mov x0, x21
    mov x1, x22
    mov x2, x23
    mov x3, x24
    bl apresenta_info_em_tela

    b estado_receber_dados

estado_para_de_iluminar_planta:
    mov x0, #1
    ldr x1, =msg_parar_luz
    mov x2, #msg_parar_luz_fim
    mov x8, #SYS_WRITE
    svc #0

    mov x0, x19
    mov x1, #0
    bl aciona_luz

    ldr x1, =luz_ligada
    mov w2, #0
    str w2, [x1]

    mov x0, x21
    mov x1, x22
    mov x2, x23
    mov x3, x24
    bl apresenta_info_em_tela

    b estado_receber_dados
