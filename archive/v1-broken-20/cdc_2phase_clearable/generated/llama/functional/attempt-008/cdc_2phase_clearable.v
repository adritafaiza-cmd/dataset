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

  logic src_valid_synced;
  logic src_data_synced [WIDTH-1:0];
  logic src_clear_synced;
  logic dst_valid_synced;
  logic dst_data_synced [WIDTH-1:0];
  logic dst_clear_synced;
  logic src_clear_pending_reg;
  logic dst_clear_pending_reg;
  logic src_valid_reg;
  logic src_data_reg [WIDTH-1:0];
  logic dst_valid_reg;
  logic dst_data_reg [WIDTH-1:0];

  // Synchronize signals from src_clk_i to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_synced <= 1'b0;
      src_data_synced <= '0;
      src_clear_synced <= 1'b0;
    end else begin
      src_valid_synced <= src_valid_synced_1;
      src_data_synced <= src_data_synced_1;
      src_clear_synced <= src_clear_synced_1;
    end
  end

  logic src_valid_synced_1;
  logic [WIDTH-1:0] src_data_synced_1;
  logic src_clear_synced_1;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_synced_1 <= 1'b0;
      src_data_synced_1 <= '0;
      src_clear_synced_1 <= 1'b0;
    end else begin
      src_valid_synced_1 <= src_valid_synced_2;
      src_data_synced_1 <= src_data_synced_2;
      src_clear_synced_1 <= src_clear_synced_2;
    end
  end

  logic src_valid_synced_2;
  logic [WIDTH-1:0] src_data_synced_2;
  logic src_clear_synced_2;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_synced_2 <= 1'b0;
      src_data_synced_2 <= '0;
      src_clear_synced_2 <= 1'b0;
    end else begin
      src_valid_synced_2 <= src_valid_synced_3;
      src_data_synced_2 <= src_data_synced_3;
      src_clear_synced_2 <= src_clear_synced_3;
    end
  end

  logic src_valid_synced_3;
  logic [WIDTH-1:0] src_data_synced_3;
  logic src_clear_synced_3;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_synced_3 <= 1'b0;
      src_data_synced_3 <= '0;
      src_clear_synced_3 <= 1'b0;
    end else begin
      src_valid_synced_3 <= src_valid_i;
      src_data_synced_3 <= src_data_i;
      src_clear_synced_3 <= src_clear_i;
    end
  end

  // Synchronize signals from dst_clk_i to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_valid_synced <= 1'b0;
      dst_data_synced <= '0;
      dst_clear_synced <= 1'b0;
    end else begin
      dst_valid_synced <= dst_valid_synced_1;
      dst_data_synced <= dst_data_synced_1;
      dst_clear_synced <= dst_clear_synced_1;
    end
  end

  logic dst_valid_synced_1;
  logic [WIDTH-1:0] dst_data_synced_1;
  logic dst_clear_synced_1;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_synced_1 <= 1'b0;
      dst_data_synced_1 <= '0;
      dst_clear_synced_1 <= 1'b0;
    end else begin
      dst_valid_synced_1 <= dst_valid_synced_2;
      dst_data_synced_1 <= dst_data_synced_2;
      dst_clear_synced_1 <= dst_clear_synced_2;
    end
  end

  logic dst_valid_synced_2;
  logic [WIDTH-1:0] dst_data_synced_2;
  logic dst_clear_synced_2;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_synced_2 <= 1'b0;
      dst_data_synced_2 <= '0;
      dst_clear_synced_2 <= 1'b0;
    end else begin
      dst_valid_synced_2 <= dst_valid_synced_3;
      dst_data_synced_2 <= dst_data_synced_3;
      dst_clear_synced_2 <= dst_clear_synced_3;
    end
  end

  logic dst_valid_synced_3;
  logic [WIDTH-1:0] dst_data_synced_3;
  logic dst_clear_synced_3;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_synced_3 <= 1'b0;
      dst_data_synced_3 <= '0;
      dst_clear_synced_3 <= 1'b0;
    end else begin
      dst_valid_synced_3 <= dst_valid_o;
      dst_data_synced_3 <= dst_data_o;
      dst_clear_synced_3 <= dst_clear_i;
    end
  end

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_reg <= 1'b0;
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end else if (src_clear_i) begin
      src_clear_pending_reg <= 1'b1;
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_reg <= 1'b1;
      src_data_reg <= src_data_i;
    end else if (dst_valid_synced && dst_ready_i) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end
  end

  assign src_ready_o = !(src_valid_reg && !dst_valid_synced) && !src_clear_pending_reg;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_reg <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (dst_clear_i) begin
      dst_clear_pending_reg <= 1'b1;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else if (src_valid_synced && !dst_valid_reg) begin
      dst_valid_reg <= 1'b1;
      dst_data_reg <= src_data_synced;
    end else if (dst_valid_reg && dst_ready_i) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule
