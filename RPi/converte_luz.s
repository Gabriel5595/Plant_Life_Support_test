// ============================================================
// converte_luz.s
//
// Converte a leitura bruta de luminosidade do BH1750 (modo
// Continuously H-Resolution Mode) em lux. Nao depende de
// nenhum coeficiente de calibracao - o BH1750 nao tem NVM de
// calibracao por unidade, ao contrario do BME280.
//
// Formula do datasheet: lux = bruto / 1.2
// Sem ponto flutuante: lux_x10 = bruto * 10 / 1.2 = bruto * 25 / 3
// (exato, preserva 1 casa decimal, arredondado pra baixo)
//
// Validado: Python de referencia e Assembly via qemu-aarch64
// batem exatamente (raw=0x0019 -> 208 -> 20.8 lux).
// ============================================================

.global converte_luz

.section .text

// ============================================================
// converte_luz
// Entrada: w0 = luminosidade bruta (16 bits, sem sinal)
// Saida:   x0 = lux * 10 (ex.: 208 significa 20.8 lux)
// ============================================================
converte_luz:
    mov w1, #25
    mul w0, w0, w1
    mov w1, #3
    udiv w0, w0, w1
    ret
