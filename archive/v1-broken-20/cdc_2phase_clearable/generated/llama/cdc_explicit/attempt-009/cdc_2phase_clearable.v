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

  logic src_clear_synced;
  logic dst_clear_synced;
  logic src_valid_synced;
  logic src_data_synced [WIDTH-1:0];
  logic dst_valid_synced;
  logic dst_data_synced [WIDTH-1:0];

  logic src_clear_pending;
  logic dst_clear_pending;

  logic src_valid_reg;
  logic src_data_reg [WIDTH-1:0];
  logic dst_valid_reg;
  logic dst_data_reg [WIDTH-1:0];

  logic src_valid_pulse;
  logic dst_valid_pulse;

  // Synchronize src_clear_i to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_synced <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_synced <= 1'b1;
    end else if (src_clear_pending) begin
      src_clear_synced <= 1'b0;
    end
  end

  // Synchronize dst_clear_i to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_synced <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_synced <= 1'b1;
    end else if (dst_clear_pending) begin
      dst_clear_synced <= 1'b0;
    end
  end

  // Synchronize src_valid_i and src_data_i to dst_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_synced <= 1'b0;
      src_data_synced <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_synced <= 1'b1;
      src_data_synced <= src_data_i;
    end else if (src_clear_synced) begin
      src_valid_synced <= 1'b0;
      src_data_synced <= '0;
    end
  end

  // Synchronize dst_valid_o and dst_data_o to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_synced <= 1'b0;
      dst_data_synced <= '0;
    end else if (dst_valid_pulse) begin
      dst_valid_synced <= 1'b1;
      dst_data_synced <= dst_data_reg;
    end else if (dst_clear_synced) begin
      dst_valid_synced <= 1'b0;
      dst_data_synced <= '0;
    end
  end

  // Generate src_ready_o
  always_comb begin
    src_ready_o = !src_valid_synced || dst_ready_i;
  end

  // Generate dst_valid_o and dst_data_o
  always_comb begin
    dst_valid_o = dst_valid_synced;
    dst_data_o = dst_data_synced;
  end

  // Generate src_clear_pending_o and dst_clear_pending_o
  always_comb begin
    src_clear_pending_o = src_clear_pending;
    dst_clear_pending_o = dst_clear_pending;
  end

  // Clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending <= 1'b1;
    end else if (dst_clear_synced) begin
      src_clear_pending <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending <= 1'b1;
    end else if (src_clear_synced) begin
      dst_clear_pending <= 1'b0;
    end
  end

  // Pulse generation
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_reg <= 1'b1;
      src_data_reg <= src_data_i;
    end else if (src_clear_synced) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (dst_valid_pulse) begin
      dst_valid_reg <= 1'b1;
      dst_data_reg <= src_data_synced;
    end else if (dst_clear_synced) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_pulse <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_pulse <= 1'b1;
    end else if (src_clear_synced) begin
      src_valid_pulse <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_pulse <= 1'b0;
    end else if (dst_valid_synced && dst_ready_i) begin
      dst_valid_pulse <= 1'b1;
    end else if (dst_clear_synced) begin
      dst_valid_pulse <= 1'b0;
    end
  end

endmodule
