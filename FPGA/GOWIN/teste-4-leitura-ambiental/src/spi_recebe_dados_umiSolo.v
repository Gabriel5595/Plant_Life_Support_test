module spi_recebe_dados_umiSolo (
    input  wire [15:0] umidade_solo_bruta,
    input  wire        leitura_concluida,

    output wire [15:0] umidade_solo_bruta_saida,
    output wire        leitura_concluida_saida
);

    assign umidade_solo_bruta_saida = umidade_solo_bruta;
    assign leitura_concluida_saida  = leitura_concluida;

endmodule