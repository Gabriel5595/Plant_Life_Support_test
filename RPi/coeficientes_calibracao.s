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

dig_t1_valor: .hword 0x6FA3
dig_t2_valor: .hword 0x680E
dig_t3_valor: .hword 0x0032

dig_p1_valor: .hword 0x83E6
dig_p2_valor: .hword 0xD665
dig_p3_valor: .hword 0x0BD0
dig_p4_valor: .hword 0x160C
dig_p5_valor: .hword 0x00FE
dig_p6_valor: .hword 0xFFF9
dig_p7_valor: .hword 0x2DB4
dig_p8_valor: .hword 0xD1E8
dig_p9_valor: .hword 0x1388

dig_h1_valor: .byte 0x4B

.align 8
bloco_h2_h6_valor: .byte 0x70, 0x01, 0x00, 0x13, 0x21, 0x03, 0x1E
