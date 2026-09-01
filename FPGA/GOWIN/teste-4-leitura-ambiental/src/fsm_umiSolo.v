module fsm_umiSolo (
    input  wire        clk,
    input  wire        reset,
    output reg         sclk_adc,
    output reg         cs_adc,
    output reg         din_adc,
    input  wire        dout_adc,

    output reg [15:0]  umidade_solo_bruta,
    output reg         leitura_concluida
);

    // Canal unico do MCP3008 usado (CH0). SGL/DIFF=1 (single-ended).
    localparam [2:0] CANAL_SOLO = 3'b000;

    localparam IDLE       = 3'd0;
    localparam ESPERA_CS  = 3'd1;
    localparam TRANSFERE  = 3'd2;
    localparam ESPERA_CSH = 3'd3;
    localparam DONE       = 3'd4;

    reg [2:0] estado;
    reg       fase;         // 0 = SCLK baixo (setup), 1 = SCLK alto (amostra)
    reg [4:0] indice_bit;   // 0..17 (18 pulsos de clock por transacao)
    reg [4:0] comando;      // {start, sgl/diff, d2, d1, d0}
    reg [9:0] dado_recebido;

    reg [15:0] divisor_clock;
    localparam DIVISOR_MAX = 16'd270; // mesmo divisor ja validado no I2C (~100kHz de granularidade)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado             <= IDLE;
            fase               <= 1'b0;
            sclk_adc           <= 1'b0;
            cs_adc             <= 1'b1;
            din_adc            <= 1'b0;
            indice_bit         <= 5'd0;
            comando            <= 5'd0;
            dado_recebido      <= 10'd0;
            divisor_clock      <= 16'd0;
            umidade_solo_bruta <= 16'd0;
            leitura_concluida  <= 1'b0;
        end else begin
            leitura_concluida <= 1'b0;

            if (divisor_clock != DIVISOR_MAX) begin
                divisor_clock <= divisor_clock + 16'd1;
            end else begin
                divisor_clock <= 16'd0;

                case (estado)

                    IDLE: begin
                        cs_adc     <= 1'b1;
                        sclk_adc   <= 1'b0;
                        comando    <= {2'b11, CANAL_SOLO}; // start=1, sgl/diff=1, D2D1D0=canal
                        indice_bit <= 5'd0;
                        fase       <= 1'b0;
                        estado     <= ESPERA_CS;
                    end

                    ESPERA_CS: begin
                        cs_adc <= 1'b0; // CS baixo inicia a transacao
                        estado <= TRANSFERE;
                    end

                    TRANSFERE: begin
                        case (fase)
                            1'b0: begin
                                sclk_adc <= 1'b0;
                                din_adc  <= (indice_bit < 5'd5) ? comando[4] : 1'b0;
                                fase     <= 1'b1;
                            end
                            default: begin
                                sclk_adc <= 1'b1;
                                if (indice_bit >= 5'd8)
                                    dado_recebido <= {dado_recebido[8:0], dout_adc};
                                if (indice_bit < 5'd5)
                                    comando <= {comando[3:0], 1'b0};
                                if (indice_bit == 5'd17) begin
                                    fase   <= 1'b0;
                                    estado <= ESPERA_CSH;
                                end else begin
                                    indice_bit <= indice_bit + 5'd1;
                                    fase       <= 1'b0;
                                end
                            end
                        endcase
                    end

                    ESPERA_CSH: begin
                        sclk_adc           <= 1'b0;
                        cs_adc             <= 1'b1;
                        umidade_solo_bruta <= {6'd0, dado_recebido};
                        estado             <= DONE;
                    end

                    DONE: begin
                        leitura_concluida <= 1'b1;
                        estado            <= IDLE;
                    end

                    default: estado <= IDLE;
                endcase
            end
        end
    end

endmodule