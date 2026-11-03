The following is the complete SystemVerilog code for the module `cdc_2phase_clearable`:

```
module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_wire;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;
  reg src_clear_reg;
  reg dst_clear_reg;
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;

  // Synchronization FIFOs
  wire [WIDTH-1:0] src_data_sync;
  wire src_valid_sync;
  wire src_ready_sync;
  wire [WIDTH-1:0] dst_data_sync;
  wire dst_valid_sync;
  wire dst_ready_sync;

  // Synchronization FIFOs
  generate
    if (SYNC_STAGES > 0) begin
      for (genvar i = 0; i < SYNC_STAGES; i = i + 1) begin
        if (i == 0) begin
          fifo_sync #(.WIDTH(WIDTH), .DEPTH(2)) src_fifo (
            .clk_i(src_clk_i),
            .rst_ni(src_rst_ni),
            .clear_i(src_clear_reg),
            .data_i(src_data_reg),
            .valid_i(src_valid_reg),
            .ready_o(src_ready_wire),
            .data_o(src_data_sync),
            .valid_o(src_valid_sync),
            .ready_i(src_ready_sync)
          );
          fifo_sync #(.WIDTH(WIDTH), .DEPTH(2)) dst_fifo (
            .clk_i(dst_clk_i),
            .rst_ni(dst_rst_ni),
            .clear_i(dst_clear_reg),
            .data_i(dst_data_reg),
            .valid_i(dst_valid_reg),
            .ready_o(dst_ready_wire),
            .data_o(dst_data_sync),
            .valid_o(dst_valid_sync),
            .ready_i(dst_ready_sync)
          );
        end else begin
          fifo_sync #(.WIDTH(WIDTH), .DEPTH(2)) src_fifo (
            .clk_i(src_clk_i),
            .rst_ni(src_rst_ni),
            .clear_i(src_clear_reg),
            .data_i(src_data_sync),
            .valid_i(src_valid_sync),
            .ready_o(src_ready_sync),
            .data_o(src_data_sync),
            .valid_o(src_valid_sync),
            .ready_i(src_ready_wire)
          );
          fifo_sync #(.WIDTH(WIDTH), .DEPTH(2)) dst_fifo (
            .clk_i(dst_clk_i),
            .rst_ni(dst_rst_ni),
            .clear_i(dst_clear_reg),
            .data_i(dst_data_sync),
            .valid_i(dst_valid_sync),
            .ready_o(dst_ready_sync),
            .data_o(dst_data_sync),
            .valid_o(dst_valid_sync),
            .ready_i(dst_ready_wire)
          );
        end
      end
    end else begin
      assign src_data_sync = src_data_reg;
      assign src_valid_sync = src_valid_reg;
      assign src_ready_sync = src_ready_wire;
      assign dst_data_sync = dst_data_reg;
      assign dst_valid_sync = dst_valid_reg;
      assign dst_ready_sync = dst_ready_wire;
    end
  endgenerate

  // Clear logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_reg <= 1'b1;
      src_clear_pending_reg <= 1'b1;
    end else if (src_ready_wire && dst_valid_sync) begin
      src_clear_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_reg <= 1'b1;
      dst_clear_pending_reg <= 1'b1;
    end else if (dst_ready_i && src_valid_sync) begin
      dst_clear_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end
  end

  // Source side
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else if (src_clear_i) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else if (src_valid_i && src_ready_wire) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1'b1;
    end else if (src_ready_wire) begin
      src_valid_reg <= 1'b0;
    end
  end

  // Destination side
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else if (dst_clear_i) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else if (dst_ready_i && dst_valid_sync) begin
      dst_data_reg <= dst_data_sync;
      dst_valid_reg <= 1'b1;
    end else if (dst_ready_i) begin
      dst_valid_reg <= 1'b0;
    end
  end

  // Output assignments
  assign src_clear_pending_o = src_clear_pending_reg;
  assign src_ready_o = src_ready_wire;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_data_o = dst_data_sync;
  assign dst_valid_o = dst_valid_sync;

endmodule

module fifo_sync #(
  parameter WIDTH = 1,
  parameter DEPTH = 2
)(
  input  clk_i,
  input  rst_ni,
  input  clear_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  // Internal signals
  reg [WIDTH-1:0] mem [DEPTH-1:0];
  reg [DEPTH-1:0] head;
  reg [DEPTH-1:0] tail;
  reg [DEPTH-1:0] count;
  reg [DEPTH-1:0] next_head;
  reg [DEPTH-1:0] next_tail;
  reg [DEPTH-1:0] next_count;
  reg [DEPTH-1:0] next_next_head;
  reg [DEPTH-1:0] next_next_tail;
  reg [DEPTH-1:0] next_next_count;
  reg [DEPTH-1:0] next_next_next_head;
  reg [DEPTH-1:0] next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_tail;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_count;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_head;
  reg [DEPTH-1:0] next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_next_