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
reg        spi_sck_old;
reg        di_req_sync;
reg        wren_sync;
reg [N-1:0] di_sync;
reg        wr_ack_sync;
reg        do_valid_sync;
reg [N-1:0] do_sync;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i) begin
        spi_sck_o <= 1'b0;
        spi_ssel_o <= 1'b1;
        shift_reg <= {N{1'b0}};
        bit_cnt <= 4'b0;
        tx_valid <= 1'b0;
        rx_valid <= 1'b0;
        spi_sck_en <= 1'b0;
    end else begin
        if (tx_valid) begin
            spi_sck_en <= 1'b1;
            if (bit_cnt == 4'b1000) begin
                tx_valid <= 1'b0;
                rx_valid <= 1'b1;
                bit_cnt <= 4'b0;
            end else begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end else if (rx_valid) begin
            spi_sck_en <= 1'b1;
            if (bit_cnt == 4'b1000) begin
                rx_valid <= 1'b0;
                bit_cnt <= 4'b0;
            end else begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end else begin
            spi_sck_en <= 1'b0;
        end
    end
end

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i) begin
        spi_sck_old <= 1'b0;
    end else begin
        spi_sck_old <= spi_sck_en;
    end
end

assign spi_sck_o = spi_sck_en ^ spi_sck_old;

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i) begin
        shift_reg <= {N{1'b0}};
    end else if (tx_valid) begin
        shift_reg <= {shift_reg[N-2:0], 1'b0};
    end else if (rx_valid) begin
        shift_reg <= {shift_reg[N-2:0], spi_miso_i};
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
        di_req_o <= di_req_sync;
        wr_ack_o <= wr_ack_sync;
        do_valid_o <= do_valid_sync;
        do_o <= do_sync;
    end
end

always @(posedge sclk_i or posedge rst_i)
begin
    if (rst_i) begin
        di_req_sync <= 1'b0;
        wren_sync <= 1'b0;
        di_sync <= {N{1'b0}};
        wr_ack_sync <= 1'b0;
        do_valid_sync <= 1'b0;
        do_sync <= {N{1'b0}};
    end else begin
        di_req_sync <= di_req_o;
        wren_sync <= wren_i;
        di_sync <= di_i;
        wr_ack_sync <= wr_ack_o;
        do_valid_sync <= do_valid_o;
        do_sync <= do_o;
    end
end

always @(posedge pclk_i or posedge rst_i)
begin
    if (rst_i) begin
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
    end else begin
        if (wren_i) begin
            wr_ack_o <= 1'b1;
            shift_reg <= di_i;
            tx_valid <= 1'b1;
            spi_ssel_o <= 1'b0;
        end else begin
            wr_ack_o <= 1'b0;
        end
        if (rx_valid && bit_cnt == 4'b1000) begin
            do_valid_o <= 1'b1;
            do_o <= shift_reg;
            spi_ssel_o <= 1'b1;
        end else begin
            do_valid_o <= 1'b0;
        end
    end
end

assign spi_mosi_o = shift_reg[N-1];

endmodule
