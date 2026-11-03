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
    reg [2:0] bit_cnt;
    reg [3:0] sclk_cnt;
    reg [3:0] sclk_div;
    reg [3:0] pclk_cnt;
    reg [3:0] pclk_div;
    reg [1:0] state;
    reg [1:0] next_state;

    parameter IDLE = 2'b00;
    parameter WRITE = 2'b01;
    parameter READ = 2'b10;
    parameter DONE = 2'b11;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            state <= IDLE;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    di_req_o <= 1'b0;
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    if (wren_i) begin
                        shift_reg <= di_i;
                        next_state <= WRITE;
                    end
                end
                WRITE: begin
                    spi_ssel_o <= 1'b0;
                    spi_mosi_o <= shift_reg[0];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == N) begin
                        bit_cnt <= 0;
                        next_state <= READ;
                    end else begin
                        sclk_cnt <= 0;
                        next_state <= WRITE;
                    end
                end
                READ: begin
                    spi_sck_o <= 1'b1;
                    sclk_cnt <= sclk_cnt + 1;
                    if (sclk_cnt == SPI_2X_CLK_DIV) begin
                        sclk_cnt <= 0;
                        spi_sck_o <= 1'b0;
                        do_o <= {do_o[N-2:0], spi_miso_i};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == N) begin
                            bit_cnt <= 0;
                            do_valid_o <= 1'b1;
                            next_state <= DONE;
                        end else begin
                            next_state <= READ;
                        end
                    end
                end
                DONE: begin
                    do_valid_o <= 1'b0;
                    spi_ssel_o <= 1'b1;
                    di_req_o <= 1'b1;
                    wr_ack_o <= 1'b1;
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule
