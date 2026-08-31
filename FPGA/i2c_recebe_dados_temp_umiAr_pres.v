module i2c_recebe_dados_temp_umiAr_pres (
    input  wire        clk,
    input  wire        reset,
    output wire        scl,
    output wire        sda_saida,
    output wire        sda_direcao,
    input  wire        sda_entrada,

    output wire [23:0] pressao_bruta,
    output wire [23:0] temperatura_bruta,
    output wire [15:0] umidade_bruta,
    output wire        leitura_concluida,
    output wire [3:0]  passo_debug
);

    fsm_temp_umiAr_pres u_fsm (
        .clk               (clk),
        .reset             (reset),
        .scl               (scl),
        .sda_saida         (sda_saida),
        .sda_direcao       (sda_direcao),
        .sda_entrada       (sda_entrada),
        .pressao_bruta     (pressao_bruta),
        .temperatura_bruta (temperatura_bruta),
        .umidade_bruta     (umidade_bruta),
        .leitura_concluida (leitura_concluida),
        .passo_debug       (passo_debug)
    );

endmodule