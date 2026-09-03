// ============================================================
// calcula_info.s
//
// Calcula a media de uma tabela de amostras e zera o indice
// depois (proxima janela de 5 minutos comeca do zero). Reaproveitada
// pelos 4 parametros (temperatura, umidade do ar, luminosidade,
// umidade do solo) - responsabilidade unica: resgatar e calcular,
// nunca grava amostra nova (isso e' o armazena_amostra).
// ============================================================

.global calcula_media

.section .text

// ============================================================
// calcula_media
// Entrada: x0 = ponteiro para a tabela (base)
//          x1 = ponteiro para a variavel de indice
// Saida:   x0 = media das amostras (0 se nao houver nenhuma)
// Efeito colateral: zera o indice apontado por x1
// ============================================================
calcula_media:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    ldr w9, [x1]                   // quantidade de amostras validas
    cmp w9, #0
    beq media_vazia

    mov x10, #0                    // soma (64 bits, evita overflow)
    mov w11, #0                    // contador do loop

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
