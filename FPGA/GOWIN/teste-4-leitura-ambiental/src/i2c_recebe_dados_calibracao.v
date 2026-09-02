module i2c_recebe_dados_calibracao (
    input  wire [15:0] dig_t1_bruto,
    input  wire [15:0] dig_t2_bruto,
    input  wire [15:0] dig_t3_bruto,
    input  wire [15:0] dig_p1_bruto,
    input  wire [15:0] dig_p2_bruto,
    input  wire [15:0] dig_p3_bruto,
    input  wire [15:0] dig_p4_bruto,
    input  wire [15:0] dig_p5_bruto,
    input  wire [15:0] dig_p6_bruto,
    input  wire [15:0] dig_p7_bruto,
    input  wire [15:0] dig_p8_bruto,
    input  wire [15:0] dig_p9_bruto,
    input  wire [7:0]  dig_h1_bruto,
    input  wire [55:0] bloco_h2_h6_bruto,
    input  wire        leitura_concluida,

    output wire [15:0] dig_t1_bruto_saida,
    output wire [15:0] dig_t2_bruto_saida,
    output wire [15:0] dig_t3_bruto_saida,
    output wire [15:0] dig_p1_bruto_saida,
    output wire [15:0] dig_p2_bruto_saida,
    output wire [15:0] dig_p3_bruto_saida,
    output wire [15:0] dig_p4_bruto_saida,
    output wire [15:0] dig_p5_bruto_saida,
    output wire [15:0] dig_p6_bruto_saida,
    output wire [15:0] dig_p7_bruto_saida,
    output wire [15:0] dig_p8_bruto_saida,
    output wire [15:0] dig_p9_bruto_saida,
    output wire [7:0]  dig_h1_bruto_saida,
    output wire [55:0] bloco_h2_h6_bruto_saida,
    output wire         leitura_concluida_saida
);

    assign dig_t1_bruto_saida = dig_t1_bruto;
    assign dig_t2_bruto_saida = dig_t2_bruto;
    assign dig_t3_bruto_saida = dig_t3_bruto;
    assign dig_p1_bruto_saida = dig_p1_bruto;
    assign dig_p2_bruto_saida = dig_p2_bruto;
    assign dig_p3_bruto_saida = dig_p3_bruto;
    assign dig_p4_bruto_saida = dig_p4_bruto;
    assign dig_p5_bruto_saida = dig_p5_bruto;
    assign dig_p6_bruto_saida = dig_p6_bruto;
    assign dig_p7_bruto_saida = dig_p7_bruto;
    assign dig_p8_bruto_saida = dig_p8_bruto;
    assign dig_p9_bruto_saida = dig_p9_bruto;
    assign dig_h1_bruto_saida = dig_h1_bruto;
    assign bloco_h2_h6_bruto_saida = bloco_h2_h6_bruto;
    assign leitura_concluida_saida = leitura_concluida;

endmodule