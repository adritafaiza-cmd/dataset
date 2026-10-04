`timescale 1ns/1ps
module spi_master_slave_tb;
  integer errors,requests,responses,age;
  reg sclk_i,pclk_i,rst_i,wren_i;
  reg [7:0] di_i;
  wire ssel,sck,mosi,di_req,wr_ack,do_valid;
  wire [7:0] do_o;
  always #4 sclk_i=~sclk_i;
  always #7 pclk_i=~pclk_i;
  spi_master #(.N(8),.SPI_2X_CLK_DIV(2)) dut(
    .sclk_i(sclk_i),.pclk_i(pclk_i),.rst_i(rst_i),
    .spi_ssel_o(ssel),.spi_sck_o(sck),.spi_mosi_o(mosi),
    .spi_miso_i(mosi),.di_req_o(di_req),.di_i(di_i),
    .wren_i(wren_i),.wr_ack_o(wr_ack),.do_valid_o(do_valid),.do_o(do_o));
  always @(posedge pclk_i) begin
    if(rst_i)age<=0;
    else begin
      if(wr_ack)begin requests=requests+1;age<=1;end
      if(do_valid)begin
        responses=responses+1;age<=0;
        if(responses>requests)begin $display("CDC/RESET VIOLATION [SPI_RESPONSE_COHERENCY]: response without request");errors=errors+1;end
        if(^do_o===1'bx)begin $display("CDC/RESET VIOLATION [SPI_RECEIVE_DATA_KNOWN]: X in receive data");errors=errors+1;end
      end
      if(requests>responses)begin age<=age+1;if(age>160)begin $display("CDC/RESET VIOLATION [SPI_CROSS_DOMAIN_LATENCY]: bounded completion exceeded");errors=errors+1;age<=0;end end
      if(wr_ack&&^di_i===1'bx)begin $display("CDC/RESET VIOLATION [SPI_ACCEPTED_DATA_KNOWN]: X in accepted data");errors=errors+1;end
    end
  end
  task transfer;
    input [7:0] d;
    begin
      @(negedge pclk_i);
      while(wr_ack)@(negedge pclk_i);
      while(!di_req)@(negedge pclk_i);
      di_i=d;wren_i=1;
      while(!wr_ack)@(negedge pclk_i);
      @(negedge pclk_i);wren_i=0;
      while(do_valid)@(negedge pclk_i);
      while(!do_valid)@(negedge pclk_i);
      if(do_o!==d)begin $display("CDC/RESET VIOLATION [SPI_STALE_TRANSFER]: stale or incorrect loopback %h expected %h",do_o,d);errors=errors+1;end
      @(posedge pclk_i);
      // Let the synchronized start request return low before a new request.
      repeat(20)@(posedge sclk_i);
    end
  endtask
  initial begin
    errors=0;requests=0;responses=0;age=0;sclk_i=0;pclk_i=0;rst_i=1;wren_i=0;di_i=0;
    repeat(8)@(posedge pclk_i);rst_i=0;repeat(5)@(posedge pclk_i);
    transfer(8'h5a);transfer(8'ha5);
    @(negedge pclk_i);di_i=8'hee;wren_i=1;while(!wr_ack)@(negedge pclk_i);
    repeat(8)@(posedge sclk_i);rst_i=1;wren_i=0;
    repeat(8)@(posedge pclk_i);rst_i=0;requests=0;responses=0;age=0;
    repeat(4)@(posedge pclk_i);transfer(8'h3c);
    if(requests!=responses)begin $display("CDC/RESET VIOLATION [SPI_TRANSACTION_CONSERVATION]: requests=%0d responses=%0d",requests,responses);errors=errors+1;end
    if(errors==0)$display("SPI MASTER SLAVE ENHANCED: ALL TESTS PASSED");else $display("SPI MASTER SLAVE ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #120000;$display("SPI MASTER SLAVE ENHANCED: TIMEOUT");$finish;end
endmodule
