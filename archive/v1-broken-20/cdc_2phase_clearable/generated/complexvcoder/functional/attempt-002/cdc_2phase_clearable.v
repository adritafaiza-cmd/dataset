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
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic src_clear_req;
  logic dst_clear_req;
  logic [SYNC_STAGES-1:0] src_clear_pending;
  logic [SYNC_STAGES-1:0] dst_clear_pending;
  logic src_clear_done;
  logic dst_clear_done;

  // Clear handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req <= 1'b0;
      src_clear_pending <= {SYNC_STAGES{1'b0}};
      src_clear_done <= 1'b0;
    end else begin
      src_clear_req <= src_clear_i;
      src_clear_pending <= {src_clear_req, src_clear_pending[SYNC_STAGES-2:0]};
      src_clear_done <= src_clear_pending[0];
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_req <= 1'b0;
      dst_clear_pending <= {SYNC_STAGES{1'b0}};
      dst_clear_done <= 1'b0;
    end else begin
      dst_clear_req <= dst_clear_i;
      dst_clear_pending <= {dst_clear_req, dst_clear_pending[SYNC_STAGES-2:0]};
      dst_clear_done <= dst_clear_pending[0];
    end
  end

  // Clear pending outputs
  assign src_clear_pending_o = |src_clear_pending;
  assign dst_clear_pending_o = |dst_clear_pending;

  // Source logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
    end else begin
      if (src_clear_done) begin
        src_data_reg <= {WIDTH{1'b0}};
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
      end else if (src_valid_i && src_ready_i) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b0;
      end else begin
        src_ready_reg <= 1'b0;
      end
    end
  end

  // Destination logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
    end else begin
      if (dst_clear_done) begin
        dst_data_reg <= {WIDTH{1'b0}};
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b1;
      end else if (src_valid_reg && dst_ready_i) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
        src_valid_reg <= 1'b0;
      end else begin
        dst_ready_reg <= 1'b0;
      end
    end
  end

  // Outputs
  assign src_data_o = src_data_reg;
  assign src_valid_o = src_valid_reg;
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
