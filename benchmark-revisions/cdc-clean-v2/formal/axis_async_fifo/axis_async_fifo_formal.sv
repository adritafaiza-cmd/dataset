module axis_async_fifo_formal;
  (* gclk *) reg gclk; reg [6:0] tick=0; always @(posedge gclk) tick<=tick+1;
  wire s_clk=tick[0],m_clk=tick[1]; wire s_rst=tick<2,m_rst=tick<2;
  (* anyseq *) reg s_axis_tvalid,m_axis_tready;
  reg [7:0] wr_seq=0,rd_seq=0; wire [7:0] s_axis_tdata=wr_seq,m_axis_tdata;
  wire s_axis_tready,m_axis_tvalid,m_axis_tlast; wire [1:0] s_status_depth,s_status_depth_commit,m_status_depth,m_status_depth_commit;
  axis_async_fifo #(.DEPTH(4),.DATA_WIDTH(8),.KEEP_ENABLE(0),.KEEP_WIDTH(1),.LAST_ENABLE(1),.ID_ENABLE(0),.DEST_ENABLE(0),.USER_ENABLE(0),.RAM_PIPELINE(1)) dut(
   .s_clk(s_clk),.s_rst(s_rst),.s_axis_tdata(s_axis_tdata),.s_axis_tkeep(1'b1),.s_axis_tvalid(s_axis_tvalid),.s_axis_tready(s_axis_tready),.s_axis_tlast(wr_seq[0]),.s_axis_tid(1'b0),.s_axis_tdest(1'b0),.s_axis_tuser(1'b0),
   .m_clk(m_clk),.m_rst(m_rst),.m_axis_tdata(m_axis_tdata),.m_axis_tkeep(),.m_axis_tvalid(m_axis_tvalid),.m_axis_tready(m_axis_tready),.m_axis_tlast(m_axis_tlast),.m_axis_tid(),.m_axis_tdest(),.m_axis_tuser(),
   .s_pause_req(1'b0),.s_pause_ack(),.m_pause_req(1'b0),.m_pause_ack(),.s_status_depth(s_status_depth),.s_status_depth_commit(s_status_depth_commit),.s_status_overflow(),.s_status_bad_frame(),.s_status_good_frame(),.m_status_depth(m_status_depth),.m_status_depth_commit(m_status_depth_commit),.m_status_overflow(),.m_status_bad_frame(),.m_status_good_frame());
  always @(posedge s_clk) begin if(s_rst) wr_seq<=0; else if(s_axis_tvalid&&s_axis_tready) wr_seq<=wr_seq+1; assert(s_status_depth<=4); assert(s_status_depth_commit<=4); end
  reg stall; reg [8:0] held;
  always @(posedge m_clk) begin
    if(m_rst) begin rd_seq<=0;stall<=0;assert(!m_axis_tvalid);end else begin
      if(m_axis_tvalid) begin assert(m_axis_tdata==rd_seq);assert(m_axis_tlast==rd_seq[0]);end
      if(stall) begin assert(m_axis_tvalid);assert({m_axis_tlast,m_axis_tdata}==held);end
      stall<=m_axis_tvalid&&!m_axis_tready;held<={m_axis_tlast,m_axis_tdata};
      if(m_axis_tvalid&&m_axis_tready)rd_seq<=rd_seq+1;
    end
    assert(m_status_depth<=4);assert(m_status_depth_commit<=4);
  end
  always @(posedge gclk) begin cover(wr_seq>=4&&rd_seq>=3);cover(m_axis_tvalid&&!m_axis_tready); end
  always @* begin
    if (tick < 16) begin assume(!s_axis_tvalid); assume(!m_axis_tready); end
  end
endmodule
