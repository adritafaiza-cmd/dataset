`timescale 1ns/1ps
module wbxclk_tb;
  localparam AW=8,DW=32,LGFIFO=3;
  integer errors,sreq,srsp,xreq,tick,age,i;
  reg wb_clk,xclk,reset,cyc,stb,we;
  reg [AW-1:0] addr;
  reg [DW-1:0] data;
  reg [3:0] sel;
  wire stall,ack,err;
  wire [DW-1:0] rdata;
  wire x_cyc,x_stb,x_we;
  wire [AW-1:0] x_addr;
  wire [DW-1:0] x_data;
  wire [3:0] x_sel;
  reg x_stall,x_ack,x_err;
  reg [DW-1:0] x_rdata;
  reg [DW-1:0] mem[0:255];
  reg prev_wait,prev_we;
  reg [AW-1:0] prev_addr;
  reg [DW-1:0] prev_data;
  always #5 wb_clk=~wb_clk;
  always #7 xclk=~xclk;

  wbxclk #(.AW(AW),.DW(DW),.LGFIFO(LGFIFO)) dut(
    .i_wb_clk(wb_clk),.i_reset(reset),.i_wb_cyc(cyc),.i_wb_stb(stb),
    .i_wb_we(we),.i_wb_addr(addr),.i_wb_data(data),.i_wb_sel(sel),
    .o_wb_stall(stall),.o_wb_ack(ack),.o_wb_data(rdata),.o_wb_err(err),
    .i_xclk_clk(xclk),.o_xclk_cyc(x_cyc),.o_xclk_stb(x_stb),
    .o_xclk_we(x_we),.o_xclk_addr(x_addr),.o_xclk_data(x_data),
    .o_xclk_sel(x_sel),.i_xclk_stall(x_stall),.i_xclk_ack(x_ack),
    .i_xclk_data(x_rdata),.i_xclk_err(x_err));

  always @(posedge xclk) begin
    if(reset || dut.x_fifo_reset!==1'b0) begin x_ack<=0;x_err<=0;x_stall<=0;tick<=0;prev_wait<=0;end
    else begin
      tick<=tick+1;x_ack<=0;x_err<=0;x_stall<=(tick[2:0]<3);
      if(x_cyc&&x_stb&&!x_stall) begin
        xreq=xreq+1;x_ack<=1;
        if(x_we)mem[x_addr]<=x_data;
        x_rdata<=x_we?x_data:mem[x_addr];
      end
      if(prev_wait&&(!x_cyc||!x_stb||x_addr!==prev_addr||
         x_data!==prev_data||x_we!==prev_we)) begin
        $display("CDC/RESET VIOLATION [WB_STALL_STABILITY]: downstream payload changed while stalled");errors=errors+1;
      end
      if(x_cyc&&x_stb&&((^x_addr===1'bx)||(^x_we===1'bx)))begin
        $display("CDC/RESET VIOLATION [WB_REQUEST_KNOWN]: X on downstream request");errors=errors+1;
      end
      if((x_ack||x_err)&&!x_cyc)begin $display("CDC/RESET VIOLATION [WB_RESPONSE_COHERENCY]: downstream response without cycle");errors=errors+1;end
      prev_wait<=x_cyc&&x_stb&&x_stall;prev_addr<=x_addr;prev_data<=x_data;prev_we<=x_we;
    end
  end

  always @(posedge wb_clk) begin
    if(reset) age<=0;
    else begin
      if(cyc&&stb&&!stall)begin sreq=sreq+1;age<=1;end
      if(ack||err)begin
        srsp=srsp+1;age<=0;
        if(srsp>sreq)begin $display("CDC/RESET VIOLATION [WB_RESPONSE_COHERENCY]: response without request");errors=errors+1;end
        if(ack&&err)begin $display("CDC/RESET VIOLATION [WB_RESPONSE_EXCLUSIVITY]: ACK and ERR asserted together");errors=errors+1;end
        if(!cyc)begin $display("CDC/RESET VIOLATION [WB_RESPONSE_COHERENCY]: response without CYC");errors=errors+1;end
        if(ack&&^rdata===1'bx)begin $display("CDC/RESET VIOLATION [WB_RESPONSE_KNOWN]: X response data");errors=errors+1;end
      end
      if(sreq>srsp)begin age<=age+1;if(age>100)begin $display("CDC/RESET VIOLATION [WB_CROSS_DOMAIN_LATENCY]: bounded latency exceeded");errors=errors+1;age<=0;end end
    end
  end

  task wb_write;
    input [AW-1:0] a;input [DW-1:0] d;
    begin
      @(negedge wb_clk);cyc=1;stb=1;we=1;addr=a;data=d;sel=4'hf;
      while(stall)@(negedge wb_clk);@(negedge wb_clk);stb=0;
      while(!ack&&!err)@(negedge wb_clk);@(negedge wb_clk);cyc=0;we=0;
    end
  endtask
  task wb_read_check;
    input [AW-1:0] a;input [DW-1:0] e;
    begin
      @(negedge wb_clk);cyc=1;stb=1;we=0;addr=a;sel=4'hf;
      while(stall)@(negedge wb_clk);@(negedge wb_clk);stb=0;
      while(!ack&&!err)@(negedge wb_clk);
      if(rdata!==e)begin $display("CDC/RESET VIOLATION [WB_DATA_COHERENCY]: read %h expected %h",rdata,e);errors=errors+1;end
      @(negedge wb_clk);cyc=0;
    end
  endtask

  initial begin
    errors=0;sreq=0;srsp=0;xreq=0;tick=0;age=0;wb_clk=0;xclk=0;reset=1;
    cyc=0;stb=0;we=0;addr=0;data=0;sel=0;x_stall=0;x_ack=0;x_err=0;x_rdata=0;prev_wait=0;
    for(i=0;i<256;i=i+1)mem[i]=0;
    repeat(8)@(posedge wb_clk);reset=0;repeat(8)@(posedge wb_clk);
    wb_write(8'h01,32'h1234abcd);wb_read_check(8'h01,32'h1234abcd);
    wb_write(8'h02,32'ha5a55a5a);wb_read_check(8'h02,32'ha5a55a5a);
    @(negedge wb_clk);cyc=1;stb=1;we=1;addr=8'h03;data=32'hdeadbeef;sel=4'hf;
    repeat(2)@(posedge xclk);reset=1;cyc=0;stb=0;we=0;
    repeat(7)@(posedge wb_clk);reset=0;repeat(10)@(posedge wb_clk);
    sreq=0;srsp=0;xreq=0;
    wb_write(8'h03,32'hcafef00d);wb_read_check(8'h03,32'hcafef00d);
    if(sreq!=srsp||sreq!=xreq)begin $display("CDC/RESET VIOLATION [WB_TRANSACTION_CONSERVATION]: source=%0d response=%0d destination=%0d",sreq,srsp,xreq);errors=errors+1;end
    if(errors==0)$display("WBXCLK ENHANCED: ALL TESTS PASSED");else $display("WBXCLK ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #180000;$display("WBXCLK ENHANCED: TIMEOUT");$finish;end
endmodule
