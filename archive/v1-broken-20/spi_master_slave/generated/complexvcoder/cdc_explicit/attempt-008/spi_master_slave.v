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
    reg [2:0] clk_cnt;
    reg sclk_reg;
    reg pclk_reg;
    reg [1:0] state;

    // State machine states
    parameter IDLE = 2'b00;
    parameter SEND = 2'b01;
    parameter RECEIVE = 2'b10;

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
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;

            case (state)
                IDLE: begin
                    if (wren_i) begin
                        shift_reg <= di_i;
                        bit_cnt <= 3'b000;
                        state <= SEND;
                        wr_ack_o <= 1'b1;
                    end
                end
                SEND: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= sclk_reg;
                    spi_mosi_o <= shift_reg[bit_cnt];
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == (N-1)) begin
                        state <= RECEIVE;
                    end
                end
                RECEIVE: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o <= ~sclk_reg;
                    shift_reg[N-1] <= spi_miso_i;
                    bit_cnt <= bit_cnt - 1;
                    if (bit_cnt == 3'b000) begin
                        do_o <= shift_reg;
                        do_valid_o <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase

            sclk_reg <= sclk_i;
            pclk_reg <= pclk_i;
        end
    end

endmodule
