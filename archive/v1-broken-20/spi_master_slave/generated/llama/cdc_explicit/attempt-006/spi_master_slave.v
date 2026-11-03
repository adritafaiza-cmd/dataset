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
reg [3:0]   sclk_cnt;
reg [3:0]   pclk_cnt;
reg         spi_ssel_int;
reg         spi_sck_int;
reg         spi_mosi_int;
reg         di_req_int;
reg         wr_ack_int;
reg         do_valid_int;
reg [N-1:0] do_int;

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_ssel_int <= 1'b0;
        spi_sck_int  <= 1'b0;
        spi_mosi_int <=1'b0;
        sclk_cnt     <= 4'b0;
    end else begin
        if (sclk_cnt == 4'b0) begin
            spi_sck_int <= ~spi_sck_int;
            if (spi_ssel_int) begin
                if (shift_reg[N-1]) begin
                    spi_mosi_int <= 1'b1;
                end else begin
                    spi_mosi_int <= 1'b0;
                end
                shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                sclk_cnt  <= sclk_cnt + 1'b1;
            end
        end else begin
            sclk_cnt <= sclk_cnt + 1'b1;
            if (sclk_cnt == 4'b1111) begin
                sclk_cnt <= 4'b0;
                if (shift_reg == {N{1'b0}}) begin
                    spi_ssel_int <= 1'b0;
                end
            end
        end
    end
end

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        di_req_o    <= 1'b0;
        wr_ack_o   <= 1'b0;
        do_valid_o <= 1'b0;
        do_o       <= {N{1'b0}};
        pclk_cnt   <= 4'b0;
        capture_reg <= {N{1'b0}};
    end else begin
        if (wren_i) begin
            shift_reg <= di_i;
            spi_ssel_int <= 1'b1;
            wr_ack_o   <= 1'b1;
        end else begin
            wr_ack_o <= 1'b0;
        end
        if (pclk_cnt == 4'b0) begin
            if (spi_ssel_int == 1'b0) begin
                di_req_o <= 1'b1;
            end else begin
                di_req_o <= 1'b0;
            end
            if (spi_ssel_int == 1'b0 && shift_reg == {N{1'b0}}) begin
                capture_reg <= shift_reg;
                do_valid_o <= 1'b1;
                do_o       <= capture_reg;
            end else begin
                do_valid_o <= 1'b0;
            end
            pclk_cnt <= pclk_cnt + 1'b1;
        end else begin
            pclk_cnt <= pclk_cnt + 1'b1;
            if (pclk_cnt == 4'b1111) begin
                pclk_cnt <= 4'b0;
            end
        end
    end
end

assign spi_ssel_o = spi_ssel_int;
assign spi_sck_o  = spi_sck_int;
assign spi_mosi_o = spi_mosi_int;

endmodule
