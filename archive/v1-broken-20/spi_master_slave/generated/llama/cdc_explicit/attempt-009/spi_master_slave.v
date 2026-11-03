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
reg [3:0] sclk_div;
reg [3:0] sclk_cnt;
reg spi_sck_int;
reg spi_ssel_int;
reg [1:0] state;
reg [N-1:0] di_sync;
reg wren_sync;
reg [N-1:0] do_sync;
reg do_valid_sync;
reg di_req_sync;
reg wr_ack_sync;

always @(posedge pclk_i or posedge rst_i) begin
    if (rst_i) begin
        di_req_o <= 1'b1;
        wr_ack_o <= 1'b0;
        do_valid_o <= 1'b0;
        do_o <= {N{1'b0}};
        di_sync <= {N{1'b0}};
        wren_sync <= 1'b0;
        do_sync <= {N{1'b0}};
        do_valid_sync <= 1'b0;
        di_req_sync <= 1'b1;
        wr_ack_sync <= 1'b0;
    end else begin
        di_req_o <= di_req_sync;
        wr_ack_o <= wr_ack_sync;
        do_valid_o <= do_valid_sync;
        do_o <= do_sync;
        di_sync <= di_i;
        wren_sync <= wren_i;
        if (wren_i) begin
            wr_ack_sync <= 1'b1;
        end else begin
            wr_ack_sync <= 1'b0;
        end
    end
end

always @(posedge sclk_i or posedge rst_i) begin
    if (rst_i) begin
        spi_ssel_o <= 1'b1;
        spi_sck_o <= 1'b0;
        spi_sck_int <= 1'b0;
        sclk_div <= {4{1'b0}};
        sclk_cnt <= {4{1'b0}};
        state <= 2'b00;
        shift_reg <= {N{1'b0}};
        capture_reg <= {N{1'b0}};
        spi_mosi_o <= 1'b0;
        do_valid_sync <= 1'b0;
        do_sync <= {N{1'b0}};
        di_req_sync <= 1'b1;
    end else begin
        spi_ssel_o <= spi_ssel_int;
        spi_sck_o <= spi_sck_int;
        if (sclk_div == SPI_2X_CLK_DIV) begin
            sclk_div <= {4{1'b0}};
            spi_sck_int <= ~spi_sck_int;
        end else begin
            sclk_div <= sclk_div + 1'b1;
        end
        case (state)
            2'b00: begin
                if (di_req_sync) begin
                    state <= 2'b01;
                    spi_ssel_int <= 1'b0;
                    shift_reg <= di_sync;
                    capture_reg <= {N{1'b0}};
                    sclk_cnt <= {4{1'b0}};
                end
            end
            2'b01: begin
                if (sclk_cnt == N) begin
                    state <= 2'b10;
                    spi_ssel_int <= 1'b1;
                    do_valid_sync <= 1'b1;
                    do_sync <= capture_reg;
                    di_req_sync <= 1'b1;
                end else begin
                    spi_mosi_o <= shift_reg[N-1];
                    capture_reg[N-1] <= spi_miso_i;
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    sclk_cnt <= sclk_cnt + 1'b1;
                end
            end
            2'b10: begin
                state <= 2'b00;
                do_valid_sync <= 1'b0;
                di_req_sync <= 1'b0;
            end
        endcase
    end
end

endmodule
