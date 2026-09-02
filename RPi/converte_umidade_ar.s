// ============================================================
// converte_umidade_ar.s
//
// Converte a leitura bruta de umidade relativa do ar do BME280
// em %RH, usando a formula inteira oficial do datasheet Bosch
// (32-bit, sem ponto flutuante). Depende de t_fine, calculado
// por converte_temp - por isso converte_temp DEVE ser chamado
// antes, na mesma iteracao.
//
// dig_H4 e dig_H5 sao valores de 12 bits entrelacados no byte
// 0xE5 do sensor (E5[3:0]=dig_H4[3:0], E5[7:4]=dig_H5[3:0]) -
// esse e' o desempacotamento que o FPGA deliberadamente NAO faz
// (fica pra ca, que e' onde a interpretacao de verdade acontece,
// nao na aquisicao).
//
// Validado: Python de referencia e Assembly via qemu-aarch64
// batem exatamente, usando dados reais capturados (Temperatura
// bruta=0x83A200, Umidade bruta=0x7712 -> 61.56% RH).
// ============================================================

.global converte_umidade_ar
.extern t_fine_global
.extern dig_h1_valor
.extern bloco_h2_h6_valor

.section .text

// ============================================================
// converte_umidade_ar
// Entrada: x0 = adc_H (16 bits, leitura bruta de umidade do ar)
// Pre-requisito: converte_temp deve ter sido chamado antes na
//                mesma iteracao (usa t_fine_global)
// Saida:   x0 = umidade relativa em centesimos de porcento
//               (6156 significa 61.56% RH)
// ============================================================
converte_umidade_ar:
    stp x29, x30, [sp, -80]!
    mov x29, sp
    stp x19, x20, [sp, 16]
    stp x21, x22, [sp, 32]
    stp x23, x24, [sp, 48]
    stp x25, x26, [sp, 64]

    mov w19, w0              // adc_H

    // le dig_H1 (unsigned, 1 byte)
    ldr x1, =dig_h1_valor
    ldrb w20, [x1]

    // le os 7 bytes brutos E1..E7 e desempacota dig_H2..H6
    ldr x1, =bloco_h2_h6_valor
    ldrb w2, [x1, #0]        // E1
    ldrb w3, [x1, #1]        // E2
    ldrb w4, [x1, #2]        // E3
    ldrb w5, [x1, #3]        // E4
    ldrb w6, [x1, #4]        // E5
    ldrb w7, [x1, #5]        // E6
    ldrb w8, [x1, #6]        // E7

    // dig_H2 = sinal((E2<<8)|E1), 16 bits
    lsl w21, w3, #8
    orr w21, w21, w2
    sxth w21, w21

    // dig_H3 = E3 (unsigned)
    mov w22, w4

    // dig_H4 = sinal12((E4<<4)|(E5&0xF))
    and w9, w6, #0xF
    lsl w23, w5, #4
    orr w23, w23, w9
    lsl w23, w23, #20
    asr w23, w23, #20

    // dig_H5 = sinal12((E6<<4)|(E5>>4))
    lsr w9, w6, #4
    lsl w24, w7, #4
    orr w24, w24, w9
    lsl w24, w24, #20
    asr w24, w24, #20

    // dig_H6 = sinal8(E7)
    sxtb w25, w8

    // t_fine (32 bits baixos do t_fine_global de 64 bits)
    ldr x1, =t_fine_global
    ldr w26, [x1]

    // v1 = t_fine - 76800
    ldr w9, =76800
    sub w26, w26, w9

    // Part1 = (((adc_H<<14) - (dig_H4<<20) - (dig_H5*v1)) + 16384) >> 15
    lsl w9, w19, #14
    lsl w10, w23, #20
    sub w9, w9, w10
    mul w11, w24, w26
    sub w9, w9, w11
    add w9, w9, #16384
    asr w9, w9, #15          // w9 = Part1

    // Part2 = ((((((v1*dig_H6)>>10) * (((v1*dig_H3)>>11)+32768)) >>10) + 2097152) * dig_H2 + 8192) >> 14
    mul w12, w26, w25
    asr w12, w12, #10
    mul w13, w26, w22
    asr w13, w13, #11
    add w13, w13, #32768
    mul w12, w12, w13
    asr w12, w12, #10
    add w12, w12, #2097152
    mul w12, w12, w21
    add w12, w12, #8192
    asr w12, w12, #14        // w12 = Part2

    mul w14, w9, w12         // new_v = Part1 * Part2

    // final_v = new_v - ((((new_v>>15)^2)>>7) * dig_H1) >> 4
    asr w15, w14, #15
    mul w16, w15, w15
    asr w16, w16, #7
    mul w16, w16, w20
    asr w16, w16, #4
    sub w14, w14, w16

    // clamp [0, 419430400]
    cmp w14, #0
    bge nao_negativo_umid
    mov w14, #0
nao_negativo_umid:
    ldr w17, =419430400
    cmp w14, w17
    ble nao_estoura_umid
    mov w14, w17
nao_estoura_umid:

    // Q22.10 -> descarta os 12 bits fracionarios
    lsr w0, w14, #12

    // centesimos de porcento = (q22_10 * 100) / 1024
    mov w1, #100
    mul w0, w0, w1
    mov w1, #1024
    udiv w0, w0, w1

    ldp x25, x26, [sp, 64]
    ldp x23, x24, [sp, 48]
    ldp x21, x22, [sp, 32]
    ldp x19, x20, [sp, 16]
    ldp x29, x30, [sp], 80
    ret
