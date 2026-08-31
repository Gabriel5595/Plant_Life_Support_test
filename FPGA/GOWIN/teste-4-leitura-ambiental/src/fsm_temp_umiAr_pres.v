module fsm_temp_umiAr_pres (
    input  wire        clk,
    input  wire        reset,
    output reg         scl,
    output reg         sda_saida,
    output reg         sda_direcao,
    input  wire        sda_entrada,

    output reg [23:0]  pressao_bruta,
    output reg [23:0]  temperatura_bruta,
    output reg [15:0]  umidade_bruta,
    output reg         leitura_concluida,
    output wire [3:0]  passo_debug
);

    localparam [6:0] ENDERECO_SENSOR = 7'h76;

    // 10 estados no total -- cada acao de protocolo (enviar byte,
    // checar ack, receber byte) e generica e reutilizada em todos os
    // pontos da transacao, em vez de um estado nomeado por micro-passo.
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

    reg [3:0] estado;

    // Fase dentro do estado atual (0..3): 0=prepara dado com SCL baixo,
    // 1=sobe SCL, 2=mantem SCL alto (ponto de amostragem), 3=desce SCL.
    reg [1:0] fase;

    reg [2:0] indice_bit;
    reg [7:0] byte_atual;

    reg [3:0] passo;
    assign passo_debug = passo;

    reg       configurado;
    reg [1:0] indice_config;
    reg [2:0] indice_leitura;

    reg [7:0] reg_config;
    reg [7:0] valor_config;
    always @(*) begin
        case (indice_config)
            2'd0: begin reg_config = 8'hF2; valor_config = 8'h01; end
            2'd1: begin reg_config = 8'hF4; valor_config = 8'h27; end
            default: begin reg_config = 8'hF5; valor_config = 8'hA0; end
        endcase
    end

    reg [15:0] divisor_clock;
    localparam DIVISOR_MAX = 16'd270;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado            <= IDLE;
            fase              <= 2'd0;
            scl               <= 1'b1;
            sda_saida         <= 1'b1;
            sda_direcao       <= 1'b1;
            divisor_clock     <= 16'd0;
            passo             <= 4'd0;
            indice_config     <= 2'd0;
            indice_leitura    <= 3'd0;
            configurado       <= 1'b0;
            leitura_concluida <= 1'b0;
            pressao_bruta     <= 24'd0;
            temperatura_bruta <= 24'd0;
            umidade_bruta     <= 16'd0;
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

                    // SDA cai com SCL alto (SCL ja vem alto de IDLE/STOP).
                    START: begin
                        sda_saida   <= 1'b0;
                        sda_direcao <= 1'b1;
                        byte_atual  <= {ENDERECO_SENSOR, 1'b0};
                        indice_bit  <= 3'd7;
                        fase        <= 2'd0;
                        estado      <= WRITE_BYTE;
                    end

                    // Envia byte_atual, MSB primeiro.
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

                    // Solta o barramento, le o ACK, e decide o proximo
                    // passo da transacao.
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
                                    default: estado <= IDLE;
                                endcase
                            end
                        endcase
                    end

                    // Repeated START.
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
                                byte_atual <= {ENDERECO_SENSOR, 1'b1};
                                indice_bit <= 3'd7;
                                fase       <= 2'd0;
                                estado     <= WRITE_BYTE;
                            end
                        endcase
                    end

                    // Recebe um byte, MSB primeiro.
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
                                end else begin
                                    indice_bit <= indice_bit - 3'd1;
                                    fase       <= 2'd0;
                                end
                            end
                        endcase
                    end

                    // Mestre envia ACK (continuar lendo).
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
                                scl            <= 1'b0;
                                indice_leitura <= indice_leitura + 3'd1;
                                indice_bit     <= 3'd7;
                                fase           <= 2'd0;
                                estado         <= READ_BYTE;
                            end
                        endcase
                    end

                    // Mestre envia NACK (ultimo byte lido).
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

                    // STOP.
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
                                if (passo == 4'd2) begin
                                    if (indice_config == 2'd2) begin
                                        configurado <= 1'b1;
                                        passo       <= 4'd3;
                                    end else begin
                                        indice_config <= indice_config + 2'd1;
                                        passo         <= 4'd0;
                                    end
                                    estado <= START;
                                end else begin
                                    estado <= DONE;
                                end
                            end
                        endcase
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