module isochronous_4phase_handshake_formal;
  reg src_clk_i, dst_clk_i;
  reg src_div;
  reg [1:0] dst_div;
  reg [7:0] reset_count;
  initial begin
    src_clk_i=0; dst_clk_i=0; src_div=0; dst_div=0; reset_count=0;
  end
  always @($global_clock) begin
    reset_count<=reset_count+1'b1;
    if (src_div==0) begin src_div<=1; src_clk_i<=~src_clk_i; end else src_div<=0;
    if (dst_div==1) begin dst_div<=0; dst_clk_i<=~dst_clk_i; end else dst_div<=dst_div+1'b1;
  end
  // The circuit is specified only for related clocks; this is an exact 2:1
  // schedule with coincident edges represented as distinct formal domains.
  wire src_rst_ni = reset_count>=4;
  wire dst_rst_ni = reset_count>=4;
  (* anyseq *) reg src_valid_i, dst_ready_i;
  wire src_ready_o, dst_valid_o;
  isochronous_4phase_handshake dut (.*);

  reg [7:0] accepted, delivered;
  reg src_stalled, dst_stalled, reset_seen;
  reg [2:0] ready_wait;
  reg [4:0] pending_age;
  reg [2:0] source_boot;
  initial begin
    accepted=0; delivered=0; src_stalled=0; dst_stalled=0;
    reset_seen=0; ready_wait=0; pending_age=0; source_boot=0;
  end
  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin accepted<=0; src_stalled<=0; reset_seen<=1; source_boot<=0; end
    else begin
      if (source_boot<4) begin
        source_boot<=source_boot+1'b1;
        assume(!src_valid_i);
      end
      if (src_stalled) assume(src_valid_i);
      if (src_valid_i && src_ready_o) accepted<=accepted+1'b1;
      src_stalled<=src_valid_i && !src_ready_o;
    end
  end
  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      delivered<=0; dst_stalled<=0; ready_wait<=0; pending_age<=0;
      assert(!dst_valid_o);
    end else begin
      if (dst_stalled) assert(dst_valid_o);
      if (dst_valid_o && dst_ready_i) begin
        assert(delivered<accepted);
        delivered<=delivered+1'b1;
      end
      assert(delivered<=accepted);
      assert((accepted-delivered)<=1);
      if (dst_valid_o && !dst_ready_i) ready_wait<=ready_wait+1'b1;
      else ready_wait<=0;
      assume(ready_wait<4);
      if (accepted!=delivered) pending_age<=pending_age+1'b1;
      else pending_age<=0;
      assert(pending_age<16);
      dst_stalled<=dst_valid_o && !dst_ready_i;
      cover(reset_seen && accepted>=3 && delivered>=2 && dst_stalled);
    end
  end
endmodule
