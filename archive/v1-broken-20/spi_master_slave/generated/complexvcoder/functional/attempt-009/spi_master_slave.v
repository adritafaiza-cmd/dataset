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

    reg [1:0] state;
    reg [N-1:0] shift_reg;
    reg [3:0] bit_cnt;
    reg [3:0] word_cnt;

    parameter IDLE = 2'b00;
    parameter TRANSFER = 2'b01;
    parameter CAPTURE = 2'b10;
    parameter DONE = 2'b11;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= 1'b0;
            shift_reg <= 1'b0;
            bit_cnt <= 1'b0;
            word_cnt <= 1'b0;
        end else begin
            case (state)
                IDLE:
                    begin
                        spi_ssel_o <= 1'b1;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'b0;
                        di_req_o <= 1'b1;
                        wr_ack_o <= 1'b0;
                        do_valid_o <= 1'b0;
                        do_o <= 1'b0;
                        shift_reg <= 1'b0;
                        bit_cnt <= 1'b0;
                        word_cnt <= 1'b0;
                        if (wren_i) begin
                            state <= TRANSFER;
                            shift_reg <= di_i;
                            bit_cnt <= 4'b1000;
                            word_cnt <= 4'b0001;
                        end
                    end
                TRANSFER:
                    begin
                        spi_ssel_o <= 1'b0;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= shift_reg[0];
                        di_req_o <= 1'b1;
                        wr_ack_o <= 1'b0;
                        do_valid_o <= 1'b0;
                        do_o <= 1'b0;
                        shift_reg <= {shift_reg[1:N-1], spi_miso_i};
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 4'b0000) begin
                            state <= CAPTURE;
                        end
                    end
                CAPTURE:
                    begin
                        spi_ssel_o <= 1'b0;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= shift_reg[0];
                        di_req_o <= 1'b1;
                        wr_ack_o <= 1'b0;
                        do_valid_o <= 1'b1;
                        do_o <= shift_reg;
                        shift_reg <= {shift_reg[1:N-1], spi_miso_i};
                        word_cnt <= word_cnt - 1;
                        if (word_cnt == 4'b0000) begin
                            state <= DONE;
                        end
                    end
                DONE:
                    begin
                        spi_ssel_o <= 1'b1;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= 1'b0;
                        di_req_o <= 1'b0;
                        wr_ack_o <= 1'b1;
                        do_valid_o <= 1'b0;
                        do_o <= 1'b0;
                        state <= IDLE;
                    end
                default:
                    state <= IDLE;
            endcase
        end
    end

endmodule
