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
  wire src_to_dst_valid;
  wire dst_to_src_ready;
  wire dst_to_src_clear;
  wire src_to_dst_clear;

  // Source domain: data register and valid handshake
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_clear_pending_reg;
  reg src_ready_reg;

  // Destination domain: data register and valid handshake
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_clear_pending_reg;
  reg dst_ready_reg;

  // Synchronizers
  // src_valid -> dst domain
  reg [SYNC_STAGES-1:0] src_valid_sync;
  // dst_ready -> src domain
  reg [SYNC_STAGES-1:0] dst_ready_sync;
  // dst_clear -> src domain
  reg [SYNC_STAGES-1:0] dst_clear_sync;
  // src_clear -> dst domain
  reg [SYNC_STAGES-1:0] src_clear_sync;

  // Synchronizer logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_reg};
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_reg};
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_reg};
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_reg};
    end
  end

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_ready_reg <= 1'b1;
    end else begin
      // Handle clear
      if (src_clear_i || dst_clear_sync[SYNC_STAGES-1]) begin
        src_clear_pending_reg <= 1'b1;
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b0;
      end else if (src_clear_pending_reg) begin
        // Wait for dst to acknowledge clear
        if (dst_clear_sync[SYNC_STAGES-1] == 1'b0) begin
          src_clear_pending_reg <= 1'b0;
          src_ready_reg <= 1'b1;
        end
      end else begin
        // Normal operation
        if (src_valid_i && src_ready_reg) begin
          src_data_reg <= src_data_i;
          src_valid_reg <= 1'b1;
          src_ready_reg <= 1'b0;
        end else if (dst_ready_sync[SYNC_STAGES-1]) begin
          src_valid_reg <= 1'b0;
          src_ready_reg <= 1'b1;
        end
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
    end else begin
      // Handle clear
      if (dst_clear_i || src_clear_sync[SYNC_STAGES-1]) begin
        dst_clear_pending_reg <= 1'b1;
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b0;
      end else if (dst_clear_pending_reg) begin
        // Wait for src to acknowledge clear
        if (src_clear_sync[SYNC_STAGES-1] == 1'b0) begin
          dst_clear_pending_reg <= 1'b0;
          dst_ready_reg <= 1'b1;
        end
      end else begin
        // Normal operation
        if (src_valid_sync[SYNC_STAGES-1] && dst_ready_reg) begin
          dst_data_reg <= src_data_reg;
          dst_valid_reg <= 1'b1;
          dst_ready_reg <= 1'b0;
        end else if (dst_valid_reg && dst_ready_i) begin
          dst_valid_reg <= 1'b0;
          dst_ready_reg <= 1'b1;
        end
      end
    end
  end

  // Clear request registers
  reg src_clear_reg;
  reg dst_clear_reg;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_reg <= 1'b0;
    end else begin
      src_clear_reg <= src_clear_i;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_reg <= 1'b0;
    end else begin
      dst_clear_reg <= dst_clear_i;
    end
  end

  // Outputs
  assign src_ready_o = src_ready_reg;
  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule
