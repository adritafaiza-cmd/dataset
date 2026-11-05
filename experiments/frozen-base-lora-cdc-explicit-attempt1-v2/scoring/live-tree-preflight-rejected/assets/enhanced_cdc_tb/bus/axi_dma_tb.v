`timescale 1ns/1ps
module axi_dma_tb;
  integer errors,wr_desc,wr_status,rd_desc,rd_status,age,tick;
  reg clk,rst;
  reg [15:0] rd_addr,wr_addr;
  reg [19:0] rd_len,wr_len;
  reg [7:0] rd_tag,wr_tag;
  reg rd_valid,wr_valid,wd_valid,wd_last,rd_out_ready;
  reg [31:0] wd_data;
  wire rd_ready,wr_ready,wd_ready;
  wire [7:0] rd_status_tag,wr_status_tag;
  wire [3:0] rd_status_error,wr_status_error;
  wire rd_status_valid,wr_status_valid;
  wire [31:0] rd_out_data;
  wire [3:0] rd_out_keep;
  wire rd_out_valid,rd_out_last;
  wire [19:0] wr_status_len;
  wire awvalid,wvalid,wlast,bready,arvalid,rready;
  wire [15:0] awaddr,araddr;
  wire [31:0] wdata;
  wire [3:0] wstrb;
  reg awready,wready,bvalid,arready,rvalid,rlast;
  reg [31:0] rdata;
  reg paw,pw,par,pout;
  reg [15:0] pawaddr,paraddr;
  reg [31:0] pwdata,poutdata;
  always #5 clk=~clk;
  axi_dma #(.AXI_DATA_WIDTH(32),.AXI_ADDR_WIDTH(16),.AXI_ID_WIDTH(8),
    .AXIS_DATA_WIDTH(32),.ENABLE_SG(0),.ENABLE_UNALIGNED(0)) dut(
    .clk(clk),.rst(rst),.s_axis_read_desc_addr(rd_addr),.s_axis_read_desc_len(rd_len),
    .s_axis_read_desc_tag(rd_tag),.s_axis_read_desc_id(8'h11),
    .s_axis_read_desc_dest(8'h22),.s_axis_read_desc_user(1'b0),
    .s_axis_read_desc_valid(rd_valid),.s_axis_read_desc_ready(rd_ready),
    .m_axis_read_desc_status_tag(rd_status_tag),
    .m_axis_read_desc_status_error(rd_status_error),
    .m_axis_read_desc_status_valid(rd_status_valid),
    .m_axis_read_data_tdata(rd_out_data),.m_axis_read_data_tkeep(rd_out_keep),
    .m_axis_read_data_tvalid(rd_out_valid),.m_axis_read_data_tready(rd_out_ready),
    .m_axis_read_data_tlast(rd_out_last),.m_axis_read_data_tid(),
    .m_axis_read_data_tdest(),.m_axis_read_data_tuser(),
    .s_axis_write_desc_addr(wr_addr),.s_axis_write_desc_len(wr_len),
    .s_axis_write_desc_tag(wr_tag),.s_axis_write_desc_valid(wr_valid),
    .s_axis_write_desc_ready(wr_ready),.m_axis_write_desc_status_len(wr_status_len),
    .m_axis_write_desc_status_tag(wr_status_tag),.m_axis_write_desc_status_id(),
    .m_axis_write_desc_status_dest(),.m_axis_write_desc_status_user(),
    .m_axis_write_desc_status_error(wr_status_error),
    .m_axis_write_desc_status_valid(wr_status_valid),
    .s_axis_write_data_tdata(wd_data),.s_axis_write_data_tkeep(4'hf),
    .s_axis_write_data_tvalid(wd_valid),.s_axis_write_data_tready(wd_ready),
    .s_axis_write_data_tlast(wd_last),.s_axis_write_data_tid(8'h0),
    .s_axis_write_data_tdest(8'h0),.s_axis_write_data_tuser(1'b0),
    .m_axi_awid(),.m_axi_awaddr(awaddr),.m_axi_awlen(),.m_axi_awsize(),
    .m_axi_awburst(),.m_axi_awlock(),.m_axi_awcache(),.m_axi_awprot(),
    .m_axi_awvalid(awvalid),.m_axi_awready(awready),.m_axi_wdata(wdata),
    .m_axi_wstrb(wstrb),.m_axi_wlast(wlast),.m_axi_wvalid(wvalid),
    .m_axi_wready(wready),.m_axi_bid(8'h0),.m_axi_bresp(2'b0),
    .m_axi_bvalid(bvalid),.m_axi_bready(bready),.m_axi_arid(),
    .m_axi_araddr(araddr),.m_axi_arlen(),.m_axi_arsize(),.m_axi_arburst(),
    .m_axi_arlock(),.m_axi_arcache(),.m_axi_arprot(),.m_axi_arvalid(arvalid),
    .m_axi_arready(arready),.m_axi_rid(8'h0),.m_axi_rdata(rdata),
    .m_axi_rresp(2'b0),.m_axi_rlast(rlast),.m_axi_rvalid(rvalid),
    .m_axi_rready(rready),.read_enable(1'b1),.write_enable(1'b1),.write_abort(1'b0));

  always @(posedge clk) begin
    if(rst)begin awready<=0;wready<=0;arready<=0;bvalid<=0;rvalid<=0;tick<=0;end
    else begin
      tick<=tick+1;awready<=(tick[1:0]!=0);wready<=(tick[2:1]!=0);arready<=(tick[1:0]!=1);
      if(bvalid&&bready)bvalid<=0;else if(wvalid&&wready&&wlast)bvalid<=1;
      if(arvalid&&arready)begin rdata<=32'hc001d00d;rvalid<=1;rlast<=1;end
      else if(rvalid&&rready)rvalid<=0;
      if(paw&&(!awvalid||awaddr!==pawaddr))begin $display("PROTOCOL VIOLATION [AXI_AW_STALL_STABILITY]: AW changed while stalled");errors=errors+1;end
      if(pw&&(!wvalid||wdata!==pwdata))begin $display("PROTOCOL VIOLATION [AXI_W_STALL_STABILITY]: W changed while stalled");errors=errors+1;end
      if(par&&(!arvalid||araddr!==paraddr))begin $display("PROTOCOL VIOLATION [AXI_AR_STALL_STABILITY]: AR changed while stalled");errors=errors+1;end
      if(pout&&(!rd_out_valid||rd_out_data!==poutdata))begin $display("PROTOCOL VIOLATION [AXIS_PAYLOAD_STABILITY]: stream output changed while stalled");errors=errors+1;end
      if((awvalid&&^awaddr===1'bx)||(wvalid&&^wdata===1'bx)||(arvalid&&^araddr===1'bx)||(rd_out_valid&&^rd_out_data===1'bx))begin
        $display("PROTOCOL VIOLATION [AXI_CHANNEL_KNOWN]: X on valid channel");errors=errors+1;
      end
      paw<=awvalid&&!awready;pw<=wvalid&&!wready;par<=arvalid&&!arready;pout<=rd_out_valid&&!rd_out_ready;
      pawaddr<=awaddr;pwdata<=wdata;paraddr<=araddr;poutdata<=rd_out_data;
      if(wr_valid&&wr_ready)begin wr_desc=wr_desc+1;age<=1;end
      if(wr_status_valid)begin wr_status=wr_status+1;if(wr_status>wr_desc)begin $display("PROTOCOL VIOLATION [DMA_WRITE_STATUS_WITHOUT_DESCRIPTOR]: write status without descriptor");errors=errors+1;end end
      if(rd_valid&&rd_ready)begin rd_desc=rd_desc+1;age<=1;end
      if(rd_status_valid)begin rd_status=rd_status+1;if(rd_status>rd_desc)begin $display("PROTOCOL VIOLATION [DMA_READ_STATUS_WITHOUT_DESCRIPTOR]: read status without descriptor");errors=errors+1;end end
      if((wr_desc>wr_status)||(rd_desc>rd_status))begin age<=age+1;if(age>200)begin $display("PROTOCOL VIOLATION [DMA_COMPLETION_LATENCY]: bounded completion exceeded");errors=errors+1;age<=0;end end
    end
  end
  task write_transfer;
    reg desc_done, data_done;
    begin
      @(negedge clk);wr_addr=16'h0100;wr_len=4;wr_tag=8'ha1;wr_valid=1;wd_data=32'h5a5aa5a5;wd_last=1;wd_valid=1;
      while(wr_valid||wd_valid)begin
        @(posedge clk);desc_done=wr_valid&&wr_ready;data_done=wd_valid&&wd_ready;
        #1;if(desc_done)wr_valid=0;if(data_done)wd_valid=0;
      end
      while(wr_status<wr_desc)@(negedge clk);
      if(wr_status_tag!==8'ha1||wr_status_error!==0||wr_status_len!==4)begin $display("PROTOCOL VIOLATION [DMA_WRITE_STATUS]: invalid write status");errors=errors+1;end
    end
  endtask
  task read_transfer;
    reg desc_done;
    begin
      @(negedge clk);rd_addr=16'h0200;rd_len=4;rd_tag=8'hb2;rd_valid=1;rd_out_ready=0;
      desc_done=0;while(!desc_done)begin @(posedge clk);desc_done=rd_valid&&rd_ready;end
      #1 rd_valid=0;
      repeat(4)@(negedge clk);rd_out_ready=1;
      while(!rd_out_valid)@(negedge clk);
      if(rd_out_data!==32'hc001d00d||!rd_out_last)begin $display("PROTOCOL VIOLATION [DMA_READ_DATA]: invalid read data or last marker");errors=errors+1;end
      while(rd_status<rd_desc)@(negedge clk);
      if(rd_status_tag!==8'hb2||rd_status_error!==0)begin $display("PROTOCOL VIOLATION [DMA_READ_STATUS]: invalid read status");errors=errors+1;end
    end
  endtask
  initial begin
    errors=0;wr_desc=0;wr_status=0;rd_desc=0;rd_status=0;age=0;tick=0;clk=0;rst=1;
    rd_addr=0;rd_len=0;rd_tag=0;rd_valid=0;wr_addr=0;wr_len=0;wr_tag=0;wr_valid=0;wd_valid=0;wd_last=0;wd_data=0;rd_out_ready=0;
    awready=0;wready=0;bvalid=0;arready=0;rvalid=0;rlast=0;rdata=0;paw=0;pw=0;par=0;pout=0;
    repeat(5)@(posedge clk);rst=0;write_transfer;read_transfer;
    @(negedge clk);wr_addr=16'h0300;wr_len=4;wr_valid=1;repeat(2)@(posedge clk);rst=1;wr_valid=0;
    repeat(4)@(posedge clk);rst=0;wr_desc=0;wr_status=0;rd_desc=0;rd_status=0;repeat(4)@(posedge clk);
    write_transfer;read_transfer;
    if(wr_desc!=wr_status||rd_desc!=rd_status)begin $display("PROTOCOL VIOLATION [DMA_TRANSACTION_CONSERVATION]: descriptor and status counts differ");errors=errors+1;end
    if(errors==0)$display("AXI DMA ENHANCED: ALL TESTS PASSED");else $display("AXI DMA ENHANCED: TESTS FAILED (%0d)",errors);
    $finish;
  end
  initial begin #150000;$display("AXI DMA ENHANCED: TIMEOUT");$finish;end
endmodule
