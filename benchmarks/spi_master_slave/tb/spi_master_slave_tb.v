`timescale 1ns/1ps

module spi_master_slave_tb;
    integer errors = 0;

    reg sclk_i = 0, pclk_i = 0, rst_i = 1, wren_i = 0;
    wire ssel, sck, mosi, di_req, wr_ack, do_valid;
    wire [7:0] do_o;
    always #5 sclk_i = ~sclk_i;
    always #5 pclk_i = ~pclk_i;

    spi_master #(.N(8), .SPI_2X_CLK_DIV(2)) dut (
        .sclk_i(sclk_i), .pclk_i(pclk_i), .rst_i(rst_i),
        .spi_ssel_o(ssel), .spi_sck_o(sck), .spi_mosi_o(mosi),
        .spi_miso_i(mosi),
        .di_req_o(di_req), .di_i(8'h5A), .wren_i(wren_i),
        .wr_ack_o(wr_ack), .do_valid_o(do_valid), .do_o(do_o)
    );

    initial begin
        repeat (8) @(posedge pclk_i); rst_i = 0;
        repeat (4) @(posedge pclk_i);
        repeat (4) @(posedge sclk_i);
        @(negedge pclk_i); wren_i = 1;
        @(negedge pclk_i); wren_i = 0;
        repeat (80) @(posedge pclk_i);
        if (do_o !== 8'h5A) begin
            $display("FAIL loopback got %h", do_o);
            errors = errors + 1;
        end
        if (errors == 0) $display("SPI MASTER SLAVE: ALL TESTS PASSED");
        else $display("SPI MASTER SLAVE: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #40000;
        $display("SPI_MASTER_SLAVE_TB: TIMEOUT");
        $finish;
    end
endmodule
