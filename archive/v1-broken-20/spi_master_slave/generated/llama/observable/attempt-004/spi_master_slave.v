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
reg        tx_idle;
reg        rx_idle;
reg        spi_sck_en;
reg        spi_sck;
reg [1:0]  sclk_cnt;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i) begin
        spi_sck_en <= 1'b0;
        spi_sck    <= 1'b0;
        sclk_cnt   <= 2'b00;
    end else begin
        if (sclk_cnt == 2'b11) begin
            spi_sck_en <= ~spi_sck_en;
            sclk_cnt   <= 2'b00;
        end else begin
            sclk_cnt <= sclk_cnt + 1'b1;
        end
        spi_sck <= spi_sck_en;
    end
end

always @(posedge spi_sck or posedge rst_i)
begin
    if (rst_i) begin
        spi_ssel_o <= 1'b1;
        bit_cnt   <= 4'b0000;
        tx_idle   <= 1'b1;
        rx_idle   <= 1'b1;
        shift_reg <= {N{1'b0}};
    end else if (spi_sck) begin
        if (tx_idle) begin
            if (di_req_o && wren_i) begin
                tx_idle <= 1'b0;
                shift_reg <= di_i;
                spi_ssel_o <= 1'b0;
            end
        end else if (bit_cnt == N) begin
            tx_idle <= 1'b1;
            rx_idle <= 1'b0;
            bit_cnt <= 4'b0000;
        end else begin
            shift_reg <= {shift_reg[N-2:0], 1'b0};
            bit_cnt <= bit_cnt + 1'b1;
        end
    end else begin
        if (~rx_idle) begin
            if (bit_cnt == N) begin
                rx_idle <= 1'b1;
                spi_ssel_o <= 1'b1;
            end else begin
                shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                bit_cnt <= bit_cnt + 1'b1;
            end
        end
    end
end

assign spi_sck_o = spi_sck;
assign spi_mosi_o = tx_idle ? 1'b0 : shift_reg[N-1];

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i) begin
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
    end else begin
        if (rx_idle && ~tx_idle) begin
            do_valid_o <= 1'b1;
            do_o <= shift_reg;
        end else begin
            do_valid_o <= 1'b0;
        end
        if (wren_i && di_req_o) begin
            wr_ack_o <= 1'b1;
        end else begin
            wr_ack_o <= 1'b0;
        end
        if (~tx_idle) begin
            di_req_o <= 1'b0;
        end else if (rx_idle) begin
            di_req_o <= 1'b1;
        end
    end
end

endmodule
