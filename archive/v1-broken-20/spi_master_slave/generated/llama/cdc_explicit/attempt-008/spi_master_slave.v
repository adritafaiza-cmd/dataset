module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output reg         spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

reg [N-1:0] shift_reg;
reg [N-1:0] capture_reg;
reg [3:0]   sclk_cnt;
reg [3:0]   pclk_cnt;
reg         sclk_rst;
reg         pclk_rst;
reg         spi_ssel_int;
reg         spi_sck_int;
reg         spi_mosi_int;
reg         di_req_int;
reg         wr_ack_int;
reg         do_valid_int;
reg [N-1:0] do_int;

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        sclk_rst <= 1'b1;
        spi_ssel_int <= 1'b0;
        spi_sck_int <= 1'b0;
        spi_mosi_int <= 1'b0;
        sclk_cnt <= 4'd0;
    end else begin
        sclk_rst <= 1'b0;
        if (spi_ssel_int) begin
            if (sclk_cnt == 4'd0) begin
                spi_sck_int <= ~spi_sck_int;
                if (spi_sck_int) begin
                    spi_mosi_int <= shift_reg[N-1];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                end else begin
                    capture_reg[N-1] <= spi_miso_i;
                    capture_reg[N-2:0] <= capture_reg[N-1:1];
                end
                sclk_cnt <= sclk_cnt + 1'b1;
            end else if (sclk_cnt == 4'd(SPI_2X_CLK_DIV)) begin
                sclk_cnt <= 4'd0;
            end else begin
                sclk_cnt <= sclk_cnt + 1'b1;
            end
        end
    end
end

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        pclk_rst <= 1'b1;
        di_req_int <= 1'b0;
        wr_ack_int <= 1'b0;
        do_valid_int <= 1'b0;
        do_int <= {N{1'b0}};
        pclk_cnt <= 4'd0;
    end else begin
        pclk_rst <= 1'b0;
        if (wren_i) begin
            shift_reg <= di_i;
            spi_ssel_int <= 1'b1;
            wr_ack_int <= 1'b1;
        end else begin
            wr_ack_int <= 1'b0;
        end
        if (spi_ssel_int && (sclk_cnt == 4'd(SPI_2X_CLK_DIV))) begin
            spi_ssel_int <= 1'b0;
            do_int <= capture_reg;
            do_valid_int <= 1'b1;
        end else begin
            do_valid_int <= 1'b0;
        end
        if (pclk_cnt == 4'd0) begin
            di_req_int <= 1'b1;
        end else if (pclk_cnt == 4'd1) begin
            di_req_int <= 1'b0;
            pclk_cnt <= 4'd0;
        end else begin
            pclk_cnt <= pclk_cnt + 1'b1;
        end
    end
end

assign spi_ssel_o = spi_ssel_int;
assign spi_sck_o = spi_sck_int;
assign spi_mosi_o = spi_mosi_int;
assign di_req_o = di_req_int;
assign wr_ack_o = wr_ack_int;
assign do_valid_o = do_valid_int;
assign do_o = do_int;

endmodule
