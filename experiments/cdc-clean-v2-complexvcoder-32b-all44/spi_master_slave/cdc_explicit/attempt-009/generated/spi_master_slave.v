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
reg [31:0] sclk_div_cnt;
reg [3:0]  bit_cnt;
reg [N-1:0] shift_reg;
reg        tx_done;
reg        rx_done;
reg        wren_sclk;
reg [N-1:0] di_sclk;
reg        rst_sclk;
reg        rst_pclk;
reg        wr_ack;
reg        di_req;

// Cross-domain synchronization instances
cdc_sync sclk_rst_sync (
    .async_in(rst_i),
    .sync_out(sclk_rst_sync_o),
    .clk(sclk_i)
);

cdc_sync pclk_rst_sync (
    .async_in(rst_i),
    .sync_out(pclk_rst_sync_o),
    .clk(pclk_i)
);

cdc_sync wren_sync (
    .async_in(wren_i),
    .sync_out(wren_sclk),
    .clk(sclk_i)
);

cdc_sync #(.WIDTH(N)) di_sync (
    .async_in(di_i),
    .sync_out(di_sclk),
    .clk(sclk_i)
);

assign rst_sclk = sclk_rst_sync_o;
assign rst_pclk = pclk_rst_sync_o;

// SCLK domain logic
always @(posedge sclk_i or posedge rst_sclk) begin
    if (rst_sclk) begin
        sclk_div_cnt <= 0;
        spi_sck_o <= 0;
        spi_ssel_o <= 0;
        spi_mosi_o <= 0;
        bit_cnt <= 0;
        shift_reg <= 0;
        tx_done <= 0;
        rx_done <= 0;
    end else begin
        // SPI clock divider
        if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
            sclk_div_cnt <= 0;
            spi_sck_o <= ~spi_sck_o;
        end else begin
            sclk_div_cnt <= sclk_div_cnt + 1;
        end

        // SPI transaction control
        if (wren_sclk && !tx_done) begin
            spi_ssel_o <= 1;
            shift_reg <= di_sclk;
            bit_cnt <= N - 1;
            tx_done <= 0;
        end else if (spi_sck_o && bit_cnt < N) begin
            spi_mosi_o <= shift_reg[bit_cnt];
            if (bit_cnt == 0) begin
                tx_done <= 1;
            end else begin
                bit_cnt <= bit_cnt - 1;
            end
        end else if (tx_done && !rx_done && !spi_sck_o) begin
            rx_done <= 1;
        end else if (!spi_sck_o && rx_done) begin
            spi_ssel_o <= 0;
            bit_cnt <= 0;
            tx_done <= 0;
            rx_done <= 0;
        end
    end
end

// PCLK domain logic
always @(posedge pclk_i or posedge rst_pclk) begin
    if (rst_pclk) begin
        di_req_o <= 0;
        wr_ack_o <= 0;
        do_valid_o <= 0;
        do_o <= 0;
    end else begin
        // Control signals
        if (!tx_done && wren_sclk) begin
            wr_ack_o <= 1;
        end else begin
            wr_ack_o <= 0;
        end

        if (tx_done && !rx_done) begin
            di_req_o <= 1;
        end else begin
            di_req_o <= 0;
        end

        // Data output
        if (rx_done) begin
            do_valid_o <= 1;
            do_o <= shift_reg;
        end else begin
            do_valid_o <= 0;
        end
    end
end

endmodule

// Cross-domain synchronization module
module cdc_sync #(
    parameter WIDTH = 1
)(
    input  [WIDTH-1:0] async_in,
    output [WIDTH-1:0] sync_out,
    input              clk
);

reg [WIDTH-1:0] sync_reg1;
reg [WIDTH-1:0] sync_reg2;

always @(posedge clk) begin
    sync_reg1 <= async_in;
    sync_reg2 <= sync_reg1;
end

assign sync_out = sync_reg2;

endmodule
