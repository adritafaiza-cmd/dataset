module cdc_2phase_clearable_formal;
  localparam WIDTH = 8;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire src_clk_i = tick[0];
  wire dst_clk_i = tick[1];
  wire src_rst_ni = (tick >= 10);
  wire dst_rst_ni = (tick >= 10);
  (* anyseq *) reg src_clear_i, dst_clear_i, src_valid_i, dst_ready_i;
  (* anyseq *) reg [WIDTH-1:0] src_data_i;
  wire src_clear_pending_o, dst_clear_pending_o, src_ready_o, dst_valid_o;
  wire [WIDTH-1:0] dst_data_o;

  cdc_2phase_clearable #(.WIDTH(WIDTH), .SYNC_STAGES(3), .CLEAR_ON_ASYNC_RESET(1)) dut (.*);

  always @* begin
    if (tick < 14) begin
      assume(!src_valid_i);
      assume(!src_clear_i);
      assume(!dst_clear_i);
    end
  end

  always @(posedge src_clk_i) begin
    if (src_rst_ni && $past(src_rst_ni && src_valid_i && !src_ready_o))
      assume(src_valid_i && $stable(src_data_i));
    if (!src_rst_ni)
      assume(!src_valid_i);
  end

  always @(posedge dst_clk_i) begin
    if (dst_rst_ni && $past(dst_rst_ni && dst_valid_o && !dst_ready_i))
      assert(dst_valid_o && $stable(dst_data_o));
    if (!dst_rst_ni)
      assert(!dst_valid_o);
  end

  always @(posedge gclk) begin
    cover(src_rst_ni && dst_rst_ni && src_valid_i && src_ready_o);
    cover(src_rst_ni && dst_rst_ni && dst_valid_o && dst_ready_i);
  end
endmodule
