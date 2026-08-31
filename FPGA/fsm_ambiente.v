module fsm_ambiente (
    input  wire        clk,
    input  wire        reset,
    output reg         scl,
    output reg         sda_saida,
    output reg         sda_direcao,
    input  wire        sda_entrada,

    output reg [23:0]  pressao_bruta,
    output reg [23:0]  temperatura_bruta,
    output reg [15:0]  umidade_bruta,
    output reg [15:0]  luminosidade_bruta,
    output reg         leitura_concluida
);

    localparam [6:0] ENDERECO_BME280 = 7'h76;
    localparam [6:0] ENDERECO_LUZ    = 7'h23;

    localparam IDLE       = 4'd0;
    localparam START      = 4'd1;
    localparam WRITE_BYTE = 4'd2;
    localparam CHECK_ACK  = 4'd3;
    localparam RESTART    = 4'd4;
    localparam READ_BYTE  = 4'd5;
    localparam SEND_ACK   = 4'd6;
    localparam SEND_NACK  = 4'd7;
    localparam STOP       = 4'd8;
    localparam DONE       = 4'd9;
    localparam ESPERA     = 4'd10;

    reg [3:0] estado;
    reg [1:0] fase;
    reg [2:0] indice_bit;
    reg [7:0] byte_atual;

    // passo identifica a proxima acao a ser tomada apos o CHECK_ACK
    // corrente. 0-2: config do BME280. 3-5: leitura do BME280.
    // 6-7: config do BH1750 (uma vez). 8: leitura do BH1750.
    reg [3:0] passo;

    reg       configurado;
    reg       configurado_luz;
    reg [1:0] indice_config;
    reg [2:0] indice_leitura;
    reg       indice_leitura_luz;

    reg [7:0] reg_config;
    reg [7:0] valor_config;
    always @(*) begin
        case (indice_config)
            2'd0: begin reg_config = 8'hF2; valor_config = 8'h01; end
            2'd1: begin reg_config = 8'hF4; valor_config = 8'h27; end
            default: begin reg_config = 8'hF5; valor_config = 8'hA0; end
        endcase
    end

    reg [6:0] endereco_atual;
    always @(*) begin
        case (passo)
            4'd6, 4'd7, 4'd8: endereco_atual = ENDERECO_LUZ;
            default:          endereco_atual = ENDERECO_BME280;
        endcase
    end

    reg [15:0] divisor_clock;
    localparam DIVISOR_MAX = 16'd270;

    localparam ESPERA_MAX = 16'd20000;
    reg [15:0] contador_espera;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado             <= IDLE;
            fase               <= 2'd0;
            scl                <= 1'b1;
            sda_saida          <= 1'b1;
            sda_direcao        <= 1'b1;
            divisor_clock      <= 16'd0;
            passo              <= 4'd0;
            indice_config      <= 2'd0;
            indice_leitura     <= 3'd0;
            indice_leitura_luz <= 1'b0;
            configurado        <= 1'b0;
            configurado_luz    <= 1'b0;
            contador_espera    <= 16'd0;
            leitura_concluida  <= 1'b0;
            pressao_bruta      <= 24'd0;
            temperatura_bruta  <= 24'd0;
            umidade_bruta      <= 16'd0;
            luminosidade_bruta <= 16'd0;
        end else begin
            leitura_concluida <= 1'b0;

            if (divisor_clock != DIVISOR_MAX) begin
                divisor_clock <= divisor_clock + 16'd1;
            end else begin
                divisor_clock <= 16'd0;

                case (estado)

                    IDLE: begin
                        scl         <= 1'b1;
                        sda_saida   <= 1'b1;
                        sda_direcao <= 1'b1;
                        fase        <= 2'd0;
                        passo       <= configurado ? 4'd3 : 4'd0;
                        estado      <= START;
                    end

                    START: begin
                        sda_saida   <= 1'b0;
                        sda_direcao <= 1'b1;
                        byte_atual  <= {endereco_atual, (passo == 4'd8) ? 1'b1 : 1'b0};
                        indice_bit  <= 3'd7;
                        fase        <= 2'd0;
                        estado      <= WRITE_BYTE;
                    end

                    WRITE_BYTE: begin
                        case (fase)
                            2'd0: begin
                                scl         <= 1'b0;
                                sda_direcao <= 1'b1;
                                sda_saida   <= byte_atual[indice_bit];
                                fase        <= 2'd1;
                            end
                            2'd1: begin
                                scl  <= 1'b1;
                                fase <= 2'd2;
                            end
                            2'd2: begin
                                fase <= 2'd3;
                            end
                            default: begin
                                scl <= 1'b0;
                                if (indice_bit == 3'd0) begin
                                    fase   <= 2'd0;
                                    estado <= CHECK_ACK;
                                end else begin
                                    indice_bit <= indice_bit - 3'd1;
                                    fase       <= 2'd0;
                                end
                            end
                        endcase
                    end

                    CHECK_ACK: begin
                        case (fase)
                            2'd0: begin
                                scl         <= 1'b0;
                                sda_direcao <= 1'b0;
                                fase        <= 2'd1;
                            end
                            2'd1: begin
                                scl  <= 1'b1;
                                fase <= 2'd2;
                            end
                            2'd2: begin
                                fase <= 2'd3;
                            end
                            default: begin
                                scl         <= 1'b0;
                                sda_direcao <= 1'b1;
                                fase        <= 2'd0;
                                case (passo)
                                    4'd0: begin
                                        byte_atual <= reg_config;
                                        indice_bit <= 3'd7;
                                        passo      <= 4'd1;
                                        estado     <= WRITE_BYTE;
                                    end
                                    4'd1: begin
                                        byte_atual <= valor_config;
                                        indice_bit <= 3'd7;
                                        passo      <= 4'd2;
                                        estado     <= WRITE_BYTE;
                                    end
                                    4'd2: begin
                                        estado <= STOP;
                                    end
                                    4'd3: begin
                                        byte_atual <= 8'hF7;
                                        indice_bit <= 3'd7;
                                        passo      <= 4'd4;
                                        estado     <= WRITE_BYTE;
                                    end
                                    4'd4: begin
                                        passo  <= 4'd5;
                                        estado <= RESTART;
                                    end
                                    4'd5: begin
                                        indice_leitura <= 3'd0;
                                        indice_bit     <= 3'd7;
                                        estado         <= READ_BYTE;
                                    end
                                    4'd6: begin
                                        byte_atual <= 8'h10;
                                        indice_bit <= 3'd7;
                                        passo      <= 4'd7;
                                        estado     <= WRITE_BYTE;
                                    end
                                    4'd7: begin
                                        estado <= STOP;
                                    end
                                    4'd8: begin
                                        indice_leitura_luz <= 1'b0;
                                        indice_bit         <= 3'd7;
                                        estado             <= READ_BYTE;
                                    end
                                    default: estado <= IDLE;
                                endcase
                            end
                        endcase
                    end

                    RESTART: begin
                        case (fase)
                            2'd0: begin
                                scl  <= 1'b0;
                                fase <= 2'd1;
                            end
                            2'd1: begin
                                sda_direcao <= 1'b1;
                                sda_saida   <= 1'b1;
                                fase        <= 2'd2;
                            end
                            2'd2: begin
                                scl  <= 1'b1;
                                fase <= 2'd3;
                            end
                            default: begin
                                sda_saida  <= 1'b0;
                                byte_atual <= {endereco_atual, 1'b1};
                                indice_bit <= 3'd7;
                                fase       <= 2'd0;
                                estado     <= WRITE_BYTE;
                            end
                        endcase
                    end

                    READ_BYTE: begin
                        case (fase)
                            2'd0: begin
                                scl         <= 1'b0;
                                sda_direcao <= 1'b0;
                                fase        <= 2'd1;
                            end
                            2'd1: begin
                                scl  <= 1'b1;
                                fase <= 2'd2;
                            end
                            2'd2: begin
                                byte_atual <= {byte_atual[6:0], sda_entrada};
                                fase       <= 2'd3;
                            end
                            default: begin
                                scl <= 1'b0;
                                if (indice_bit == 3'd0) begin
                                    if (passo == 4'd8) begin
                                        case (indice_leitura_luz)
                                            1'b0: luminosidade_bruta[15:8] <= byte_atual;
                                            default: luminosidade_bruta[7:0] <= byte_atual;
                                        endcase
                                        fase   <= 2'd0;
                                        estado <= (indice_leitura_luz == 1'b1) ? SEND_NACK : SEND_ACK;
                                    end else begin
                                        case (indice_leitura)
                                            3'd0: pressao_bruta[23:16]     <= byte_atual;
                                            3'd1: pressao_bruta[15:8]      <= byte_atual;
                                            3'd2: pressao_bruta[7:0]       <= byte_atual;
                                            3'd3: temperatura_bruta[23:16] <= byte_atual;
                                            3'd4: temperatura_bruta[15:8]  <= byte_atual;
                                            3'd5: temperatura_bruta[7:0]   <= byte_atual;
                                            3'd6: umidade_bruta[15:8]      <= byte_atual;
                                            default: umidade_bruta[7:0]    <= byte_atual;
                                        endcase
                                        fase   <= 2'd0;
                                        estado <= (indice_leitura == 3'd7) ? SEND_NACK : SEND_ACK;
                                    end
                                end else begin
                                    indice_bit <= indice_bit - 3'd1;
                                    fase       <= 2'd0;
                                end
                            end
                        endcase
                    end

                    SEND_ACK: begin
                        case (fase)
                            2'd0: begin
                                scl         <= 1'b0;
                                sda_direcao <= 1'b1;
                                sda_saida   <= 1'b0;
                                fase        <= 2'd1;
                            end
                            2'd1: begin scl <= 1'b1; fase <= 2'd2; end
                            2'd2: begin fase <= 2'd3; end
                            default: begin
                                scl <= 1'b0;
                                if (passo == 4'd8)
                                    indice_leitura_luz <= indice_leitura_luz + 1'b1;
                                else
                                    indice_leitura <= indice_leitura + 3'd1;
                                indice_bit <= 3'd7;
                                fase       <= 2'd0;
                                estado     <= READ_BYTE;
                            end
                        endcase
                    end

                    SEND_NACK: begin
                        case (fase)
                            2'd0: begin
                                scl         <= 1'b0;
                                sda_direcao <= 1'b1;
                                sda_saida   <= 1'b1;
                                fase        <= 2'd1;
                            end
                            2'd1: begin scl <= 1'b1; fase <= 2'd2; end
                            2'd2: begin fase <= 2'd3; end
                            default: begin
                                scl    <= 1'b0;
                                fase   <= 2'd0;
                                estado <= STOP;
                            end
                        endcase
                    end

                    STOP: begin
                        case (fase)
                            2'd0: begin
                                scl  <= 1'b0;
                                fase <= 2'd1;
                            end
                            2'd1: begin
                                sda_direcao <= 1'b1;
                                sda_saida   <= 1'b0;
                                fase        <= 2'd2;
                            end
                            2'd2: begin
                                scl  <= 1'b1;
                                fase <= 2'd3;
                            end
                            default: begin
                                sda_saida <= 1'b1;
                                fase      <= 2'd0;
                                case (passo)
                                    4'd2: begin
                                        if (indice_config == 2'd2) begin
                                            configurado <= 1'b1;
                                            passo       <= 4'd3;
                                        end else begin
                                            indice_config <= indice_config + 2'd1;
                                            passo         <= 4'd0;
                                        end
                                        estado <= START;
                                    end
                                    4'd5: begin
                                        passo  <= configurado_luz ? 4'd8 : 4'd6;
                                        estado <= START;
                                    end
                                    4'd7: begin
                                        estado <= ESPERA;
                                    end
                                    default: begin
                                        estado <= DONE;
                                    end
                                endcase
                            end
                        endcase
                    end

                    ESPERA: begin
                        if (contador_espera == ESPERA_MAX) begin
                            contador_espera <= 16'd0;
                            configurado_luz <= 1'b1;
                            passo           <= 4'd8;
                            estado          <= START;
                        end else begin
                            contador_espera <= contador_espera + 16'd1;
                        end
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