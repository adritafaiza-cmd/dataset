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

  logic src_clear_pending;
  logic dst_clear_pending;

  logic src_valid_reg;
  logic src_data_reg [WIDTH-1:0];
  logic dst_valid_reg;
  logic dst_data_reg [WIDTH-1:0];

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
      src_clear_pending <= 1'b0;
    end else if (src_clear_i) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
      src_clear_pending <= 1'b1;
    end else if (src_valid_i && !src_valid_reg) begin
      src_valid_reg <= 1'b1;
      src_data_reg <= src_data_i;
    end else if (!src_valid_i && src_valid_reg) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '0;
    end
  end

  always_ff @(posedge src_clk_i) begin
    src_clear_synced <= src_clear_i;
    src_valid_synced <= src_valid_reg;
    src_data_synced <= src_data_reg;
  end

  for (genvar i = 0; i < SYNC_STAGES - 1; i++) begin
    logic [WIDTH-1:0] src_data_synced_reg [i];
    logic src_valid_synced_reg [i];
    logic src_clear_synced_reg [i];

    always_ff @(posedge dst_clk_i) begin
      src_data_synced_reg[0] <= src_data_synced;
      src_valid_synced_reg[0] <= src_valid_synced;
      src_clear_synced_reg[0] <= src_clear_synced;
      for (int j = 1; j < i + 1; j++) begin
        src_data_synced_reg[j] <= src_data_synced_reg[j-1];
        src_valid_synced_reg[j] <= src_valid_synced_reg[j-1];
        src_clear_synced_reg[j] <= src_clear_synced_reg[j-1];
      end
    end

    assign src_data_synced = src_data_synced_reg[i];
    assign src_valid_synced = src_valid_synced_reg[i];
    assign src_clear_synced = src_clear_synced_reg[i];
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
      dst_clear_pending <= 1'b0;
    end else if (dst_clear_i) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
      dst_clear_pending <= 1'b1;
    end else if (src_valid_synced && !dst_valid_reg) begin
      dst_valid_reg <= 1'b1;
      dst_data_reg <= src_data_synced;
    end else if (!src_valid_synced && dst_valid_reg && dst_ready_i) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end
  end

  always_ff @(posedge dst_clk_i) begin
    dst_valid_synced <= dst_valid_reg;
    dst_data_synced <= dst_data_reg;
    dst_clear_synced <= dst_clear_i;
  end

  for (genvar i = 0; i < SYNC_STAGES - 1; i++) begin
    logic [WIDTH-1:0] dst_data_synced_reg [i];
    logic dst_valid_synced_reg [i];
    logic dst_clear_synced_reg [i];

    always_ff @(posedge src_clk_i) begin
      dst_data_synced_reg[0] <= dst_data_synced;
      dst_valid_synced_reg[0] <= dst_valid_synced;
      dst_clear_synced_reg[0] <= dst_clear_synced;
      for (int j = 1; j < i + 1; j++) begin
        dst_data_synced_reg[j] <= dst_data_synced_reg[j-1];
        dst_valid_synced_reg[j] <= dst_valid_synced_reg[j-1];
        dst_clear_synced_reg[j] <= dst_clear_synced_reg[j-1];
      end
    end

    assign dst_data_synced = dst_data_synced_reg[i];
    assign dst_valid_synced = dst_valid_synced_reg[i];
    assign dst_clear_synced = dst_clear_synced_reg[i];
  end

  assign src_ready_o = !src_valid_reg || dst_valid_synced;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
