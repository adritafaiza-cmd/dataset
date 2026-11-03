module axis_switch_formal;
  reg clk;
  (* anyseq *) reg rst;
  (* anyseq *) reg [7:0] s_data;
  (* anyseq *) reg s_valid, s_last, s_dest;
  (* anyseq *) reg [1:0] m_ready;
  wire [1:0] s_ready, m_valid, m_last;
  wire [15:0] m_data;

  axis_switch #(.S_COUNT(2), .M_COUNT(2), .DATA_WIDTH(8), .KEEP_ENABLE(0),
      .ID_ENABLE(0), .USER_ENABLE(0), .M_DEST_WIDTH(1), .S_DEST_WIDTH(1),
      .S_REG_TYPE(2), .M_REG_TYPE(2)) dut (
      .clk(clk), .rst(rst), .s_axis_tdata({8'b0,s_data}),
      .s_axis_tkeep(2'b11), .s_axis_tvalid({1'b0,s_valid}),
      .s_axis_tready(s_ready), .s_axis_tlast({1'b0,s_last}),
      .s_axis_tid(16'b0), .s_axis_tdest({1'b0,s_dest}),
      .s_axis_tuser(2'b0), .m_axis_tdata(m_data), .m_axis_tkeep(),
      .m_axis_tvalid(m_valid), .m_axis_tready(m_ready),
      .m_axis_tlast(m_last), .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser());

  reg f_past_valid;
  initial begin
    f_past_valid = 0;
    assume(rst);
  end

  always @(posedge clk) begin
    f_past_valid <= 1;
    if (!rst && f_past_valid && $past(!rst && s_valid && !s_ready[0]))
      assume(s_valid && s_data == $past(s_data) &&
             s_last == $past(s_last) && s_dest == $past(s_dest));
    if (!rst && f_past_valid && $past(!rst && m_valid[0] && !m_ready[0]))
      assert(m_valid[0] && m_data[7:0] == $past(m_data[7:0]) &&
             m_last[0] == $past(m_last[0]));
    if (!rst && f_past_valid && $past(!rst && m_valid[1] && !m_ready[1]))
      assert(m_valid[1] && m_data[15:8] == $past(m_data[15:8]) &&
             m_last[1] == $past(m_last[1]));
    if (f_past_valid && $past(rst))
      assert(m_valid == 2'b00);
    cover(!rst && s_valid && s_ready[0]);
    cover(!rst && m_valid[0] && m_ready[0]);
    cover(!rst && m_valid[1] && m_ready[1]);
  end
endmodule
