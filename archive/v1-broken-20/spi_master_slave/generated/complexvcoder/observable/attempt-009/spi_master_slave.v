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
    reg sclk_div;
    reg pclk_div;
    reg [N-1:0] received_data;
    reg spi_ssel;
    reg spi_sck;
    reg spi_mosi;
    reg [2:0] state;

    // State definitions
    parameter IDLE = 3'b000;
    parameter SEND_START = 3'b001;
    parameter SEND_DATA = 3'b010;
    parameter RECEIVE_DATA = 3'b011;
    parameter SEND_STOP = 3'b100;

    // Clock dividers
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div <= 0;
        end else begin
            sclk_div <= ~sclk_div;
        end
    end

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            pclk_div <= 0;
        end else begin
            pclk_div <= ~pclk_div;
        end
    end

    // SPI control logic
    always @(posedge pclk_div or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            spi_ssel_o <= 1;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            shift_reg <= 0;
            bit_cnt <= 0;
            received_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    di_req_o <= 0;
                    wr_ack_o <= 0;
                    do_valid_o <= 0;
                    if (wren_i) begin
                        di_req_o <= 1;
                    end
                end
                SEND_START: begin
                    spi_ssel_o <= 0;
                    spi_sck_o <= 0;
                    spi_mosi_o <= di_i[N-1];
                    bit_cnt <= N-1;
                    state <= SEND_DATA;
                end
                SEND_DATA: begin
                    if (sclk_div) begin
                        spi_sck_o <= ~spi_sck_o;
                        if (spi_sck_o) begin
                            spi_mosi_o <= di_i[bit_cnt];
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                    if (bit_cnt == 0) begin
                        state <= RECEIVE_DATA;
                    end
                end
                RECEIVE_DATA: begin
                    if (sclk_div) begin
                        spi_sck_o <= ~spi_sck_o;
                        if (spi_sck_o) begin
                            received_data[N-1-bit_cnt] <= spi_miso_i;
                        end
                    end
                    if (bit_cnt == 0) begin
                        state <= SEND_STOP;
                    end else begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                SEND_STOP: begin
                    spi_ssel_o <= 1;
                    spi_sck_o <= 0;
                    spi_mosi_o <= 0;
                    wr_ack_o <= 1;
                    do_valid_o <= 1;
                    do_o <= received_data;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
