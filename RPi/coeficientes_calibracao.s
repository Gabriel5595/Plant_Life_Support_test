// ============================================================
// coeficientes_calibracao.s
//
// Coeficientes de calibracao do BME280, fixos em codigo.
//
// POR QUE FIXO E NAO TRANSMITIDO PELO FPGA: esses valores sao
// gravados na NVM do sensor na fabrica e nunca mudam em tempo de
// execucao - ja confirmamos isso em varias capturas reais (os
// mesmos 13 valores, identicos, sessao apos sessao). Nao faz
// sentido retransmitir 32 bytes constantes a cada leitura de 2s
// pro resto da vida do projeto. O FPGA voltou a transmitir so o
// frame original de 12 bytes (pressao/temperatura/umidade/luz/
// solo); esses coeficientes aqui sao o valor real ja lido e
// confirmado do sensor fisico do Gabriel.
//
// ATENCAO: se o sensor BME280 fisico for trocado por outra
// unidade no futuro, esses valores precisam ser relidos e
// atualizados aqui (cada unidade fisica tem os seus proprios).
// ============================================================

.global dig_t1_valor
.global dig_t2_valor
.global dig_t3_valor
.global dig_p1_valor
.global dig_p2_valor
.global dig_p3_valor
.global dig_p4_valor
.global dig_p5_valor
.global dig_p6_valor
.global dig_p7_valor
.global dig_p8_valor
.global dig_p9_valor
.global dig_h1_valor
.global bloco_h2_h6_valor

.section .data
.align 8

dig_t1_valor: .hword 0x6FA3    // unsigned
dig_t2_valor: .hword 0x680E    // signed
dig_t3_valor: .hword 0x0032    // signed

dig_p1_valor: .hword 0x83E6    // unsigned
dig_p2_valor: .hword 0xD665    // signed
dig_p3_valor: .hword 0x0BD0    // signed
dig_p4_valor: .hword 0x160C    // signed
dig_p5_valor: .hword 0x00FE    // signed
dig_p6_valor: .hword 0xFFF9    // signed
dig_p7_valor: .hword 0x2DB4    // signed
dig_p8_valor: .hword 0xD1E8    // signed
dig_p9_valor: .hword 0x1388    // signed

dig_h1_valor: .byte 0x4B       // unsigned

// dig_H2..H6 brutos, na ordem em que chegaram do sensor (0xE1
// primeiro). Desempacotar dig_H4/dig_H5 (12 bits entrelacados no
// byte 0xE5) fica pra quando calcularmos umidade do ar.
.align 8
bloco_h2_h6_valor: .byte 0x70, 0x01, 0x00, 0x13, 0x21, 0x03, 0x1E
