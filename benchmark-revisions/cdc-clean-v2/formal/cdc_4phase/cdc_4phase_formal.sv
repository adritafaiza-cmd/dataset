module cdc_4phase_formal;
  localparam WIDTH = 8;
  reg src_clk_i, dst_clk_i;
  reg [1:0] src_div, dst_div;
  reg [7:0] reset_count;
  initial begin
    src_clk_i=0; dst_clk_i=0; src_div=0; dst_div=0; reset_count=0;
  end
  always @($global_clock) begin
    reset_count <= reset_count + 1'b1;
    if (src_div==1) begin src_div<=0; src_clk_i<=~src_clk_i; end else src_div<=src_div+1'b1;
    if (dst_div==2) begin dst_div<=0; dst_clk_i<=~dst_clk_i; end else dst_div<=dst_div+1'b1;
  end
  wire src_rst_ni = reset_count >= 4;
  wire dst_rst_ni = reset_count >= 4;
  (* anyseq *) reg [WIDTH-1:0] src_data_i;
  (* anyseq *) reg src_valid_i, dst_ready_i;
  wire src_ready_o, dst_valid_o;
  wire [WIDTH-1:0] dst_data_o;

  cdc_4phase #(.WIDTH(WIDTH), .DECOUPLED(1), .SEND_RESET_MSG(0)) dut (.*);

  reg [WIDTH-1:0] produced, consumed;
  reg src_stalled, dst_stalled;
  reg [WIDTH-1:0] src_stall_data, dst_stall_data;
  reg [5:0] pending_age;
  reg [2:0] ready_wait;
  reg reset_seen;
  reg [2:0] source_boot;
  initial begin
    produced=0; consumed=0; src_stalled=0; dst_stalled=0;
    pending_age=0; ready_wait=0; reset_seen=0; source_boot=0;
  end

  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      produced<=0; src_stalled<=0; reset_seen<=1; source_boot<=0;
    end else begin
      if (source_boot<4) begin
        source_boot<=source_boot+1'b1;
        assume(!src_valid_i);
      end
      if (src_stalled) begin
        assume(src_valid_i);
        assume(src_data_i==src_stall_data);
      end
      if (src_valid_i) assume(src_data_i==produced);
      if (src_valid_i && src_ready_o) produced<=produced+1'b1;
      src_stalled<=src_valid_i && !src_ready_o;
      src_stall_data<=src_data_i;
    end
  end

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      consumed<=0; dst_stalled<=0; pending_age<=0; ready_wait<=0;
      assert(!dst_valid_o);
    end else begin
      if (dst_stalled) begin
        assert(dst_valid_o);
        assert(dst_data_o==dst_stall_data);
      end
      if (dst_valid_o && dst_ready_i) begin
        assert(consumed < produced);
        assert(dst_data_o==consumed);
        consumed<=consumed+1'b1;
      end
      assert(consumed<=produced);
      // The decoupled implementation has at most two externally accepted beats.
      assert((produced-consumed)<=2);

      if (dst_valid_o && !dst_ready_i) ready_wait<=ready_wait+1'b1;
      else ready_wait<=0;
      assume(ready_wait<4);
      if (consumed!=produced) pending_age<=pending_age+1'b1;
      else pending_age<=0;
      assert(pending_age<32);

      dst_stalled<=dst_valid_o && !dst_ready_i;
      dst_stall_data<=dst_data_o;
      cover(reset_seen && produced>=3 && consumed>=2 && dst_stalled);
    end
  end
endmodule
