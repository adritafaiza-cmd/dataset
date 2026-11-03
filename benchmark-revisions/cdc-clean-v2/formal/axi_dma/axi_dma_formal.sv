`default_nettype wire
module axi_dma_formal;
  localparam AW=8, DW=8, IW=1, LW=8, TW=4;
  reg clk;
  (* anyseq *) reg rst, read_enable, write_enable, write_abort;
  (* anyseq *) reg [AW-1:0] s_axis_read_desc_addr, s_axis_write_desc_addr;
  (* anyseq *) reg [LW-1:0] s_axis_read_desc_len, s_axis_write_desc_len;
  (* anyseq *) reg [TW-1:0] s_axis_read_desc_tag, s_axis_write_desc_tag;
  (* anyseq *) reg s_axis_read_desc_valid, s_axis_write_desc_valid;
  (* anyseq *) reg [DW-1:0] s_axis_write_data_tdata, m_axi_rdata;
  (* anyseq *) reg s_axis_write_data_tvalid, s_axis_write_data_tlast;
  (* anyseq *) reg m_axis_read_data_tready;
  (* anyseq *) reg m_axi_awready, m_axi_wready, m_axi_bvalid, m_axi_arready, m_axi_rvalid, m_axi_rlast;
  (* anyseq *) reg [IW-1:0] m_axi_bid, m_axi_rid;
  (* anyseq *) reg [1:0] m_axi_bresp, m_axi_rresp;
  wire s_axis_read_desc_ready, s_axis_write_desc_ready;
  wire [TW-1:0] m_axis_read_desc_status_tag, m_axis_write_desc_status_tag;
  wire [3:0] m_axis_read_desc_status_error, m_axis_write_desc_status_error;
  wire m_axis_read_desc_status_valid, m_axis_write_desc_status_valid;
  wire [DW-1:0] m_axis_read_data_tdata, m_axi_wdata;
  wire m_axis_read_data_tvalid, m_axis_read_data_tlast, s_axis_write_data_tready;
  wire [IW-1:0] m_axi_awid, m_axi_arid;
  wire [AW-1:0] m_axi_awaddr, m_axi_araddr;
  wire [7:0] m_axi_awlen, m_axi_arlen;
  wire [2:0] m_axi_awsize, m_axi_arsize, m_axi_awprot, m_axi_arprot;
  wire [1:0] m_axi_awburst, m_axi_arburst;
  wire m_axi_awlock, m_axi_arlock, m_axi_awvalid, m_axi_wvalid, m_axi_wlast;
  wire m_axi_bready, m_axi_arvalid, m_axi_rready;
  wire [3:0] m_axi_awcache, m_axi_arcache;
  wire [DW/8-1:0] m_axi_wstrb;
  wire [7:0] s_axis_read_desc_id = 8'b0;
  wire [7:0] s_axis_read_desc_dest = 8'b0;
  wire s_axis_read_desc_user = 1'b0;
  wire [DW/8-1:0] s_axis_write_data_tkeep = {DW/8{1'b1}};
  wire [7:0] s_axis_write_data_tid = 8'b0;
  wire [7:0] s_axis_write_data_tdest = 8'b0;
  wire s_axis_write_data_tuser = 1'b0;
  wire [LW-1:0] m_axis_write_desc_status_len;
  wire [7:0] m_axis_write_desc_status_id, m_axis_write_desc_status_dest;
  wire m_axis_write_desc_status_user;
  wire [DW/8-1:0] m_axis_read_data_tkeep;
  wire [7:0] m_axis_read_data_tid, m_axis_read_data_tdest;
  wire m_axis_read_data_tuser;

  axi_dma #(.AXI_DATA_WIDTH(DW), .AXI_ADDR_WIDTH(AW), .AXI_ID_WIDTH(IW),
            .AXI_MAX_BURST_LEN(2), .AXIS_KEEP_ENABLE(0), .LEN_WIDTH(LW),
            .TAG_WIDTH(TW), .ENABLE_SG(0), .ENABLE_UNALIGNED(0)) dut (
      .clk(clk), .rst(rst),
      .s_axis_read_desc_addr(s_axis_read_desc_addr),
      .s_axis_read_desc_len(s_axis_read_desc_len),
      .s_axis_read_desc_tag(s_axis_read_desc_tag),
      .s_axis_read_desc_id(s_axis_read_desc_id),
      .s_axis_read_desc_dest(s_axis_read_desc_dest),
      .s_axis_read_desc_user(s_axis_read_desc_user),
      .s_axis_read_desc_valid(s_axis_read_desc_valid),
      .s_axis_read_desc_ready(s_axis_read_desc_ready),
      .m_axis_read_desc_status_tag(m_axis_read_desc_status_tag),
      .m_axis_read_desc_status_error(m_axis_read_desc_status_error),
      .m_axis_read_desc_status_valid(m_axis_read_desc_status_valid),
      .m_axis_read_data_tdata(m_axis_read_data_tdata),
      .m_axis_read_data_tkeep(m_axis_read_data_tkeep),
      .m_axis_read_data_tvalid(m_axis_read_data_tvalid),
      .m_axis_read_data_tready(m_axis_read_data_tready),
      .m_axis_read_data_tlast(m_axis_read_data_tlast),
      .m_axis_read_data_tid(m_axis_read_data_tid),
      .m_axis_read_data_tdest(m_axis_read_data_tdest),
      .m_axis_read_data_tuser(m_axis_read_data_tuser),
      .s_axis_write_desc_addr(s_axis_write_desc_addr),
      .s_axis_write_desc_len(s_axis_write_desc_len),
      .s_axis_write_desc_tag(s_axis_write_desc_tag),
      .s_axis_write_desc_valid(s_axis_write_desc_valid),
      .s_axis_write_desc_ready(s_axis_write_desc_ready),
      .m_axis_write_desc_status_len(m_axis_write_desc_status_len),
      .m_axis_write_desc_status_tag(m_axis_write_desc_status_tag),
      .m_axis_write_desc_status_id(m_axis_write_desc_status_id),
      .m_axis_write_desc_status_dest(m_axis_write_desc_status_dest),
      .m_axis_write_desc_status_user(m_axis_write_desc_status_user),
      .m_axis_write_desc_status_error(m_axis_write_desc_status_error),
      .m_axis_write_desc_status_valid(m_axis_write_desc_status_valid),
      .s_axis_write_data_tdata(s_axis_write_data_tdata),
      .s_axis_write_data_tkeep(s_axis_write_data_tkeep),
      .s_axis_write_data_tvalid(s_axis_write_data_tvalid),
      .s_axis_write_data_tready(s_axis_write_data_tready),
      .s_axis_write_data_tlast(s_axis_write_data_tlast),
      .s_axis_write_data_tid(s_axis_write_data_tid),
      .s_axis_write_data_tdest(s_axis_write_data_tdest),
      .s_axis_write_data_tuser(s_axis_write_data_tuser),
      .m_axi_awid(m_axi_awid), .m_axi_awaddr(m_axi_awaddr),
      .m_axi_awlen(m_axi_awlen), .m_axi_awsize(m_axi_awsize),
      .m_axi_awburst(m_axi_awburst), .m_axi_awlock(m_axi_awlock),
      .m_axi_awcache(m_axi_awcache), .m_axi_awprot(m_axi_awprot),
      .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
      .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb),
      .m_axi_wlast(m_axi_wlast), .m_axi_wvalid(m_axi_wvalid),
      .m_axi_wready(m_axi_wready), .m_axi_bid(m_axi_bid),
      .m_axi_bresp(m_axi_bresp), .m_axi_bvalid(m_axi_bvalid),
      .m_axi_bready(m_axi_bready), .m_axi_arid(m_axi_arid),
      .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen),
      .m_axi_arsize(m_axi_arsize), .m_axi_arburst(m_axi_arburst),
      .m_axi_arlock(m_axi_arlock), .m_axi_arcache(m_axi_arcache),
      .m_axi_arprot(m_axi_arprot), .m_axi_arvalid(m_axi_arvalid),
      .m_axi_arready(m_axi_arready), .m_axi_rid(m_axi_rid),
      .m_axi_rdata(m_axi_rdata), .m_axi_rresp(m_axi_rresp),
      .m_axi_rlast(m_axi_rlast), .m_axi_rvalid(m_axi_rvalid),
      .m_axi_rready(m_axi_rready),
      .read_enable(read_enable), .write_enable(write_enable),
      .write_abort(write_abort));

  reg f_past_valid;
  initial begin
    f_past_valid = 0;
    assume(rst);
  end

  always @(posedge clk) begin
    f_past_valid <= 1;
    if (!rst && f_past_valid && $past(!rst && s_axis_read_desc_valid && !s_axis_read_desc_ready))
      assume(s_axis_read_desc_valid && $stable({s_axis_read_desc_addr, s_axis_read_desc_len, s_axis_read_desc_tag}));
    if (!rst && f_past_valid && $past(!rst && m_axi_arvalid && !m_axi_arready))
      assert(m_axi_arvalid && $stable({m_axi_araddr, m_axi_arlen}));
    if (!rst && f_past_valid && $past(!rst && m_axi_awvalid && !m_axi_awready))
      assert(m_axi_awvalid && $stable({m_axi_awaddr, m_axi_awlen}));
    if (f_past_valid && $past(rst)) begin
      assert(!m_axis_read_data_tvalid);
      assert(!m_axi_arvalid);
      assert(!m_axi_awvalid);
    end
    cover(!rst && s_axis_read_desc_valid && s_axis_read_desc_ready);
    cover(!rst && m_axi_arvalid);
  end
endmodule
