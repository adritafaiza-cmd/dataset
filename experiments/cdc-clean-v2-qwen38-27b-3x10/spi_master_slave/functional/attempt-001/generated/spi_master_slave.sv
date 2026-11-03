module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    // State machine states
    localparam S_IDLE    = 3'd0;
    localparam S_WAIT_WR = 3'd1;
    localparam S_SHIFT   = 3'd2;
    localparam S_DONE    = 3'd3;

    reg [2:0] state;
    reg [2:0] next_state;

    // Shift register and counter
    reg [N-1:0] tx_shift;
    reg [N-1:0] rx_shift;
    reg [N-1:0] bit_count;

    // SCLK divider counter
    reg [N-1:0] sclk_div_cnt;
    reg         sclk_phase;

    // MOSI output
    assign spi_mosi_o = tx_shift[N-1];

    // State machine - next state logic
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (wren_i)
                    next_state = S_WAIT_WR;
            end
            S_WAIT_WR: begin
                // Wait for wren to deassert, then start shift
                if (!wren_i)
                    next_state = S_SHIFT;
            end
            S_SHIFT: begin
                if (bit_count == N-1 && sclk_phase == 1'b1)
                    next_state = S_DONE;
            end
            S_DONE: begin
                next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    // State machine - state register
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // SCLK generation and shift logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o    <= 1'b0;
            spi_sck_o     <= 1'b0;
            sclk_div_cnt  <= {N{1'b0}};
            sclk_phase    <= 1'b0;
            tx_shift      <= {N{1'b0}};
            rx_shift      <= {N{1'b0}};
            bit_count     <= {N{1'b0}};
        end else begin
            case (state)
                S_IDLE: begin
                    spi_ssel_o   <= 1'b0;
                    spi_sck_o    <= 1'b0;
                    sclk_div_cnt <= {N{1'b0}};
                    sclk_phase   <= 1'b0;
                    bit_count    <= {N{1'b0}};
                end

                S_WAIT_WR: begin
                    spi_ssel_o   <= 1'b1;
                    spi_sck_o    <= 1'b0;
                    sclk_div_cnt <= {N{1'b0}};
                    sclk_phase   <= 1'b0;
                    bit_count    <= {N{1'b0}};
                    // Load TX data when entering shift
                    if (!wren_i)
                        tx_shift <= di_i;
                end

                S_SHIFT: begin
                    spi_ssel_o <= 1'b1;
                    
                    // SCLK divider
                    if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                        sclk_div_cnt <= {N{1'b0}};
                        sclk_phase   <= ~sclk_phase;
                        
                        if (sclk_phase == 1'b0) begin
                            // Rising edge of SCLK: shift out MSB, capture MISO
                            spi_sck_o  <= 1'b1;
                            tx_shift   <= {tx_shift[N-2:0], 1'b0};
                            rx_shift   <= {spi_miso_i, rx_shift[N-1:0]};
                            bit_count  <= bit_count + 1'b1;
                        end else begin
                            // Falling edge of SCLK
                            spi_sck_o <= 1'b0;
                        end
                    end else begin
                        sclk_div_cnt <= sclk_div_cnt + 1'b1;
                    end
                end

                S_DONE: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o  <= 1'b0;
                end

                default: begin
                    spi_ssel_o   <= 1'b0;
                    spi_sck_o    <= 1'b0;
                    sclk_div_cnt <= {N{1'b0}};
                    sclk_phase   <= 1'b0;
                    bit_count    <= {N{1'b0}};
                end
            endcase
        end
    end

    // Handshake signals
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o   <= 1'b0;
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;
            do_o       <= {N{1'b0}};
        end else begin
            // Default: deassert one-shot signals
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;

            case (state)
                S_IDLE: begin
                    di_req_o <= 1'b1;
                    if (wren_i) begin
                        di_req_o <= 1'b0;
                        wr_ack_o <= 1'b1;
                    end
                end

                S_WAIT_WR: begin
                    di_req_o <= 1'b0;
                end

                S_SHIFT: begin
                    di_req_o <= 1'b0;
                end

                S_DONE: begin
                    di_req_o   <= 1'b1;
                    do_valid_o <= 1'b1;
                    do_o       <= rx_shift;
                end

                default: begin
                    di_req_o <= 1'b0;
                end
            endcase
        end
    end

endmodule
