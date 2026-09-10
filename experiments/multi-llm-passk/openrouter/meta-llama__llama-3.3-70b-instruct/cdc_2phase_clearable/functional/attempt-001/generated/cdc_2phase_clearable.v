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
  logic src_clear_pending;
  logic dst_clear_pending;
  logic src_valid_synced;
  logic src_data_synced [WIDTH-1:0];
  logic src_ready_synced;
  logic dst_valid_synced;
  logic dst_data_synced [WIDTH-1:0];
  logic dst_ready_synced;

  // Source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending <= 1'b0;
      src_ready_o <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending <= 1'b1;
      src_ready_o <= 1'b0;
    end else if (src_clear_pending && !src_valid_i) begin
      src_clear_pending <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_ready_o <= 1'b0;
    end else if (!src_clear_pending && !src_valid_i) begin
      src_ready_o <= 1'b1;
    end
  end

  // Destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending <= 1'b0;
      dst_valid_o <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending <= 1'b1;
      dst_valid_o <= 1'b0;
    end else if (dst_clear_pending && !dst_valid_o) begin
      dst_clear_pending <= 1'b0;
    end else if (dst_valid_o && dst_ready_i) begin
      dst_valid_o <= 1'b0;
    end else if (!dst_clear_pending && !dst_valid_o) begin
      dst_valid_o <= 1'b1;
    end
  end

  // Synchronization of clear signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_synced <= 1'b0;
    end else begin
      src_clear_synced <= src_clear_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_synced <= 1'b0;
    end else begin
      dst_clear_synced <= dst_clear_i;
    end
  end

  // Synchronization of valid and data signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_synced <= 1'b0;
      src_data_synced <= '0;
    end else if (src_clear_synced) begin
      src_valid_synced <= 1'b0;
      src_data_synced <= '0;
    end else if (src_valid_i && src_ready_o) begin
      src_valid_synced <= 1'b1;
      src_data_synced <= src_data_i;
    end else if (src_valid_synced && !src_ready_o) begin
      src_valid_synced <= 1'b0;
      src_data_synced <= '0;
    end
  end

  // Crossing from source to destination domain
  logic [SYNC_STAGES-1:0] src_valid_crossed;
  logic [SYNC_STAGES-1:0] [WIDTH-1:0] src_data_crossed;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_crossed <= '0;
      src_data_crossed <= '0;
    end else if (dst_clear_synced) begin
      src_valid_crossed <= '0;
      src_data_crossed <= '0;
    end else begin
      src_valid_crossed[0] <= src_valid_synced;
      src_data_crossed[0] <= src_data_synced;
      for (int i = 1; i < SYNC_STAGES; i++) begin
        src_valid_crossed[i] <= src_valid_crossed[i-1];
        src_data_crossed[i] <= src_data_crossed[i-1];
      end
    end
  end

  // Destination domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else if (dst_clear_i) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else if (src_valid_crossed[SYNC_STAGES-1] && dst_ready_i) begin
      dst_valid_o <= 1'b1;
      dst_data_o <= src_data_crossed[SYNC_STAGES-1];
    end else if (dst_valid_o && dst_ready_i) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end
  end

  assign src_clear_pending_o = src_clear_pending;
  assign dst_clear_pending_o = dst_clear_pending;

endmodule
