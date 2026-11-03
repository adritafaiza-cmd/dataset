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
    reg [2:0] state;
    reg [1:0] bit_cnt;
    reg [1:0] sclk_cnt;
    reg [1:0] sclk_div;
    reg [1:0] sclk_div_cnt;

    localparam IDLE = 3'b000;
    localparam SEND = 3'b001;
    localparam RECEIVE = 3'b010;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            do_o <= 0;
            shift_reg <= 0;
            state <= IDLE;
            bit_cnt <= 0;
            sclk_cnt <= 0;
            sclk_div_cnt <= 0;
        end else begin
            di_req_o <= 1'b1;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;

            case (state)
                IDLE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    if (wren_i) begin
                        shift_reg <= di_i;
                        state <= SEND;
                    end
                end
                SEND: begin
                    spi_ssel_o <= 1'b0;
                    spi_mosi_o <= shift_reg[0];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == (N-1)) begin
                        bit_cnt <= 0;
                        state <= RECEIVE;
                    end
                    sclk_cnt <= sclk_cnt + 1;
                    if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                        sclk_cnt <= 0;
                        spi_sck_o <= ~spi_sck_o;
                    end
                end
                RECEIVE: begin
                    spi_ssel_o <= 1'b0;
                    bit_cnt <= bit_cnt + 1;
                    do_o[N-1-bit_cnt] <= spi_miso_i;
                    if (bit_cnt == (N-1)) begin
                        bit_cnt <= 0;
                        state <= IDLE;
                        do_valid_o <= 1'b1;
                        wr_ack_o <= 1'b1;
                    end
                    sclk_cnt <= sclk_cnt + 1;
                    if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                        sclk_cnt <= 0;
                        spi_sck_o <= ~spi_sck_o;
                    end
                end
            endcase
        end
    end

endmodule
