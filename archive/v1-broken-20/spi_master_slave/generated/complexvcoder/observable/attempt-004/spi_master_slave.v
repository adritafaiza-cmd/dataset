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
    reg [N-1:0] spi_tx_buffer;
    reg [N-1:0] spi_rx_buffer;
    reg [2:0] bit_cnt;
    reg [1:0] state;
    reg spi_clk;
    reg spi_mosi;

    // State definitions
    parameter IDLE = 2'b00;
    parameter SEND = 2'b01;
    parameter RECEIVE = 2'b10;
    parameter DONE = 2'b11;

    // Clock divider for SPI clock
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_clk <= 1'b0;
        end else begin
            spi_clk <= ~spi_clk;
        end
    end

    // SPI clock generator
    assign spi_sck_o = spi_clk;

    // SPI state machine
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            state <= IDLE;
            bit_cnt <= 3'b000;
            spi_tx_buffer <= 8'b0;
            spi_rx_buffer <= 8'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (wren_i) begin
                        spi_ssel_o <= 1'b0;
                        spi_tx_buffer <= di_i;
                        bit_cnt <= 3'b111;
                        state <= SEND;
                    end
                end
                SEND: begin
                    spi_mosi <= spi_tx_buffer[7];
                    if (bit_cnt == 0) begin
                        state <= RECEIVE;
                    end else begin
                        spi_tx_buffer <= {spi_tx_buffer[6:0], spi_miso_i};
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                RECEIVE: begin
                    if (bit_cnt == 0) begin
                        spi_ssel_o <= 1'b1;
                        state <= DONE;
                        wr_ack_o <= 1'b1;
                        do_valid_o <= 1'b1;
                        do_o <= spi_rx_buffer;
                    end else begin
                        spi_rx_buffer <= {spi_rx_buffer[6:0], spi_miso_i};
                        bit_cnt <= bit_cnt - 1;
                    end
                end
                DONE: begin
                    wr_ack_o <= 1'b0;
                    do_valid_o <= 1'b0;
                    if (wren_i) begin
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
