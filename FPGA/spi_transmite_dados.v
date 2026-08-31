module spi_transmite_dados (
    input  wire        sclk,
    input  wire        cs_n,
    output wire        miso,
    input  wire [79:0] dados_atuais  // 10 bytes: pressao(3) + temperatura(3) + umidade(2) + luminosidade(2)
);
    reg [79:0] registrador_saida;

    always @(negedge sclk or posedge cs_n) begin
        if (cs_n)
            registrador_saida <= dados_atuais;
        else
            registrador_saida <= registrador_saida << 1;
    end

    assign miso = registrador_saida[79];
endmodule