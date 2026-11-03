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
    reg [3:0] bit_cnt;
    reg [2:0] state;
    reg [3:0] sclk_cnt;
    reg [3:0] sclk_div_cnt;

    parameter IDLE = 3'b000;
    parameter SEND = 3'b001;
    parameter RECEIVE = 3'b010;
    parameter DONE = 3'b011;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            state <= IDLE;
            shift_reg <= 0;
            bit_cnt <= 0;
            sclk_cnt <= 0;
            sclk_div_cnt <= 0;
        end else begin
            case (state)
                IDLE:
                    begin
                        if (wren_i) begin
                            shift_reg <= di_i;
                            di_req_o <= 1'b1;
                            state <= SEND;
                        end else begin
                            di_req_o <= 1'b0;
                        end
                    end
                SEND:
                    begin
                        spi_ssel_o <= 1'b0;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= shift_reg[N-1];
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                        sclk_cnt <= 0;
                        state <= RECEIVE;
                    end
                RECEIVE:
                    begin
                        spi_sck_o <= 1'b1;
                        sclk_cnt <= sclk_cnt + 1;
                        if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                            spi_sck_o <= 1'b0;
                            sclk_cnt <= 0;
                            if (bit_cnt == N - 1) begin
                                bit_cnt <= 0;
                                state <= DONE;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                                spi_mosi_o <= shift_reg[N-1];
                                shift_reg <= {shift_reg[N-2:0], 1'b0};
                            end
                        end
                    end
                DONE:
                    begin
                        spi_ssel_o <= 1'b1;
                        wr_ack_o <= 1'b1;
                        do_valid_o <= 1'b1;
                        do_o <= shift_reg;
                        state <= IDLE;
                    end
            endcase
        end
    end

endmodule
