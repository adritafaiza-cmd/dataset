module spi_master_slave_formal;
  localparam N=4;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire sclk_i = tick[0];
  wire pclk_i = tick[1];
  wire rst_i = (tick < 8);
  (* anyseq *) reg [N-1:0] di_i;
  (* anyseq *) reg wren_i, spi_miso_i;
  wire spi_ssel_o, spi_sck_o, spi_mosi_o, di_req_o, wr_ack_o, do_valid_o;
  wire [N-1:0] do_o;
  spi_master #(.N(N), .SPI_2X_CLK_DIV(1)) dut(.*);

  always @* begin
    if (tick < 10)
      assume(!wren_i);
  end

  always @(posedge pclk_i) begin
    if (!rst_i && $past(!rst_i && wr_ack_o))
      assert(!wr_ack_o);
    if (!rst_i && $past(!rst_i && do_valid_o))
      assert(!do_valid_o);
  end

  always @(posedge sclk_i) begin
    if (!rst_i && $past(rst_i))
      assert(spi_ssel_o);
  end

  always @(posedge gclk) begin
    cover(!rst_i && wr_ack_o);
    cover(!rst_i && !spi_ssel_o);
  end
endmodule
