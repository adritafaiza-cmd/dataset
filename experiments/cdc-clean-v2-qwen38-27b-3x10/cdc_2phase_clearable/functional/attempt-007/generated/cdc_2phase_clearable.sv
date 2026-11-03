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
  wire src_req;
  wire dst_ack;
  wire dst_req;
  wire src_ack;

  // Source domain: request generation
  reg src_req_reg;
  reg src_ack_reg;
  reg src_clear_pending_reg;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain: acknowledge generation
  reg dst_ack_reg;
  reg dst_req_reg;
  reg dst_ack_reg_next;
  reg dst_clear_pending_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Synchronizers
  wire [SYNC_STAGES-1:0] src_req_sync;
  wire [SYNC_STAGES-1:0] dst_ack_sync;
  wire [SYNC_STAGES-1:0] dst_req_sync;
  wire [SYNC_STAGES-1:0] src_ack_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_reg <= 1'b0;
      src_ack_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      // Clear handling
      if (src_clear_i) begin
        src_clear_pending_reg <= 1'b1;
        src_req_reg <= 1'b0;
        src_ack_reg <= 1'b0;
      end else begin
        // Normal operation
        if (src_valid_i && src_ready_o) begin
          src_data_reg <= src_data_i;
          src_req_reg <= 1'b1;
        end else if (src_ack_reg) begin
          src_req_reg <= 1'b0;
        end

        if (src_clear_pending_reg) begin
          if (!src_req_reg && !src_ack_reg) begin
            src_clear_pending_reg <= 1'b0;
          end
        end
      end
    end
  end

  assign src_ready_o = !src_req_reg || src_ack_reg;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
      dst_req_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      // Clear handling
      if (dst_clear_i) begin
        dst_clear_pending_reg <= 1'b1;
        dst_ack_reg <= 1'b0;
        dst_req_reg <= 1'b0;
        dst_valid_reg <= 1'b0;
      end else begin
        // Normal operation
        if (dst_req_reg && !dst_ack_reg) begin
          dst_data_reg <= dst_req_sync[SYNC_STAGES-1];
          dst_valid_reg <= 1'b1;
        end else if (dst_valid_reg && dst_ready_i) begin
          dst_valid_reg <= 1'b0;
        end

        if (dst_clear_pending_reg) begin
          if (!dst_req_reg && !dst_ack_reg) begin
            dst_clear_pending_reg <= 1'b0;
          end
        end
      end
    end
  end

  assign dst_ack = dst_ack_reg;
  assign dst_req = dst_req_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Synchronizers
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_req_sync <= {SYNC_STAGES{1'b0}};
      dst_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_req_sync <= {src_req_sync[SYNC_STAGES-2:0], src_req};
      dst_ack_sync <= {dst_ack_sync[SYNC_STAGES-2:0], dst_ack};
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_req_sync <= {SYNC_STAGES{1'b0}};
      src_ack_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_req_sync <= {dst_req_sync[SYNC_STAGES-2:0], dst_req};
      src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], src_ack};
    end
  end

  // Assign synchronized signals
  assign src_req = src_req_reg;
  assign dst_ack = dst_ack_sync[SYNC_STAGES-1];
  assign dst_req = dst_req_reg;
  assign src_ack = src_ack_sync[SYNC_STAGES-1];

  // Update source ack from synchronized dst_ack
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ack_reg <= 1'b0;
    end else begin
      src_ack_reg <= dst_ack_sync[SYNC_STAGES-1];
    end
  end

  // Update destination req from synchronized src_req
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_reg <= 1'b0;
    end else begin
      dst_req_reg <= src_req_sync[SYNC_STAGES-1];
    end
  end

  // Update destination ack
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_reg <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_ack_reg <= 1'b0;
      end else if (dst_req_reg) begin
        dst_ack_reg <= 1'b1;
      end else begin
        dst_ack_reg <= 1'b0;
      end
    end
  end

endmodule
