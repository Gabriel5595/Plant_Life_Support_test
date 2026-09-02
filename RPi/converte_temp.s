// ============================================================
// converte_temp.s
//
// Converte a leitura bruta de temperatura do BME280 (ADC de 20
// bits) em graus Celsius, usando a formula inteira oficial do
// datasheet Bosch (32 bits, sem ponto flutuante).
//
// Coeficientes de calibracao vem fixos de coeficientes_calibracao.s
// (nao sao mais transmitidos pelo FPGA - ver esse arquivo pro motivo).
//
// Validado: Python de referencia e Assembly via qemu-aarch64
// batem exatamente (2684 = 26.84 °C) usando os coeficientes de
// calibracao reais do sensor (dig_T1=0x6FA3, dig_T2=0x680E,
// dig_T3=0x0032) e uma leitura bruta real (0x844500).
// ============================================================

.global converte_temp
.global t_fine_global
.extern dig_t1_valor
.extern dig_t2_valor
.extern dig_t3_valor

.section .data
.align 8
t_fine_global: .quad 0   // usado depois por converte_pressao / converte_umidade_ar

.section .text

// ============================================================
// converte_temp
// Entrada: x0 = adc_T (20 bits reais do ADC de temperatura,
//               ja deslocado - temperatura_bruta_24bit >> 4,
//               porque o Bosch guarda so os 4 bits superiores
//               do byte xlsb quando osrs_t=1, que e' o nosso caso)
// Saida:   x0 = temperatura em centesimos de grau Celsius
//               (2684 significa 26.84 °C)
// Efeito colateral: grava t_fine em t_fine_global
// ============================================================
converte_temp:
    stp x29, x30, [sp, -16]!
    mov x29, sp

    mov w9, w0              // adc_T

    ldr x10, =dig_t1_valor
    ldrh w10, [x10]         // dig_T1 (unsigned)
    ldr x11, =dig_t2_valor
    ldrsh w11, [x11]        // dig_T2 (signed)
    ldr x12, =dig_t3_valor
    ldrsh w12, [x12]        // dig_T3 (signed)

    // var1 = ((adc_T>>3) - (dig_T1<<1)) * dig_T2 >> 11
    asr w13, w9, #3
    lsl w14, w10, #1
    sub w13, w13, w14
    mul w13, w13, w11
    asr w13, w13, #11

    // var2 = (((adc_T>>4) - dig_T1)^2 >> 12) * dig_T3 >> 14
    asr w14, w9, #4
    sub w14, w14, w10
    mul w15, w14, w14
    asr w15, w15, #12
    mul w15, w15, w12
    asr w15, w15, #14

    add w16, w13, w15        // t_fine

    sxtw x16, w16
    ldr x17, =t_fine_global
    str x16, [x17]

    // T = (t_fine * 5 + 128) >> 8
    mov w0, #5
    mul w0, w16, w0
    add w0, w0, #128
    asr w0, w0, #8
    sxtw x0, w0

    ldp x29, x30, [sp], 16
    ret
