// ============================================================
// converte_umidade_solo.s
//
// Converte a leitura bruta do sensor capacitivo de umidade do
// solo (via MCP3008 CH0) em %, usando calibracao de dois pontos
// medida com o sensor fisico real, DEPOIS da correcao do bug de
// alinhamento de bits no fsm_umiSolo.v:
//   Seco no ar (0% umidade):    bruto ~ 644
//   Molhado em agua (100%):     bruto ~ 130
// Relacao inversa (confirmada no datasheet e na captura real):
// bruto alto = seco, bruto baixo = molhado.
//
// ATENCAO: esses dois numeros sao especificos DESSE sensor
// fisico, dessa fiacao e dessa tensao de referencia. Se o sensor
// fisico for trocado, ou a fiacao/alimentacao mudar de novo,
// recalibrar: medir seco/molhado de novo com o main atual
// (ignorando as primeiras leituras de cada teste, ate o valor
// assentar) e atualizar LIMIAR_SECO_VALOR/LIMIAR_MOLHADO_VALOR
// aqui.
// ============================================================

.global converte_umidade_solo

.section .data
.align 8
LIMIAR_SECO_VALOR:    .word 644
LIMIAR_MOLHADO_VALOR: .word 130

.section .text

// ============================================================
// converte_umidade_solo
// Entrada: x0 = umidade_solo_bruta (valor de 10 bits do ADC,
//               0-1023)
// Saida:   x0 = umidade em centesimos de porcento (0 a 10000),
//               ja saturado nos limites (nunca <0% nem >100%)
// ============================================================
converte_umidade_solo:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov w9, w0                    // bruto

    ldr x1, =LIMIAR_SECO_VALOR
    ldr w10, [x1]                 // seco (~644)
    ldr x1, =LIMIAR_MOLHADO_VALOR
    ldr w11, [x1]                 // molhado (~130)

    // satura: mais seco que a referencia -> 0%; mais molhado -> 100%
    cmp w9, w10
    bgt satura_seco_solo
    cmp w9, w11
    blt satura_molhado_solo

    // centesimos_de_% = (seco - bruto) * 10000 / (seco - molhado)
    sub w12, w10, w9               // seco - bruto
    sub w13, w10, w11              // seco - molhado (faixa util)
    mov w14, #10000
    mul w12, w12, w14
    udiv w0, w12, w13
    b fim_conversao_solo

satura_seco_solo:
    mov w0, #0
    b fim_conversao_solo

satura_molhado_solo:
    mov w0, #10000

fim_conversao_solo:
    sxtw x0, w0
    ldp x29, x30, [sp], 16
    ret
