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

  // Source domain signals
  reg dst_clear_sync1, dst_clear_sync;
  wire clear_req_src;

  // Destination domain signals
  reg src_clear_sync1, src_clear_sync;
  wire clear_req_dst;

  // Source domain CDC
  reg dst_ready_sync1, dst_ready_sync;
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;
  wire src_transfer;

  // Destination domain CDC
  reg src_valid_sync1, src_valid_sync;
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Synchronize dst_clear_i to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync1 <= 0;
      dst_clear_sync <= 0;
    end else begin
      dst_clear_sync1 <= dst_clear_i;
      dst_clear_sync <= dst_clear_sync1;
    end
  end

  // Synchronize src_clear_i to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync1 <= 0;
      src_clear_sync <= 0;
    end else begin
      src_clear_sync1 <= src_clear_i;
      src_clear_sync <= src_clear_sync1;
    end
  end

  // Clear requests
  assign clear_req_src = src_clear_i | dst_clear_sync;
  assign clear_req_dst = dst_clear_i | src_clear_sync;

  // Assign pending outputs
  assign src_clear_pending_o = clear_req_src;
  assign dst_clear_pending_o = clear_req_dst;

  // Source domain CDC for dst_ready_i
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync1 <= 0;
      dst_ready_sync <= 0;
    end else begin
      dst_ready_sync1 <= dst_ready_i;
      dst_ready_sync <= dst_ready_sync1;
    end
  end

  // Source valid and data handling
  assign src_ready_o = dst_ready_sync;
  assign src_transfer = src_valid_reg && dst_ready_sync;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_data_reg <= 0;
    end else if (clear_req_src) begin
      src_valid_reg <= 0;
      src_data_reg <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_valid_reg <= 1;
        src_data_reg <= src_data_i;
      end else if (src_transfer) begin
        src_valid_reg <= 0;
      end
    end
  end

  // Destination domain CDC for src_valid_reg
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync1 <= 0;
      src_valid_sync <= 0;
    end else begin
      src_valid_sync1 <= src_valid_reg;
      src_valid_sync <= src_valid_sync1;
    end
  end

  // Destination valid and data handling
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
    end else if (clear_req_dst) begin
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
    end else begin
      if (src_valid_sync && !dst_valid_reg) begin
        dst_valid_reg <= 1;
        dst_data_reg <= src_data_reg;
      end
      if (dst_ready_i) begin
        dst_valid_reg <= 0;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
