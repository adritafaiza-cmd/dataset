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
reg [3:0]   sclk_cnt;
reg        spi_sck_int;
reg        spi_sck_rising;
reg        spi_sck_falling;
reg        spi_sck_prev;
reg        spi_miso_sync;
reg        spi_miso_sync_prev;
reg        di_req_int;
reg        wr_ack_int;
reg        do_valid_int;
reg [N-1:0] do_int;

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_sck_int <= 1'b0;
        sclk_div <= 4'b0;
        sclk_cnt <= 4'b0;
        spi_sck_prev <= 1'b0;
    end else begin
        if (sclk_div == SPI_2X_CLK_DIV) begin
            spi_sck_int <= ~spi_sck_int;
            sclk_div <= 4'b0;
        end else begin
            sclk_div <= sclk_div + 1'b1;
        end
        spi_sck_prev <= spi_sck_int;
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_sck_o <= 1'b0;
    end else begin
        spi_sck_o <= spi_sck_int;
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_sck_rising <= 1'b0;
        spi_sck_falling <= 1'b0;
    end else begin
        spi_sck_rising <= spi_sck_int && ~spi_sck_prev;
        spi_sck_falling <= ~spi_sck_int && spi_sck_prev;
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        shift_reg <= {N{1'b0}};
    end else if (spi_sck_rising) begin
        shift_reg <= {shift_reg[N-2:0], 1'b0};
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_mosi_o <= 1'b0;
    end else begin
        spi_mosi_o <= shift_reg[N-1];
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_miso_sync <= 1'b0;
        spi_miso_sync_prev <= 1'b0;
    end else begin
        spi_miso_sync <= spi_miso_i;
        spi_miso_sync_prev <= spi_miso_sync;
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        capture_reg <= {N{1'b0}};
    end else if (spi_sck_falling) begin
        capture_reg <= {spi_miso_sync, capture_reg[N-1:1]};
    end
end

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        di_req_o <= 1'b0;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
    end else begin
        di_req_o <= di_req_int;
        wr_ack_o <= wr_ack_int;
        do_valid_o <= do_valid_int;
        do_o <= do_int;
    end
end

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        di_req_int <= 1'b1;
        wr_ack_int <= 1'b0;
        do_valid_int <= 1'b0;
        do_int <= {N{1'b0}};
    end else begin
        if (wren_i) begin
            shift_reg <= di_i;
            wr_ack_int <= 1'b1;
            di_req_int <= 1'b0;
        end else begin
            wr_ack_int <= 1'b0;
        end
        if (spi_sck_falling && sclk_cnt == N) begin
            do_int <= capture_reg;
            do_valid_int <= 1'b1;
        end else begin
            do_valid_int <= 1'b0;
        end
        if (do_valid_int) begin
            di_req_int <= 1'b1;
        end
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        sclk_cnt <= 4'b0;
    end else if (spi_sck_rising) begin
        sclk_cnt <= sclk_cnt + 1'b1;
    end else if (sclk_cnt == N) begin
        sclk_cnt <= 4'b0;
    end
end

always @(posedge rst_i or posedge sclk_i) begin
    if (rst_i) begin
        spi_ssel_o <= 1'b1;
    end else if (spi_sck_rising && sclk_cnt == N) begin
        spi_ssel_o <= 1'b1;
    end else if (spi_sck_rising) begin
        spi_ssel_o <= 1'b0;
    end
end

endmodule
