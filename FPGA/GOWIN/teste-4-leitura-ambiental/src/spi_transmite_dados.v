module spi_transmite_dados (
    input  wire        sclk,
    input  wire        cs_n,
    output wire        miso,
    input  wire [63:0] dados_atuais  // 8 bytes: pressao(3) + temperatura(3) + umidade(2)
);
    reg [63:0] registrador_saida;

    always @(negedge sclk or posedge cs_n) begin
        if (cs_n)
            registrador_saida <= dados_atuais;
        else
            registrador_saida <= registrador_saida << 1;
    end

    assign miso = registrador_saida[63];
endmodule