module i2c_master_formal;
  reg clk;
  (* anyseq *) reg rst;
  (* anyseq *) reg [6:0] s_axis_cmd_address;
  (* anyseq *) reg s_axis_cmd_start, s_axis_cmd_read, s_axis_cmd_write;
  (* anyseq *) reg s_axis_cmd_write_multiple, s_axis_cmd_stop, s_axis_cmd_valid;
  (* anyseq *) reg [7:0] s_axis_data_tdata;
  (* anyseq *) reg s_axis_data_tvalid, s_axis_data_tlast, m_axis_data_tready;
  (* anyseq *) reg scl_i, sda_i;
  (* anyseq *) reg [15:0] prescale;
  (* anyseq *) reg stop_on_idle;
  wire s_axis_cmd_ready, s_axis_data_tready;
  wire [7:0] m_axis_data_tdata;
  wire m_axis_data_tvalid, m_axis_data_tlast;
  wire scl_o, scl_t, sda_o, sda_t;
  wire busy, bus_control, bus_active, missed_ack;
  i2c_master dut (.*);

  reg f_past_valid;
  initial begin
    f_past_valid = 0;
    assume(rst);
    assume(prescale >= 2);
  end

  always @(posedge clk) begin
    f_past_valid <= 1;
    assume(prescale >= 2);
    if (!rst && f_past_valid && $past(!rst && s_axis_cmd_valid && !s_axis_cmd_ready))
      assume(s_axis_cmd_valid && $stable({s_axis_cmd_address, s_axis_cmd_start,
             s_axis_cmd_read, s_axis_cmd_write, s_axis_cmd_write_multiple, s_axis_cmd_stop}));
    if (!rst && f_past_valid && $past(!rst && s_axis_data_tvalid && !s_axis_data_tready))
      assume(s_axis_data_tvalid && $stable({s_axis_data_tdata, s_axis_data_tlast}));
    if (!rst && f_past_valid && $past(!rst && m_axis_data_tvalid && !m_axis_data_tready))
      assert(m_axis_data_tvalid && $stable({m_axis_data_tdata, m_axis_data_tlast}));
    if (f_past_valid && $past(rst)) begin
      assert(!m_axis_data_tvalid);
      assert(!busy);
    end
    assert(scl_o == 1'b0 || scl_t);
    assert(sda_o == 1'b0 || sda_t);
    cover(!rst && s_axis_cmd_valid && s_axis_cmd_ready);
    cover(!rst && busy);
  end
endmodule
