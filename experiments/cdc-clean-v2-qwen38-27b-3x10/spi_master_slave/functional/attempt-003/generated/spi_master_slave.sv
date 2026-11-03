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
    localparam S_IDLE      = 3'd0;
    localparam S_WAIT_REQ  = 3'd1;
    localparam S_ACCEPT    = 3'd2;
    localparam S_SHIFT     = 3'd3;
    localparam S_DONE      = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    // Shift register for MOSI
    reg [N-1:0] mosi_shift;
    // Shift register for MISO
    reg [N-1:0] miso_shift;
    // Bit counter
    reg [3:0] bit_count;
    // Clock divider counter
    reg [3:0] clk_div_cnt;
    // SCK phase
    reg sck_phase;

    // Asynchronous reset for sclk domain
    reg sclk_rst;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            sclk_rst <= 1'b1;
        else
            sclk_rst <= 1'b0;
    end

    // Asynchronous reset for pclk domain
    reg pclk_rst;
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            pclk_rst <= 1'b1;
        else
            pclk_rst <= 1'b0;
    end

    // SCLK domain: SPI shift logic
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            spi_ssel_o   <= 1'b0;
            spi_sck_o    <= 1'b0;
            mosi_shift   <= {N{1'b0}};
            miso_shift   <= {N{1'b0}};
            bit_count    <= 4'd0;
            clk_div_cnt  <= 4'd0;
            sck_phase    <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    spi_ssel_o  <= 1'b0;
                    spi_sck_o   <= 1'b0;
                    clk_div_cnt <= 4'd0;
                    sck_phase   <= 1'b0;
                end

                S_WAIT_REQ: begin
                    spi_ssel_o  <= 1'b0;
                    spi_sck_o   <= 1'b0;
                    clk_div_cnt <= 4'd0;
                    sck_phase   <= 1'b0;
                end

                S_ACCEPT: begin
                    // Load data and start transfer
                    spi_ssel_o  <= 1'b1;
                    spi_sck_o   <= 1'b0;
                    mosi_shift  <= di_i;
                    miso_shift  <= {N{1'b0}};
                    bit_count   <= 4'd0;
                    clk_div_cnt <= 4'd0;
                    sck_phase   <= 1'b0;
                end

                S_SHIFT: begin
                    // Clock divider
                    if (clk_div_cnt < SPI_2X_CLK_DIV - 1) begin
                        clk_div_cnt <= clk_div_cnt + 4'd1;
                    end else begin
                        clk_div_cnt <= 4'd0;
                        if (!sck_phase) begin
                            // Rising edge of SCK
                            spi_sck_o <= 1'b1;
                            sck_phase <= 1'b1;
                            // Sample MISO on rising edge (SPI mode 0)
                            miso_shift <= {miso_shift[N-2:0], spi_miso_i};
                        end else begin
                            // Falling edge of SCK
                            spi_sck_o <= 1'b0;
                            sck_phase <= 1'b0;
                            // Shift out MOSI on falling edge
                            mosi_shift <= {mosi_shift[N-2:0], 1'b0};
                            if (bit_count == N - 1) begin
                                // Last bit done
                                spi_ssel_o <= 1'b0;
                                spi_sck_o  <= 1'b0;
                            end else begin
                                bit_count <= bit_count + 4'd1;
                            end
                        end
                    end
                end

                S_DONE: begin
                    spi_ssel_o  <= 1'b0;
                    spi_sck_o   <= 1'b0;
                    clk_div_cnt <= 4'd0;
                    sck_phase   <= 1'b0;
                end

                default: begin
                    spi_ssel_o  <= 1'b0;
                    spi_sck_o   <= 1'b0;
                    clk_div_cnt <= 4'd0;
                    sck_phase   <= 1'b0;
                end
            endcase
        end
    end

    // PCLK domain: Handshake logic
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            di_req_o   <= 1'b0;
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;
            do_o       <= {N{1'b0}};
        end else begin
            // Default: deassert one-cycle pulses
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;

            case (state)
                S_IDLE: begin
                    di_req_o <= 1'b1;
                end

                S_WAIT_REQ: begin
                    di_req_o <= 1'b1;
                    if (wren_i) begin
                        wr_ack_o <= 1'b1;
                    end
                end

                S_ACCEPT: begin
                    di_req_o <= 1'b0;
                end

                S_SHIFT: begin
                    di_req_o <= 1'b0;
                end

                S_DONE: begin
                    di_req_o <= 1'b0;
                    do_valid_o <= 1'b1;
                    do_o <= miso_shift;
                end

                default: begin
                    di_req_o <= 1'b0;
                end
            endcase
        end
    end

    // State machine (synchronous to pclk_i for handshake, but state transitions
    // need to coordinate with sclk domain. We'll use pclk for state machine
    // since handshake is pclk-based, and the sclk domain logic responds to state)
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            state <= S_IDLE;
        end else begin
            case (state)
                S_IDLE: begin
                    state <= S_WAIT_REQ;
                end

                S_WAIT_REQ: begin
                    if (wren_i) begin
                        state <= S_ACCEPT;
                    end
                end

                S_ACCEPT: begin
                    state <= S_SHIFT;
                end

                S_SHIFT: begin
                    // Wait until sclk domain signals completion
                    // We need a signal from sclk domain indicating shift is done
                    // For simplicity, we'll count or use a flag
                    // Let's use a done flag from sclk domain
                    if (shift_done) begin
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    state <= S_WAIT_REQ;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

    // Shift done flag - generated in sclk domain, synchronized to pclk
    reg shift_done_sclk;
    always @(posedge sclk_i or posedge sclk_rst) begin
        if (sclk_rst) begin
            shift_done_sclk <= 1'b0;
        end else begin
            if (state == S_SHIFT && bit_count == N - 1 && sck_phase == 1'b1) begin
                shift_done_sclk <= 1'b1;
            end else if (state != S_SHIFT) begin
                shift_done_sclk <= 1'b0;
            end
        end
    end

    // Synchronize shift_done_sclk to pclk domain
    reg [1:0] shift_done_sync;
    wire shift_done;
    always @(posedge pclk_i or posedge pclk_rst) begin
        if (pclk_rst) begin
            shift_done_sync <= 2'b00;
        end else begin
            shift_done_sync <= {shift_done_sync[0], shift_done_sclk};
        end
    end
    assign shift_done = shift_done_sync[1];

    // MOSI output
    assign spi_mosi_o = mosi_shift[N-1];

endmodule
