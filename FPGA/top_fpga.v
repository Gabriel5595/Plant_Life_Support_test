module top_fpga (
    input  wire clk_pino,
    input  wire sclk_pino,
    input  wire cs_pino,
    input  wire mosi_pino,
    output wire miso_pino,
    output wire led_status,
    inout  wire sda_bme280,
    output wire scl_bme280
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
    wire        leitura_concluida;
    wire [3:0]  passo_debug;

    wire sda_saida_i2c;
    wire sda_direcao_i2c;

    assign sda_bme280 = sda_direcao_i2c ? sda_saida_i2c : 1'bz;

    i2c_recebe_dados_temp_umiAr_pres u_i2c (
        .clk               (clk_pino),
        .reset             (reset_interno),
        .scl               (scl_bme280),
        .sda_saida         (sda_saida_i2c),
        .sda_direcao       (sda_direcao_i2c),
        .sda_entrada       (sda_bme280),
        .pressao_bruta     (pressao_bruta),
        .temperatura_bruta (temperatura_bruta),
        .umidade_bruta     (umidade_bruta),
        .leitura_concluida (leitura_concluida),
        .passo_debug       (passo_debug)
    );

    reg [63:0] dados_para_spi = 64'hA0A1A2A3A4A5A6A7;
    always @(posedge clk_pino) begin
        dados_para_spi <= {pressao_bruta, temperatura_bruta, umidade_bruta};
    end

    spi_transmite_dados u_spi (
        .sclk         (sclk_pino),
        .cs_n         (cs_pino),
        .miso         (miso_pino),
        .dados_atuais (dados_para_spi)
    );

    assign led_status = ~cs_pino;

endmodule