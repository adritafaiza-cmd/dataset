// Verilog-2001 rewrite of OpenCores spi_slave (Jonny Doin).
// Serial bits are captured on spi_sck_i; completion is synchronized to clk_i.

module spi_slave #(
    parameter N = 8
)(
    input              clk_i,
    input              spi_ssel_i,
    input              spi_sck_i,
    input              spi_mosi_i,
    output             spi_miso_o,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    reg [N-1:0] tx_hold, tx_shift, rx_shift;
    (* ASYNC_REG = "TRUE" *) reg [1:0] ssel_sync;

    assign spi_miso_o = tx_shift[N-1];

    always @(posedge clk_i) begin
        if (wren_i)
            tx_hold <= di_i;
        ssel_sync <= {ssel_sync[0], spi_ssel_i};
        do_valid_o <= 1'b0;
        if (ssel_sync == 2'b01) begin
            do_o <= rx_shift;
            do_valid_o <= 1'b1;
            di_req_o <= 1'b1;
        end else
            di_req_o <= 1'b0;
    end

    always @(posedge spi_sck_i or posedge spi_ssel_i) begin
        if (spi_ssel_i) begin
            rx_shift <= {N{1'b0}};
            tx_shift <= tx_hold;
        end else begin
            rx_shift <= {rx_shift[N-2:0], spi_mosi_i};
            tx_shift <= {tx_shift[N-2:0], 1'b0};
        end
    end

endmodule
