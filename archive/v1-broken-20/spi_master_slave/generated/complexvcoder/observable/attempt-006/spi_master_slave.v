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
    reg [2:0] bit_cnt;
    reg [1:0] state;
    reg [1:0] state_next;
    reg [1:0] sclk_div_cnt;
    reg [1:0] sclk_div_cnt_next;
    reg spi_ssel_reg;
    reg spi_sck_reg;
    reg spi_mosi_reg;

    // State definitions
    parameter IDLE = 2'b00;
    parameter START = 2'b01;
    parameter SEND = 2'b10;
    parameter RECEIVE = 2'b11;

    // Clock dividers
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 2'b00;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 2'b00;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // State machine logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
        end else begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next = state;
        sclk_div_cnt_next = sclk_div_cnt;
        spi_ssel_reg = spi_ssel_o;
        spi_sck_reg = spi_sck_o;
        spi_mosi_reg = spi_mosi_o;
        wr_ack_o = 1'b0;
        do_valid_o = 1'b0;
        do_o = 8'b0;
        spi_ssel_o = 1'b1;
        spi_sck_o = 1'b0;
        spi_mosi_o = 1'b0;

        case (state)
            IDLE: begin
                if (wren_i) begin
                    state_next = START;
                    shift_reg = di_i;
                    bit_cnt = 2'b00;
                    spi_ssel_reg = 1'b0;
                end
            end
            START: begin
                spi_sck_reg = 1'b1;
                state_next = SEND;
            end
            SEND: begin
                if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                    spi_sck_reg = 1'b0;
                    spi_mosi_reg = shift_reg[0];
                    shift_reg = {shift_reg[7:1], 1'b0};
                    bit_cnt = bit_cnt + 1;
                    if (bit_cnt == N - 1) begin
                        state_next = RECEIVE;
                    end
                end
            end
            RECEIVE: begin
                if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                    spi_sck_reg = 1'b1;
                    spi_miso_i; // Ignore MISO for now
                    bit_cnt = bit_cnt + 1;
                    if (bit_cnt == N) begin
                        state_next = IDLE;
                        wr_ack_o = 1'b1;
                        do_valid_o = 1'b1;
                        do_o = shift_reg;
                    end
                end
            end
        endcase
    end

endmodule
