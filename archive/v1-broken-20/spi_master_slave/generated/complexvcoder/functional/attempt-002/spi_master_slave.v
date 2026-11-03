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

    // Internal signals
    reg [N-1:0] shift_reg;
    reg [3:0] bit_cnt;
    reg [2:0] state;
    reg sclk_reg;

    // State definition
    parameter IDLE = 3'b000,
               SEND_DATA = 3'b001,
               RECEIVE_DATA = 3'b010,
               DONE = 3'b011;

    // Edge detection for sclk_i
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_reg <= 0;
        end else begin
            sclk_reg <= sclk_i;
        end
    end

    // State machine
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            bit_cnt <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    begin
                        spi_ssel_o <= 1;
                        spi_sck_o <= 0;
                        spi_mosi_o <= 0;
                        di_req_o <= 1;
                        wr_ack_o <= 0;
                        do_valid_o <= 0;
                        bit_cnt <= 0;
                        state <= IDLE;
                    end

                SEND_DATA:
                    begin
                        if (bit_cnt < N) begin
                            spi_ssel_o <= 0;
                            spi_sck_o <= 1;
                            spi_mosi_o <= di_i[bit_cnt];
                            bit_cnt <= bit_cnt + 1;
                            state <= SEND_DATA;
                        end else begin
                            spi_ssel_o <= 1;
                            spi_sck_o <= 0;
                            wr_ack_o <= 1;
                            state <= DONE;
                        end
                    end

                RECEIVE_DATA:
                    begin
                        if (bit_cnt < N) begin
                            spi_ssel_o <= 0;
                            spi_sck_o <= 1;
                            bit_cnt <= bit_cnt + 1;
                            state <= RECEIVE_DATA;
                        end else begin
                            spi_ssel_o <= 1;
                            spi_sck_o <= 0;
                            do_o <= shift_reg;
                            do_valid_o <= 1;
                            state <= DONE;
                        end
                    end

                DONE:
                    begin
                        spi_ssel_o <= 1;
                        spi_sck_o <= 0;
                        di_req_o <= 0;
                        wr_ack_o <= 0;
                        do_valid_o <= 0;
                        state <= IDLE;
                    end

                default:
                    state <= IDLE;
            endcase
        end
    end

endmodule
