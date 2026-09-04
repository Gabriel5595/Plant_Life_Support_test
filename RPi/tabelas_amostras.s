.global tabela_temp
.global indice_temp
.global tabela_umidade_ar
.global indice_umidade_ar
.global tabela_luz
.global indice_luz
.global tabela_solo
.global indice_solo
.global armazena_amostra

.equ TAMANHO_TABELA, 200

.section .data
.align 8
tabela_temp:       .skip (TAMANHO_TABELA * 4)
indice_temp:       .word 0

tabela_umidade_ar: .skip (TAMANHO_TABELA * 4)
indice_umidade_ar: .word 0

tabela_luz:        .skip (TAMANHO_TABELA * 4)
indice_luz:        .word 0

tabela_solo:       .skip (TAMANHO_TABELA * 4)
indice_solo:       .word 0

.section .text

armazena_amostra:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr w9, [x2]
    cmp w9, #TAMANHO_TABELA
    bge fim_armazena_amostra

    lsl x10, x9, #2
    str w0, [x1, x10]

    add w9, w9, #1
    str w9, [x2]

fim_armazena_amostra:
    ldp x29, x30, [sp], 16
    ret
