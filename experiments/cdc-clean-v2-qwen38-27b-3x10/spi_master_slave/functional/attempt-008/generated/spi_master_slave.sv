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

    // Shift register for MOSI
    reg [N-1:0] mosi_shift;
    // Shift register for MISO
    reg [N-1:0] miso_shift;
    // Bit counter
    reg [3:1] bit_cnt;
    // Clock divider counter
    reg [3:0] clk_div_cnt;
    // SCK toggle
    reg sck_toggle;

    // Asynchronous reset for sclk domain
    reg rst_sclk;
    reg rst_sclk_d;

    // Asynchronous reset for pclk domain
    reg rst_pclk;
    reg rst_pclk_d;

    // Synchronize rst_i to sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            rst_sclk <= 1'b1;
            rst_sclk_d <= 1'b1;
        end else begin
            rst_sclk <= 1'b0;
            rst_sclk_d <= 1'b0;
        end
    end

    // Synchronize rst_i to pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            rst_pclk <= 1'b1;
            rst_pclk_d <= 1'b1;
        end else begin
            rst_pclk <= 1'b0;
            rst_pclk_d <= 1'b0;
        end
    end

    // SCK generation in sclk domain
    // SPI_2X_CLK_DIV determines the division factor
    // We generate SCK at sclk_i / (2 * SPI_2X_CLK_DIV)
    // So we need to count to SPI_2X_CLK_DIV - 1 on each half cycle

    wire sclk_active = (clk_div_cnt == SPI_2X_CLK_DIV[3:0] - 1);

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_div_cnt <= 4'd0;
            sck_toggle  <= 1'b0;
        end else begin
            if (state == S_SHIFT) begin
                if (sclk_active) begin
                    clk_div_cnt <= 4'd0;
                    sck_toggle  <= ~sck_toggle;
                end else begin
                    clk_div_cnt <= clk_div_cnt + 4'd1;
                end
            end else begin
                clk_div_cnt <= 4'd0;
                sck_toggle  <= 1'b0;
            end
        end
    end

    // SPI signals in sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b0;
            spi_sck_o  <= 1'b0;
            mosi_shift <= {N{1'b0}};
            miso_shift <= {N{1'b0}};
            bit_cnt    <= 3'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o  <= 1'b0;
                end
                S_WAIT_WR: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o  <= 1'b0;
                end
                S_SHIFT: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o  <= sck_toggle;
                    // On rising edge of SCK (sck_toggle goes 0->1), shift out MSB and capture MISO
                    // On falling edge of SCK (sck_toggle goes 1->0), shift in next bit
                    if (sclk_active) begin
                        if (sck_toggle == 1'b0) begin
                            // Rising edge: shift out MSB, capture MISO
                            mosi_shift <= {mosi_shift[N-2:0], 1'b0};
                            miso_shift <= {miso_shift[N-2:0], spi_miso_i};
                            if (bit_cnt == N[3:1] - 1) begin
                                bit_cnt <= 3'd0;
                            end else begin
                                bit_cnt <= bit_cnt + 3'd1;
                            end
                        end else begin
                            // Falling edge: prepare next bit
                            // mosi_shift already shifted, so MSB is ready
                        end
                    end
                end
                S_DONE: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o  <= 1'b0;
                end
            endcase
        end
    end

    // MOSI output
    assign spi_mosi_o = mosi_shift[N-1];

    // State machine in pclk domain
    // We need to detect when the shift is complete in sclk domain and signal to pclk domain
    // Use a flag that is set when shift completes

    reg shift_done_sclk;
    reg shift_done_sync1;
    reg shift_done_sync2;
    reg shift_done_sync3;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_done_sclk <= 1'b0;
        end else begin
            if (state == S_SHIFT && sclk_active && sck_toggle == 1'b0 && bit_cnt == N[3:1] - 1) begin
                shift_done_sclk <= 1'b1;
            end else begin
                shift_done_sclk <= 1'b0;
            end
        end
    end

    // Synchronize shift_done to pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_done_sync1 <= 1'b0;
            shift_done_sync2 <= 1'b0;
            shift_done_sync3 <= 1'b0;
        end else begin
            shift_done_sync1 <= shift_done_sclk;
            shift_done_sync2 <= shift_done_sync1;
            shift_done_sync3 <= shift_done_sync2;
        end
    end

    // Also need to synchronize the state to pclk domain for control
    reg state_sync1;
    reg state_sync2;
    reg [2:0] state_pclk;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state_sync1 <= 3'd0;
            state_sync2 <= 3'd0;
            state_pclk  <= 3'd0;
        end else begin
            state_sync1 <= state;
            state_sync2 <= state_sync1;
            state_pclk  <= state_sync2;
        end
    end

    // Synchronize miso_shift to pclk domain
    reg [N-1:0] miso_sync1;
    reg [N-1:0] miso_sync2;
    reg [N-1:0] miso_pclk;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            miso_sync1 <= {N{1'b0}};
            miso_sync2 <= {N{1'b0}};
            miso_pclk  <= {N{1'b0}};
        end else begin
            miso_sync1 <= miso_shift;
            miso_sync2 <= miso_sync1;
            miso_pclk  <= miso_sync2;
        end
    end

    // Synchronize di_i and wren_i to sclk domain
    reg [N-1:0] di_sync1;
    reg [N-1:0] di_sync2;
    reg [N-1:0] di_sclk;
    reg wren_sync1;
    reg wren_sync2;
    reg wren_sclk;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_sync1   <= {N{1'b0}};
            di_sync2   <= {N{1'b0}};
            di_sclk    <= {N{1'b0}};
            wren_sync1 <= 1'b0;
            wren_sync2 <= 1'b0;
            wren_sclk  <= 1'b0;
        end else begin
            di_sync1   <= di_i;
            di_sync2   <= di_sync1;
            di_sclk    <= di_sync2;
            wren_sync1 <= wren_i;
            wren_sync2 <= wren_sync1;
            wren_sclk  <= wren_sync2;
        end
    end

    // Synchronize di_sclk and wren_sclk to sclk domain
    reg [N-1:0] di_sclk_sync1;
    reg [N-1:0] di_sclk_sync2;
    reg [N-1:0] di_sclk_domain;
    reg wren_sclk_sync1;
    reg wren_sclk_sync2;
    reg wren_sclk_domain;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_sclk_sync1   <= {N{1'b0}};
            di_sclk_sync2   <= {N{1'b0}};
            di_sclk_domain  <= {N{1'b0}};
            wren_sclk_sync1 <= 1'b0;
            wren_sclk_sync2 <= 1'b0;
            wren_sclk_domain <= 1'b0;
        end else begin
            di_sclk_sync1   <= di_sclk;
            di_sclk_sync2   <= di_sclk_sync1;
            di_sclk_domain  <= di_sclk_sync2;
            wren_sclk_sync1 <= wren_sclk;
            wren_sclk_sync2 <= wren_sclk_sync1;
            wren_sclk_domain <= wren_sclk_sync2;
        end
    end

    // State machine in pclk domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state      <= S_IDLE;
            di_req_o   <= 1'b0;
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;
            do_o       <= {N{1'b0}};
        end else begin
            // Default: clear one-cycle pulses
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;

            case (state)
                S_IDLE: begin
                    di_req_o <= 1'b1;
                    if (wren_i) begin
                        state <= S_WAIT_WR;
                    end
                end
                S_WAIT_WR: begin
                    di_req_o <= 1'b0;
                    if (wren_i) begin
                        wr_ack_o <= 1'b1;
                        state    <= S_SHIFT;
                    end
                end
                S_SHIFT: begin
                    di_req_o <= 1'b0;
                    if (shift_done_sync3) begin
                        do_o       <= miso_pclk;
                        do_valid_o <= 1'b1;
                        state      <= S_DONE;
                    end
                end
                S_DONE: begin
                    di_req_o <= 1'b1;
                    state    <= S_IDLE;
                end
                default: begin
                    state    <= S_IDLE;
                    di_req_o <= 1'b0;
                end
            endcase
        end
    end

    // Load MOSI shift register when entering S_SHIFT
    // We need to do this in sclk domain
    // Use a flag to indicate that we should load the shift register
    reg load_mosi_sclk;
    reg load_mosi_sync1;
    reg load_mosi_sync2;
    reg load_mosi_sclk_domain;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            load_mosi_sclk <= 1'b0;
        end else begin
            if (state == S_WAIT_WR && wren_i) begin
                load_mosi_sclk <= 1'b1;
            end else begin
                load_mosi_sclk <= 1'b0;
            end
        end
    end

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            load_mosi_sync1 <= 1'b0;
            load_mosi_sync2 <= 1'b0;
            load_mosi_sclk_domain <= 1'b0;
        end else begin
            load_mosi_sync1 <= load_mosi_sclk;
            load_mosi_sync2 <= load_mosi_sync1;
            load_mosi_sclk_domain <= load_mosi_sync2;
        end
    end

    // Load MOSI shift register in sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            mosi_shift <= {N{1'b0}};
            bit_cnt    <= 3'd0;
        end else begin
            if (load_mosi_sclk_domain) begin
                mosi_shift <= di_sclk_domain;
                bit_cnt    <= 3'd0;
            end
        end
    end

endmodule
