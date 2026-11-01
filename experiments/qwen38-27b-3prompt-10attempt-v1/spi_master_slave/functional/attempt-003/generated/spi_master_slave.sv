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
    localparam S_IDLE = 2'd0;
    localparam S_WAIT_WRITE = 2'd1;
    localparam S_SHIFT = 2'd2;
    localparam S_DONE = 2'd3;

    reg [1:0] state;
    reg [1:0] state_next;

    // Shift register and counter
    reg [N-1:0] shift_reg;
    reg [N-1:0] rx_reg;
    reg [$clog2(N):0] bit_count;

    // Clock divider counter for SPI clock generation
    reg [$clog2(SPI_2X_CLK_DIV):0] clk_div_cnt;
    reg sck_phase;

    // Synchronizers for asynchronous signals
    reg [1:0] wren_sync;
    reg [1:0] di_sync;
    reg [1:0] miso_sync;

    // Synchronize wren_i
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            wren_sync <= 2'b00;
        else
            wren_sync <= {wren_sync[0], wren_i};
    end

    // Synchronize di_i
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            di_sync <= 2'b00;
        else
            di_sync <= {di_sync[0], di_i[0]};
    end

    // Synchronize miso_i
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            miso_sync <= 2'b00;
        else
            miso_sync <= {miso_sync[0], spi_miso_i};
    end

    // State machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= S_IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        case (state)
            S_IDLE: begin
                if (wren_sync[1])
                    state_next = S_WAIT_WRITE;
            end
            S_WAIT_WRITE: begin
                if (wren_sync[1])
                    state_next = S_SHIFT;
            end
            S_SHIFT: begin
                if (bit_count == N)
                    state_next = S_DONE;
            end
            S_DONE: begin
                state_next = S_IDLE;
            end
            default: state_next = S_IDLE;
        endcase
    end

    // SPI clock generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_div_cnt <= 0;
            sck_phase <= 1'b0;
            spi_sck_o <= 1'b0;
        end else if (state == S_SHIFT) begin
            if (clk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                clk_div_cnt <= 0;
                sck_phase <= ~sck_phase;
                spi_sck_o <= sck_phase;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1;
            end
        end else begin
            clk_div_cnt <= 0;
            sck_phase <= 1'b0;
            spi_sck_o <= 1'b0;
        end
    end

    // SPI chip select
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            spi_ssel_o <= 1'b1;
        else if (state == S_SHIFT)
            spi_ssel_o <= 1'b0;
        else
            spi_ssel_o <= 1'b1;
    end

    // MOSI output
    assign spi_mosi_o = shift_reg[N-1];

    // Shift register and receive register
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg <= {N{1'b0}};
            rx_reg <= {N{1'b0}};
            bit_count <= 0;
        end else if (state == S_SHIFT) begin
            if (sck_phase == 1'b1 && clk_div_cnt == 0) begin
                // On rising edge of SCK, shift out and capture
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                rx_reg <= {rx_reg[N-2:0], miso_sync[1]};
                bit_count <= bit_count + 1;
            end
        end else if (state == S_WAIT_WRITE) begin
            if (wren_sync[1]) begin
                shift_reg <= di_i;
                bit_count <= 0;
            end
        end
    end

    // Parallel interface handshake
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= {N{1'b0}};
        end else begin
            // Default
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;

            case (state)
                S_IDLE: begin
                    di_req_o <= 1'b1;
                end
                S_WAIT_WRITE: begin
                    if (wren_i) begin
                        wr_ack_o <= 1'b1;
                    end
                end
                S_DONE: begin
                    do_valid_o <= 1'b1;
                    do_o <= rx_reg;
                end
                default: ;
            endcase
        end
    end

endmodule
