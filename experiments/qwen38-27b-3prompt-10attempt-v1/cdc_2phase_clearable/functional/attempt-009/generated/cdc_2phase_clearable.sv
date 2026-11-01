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
  wire src_clear_synced;
  wire dst_clear_synced;
  wire src_clear_active;
  wire dst_clear_active;
  wire src_clear_done;
  wire dst_clear_done;
  wire src_clear_pending_int;
  wire dst_clear_pending_int;

  // Source domain clear logic
  reg src_clear_pending_reg;
  reg src_clear_done_reg;

  // Destination domain clear logic
  reg dst_clear_pending_reg;
  reg dst_clear_done_reg;

  // Source domain handshake state
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;
  reg src_ready_reg;

  // Destination domain handshake state
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_ready_reg;

  // CDC signals
  wire src_to_dst_valid;
  wire [WIDTH-1:0] src_to_dst_data;
  wire dst_to_src_ready;

  // Synchronizers
  reg [SYNC_STAGES-1:0] src_clear_sync;
  reg [SYNC_STAGES-1:0] dst_clear_sync;
  reg [SYNC_STAGES-1:0] src_valid_sync;
  reg [SYNC_STAGES-1:0] dst_ready_sync;

  // Clear synchronization
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], dst_clear_synced};
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], src_clear_synced};
    end
  end

  assign src_clear_synced = src_clear_sync[SYNC_STAGES-1];
  assign dst_clear_synced = dst_clear_sync[SYNC_STAGES-1];

  // Clear pending logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_reg <= 1'b0;
      src_clear_done_reg <= 1'b0;
    end else begin
      if (src_clear_i && !src_clear_pending_reg) begin
        src_clear_pending_reg <= 1'b1;
        src_clear_done_reg <= 1'b0;
      end else if (src_clear_pending_reg && src_clear_done_reg) begin
        src_clear_pending_reg <= 1'b0;
        src_clear_done_reg <= 1'b0;
      end
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_reg <= 1'b0;
      dst_clear_done_reg <= 1'b0;
    end else begin
      if (dst_clear_i && !dst_clear_pending_reg) begin
        dst_clear_pending_reg <= 1'b1;
        dst_clear_done_reg <= 1'b0;
      end else if (dst_clear_pending_reg && dst_clear_done_reg) begin
        dst_clear_pending_reg <= 1'b0;
        dst_clear_done_reg <= 1'b0;
      end
    end
  end

  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  // Clear active signals
  assign src_clear_active = src_clear_pending_reg || (CLEAR_ON_ASYNC_RESET && !src_rst_ni);
  assign dst_clear_active = dst_clear_pending_reg || (CLEAR_ON_ASYNC_RESET && !dst_rst_ni);

  // Source domain: clear done when no valid data and clear synced from dst
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_done_reg <= 1'b0;
    end else begin
      if (src_clear_pending_reg) begin
        if (!src_valid_reg && src_clear_synced) begin
          src_clear_done_reg <= 1'b1;
        end
      end else begin
        src_clear_done_reg <= 1'b0;
      end
    end
  end

  // Destination domain: clear done when no valid data and clear synced from src
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_done_reg <= 1'b0;
    end else begin
      if (dst_clear_pending_reg) begin
        if (!dst_valid_reg && dst_clear_synced) begin
          dst_clear_done_reg <= 1'b1;
        end
      end else begin
        dst_clear_done_reg <= 1'b0;
      end
    end
  end

  // Source domain handshake
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_ready_reg <= 1'b0;
    end else begin
      if (src_clear_active) begin
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b0;
      end else begin
        if (src_valid_i && src_ready_reg) begin
          src_valid_reg <= 1'b1;
          src_data_reg <= src_data_i;
          src_ready_reg <= 1'b0;
        end else if (src_valid_reg && dst_to_src_ready) begin
          src_valid_reg <= 1'b0;
          src_ready_reg <= 1'b1;
        end else if (!src_valid_reg && !src_ready_reg) begin
          src_ready_reg <= 1'b1;
        end
      end
    end
  end

  assign src_ready_o = src_ready_reg && !src_clear_active;

  // Destination domain handshake
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_ready_reg <= 1'b0;
    end else begin
      if (dst_clear_active) begin
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b0;
      end else begin
        if (src_to_dst_valid && dst_ready_reg) begin
          dst_valid_reg <= 1'b1;
          dst_data_reg <= src_to_dst_data;
          dst_ready_reg <= 1'b0;
        end else if (dst_valid_reg && dst_ready_i) begin
          dst_valid_reg <= 1'b0;
          dst_ready_reg <= 1'b1;
        end else if (!dst_valid_reg && !dst_ready_reg) begin
          dst_ready_reg <= 1'b1;
        end
      end
    end
  end

  assign dst_valid_o = dst_valid_reg && !dst_clear_active;
  assign dst_data_o = dst_data_reg;

  // CDC: src_valid to dst
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_reg};
    end
  end

  assign src_to_dst_valid = src_valid_sync[SYNC_STAGES-1];

  // CDC: dst_ready to src
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_reg};
    end
  end

  assign dst_to_src_ready = dst_ready_sync[SYNC_STAGES-1];

  // Data path: use mux to select data based on valid
  assign src_to_dst_data = src_data_reg;

endmodule
