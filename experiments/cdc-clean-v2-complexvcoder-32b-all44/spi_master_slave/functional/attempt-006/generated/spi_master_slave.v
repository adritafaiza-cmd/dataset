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

    // Internal signals
    reg [N-1:0]        shift_reg;
    reg [$clog2(N)-1:0] bit_cnt;
    reg [N-1:0]        data_in_reg;
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] spi_clk_div_cnt;
    reg              spi_clk_div;
    reg              spi_clk_edge;
    reg              spi_clk_edge_d;
    reg [N-1:0]        miso_shift_reg;
    reg [N-1:0]        data_out_reg;
    reg [2:0]          state;
    reg [2:0]          next_state;
    reg              wren_d;
    reg              di_req_d;

    // SPI clock divider
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_clk_div_cnt <= 0;
            spi_clk_div <= 0;
        end else begin
            if (spi_clk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                spi_clk_div_cnt <= 0;
                spi_clk_div <= ~spi_clk_div;
            end else begin
                spi_clk_div_cnt <= spi_clk_div_cnt + 1;
            end
        end
    end

    // SPI clock edge detection
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_clk_edge_d <= 0;
        end else begin
            spi_clk_edge_d <= spi_clk_div;
        end
    end

    assign spi_clk_edge = spi_clk_div & ~spi_clk_edge_d;

    // State machine
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= 3'b000; // IDLE
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            3'b000: // IDLE
                if (wren_i) begin
                    next_state = 3'b001; // TRANSFER
                end
            3'b001: // TRANSFER
                if (bit_cnt == N - 1) begin
                    next_state = 3'b010; // DONE
                end
            3'b010: // DONE
                next_state = 3'b000; // IDLE
            default:
                next_state = 3'b000; // IDLE
        endcase
    end

    // Output register logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            data_in_reg <= 0;
            data_out_reg <= 0;
            bit_cnt <= 0;
        end else begin
            di_req_o <= (state == 3'b000) & (next_state == 3'b001);
            wr_ack_o <= (state == 3'b000) & (next_state == 3'b001);
            do_valid_o <= (state == 3'b010) & (next_state == 3'b000);
            if (state == 3'b000) begin
                if (wren_i) begin
                    data_in_reg <= di_i;
                end
            end
            if (spi_clk_edge) begin
                if (state == 3'b001) begin
                    shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                    bit_cnt <= bit_cnt + 1;
                end
            end
            if (state == 3'b010) begin
                data_out_reg <= shift_reg;
            end
        end
    end

    // SPI control logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 0;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
        end else begin
            spi_ssel_o <= (state == 3'b001) | (state == 3'b010);
            spi_sck_o <= spi_clk_div;
            if (spi_clk_edge) begin
                if (state == 3'b001) begin
                    spi_mosi_o <= data_in_reg[N-1-bit_cnt];
                end
            end
        end
    end

    // Output assignment
    assign do_o = data_out_reg;

endmodule
