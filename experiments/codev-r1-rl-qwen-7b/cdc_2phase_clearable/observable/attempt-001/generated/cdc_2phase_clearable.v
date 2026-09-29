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

  // Source side registers
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;

  // Synchronization of dst_ready_i to source clock
  reg [SYNC_STAGES-1:0] dst_ready_sync;

  // Destination side registers
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Synchronization of src_valid_reg to destination clock
  reg [SYNC_STAGES-1:0] src_valid_sync;

  // Clear synchronization
  reg [1:0] src_clear_sync;
  reg [1:0] dst_clear_sync;

  // Source clear pending
  assign src_clear_pending_o = src_clear_i && !src_clear_sync[1];

  // Destination clear pending
  assign dst_clear_pending_o = dst_clear_i && !dst_clear_sync[1];

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_data_reg <= 0;
      src_clear_sync <= 0;
    end else begin
      src_clear_sync <= {src_clear_sync[0], src_clear_i};

      if (src_clear_sync[1]) begin
        src_valid_reg <= 0;
      end else if (src_clear_i) begin
        src_valid_reg <= 0;
      end else begin
        if (src_valid_i && src_ready_o) begin
          src_valid_reg <= 0;
        end else if (src_valid_i && !src_valid_reg) begin
          src_data_reg <= src_data_i;
          src_valid_reg <= 1;
        end
      end
    end
  end

  // Synchronize dst_ready_i to source clock
  always @(posedge src_clk_i) begin
    dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_i};
  end

  // Source ready logic
  assign src_ready_o = !src_valid_reg || (dst_valid_sync[SYNC_STAGES-1] && dst_ready_sync[SYNC_STAGES-1]);

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_data_reg <= 0;
      dst_clear_sync <= 0;
    end else begin
      dst_clear_sync <= {dst_clear_sync[0], dst_clear_i};

      if (dst_clear_sync[1]) begin
        dst_valid_reg <= 0;
      end else if (dst_clear_i) begin
        dst_valid_reg <= 0;
      end else begin
        if (dst_valid_reg && dst_ready_i) begin
          dst_valid_reg <= 0;
        end else if (src_valid_sync[SYNC_STAGES-1]) begin
          dst_data_reg <= src_data_reg;
          dst_valid_reg <= 1;
        end
      end
    end
  end

  // Synchronize src_valid_reg to destination clock
  always @(posedge dst_clk_i) begin
    src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_reg};
  end

  // Assign outputs
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
