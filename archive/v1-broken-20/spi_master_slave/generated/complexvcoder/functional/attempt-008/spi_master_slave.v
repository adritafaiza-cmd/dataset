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
    reg [1:0] state;
    reg [N-1:0] shift_reg;
    reg [3:0] bit_cnt;
    reg wr_req_reg;
    reg rd_req_reg;
    reg sclk_reg;
    reg spi_ssel_reg;
    reg spi_sck_reg;
    reg spi_mosi_reg;
    reg di_req_reg;
    reg wr_ack_reg;
    reg do_valid_reg;
    reg [N-1:0] do_reg;

    // State definitions
    parameter IDLE = 2'b00;
    parameter TRANSFER = 2'b01;
    parameter RECEIVE = 2'b10;

    // State machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
        end else begin
            case (state)
                IDLE:
                    begin
                        if (wren_i) begin
                            shift_reg <= di_i;
                            wr_req_reg <= 1'b1;
                            state <= TRANSFER;
                        end
                        di_req_o <= 1'b0;
                    end
                TRANSFER:
                    begin
                        spi_ssel_o <= 1'b0;
                        spi_sck_o <= ~spi_sck_reg;
                        spi_mosi_o <= shift_reg[0];
                        bit_cnt <= bit_cnt + 1;
                        shift_reg <= {shift_reg[0], spi_miso_i};
                        if (bit_cnt == N-1) begin
                            state <= RECEIVE;
                        end
                    end
                RECEIVE:
                    begin
                        spi_ssel_o <= 1'b1;
                        spi_sck_o <= 1'b0;
                        do_reg <= shift_reg;
                        do_valid_o <= 1'b1;
                        wr_ack_o <= 1'b1;
                        state <= IDLE;
                    end
            endcase
        end
    end

endmodule
