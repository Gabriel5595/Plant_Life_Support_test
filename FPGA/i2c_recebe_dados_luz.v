module i2c_recebe_dados_luz (
    input  wire [15:0] luminosidade_bruta,
    input  wire        leitura_concluida,

    output wire [15:0] luminosidade_bruta_saida,
    output wire         leitura_concluida_saida
);

    assign luminosidade_bruta_saida = luminosidade_bruta;
    assign leitura_concluida_saida  = leitura_concluida;

endmodule