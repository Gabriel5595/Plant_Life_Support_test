module i2c_recebe_dados_temp_umiAr_pres (
    input  wire [23:0] pressao_bruta,
    input  wire [23:0] temperatura_bruta,
    input  wire [15:0] umidade_bruta,
    input  wire        leitura_concluida,

    output wire [23:0] pressao_bruta_saida,
    output wire [23:0] temperatura_bruta_saida,
    output wire [15:0] umidade_bruta_saida,
    output wire        leitura_concluida_saida
);

    assign pressao_bruta_saida     = pressao_bruta;
    assign temperatura_bruta_saida = temperatura_bruta;
    assign umidade_bruta_saida     = umidade_bruta;
    assign leitura_concluida_saida = leitura_concluida;

endmodule