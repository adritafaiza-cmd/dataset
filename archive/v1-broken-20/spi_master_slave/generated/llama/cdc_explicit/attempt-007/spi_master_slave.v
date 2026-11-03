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

reg [N-1:0] shift_reg;
reg [N-1:0] capture_reg;
reg [3:0]   sclk_div;
reg [3:0]   pclk_div;
reg         sclk_rst;
reg         pclk_rst;
reg         spi_ssel_r;
reg         spi_sck_r;
reg         di_req_r;
reg         wr_ack_r;
reg         do_valid_r;
reg [N-1:0] do_r;

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        sclk_rst <= 1'b1;
        spi_ssel_r <= 1'b0;
        spi_sck_r <= 1'b0;
        sclk_div <= 4'd0;
    end else begin
        sclk_rst <= 1'b0;
        if (sclk_div == SPI_2X_CLK_DIV) begin
            spi_sck_r <= ~spi_sck_r;
            sclk_div <= 4'd0;
        end else begin
            sclk_div <= sclk_div + 1'b1;
        end
    end
end

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        pclk_rst <= 1'b1;
        di_req_r <= 1'b0;
        wr_ack_r <= 1'b0;
        do_valid_r <= 1'b0;
        do_r <= {N{1'b0}};
    end else begin
        pclk_rst <= 1'b0;
        if (wren_i) begin
            shift_reg <= di_i;
            wr_ack_r <= 1'b1;
        end else begin
            wr_ack_r <= 1'b0;
        end
        if (shift_reg == {N{1'b0}}) begin
            di_req_r <= 1'b1;
        end else begin
            di_req_r <= 1'b0;
        end
        if (capture_reg == {N{1'b0}}) begin
            do_valid_r <= 1'b0;
        end else begin
            do_r <= capture_reg;
            do_valid_r <= 1'b1;
        end
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_ssel_o <= 1'b0;
        spi_mosi_o <= 1'b0;
    end else begin
        if (shift_reg != {N{1'b0}}) begin
            spi_ssel_o <= 1'b1;
            spi_mosi_o <= shift_reg[N-1];
            shift_reg <= {shift_reg[N-2:0], 1'b0};
        end else begin
            spi_ssel_o <= 1'b0;
            spi_mosi_o <= 1'b0;
        end
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        capture_reg <= {N{1'b0}};
    end else begin
        capture_reg <= {capture_reg[N-2:0], spi_miso_i};
    end
end

assign spi_sck_o = spi_sck_r;
assign di_req_o = di_req_r;
assign wr_ack_o = wr_ack_r;
assign do_valid_o = do_valid_r;
assign do_o = do_r;

endmodule
