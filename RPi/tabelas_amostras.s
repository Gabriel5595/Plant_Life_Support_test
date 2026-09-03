// ============================================================
// tabelas_amostras.s
//
// Tabelas de amostras para a media dos 5 minutos (estado
// RECEBER_DADOS da FSM). Um array de 200 slots de 32 bits por
// parametro CONVERTIDO (nao se aplica a pressao, que nao e'
// convertida - decisao de engenharia ja documentada). 200 e' a
// folga sobre as 150 leituras teoricas (5min / 2s de polling),
// absorvendo jitter de tempo entre leituras.
//
// armazena_amostra e' compartilhada pelos 4 parametros - grava
// o valor no proximo slot livre e incrementa o indice, com
// validacao obrigatoria de indice antes de gravar.
// ============================================================

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

// ============================================================
// armazena_amostra
// Grava um valor no proximo slot livre de uma tabela e
// incrementa o indice correspondente. Se a tabela ja estiver
// cheia (indice >= 200), descarta o valor silenciosamente - nao
// deveria acontecer em uso normal (200 > 150 amostras teoricas),
// mas a validacao existe pra nunca escrever fora do array.
//
// Entrada: x0 = valor a gravar (32 bits, com sinal)
//          x1 = ponteiro para a tabela (base)
//          x2 = ponteiro para a variavel de indice
// ============================================================
armazena_amostra:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr w9, [x2]                   // indice atual
    cmp w9, #TAMANHO_TABELA
    bge fim_armazena_amostra       // indice invalido - nao grava

    lsl x10, x9, #2                // offset = indice * 4
    str w0, [x1, x10]

    add w9, w9, #1
    str w9, [x2]

fim_armazena_amostra:
    ldp x29, x30, [sp], 16
    ret
