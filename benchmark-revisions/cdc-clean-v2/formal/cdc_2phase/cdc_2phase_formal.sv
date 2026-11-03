module cdc_2phase_formal;
  localparam WIDTH = 8;

  reg src_clk_i, dst_clk_i;
  reg [1:0] src_div, dst_div;
  reg [7:0] reset_count;

  initial begin
    src_clk_i = 0;
    dst_clk_i = 0;
    src_div = 0;
    dst_div = 0;
    reset_count = 0;
  end

  // Independent 2:3 clocks.  Multi-clock mode preserves both edge domains.
  always @($global_clock) begin
    reset_count <= reset_count + 1'b1;
    if (src_div == 1) begin src_div <= 0; src_clk_i <= ~src_clk_i; end
    else src_div <= src_div + 1'b1;
    if (dst_div == 2) begin dst_div <= 0; dst_clk_i <= ~dst_clk_i; end
    else dst_div <= dst_div + 1'b1;
  end

  wire src_rst_ni = (reset_count >= 4);
  wire dst_rst_ni = (reset_count >= 4);
  (* anyseq *) reg [WIDTH-1:0] src_data_i;
  (* anyseq *) reg src_valid_i;
  (* anyseq *) reg dst_ready_i;
  wire src_ready_o, dst_valid_o;
  wire [WIDTH-1:0] dst_data_o;

  cdc_2phase #(.WIDTH(WIDTH)) dut (.*);

  reg [WIDTH-1:0] source_sequence, destination_sequence;
  reg source_was_stalled, destination_was_stalled;
  reg [WIDTH-1:0] stalled_source_data, stalled_destination_data;
  reg [4:0] pending_age;
  reg [2:0] ready_wait;
  reg reset_observed;
  reg [2:0] source_boot;

  initial begin
    source_sequence = 0;
    destination_sequence = 0;
    source_was_stalled = 0;
    destination_was_stalled = 0;
    pending_age = 0;
    ready_wait = 0;
    reset_observed = 0;
    source_boot = 0;
  end

  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      source_sequence <= 0;
      source_was_stalled <= 0;
      reset_observed <= 1;
      source_boot <= 0;
    end else begin
      if (source_boot < 4) begin
        source_boot <= source_boot + 1'b1;
        assume(!src_valid_i);
      end
      if (source_was_stalled) begin
        assume(src_valid_i);
        assume(src_data_i == stalled_source_data);
      end
      if (src_valid_i)
        assume(src_data_i == source_sequence);
      if (src_valid_i && src_ready_o)
        source_sequence <= source_sequence + 1'b1;
      source_was_stalled <= src_valid_i && !src_ready_o;
      stalled_source_data <= src_data_i;
    end
  end

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      destination_sequence <= 0;
      destination_was_stalled <= 0;
      pending_age <= 0;
      ready_wait <= 0;
      assert(!dst_valid_o);
    end else begin
      if (destination_was_stalled) begin
        assert(dst_valid_o);
        assert(dst_data_o == stalled_destination_data);
      end
      if (dst_valid_o && dst_ready_i) begin
        assert(destination_sequence < source_sequence);
        assert(dst_data_o == destination_sequence);
        destination_sequence <= destination_sequence + 1'b1;
      end
      assert(destination_sequence <= source_sequence);

      // Sound liveness premise: a waiting consumer is ready within four
      // destination edges.  Under it, every accepted item drains boundedly.
      if (dst_valid_o && !dst_ready_i) ready_wait <= ready_wait + 1'b1;
      else ready_wait <= 0;
      assume(ready_wait < 4);
      if (destination_sequence != source_sequence) pending_age <= pending_age + 1'b1;
      else pending_age <= 0;
      assert(pending_age < 16);

      destination_was_stalled <= dst_valid_o && !dst_ready_i;
      stalled_destination_data <= dst_data_o;
      cover(reset_observed && source_sequence >= 3 &&
            destination_sequence >= 2 && destination_was_stalled);
    end
  end
endmodule
