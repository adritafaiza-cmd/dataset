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
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic src_clear_reg;
  logic dst_clear_reg;
  logic [SYNC_STAGES-1:0] src_clear_count;
  logic [SYNC_STAGES-1:0] dst_clear_count;
  logic src_clear_done;
  logic dst_clear_done;

  // Synchronizers for source signals
  sync #(.WIDTH(WIDTH), .STAGES(SYNC_STAGES)) src_sync (
    .clk_i(src_clk_i),
    .rst_ni(src_rst_ni),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_reg)
  );

  // Synchronizers for destination signals
  sync #(.WIDTH(WIDTH), .STAGES(SYNC_STAGES)) dst_sync (
    .clk_i(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .data_i(dst_data_o),
    .valid_i(dst_valid_reg),
    .ready_o(dst_ready_reg)
  );

  // Clear logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_reg <= 1'b0;
      src_clear_count <= 0;
      src_clear_done <= 1'b0;
    end else begin
      src_clear_reg <= src_clear_i;
      if (src_clear_reg) begin
        src_clear_count <= src_clear_count + 1;
        if (src_clear_count == SYNC_STAGES - 1) begin
          src_clear_done <= 1'b1;
        end
      end else begin
        src_clear_done <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_reg <= 1'b0;
      dst_clear_count <= 0;
      dst_clear_done <= 1'b0;
    end else begin
      dst_clear_reg <= dst_clear_i;
      if (dst_clear_reg) begin
        dst_clear_count <= dst_clear_count + 1;
        if (dst_clear_count == SYNC_STAGES - 1) begin
          dst_clear_done <= 1'b1;
        end
      end else begin
        dst_clear_done <= 1'b0;
      end
    end
  end

  // Clear pending logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_o <= 1'b0;
    end else begin
      src_clear_pending_o <= src_clear_reg | dst_clear_reg;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_o <= 1'b0;
    end else begin
      dst_clear_pending_o <= src_clear_reg | dst_clear_reg;
    end
  end

  // Data forwarding logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= 0;
      src_valid_reg <= 1'b0;
    end else if (src_valid_i && src_ready_reg) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1'b1;
    end else begin
      src_valid_reg <= 1'b0;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
      dst_valid_reg <= 1'b0;
    end else if (src_valid_reg && dst_ready_i) begin
      dst_data_o <= src_data_reg;
      dst_valid_reg <= 1'b1;
    end else begin
      dst_valid_reg <= 1'b0;
    end
  end

  // Source ready logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b1;
    end else begin
      src_ready_o <= dst_ready_i;
    end
  end

  // Destination valid logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
    end else begin
      dst_valid_o <= src_valid_reg;
    end
  end

endmodule

module sync #(
  parameter WIDTH = 1,
  parameter STAGES = 3
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o
);

  logic [WIDTH-1:0] sync_reg [STAGES-1:0];
  logic sync_valid [STAGES-1:0];

  assign ready_o = sync_valid[STAGES-2];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_reg <= '{default: 0};
      sync_valid <= '{default: 0};
    end else begin
      sync_reg[0] <= data_i;
      sync_valid[0] <= valid_i;
      for (int i = 1; i < STAGES; i++) begin
        sync_reg[i] <= sync_reg[i-1];
        sync_valid[i] <= sync_valid[i-1];
      end
    end
  end

endmodule
