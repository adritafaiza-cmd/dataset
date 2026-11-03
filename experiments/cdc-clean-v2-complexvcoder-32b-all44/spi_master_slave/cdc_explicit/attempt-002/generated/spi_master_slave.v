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
    reg [N-1:0] shift_reg;
    reg [$clog2(N):0] bit_cnt;
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] sclk_div_cnt;
    reg spi_sck_reg;
    reg spi_ssel_reg;
    reg spi_mosi_reg;
    reg di_req_reg;
    reg wr_ack_reg;
    reg do_valid_reg;
    reg [N-1:0] do_reg;
    reg miso_sync_in;
    reg miso_sync_out;
    reg miso_reg;

    // CDC synchronizer for MISO
    cdc_sync #(.WIDTH(1)) cdc_miso_sync (
        .clk(sclk_i),
        .rst(rst_i),
        .async_in(spi_miso_i),
        .sync_out(miso_sync_in)
    );

    // Synchronize MISO signal from sclk_i domain to pclk_i domain
    reg [1:0] miso_sync_pipeline;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            miso_sync_pipeline <= 0;
        end else begin
            miso_sync_pipeline <= {miso_sync_pipeline[0], miso_sync_in};
        end
    end

    assign miso_sync_out = miso_sync_pipeline[1];

    // Synchronize MISO signal to pclk_i domain
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            miso_reg <= 0;
        end else begin
            miso_reg <= miso_sync_out;
        end
    end

    // Parallel side control logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_reg <= 0;
            wr_ack_reg <= 0;
            do_valid_reg <= 0;
            shift_reg <= 0;
            bit_cnt <= 0;
            spi_ssel_reg <= 0;
        end else begin
            if (wren_i && !wr_ack_reg) begin
                shift_reg <= di_i;
                wr_ack_reg <= 1;
                di_req_reg <= 1;
                spi_ssel_reg <= 1;
            end else if (bit_cnt == N) begin
                wr_ack_reg <= 0;
                di_req_reg <= 0;
                spi_ssel_reg <= 0;
                do_valid_reg <= 1;
                do_reg <= {do_reg[N-2:0], miso_reg};
            end else if (spi_sck_reg) begin
                do_reg <= {do_reg[N-2:0], miso_reg};
            end
        end
    end

    // SPI clock divider
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 0;
            spi_sck_reg <= 0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 0;
                spi_sck_reg <= ~spi_sck_reg;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // Shift register and bit count
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            bit_cnt <= 0;
            spi_mosi_reg <= 0;
        end else begin
            if (spi_sck_reg) begin
                if (bit_cnt < N) begin
                    spi_mosi_reg <= shift_reg[N-1];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                end else begin
                    bit_cnt <= 0;
                end
            end
        end
    end

    // Outputs
    assign spi_ssel_o = spi_ssel_reg;
    assign spi_sck_o = spi_sck_reg;
    assign spi_mosi_o = spi_mosi_reg;
    assign di_req_o = di_req_reg;
    assign wr_ack_o = wr_ack_reg;
    assign do_valid_o = do_valid_reg;
    assign do_o = do_reg;

endmodule

// CDC synchronizer module
module cdc_sync #(
    parameter WIDTH = 1
)(
    input clk,
    input rst,
    input async_in,
    output reg sync_out
);

    reg [WIDTH-1:0] sync_pipeline;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_pipeline <= 0;
        end else begin
            sync_pipeline <= {sync_pipeline[WIDTH-2:0], async_in};
        end
    end

    assign sync_out = sync_pipeline[WIDTH-1];

endmodule
