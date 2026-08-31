module top_fpga (
    input  wire clk_pino,
    input  wire sclk_pino,
    input  wire cs_pino,
    input  wire mosi_pino,
    output wire miso_pino,
    output wire led_status,
    inout  wire sda_i2c,
    output wire scl_i2c
);

    reg [3:0] contador_reset = 4'd0;
    reg       reset_interno  = 1'b1;
    always @(posedge clk_pino) begin
        if (contador_reset != 4'd15)
            contador_reset <= contador_reset + 4'd1;
        else
            reset_interno <= 1'b0;
    end

    wire [23:0] pressao_bruta;
    wire [23:0] temperatura_bruta;
    wire [15:0] umidade_bruta;
    wire [15:0] luminosidade_bruta;
    wire        leitura_concluida;

    wire sda_saida_i2c;
    wire sda_direcao_i2c;

    assign sda_i2c = sda_direcao_i2c ? sda_saida_i2c : 1'bz;

    // Placeholder: quem instancia fsm_ambiente sera o fsm_top, mais a
    // frente (orquestracao/timer, ainda nao implementado). Por
    // enquanto top_fpga.v instancia direto.
    fsm_ambiente u_fsm (
        .clk                (clk_pino),
        .reset              (reset_interno),
        .scl                (scl_i2c),
        .sda_saida          (sda_saida_i2c),
        .sda_direcao        (sda_direcao_i2c),
        .sda_entrada        (sda_i2c),
        .pressao_bruta      (pressao_bruta),
        .temperatura_bruta  (temperatura_bruta),
        .umidade_bruta      (umidade_bruta),
        .luminosidade_bruta (luminosidade_bruta),
        .leitura_concluida  (leitura_concluida)
    );

    wire [23:0] pressao_bruta_final;
    wire [23:0] temperatura_bruta_final;
    wire [15:0] umidade_bruta_final;
    wire        leitura_concluida_ambiente;

    i2c_recebe_dados_temp_umiAr_pres u_dados_ambiente (
        .pressao_bruta           (pressao_bruta),
        .temperatura_bruta       (temperatura_bruta),
        .umidade_bruta           (umidade_bruta),
        .leitura_concluida       (leitura_concluida),
        .pressao_bruta_saida     (pressao_bruta_final),
        .temperatura_bruta_saida (temperatura_bruta_final),
        .umidade_bruta_saida     (umidade_bruta_final),
        .leitura_concluida_saida (leitura_concluida_ambiente)
    );

    wire [15:0] luminosidade_bruta_final;
    wire        leitura_concluida_luz;

    i2c_recebe_dados_luz u_dados_luz (
        .luminosidade_bruta       (luminosidade_bruta),
        .leitura_concluida        (leitura_concluida),
        .luminosidade_bruta_saida (luminosidade_bruta_final),
        .leitura_concluida_saida  (leitura_concluida_luz)
    );

    reg [79:0] dados_para_spi = 80'hA0A1A2A3A4A5A6A7A8A9;
    always @(posedge clk_pino) begin
        dados_para_spi <= {pressao_bruta_final, temperatura_bruta_final,
                            umidade_bruta_final, luminosidade_bruta_final};
    end

    spi_transmite_dados u_spi (
        .sclk         (sclk_pino),
        .cs_n         (cs_pino),
        .miso         (miso_pino),
        .dados_atuais (dados_para_spi)
    );

    assign led_status = ~cs_pino;

endmodule