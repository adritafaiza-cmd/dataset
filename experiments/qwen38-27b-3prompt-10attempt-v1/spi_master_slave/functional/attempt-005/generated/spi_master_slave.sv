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
    localparam S_IDLE    = 2'd0;
    localparam S_WAIT_WR = 2'd1;
    localparam S_SHIFT   = 2'd2;
    localparam S_DONE    = 2'd3;

    reg [1:0] state;
    reg [1:0] state_next;

    // Shift register and counter
    reg [N-1:0] tx_shift;
    reg [N-1:0] rx_shift;
    reg [N-1:0] bit_count;

    // SCLK divider counter
    reg [3:0] clk_div_cnt;
    reg       clk_div_done;

    // Handshake signals
    reg       wr_ack_int;
    reg       do_valid_int;

    // SCLK phase control
    reg       sclk_phase;

    // Synchronize reset for sclk domain
    reg [1:0] rst_sync;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            rst_sync <= 2'b11;
        else
            rst_sync <= {rst_sync[0], 1'b0};
    end
    wire rst_sclk = rst_sync[1];

    // Synchronize wren_i and di_i to sclk domain
    reg [1:0] wren_sync;
    reg [N-1:0] di_sync;
    always @(posedge sclk_i) begin
        wren_sync <= {wren_sync[0], wren_i};
        di_sync   <= di_i;
    end
    wire wren_sclk = wren_sync[1];
    wire [N-1:0] di_sclk = di_sync;

    // Synchronize do_valid and do_o to pclk domain
    reg [1:0] do_valid_sync;
    reg [N-1:0] do_sync;
    always @(posedge pclk_i) begin
        do_valid_sync <= {do_valid_sync[0], do_valid_int};
        do_sync       <= do_o;
    end
    wire do_valid_pclk = do_valid_sync[1];
    wire [N-1:0] do_pclk = do_sync;

    // Synchronize di_req to pclk domain
    reg [1:0] di_req_sync;
    always @(posedge pclk_i) begin
        di_req_sync <= {di_req_sync[0], di_req_o};
    end
    wire di_req_pclk = di_req_sync[1];

    // Synchronize wr_ack to pclk domain
    reg [1:0] wr_ack_sync;
    always @(posedge pclk_i) begin
        wr_ack_sync <= {wr_ack_sync[0], wr_ack_int};
    end
    wire wr_ack_pclk = wr_ack_sync[1];

    // SCLK generation logic
    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk) begin
            clk_div_cnt  <= 4'd0;
            clk_div_done <= 1'b0;
            sclk_phase   <= 1'b0;
            spi_sck_o    <= 1'b0;
        end else begin
            clk_div_done <= 1'b0;
            if (state == S_SHIFT) begin
                if (clk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                    clk_div_cnt  <= 4'd0;
                    clk_div_done <= 1'b1;
                    sclk_phase   <= ~sclk_phase;
                    spi_sck_o    <= sclk_phase;
                end else begin
                    clk_div_cnt <= clk_div_cnt + 1'b1;
                end
            end else begin
                clk_div_cnt <= 4'd0;
                sclk_phase  <= 1'b0;
                spi_sck_o   <= 1'b0;
            end
        end
    end

    // Main state machine
    always @(posedge sclk_i or posedge rst_sclk) begin
        if (rst_sclk) begin
            state        <= S_IDLE;
            spi_ssel_o   <= 1'b0;
            di_req_o     <= 1'b0;
            wr_ack_int   <= 1'b0;
            do_valid_int <= 1'b0;
            do_o         <= {N{1'b0}};
            tx_shift     <= {N{1'b0}};
            rx_shift     <= {N{1'b0}};
            bit_count    <= {N{1'b0}};
        end else begin
            wr_ack_int   <= 1'b0;
            do_valid_int <= 1'b0;

            case (state)
                S_IDLE: begin
                    spi_ssel_o <= 1'b0;
                    di_req_o   <= 1'b0;
                    if (wren_sclk) begin
                        state      <= S_WAIT_WR;
                        di_req_o   <= 1'b1;
                    end
                end

                S_WAIT_WR: begin
                    di_req_o <= 1'b0;
                    if (wren_sclk) begin
                        tx_shift   <= di_sclk;
                        rx_shift   <= {N{1'b0}};
                        bit_count  <= {N{1'b0}};
                        spi_ssel_o <= 1'b1;
                        wr_ack_int <= 1'b1;
                        state      <= S_SHIFT;
                    end
                end

                S_SHIFT: begin
                    spi_ssel_o <= 1'b1;
                    if (clk_div_done) begin
                        // On rising edge of SCLK (sclk_phase transitions 0->1), capture MISO
                        if (sclk_phase == 1'b1) begin
                            rx_shift <= {spi_miso_i, rx_shift[N-1:1]};
                        end
                        // On falling edge of SCLK (sclk_phase transitions 1->0), shift MOSI
                        if (sclk_phase == 1'b0) begin
                            tx_shift <= {tx_shift[N-2:0], 1'b0};
                        end
                        if (bit_count == N - 1) begin
                            do_o         <= rx_shift;
                            do_valid_int <= 1'b1;
                            state        <= S_DONE;
                        end else begin
                            bit_count <= bit_count + 1'b1;
                        end
                    end
                end

                S_DONE: begin
                    spi_ssel_o <= 1'b0;
                    state      <= S_IDLE;
                end

                default: begin
                    state      <= S_IDLE;
                    spi_ssel_o <= 1'b0;
                end
            endcase
        end
    end

    // MOSI output
    assign spi_mosi_o = tx_shift[N-1];

    // PCLK domain outputs
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;
            do_o       <= {N{1'b0}};
        end else begin
            wr_ack_o   <= wr_ack_pclk;
            do_valid_o <= do_valid_pclk;
            do_o       <= do_pclk;
        end
    end

endmodule
