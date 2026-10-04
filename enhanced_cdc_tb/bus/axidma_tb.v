`timescale 1ns/1ps
module axidma_tb;
  integer errors,wreq,brsp,rreq,rrsp,age;
  reg clk,rstn,awvalid,wvalid,bready,arvalid,rready;
  reg [4:0] awaddr,araddr;
  reg [31:0] wdata;
  reg [3:0] wstrb;
  wire awready,wready,bvalid,arready,rvalid;
  wire [1:0] bresp,rresp;
  wire [31:0] rdata;
  wire mawvalid,mwvalid,mwlast,mbready,marvalid,mrready;
  wire [31:0] mawaddr,mwdata,maraddr;
  reg pb,pr,pmaw,pmw,pmar;
  reg [31:0] prdata,pmawaddr,pmwdata,pmaraddr;
  always #5 clk=~clk;
  axidma #(.C_AXI_ID_WIDTH(1),.C_AXI_ADDR_WIDTH(32),.C_AXI_DATA_WIDTH(32),
    .OPT_UNALIGNED(1'b0),.LGMAXBURST(2),.LGFIFO(3)) dut(
    .S_AXI_ACLK(clk),.S_AXI_ARESETN(rstn),
    .S_AXIL_AWVALID(awvalid),.S_AXIL_AWREADY(awready),.S_AXIL_AWADDR(awaddr),.S_AXIL_AWPROT(3'b0),
    .S_AXIL_WVALID(wvalid),.S_AXIL_WREADY(wready),.S_AXIL_WDATA(wdata),.S_AXIL_WSTRB(wstrb),
    .S_AXIL_BVALID(bvalid),.S_AXIL_BREADY(bready),.S_AXIL_BRESP(bresp),
    .S_AXIL_ARVALID(arvalid),.S_AXIL_ARREADY(arready),.S_AXIL_ARADDR(araddr),.S_AXIL_ARPROT(3'b0),
    .S_AXIL_RVALID(rvalid),.S_AXIL_RREADY(rready),.S_AXIL_RDATA(rdata),.S_AXIL_RRESP(rresp),
    .M_AXI_AWVALID(mawvalid),.M_AXI_AWREADY(1'b1),.M_AXI_AWID(),.M_AXI_AWADDR(mawaddr),
    .M_AXI_AWLEN(),.M_AXI_AWSIZE(),.M_AXI_AWBURST(),.M_AXI_AWLOCK(),.M_AXI_AWCACHE(),.M_AXI_AWPROT(),.M_AXI_AWQOS(),
    .M_AXI_WVALID(mwvalid),.M_AXI_WREADY(1'b1),.M_AXI_WDATA(mwdata),.M_AXI_WSTRB(),.M_AXI_WLAST(mwlast),
    .M_AXI_BVALID(1'b0),.M_AXI_BREADY(mbready),.M_AXI_BID(1'b0),.M_AXI_BRESP(2'b0),
    .M_AXI_ARVALID(marvalid),.M_AXI_ARREADY(1'b1),.M_AXI_ARID(),.M_AXI_ARADDR(maraddr),
    .M_AXI_ARLEN(),.M_AXI_ARSIZE(),.M_AXI_ARBURST(),.M_AXI_ARLOCK(),.M_AXI_ARCACHE(),.M_AXI_ARPROT(),.M_AXI_ARQOS(),
    .M_AXI_RVALID(1'b0),.M_AXI_RREADY(mrready),.M_AXI_RID(1'b0),.M_AXI_RDATA(32'b0),.M_AXI_RRESP(2'b0),.M_AXI_RLAST(1'b1),.o_int());
  always @(posedge clk) begin
    if(!rstn)begin pb<=0;pr<=0;pmaw<=0;pmw<=0;pmar<=0;age<=0;end
    else begin
      if(awvalid&&awready)begin wreq=wreq+1;age<=1;end
      if(bvalid&&bready)begin brsp=brsp+1;age<=0;if(brsp>wreq)begin $display("PROTOCOL VIOLATION [AXIL_WRITE_RESPONSE_WITHOUT_REQUEST]: B response without request");errors=errors+1;end end
      if(arvalid&&arready)begin rreq=rreq+1;age<=1;end
      if(rvalid&&rready)begin rrsp=rrsp+1;age<=0;if(rrsp>rreq)begin $display("PROTOCOL VIOLATION [AXIL_READ_RESPONSE_WITHOUT_REQUEST]: R response without request");errors=errors+1;end end
      if(pb&&!bvalid)begin $display("PROTOCOL VIOLATION [AXIL_B_STALL_STABILITY]: B response dropped while stalled");errors=errors+1;end
      if(pr&&(!rvalid||rdata!==prdata))begin $display("PROTOCOL VIOLATION [AXIL_R_STALL_STABILITY]: R response changed while stalled");errors=errors+1;end
      if(pmaw&&(!mawvalid||mawaddr!==pmawaddr))begin $display("PROTOCOL VIOLATION [AXI_AW_STALL_STABILITY]: master AW changed while stalled");errors=errors+1;end
      if(pmw&&(!mwvalid||mwdata!==pmwdata))begin $display("PROTOCOL VIOLATION [AXI_W_STALL_STABILITY]: master W changed while stalled");errors=errors+1;end
      if(pmar&&(!marvalid||maraddr!==pmaraddr))begin $display("PROTOCOL VIOLATION [AXI_AR_STALL_STABILITY]: master AR changed while stalled");errors=errors+1;end
      if((bvalid&&^bresp===1'bx)||(rvalid&&^rdata===1'bx)||(mawvalid&&^mawaddr===1'bx)||
         (mwvalid&&^mwdata===1'bx)||(marvalid&&^maraddr===1'bx))begin $display("PROTOCOL VIOLATION [AXI_CHANNEL_KNOWN]: X on valid channel");errors=errors+1;end
      if(wreq>brsp||rreq>rrsp)begin age<=age+1;if(age>40)begin $display("PROTOCOL VIOLATION [AXIL_CONTROL_LATENCY]: bounded control latency exceeded");errors=errors+1;age<=0;end end
      pb<=bvalid&&!bready;pr<=rvalid&&!rready;prdata<=rdata;
      pmaw<=mawvalid&&!1'b1;pmw<=mwvalid&&!1'b1;pmar<=marvalid&&!1'b1;
      pmawaddr<=mawaddr;pmwdata<=mwdata;pmaraddr<=maraddr;
    end
  end
  task axil_write;
    input [4:0] a;input [31:0] d;
    begin @(negedge clk);awaddr=a;wdata=d;wstrb=4'hf;awvalid=1;wvalid=1;bready=0;
      while(awvalid||wvalid)begin @(negedge clk);if(awready)awvalid=0;if(wready)wvalid=0;end
      repeat(3)@(negedge clk);bready=1;while(!bvalid)@(negedge clk);
      if(bresp!==0)begin $display("PROTOCOL VIOLATION [AXIL_WRITE_RESPONSE]: BRESP indicates an error");errors=errors+1;end
      @(negedge clk);bready=0;end
  endtask
  task axil_read;
    input [4:0] a;
    begin @(negedge clk);araddr=a;arvalid=1;rready=0;while(!arready)@(negedge clk);
      @(negedge clk);arvalid=0;repeat(3)@(negedge clk);rready=1;while(!rvalid)@(negedge clk);
      if(rresp!==0||^rdata===1'bx)begin $display("PROTOCOL VIOLATION [AXIL_READ_RESPONSE]: invalid read response");errors=errors+1;end
      @(negedge clk);rready=0;end
  endtask
  initial begin
    errors=0;wreq=0;brsp=0;rreq=0;rrsp=0;age=0;clk=0;rstn=0;awvalid=0;wvalid=0;bready=0;arvalid=0;rready=0;awaddr=0;araddr=0;wdata=0;wstrb=0;
    pb=0;pr=0;pmaw=0;pmw=0;pmar=0;
    repeat(5)@(posedge clk);rstn=1;repeat(3)@(posedge clk);
    axil_write(5'h08,32'h00000100);axil_write(5'h10,32'h00000200);axil_write(5'h18,32'h00000010);
    axil_read(5'h08);axil_read(5'h10);axil_read(5'h18);
    @(negedge clk);awaddr=5'h08;wdata=32'hdeadbeef;awvalid=1;wvalid=1;
    @(posedge clk);rstn=0;awvalid=0;wvalid=0;
    repeat(4)@(posedge clk);rstn=1;wreq=0;brsp=0;rreq=0;rrsp=0;
    axil_write(5'h08,32'h00000300);axil_read(5'h08);
    if(wreq!=brsp||rreq!=rrsp)begin $display("PROTOCOL VIOLATION [AXIL_TRANSACTION_CONSERVATION]: request and response counts differ");errors=errors+1;end
    if(errors==0)$display("AXIDMA ENHANCED: ALL TESTS PASSED");else $display("AXIDMA ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #100000;$display("AXIDMA ENHANCED: TIMEOUT");$finish;end
endmodule
