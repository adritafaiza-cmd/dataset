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
    reg [N-1:0] rx_reg;
    reg [1:0] state;
    reg sclk_sync;
    reg pclk_sync;
    reg [1:0] sclk_cnt;

    // State definitions
    localparam IDLE = 2'b00;
    localparam SEND = 2'b01;
    localparam RECEIVE = 2'b10;

    // Synchronize clocks
    sclk_sync_inst (
        .clk_i(sclk_i),
        .clk_o(sclk_sync),
        .rst_i(rst_i)
    );

    pclk_sync_inst (
        .clk_i(pclk_i),
        .clk_o(pclk_sync),
        .rst_i(rst_i)
    );

    // SPI master state machine
    always @(posedge pclk_sync or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    begin
                        if (wren_i) begin
                            shift_reg <= di_i;
                            bit_cnt <= N;
                            spi_ssel_o <= 1'b0;
                            di_req_o <= 1'b1;
                            state <= SEND;
                        end
                    end
                SEND:
                    begin
                        spi_mosi_o <= shift_reg[N-1];
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 0) begin
                            spi_ssel_o <= 1'b1;
                            di_req_o <= 1'b0;
                            state <= RECEIVE;
                        end else begin
                            spi_sck_o <= ~spi_sck_o;
                        end
                    end
                RECEIVE:
                    begin
                        rx_reg[N-1] <= spi_miso_i;
                        rx_reg[N-2:0] <= rx_reg[N-3:0];
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 0) begin
                            do_o <= rx_reg;
                            do_valid_o <= 1'b1;
                            wr_ack_o <= 1'b1;
                            state <= IDLE;
                        end else begin
                            spi_sck_o <= ~spi_sck_o;
                        end
                    end
            endcase
        end
    end

endmodule

module sclk_sync (
    input              clk_i,
    output reg         clk_o,
    input              rst_i
);

    reg [1:0] sync_reg;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sync_reg <= 2'b00;
            clk_o <= 1'b0;
        end else begin
            sync_reg <= {sync_reg[0], clk_i};
            clk_o <= sync_reg[1];
        end
    end

endmodule

module pclk_sync (
    input              clk_i,
    output reg         clk_o,
    input              rst_i
);

    reg [1:0] sync_reg;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sync_reg <= 2'b00;
            clk_o <= 1'b0;
        end else begin
            sync_reg <= {sync_reg[0], clk_i};
            clk_o <= sync_reg[1];
        end
    end

endmodule
