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
reg [3:0] state;
reg [3:0] bit_cnt;
reg [1:0] clk_div;
reg spi_sck_int;
reg spi_sck_sync;
reg spi_miso_sync;
reg di_req_sync;
reg wren_sync;
reg [N-1:0] di_sync;

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        di_req_o <= 1'b1;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
        di_sync <= {N{1'b0}};
        wren_sync <= 1'b0;
    end else begin
        di_req_o <= di_req_sync;
        if (wren_i &&!wren_sync) begin
            di_sync <= di_i;
            wren_sync <= 1'b1;
        end else if (!wren_i && wren_sync) begin
            wren_sync <= 1'b0;
        end
        if (wren_i && wren_sync) begin
            wr_ack_o <= 1'b1;
        end else begin
            wr_ack_o <= 1'b0;
        end
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_sck_int <= 1'b0;
        spi_sck_sync <= 1'b0;
        spi_miso_sync <= 1'b0;
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
        spi_mosi_o <= 1'b0;
        shift_reg <= {N{1'b0}};
        capture_reg <= {N{1'b0}};
        state <= 4'b0000;
        bit_cnt <= 4'b0000;
        clk_div <= 2'b00;
    end else begin
        spi_sck_int <=!spi_sck_int;
        if (clk_div == SPI_2X_CLK_DIV) begin
            spi_sck_sync <= spi_sck_int;
            clk_div <= 2'b00;
        end else begin
            clk_div <= clk_div + 1'b1;
        end
        spi_sck_o <= spi_sck_sync;
        spi_miso_sync <= spi_miso_i;
        case (state)
            4'b0000: begin // idle
                spi_ssel_o <= 1'b1;
                spi_mosi_o <= 1'b0;
                if (di_req_sync) begin
                    state <= 4'b0001;
                    shift_reg <= di_sync;
                    capture_reg <= {N{1'b0}};
                    bit_cnt <= 4'b0000;
                end
            end
            4'b0001: begin // shift out
                spi_ssel_o <= 1'b0;
                spi_mosi_o <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], 1'b0};
                capture_reg[N-1] <= spi_miso_sync;
                capture_reg[N-2:0] <= capture_reg[N-1:1];
                bit_cnt <= bit_cnt + 1'b1;
                if (bit_cnt == N) begin
                    state <= 4'b0010;
                end
            end
            4'b0010: begin // capture
                spi_ssel_o <= 1'b1;
                spi_mosi_o <= 1'b0;
                do_o <= capture_reg;
                do_valid_o <= 1'b1;
                state <= 4'b0011;
            end
            4'b0011: begin // done
                spi_ssel_o <= 1'b1;
                spi_mosi_o <= 1'b0;
                do_valid_o <= 1'b0;
                di_req_sync <= 1'b1;
                state <= 4'b0000;
            end
        endcase
    end
end

endmodule
