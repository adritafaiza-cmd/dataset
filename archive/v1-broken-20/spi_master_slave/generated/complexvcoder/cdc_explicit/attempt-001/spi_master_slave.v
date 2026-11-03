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
    reg [1:0] clk_div_cnt;
    reg [1:0] clk_div_cnt_s;
    reg [2:0] state;
    reg [2:0] state_s;

    localparam IDLE = 3'b000;
    localparam SEND = 3'b001;
    localparam RECEIVE = 3'b010;
    localparam DONE = 3'b011;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            state <= IDLE;
            bit_cnt <= 3'b000;
            clk_div_cnt <= 2'b00;
            shift_reg <= 8'b0;
            do_o <= 8'b0;
        end else begin
            state_s <= state;
            clk_div_cnt_s <= clk_div_cnt;
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            bit_cnt <= bit_cnt;
            shift_reg <= shift_reg;

            case (state_s)
                IDLE: begin
                    if (wren_i) begin
                        state <= SEND;
                        spi_ssel_o <= 1'b0;
                        bit_cnt <= 3'b100;
                        shift_reg <= di_i;
                    end
                end
                SEND: begin
                    spi_sck_o <= ~spi_sck_o;
                    if (clk_div_cnt_s == SPI_2X_CLK_DIV - 1) begin
                        clk_div_cnt_s <= 2'b00;
                        spi_mosi_o <= shift_reg[0];
                        shift_reg <= {shift_reg[1:N-1], 1'b0};
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 3'b000) begin
                            state <= RECEIVE;
                        end
                    end else begin
                        clk_div_cnt_s <= clk_div_cnt_s + 1;
                    end
                end
                RECEIVE: begin
                    spi_sck_o <= ~spi_sck_o;
                    if (clk_div_cnt_s == SPI_2X_CLK_DIV - 1) begin
                        clk_div_cnt_s <= 2'b00;
                        shift_reg <= {shift_reg[1:N-1], spi_miso_i};
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 3'b000) begin
                            state <= DONE;
                        end
                    end else begin
                        clk_div_cnt_s <= clk_div_cnt_s + 1;
                    end
                end
                DONE: begin
                    spi_ssel_o <= 1'b1;
                    wr_ack_o <= 1'b1;
                    do_valid_o <= 1'b1;
                    do_o <= shift_reg;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
