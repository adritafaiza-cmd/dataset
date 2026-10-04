module axis_fifo_formal;
  reg clk;
  (* anyseq *) reg rst;
  (* anyseq *) reg [7:0] s_data;
  (* anyseq *) reg s_valid, s_last, m_ready;
  wire s_ready, m_valid, m_last;
  wire [7:0] m_data;

  axis_fifo #(.DEPTH(4), .DATA_WIDTH(8), .KEEP_ENABLE(0), .LAST_ENABLE(1),
      .ID_ENABLE(0), .DEST_ENABLE(0), .USER_ENABLE(0), .RAM_PIPELINE(1),
      .OUTPUT_FIFO_ENABLE(0), .FRAME_FIFO(0), .PAUSE_ENABLE(0)) dut (
      .clk(clk), .rst(rst), .s_axis_tdata(s_data), .s_axis_tkeep(1'b1),
      .s_axis_tvalid(s_valid), .s_axis_tready(s_ready), .s_axis_tlast(s_last),
      .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
      .m_axis_tdata(m_data), .m_axis_tkeep(), .m_axis_tvalid(m_valid),
      .m_axis_tready(m_ready), .m_axis_tlast(m_last), .m_axis_tid(),
      .m_axis_tdest(), .m_axis_tuser(), .pause_req(1'b0), .pause_ack(),
      .status_depth(), .status_depth_commit(), .status_overflow(),
      .status_bad_frame(), .status_good_frame());

  reg f_past_valid;
  initial begin
    f_past_valid = 0;
    assume(rst);
  end

  always @(posedge clk) begin
    f_past_valid <= 1;
    if (!rst && f_past_valid && $past(!rst && s_valid && !s_ready))
      assume(s_valid && s_data == $past(s_data) && s_last == $past(s_last));
    if (!rst && f_past_valid && $past(!rst && m_valid && !m_ready))
      assert(m_valid && m_data == $past(m_data) && m_last == $past(m_last));
    if (f_past_valid && $past(rst))
      assert(!m_valid);
    cover(!rst && s_valid && s_ready);
    cover(!rst && m_valid && m_ready);
  end
endmodule
