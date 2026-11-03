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
reg [3:0]  bit_cnt;
reg        tx_valid;
reg        rx_valid;
reg        spi_sck_en;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i) begin
        spi_sck_o <= 1'b0;
        spi_ssel_o <= 1'b1;
        shift_reg <= {N{1'b0}};
        bit_cnt <= 4'd0;
        tx_valid <= 1'b0;
        rx_valid <= 1'b0;
        spi_sck_en <= 1'b0;
    end else begin
        if (tx_valid) begin
            if (bit_cnt == 4'd0) begin
                tx_valid <= 1'b0;
                rx_valid <= 1'b1;
            end else begin
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                bit_cnt <= bit_cnt - 1'b1;
            end
        end
        if (spi_sck_en) begin
            spi_sck_o <= ~spi_sck_o;
        end
        if (rx_valid && (bit_cnt == 4'd0)) begin
            rx_valid <= 1'b0;
            spi_ssel_o <= 1'b1;
        end
    end
end

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i) begin
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
    end else begin
        if (wren_i && !di_req_o) begin
            di_req_o <= 1'b1;
        end
        if (tx_valid && (bit_cnt == 4'd0)) begin
            wr_ack_o <= 1'b1;
        end else begin
            wr_ack_o <= 1'b0;
        end
        if (rx_valid && (bit_cnt == 4'd0)) begin
            do_valid_o <= 1'b1;
            do_o <= shift_reg;
        end else begin
            do_valid_o <= 1'b0;
        end
        if (di_req_o && wren_i) begin
            di_req_o <= 1'b0;
            spi_ssel_o <= 1'b0;
            shift_reg <= di_i;
            bit_cnt <= 4'dN;
            tx_valid <= 1'b1;
            spi_sck_en <= 1'b1;
        end
    end
end

assign spi_mosi_o = tx_valid ? shift_reg[N-1] : 1'b0;

always @(posedge sclk_i)
begin
    if (rx_valid) begin
        shift_reg[N-1] <= spi_miso_i;
    end
end

always @(posedge sclk_i)
begin
    if (spi_sck_en) begin
        if (bit_cnt == 4'd0) begin
            spi_sck_en <= 1'b0;
        end
    end else if (tx_valid) begin
        spi_sck_en <= 1'b1;
    end
end

endmodule
