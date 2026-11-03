module axis_adapter_formal;
  reg clk;
  (* anyseq *) reg rst;
  (* anyseq *) reg [7:0] s_data;
  (* anyseq *) reg s_valid, s_last, m_ready;
  wire s_ready, m_valid, m_last;
  wire [31:0] m_data;
  wire [3:0] m_keep;

  axis_adapter #(.S_DATA_WIDTH(8), .S_KEEP_ENABLE(0),
      .M_DATA_WIDTH(32), .M_KEEP_ENABLE(1), .ID_ENABLE(0),
      .DEST_ENABLE(0), .USER_ENABLE(0)) dut (
      .clk(clk), .rst(rst), .s_axis_tdata(s_data), .s_axis_tkeep(1'b1),
      .s_axis_tvalid(s_valid), .s_axis_tready(s_ready), .s_axis_tlast(s_last),
      .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
      .m_axis_tdata(m_data), .m_axis_tkeep(m_keep), .m_axis_tvalid(m_valid),
      .m_axis_tready(m_ready), .m_axis_tlast(m_last), .m_axis_tid(),
      .m_axis_tdest(), .m_axis_tuser());

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
      assert(m_valid && m_data == $past(m_data) &&
             m_keep == $past(m_keep) && m_last == $past(m_last));
    if (f_past_valid && $past(rst))
      assert(!m_valid);
    cover(!rst && s_valid && s_ready && s_last);
    cover(!rst && m_valid && m_ready);
  end
endmodule
