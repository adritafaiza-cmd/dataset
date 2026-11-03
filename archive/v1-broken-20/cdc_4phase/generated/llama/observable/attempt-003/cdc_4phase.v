module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  logic src_valid_sync;
  logic src_ready_sync;
  logic [WIDTH-1:0] src_data_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;
  logic [WIDTH-1:0] dst_data_sync;

  logic src_valid_meta;
  logic src_ready_meta;
  logic dst_valid_meta;
  logic dst_ready_meta;

  logic src_valid_pulse;
  logic src_ready_pulse;
  logic dst_valid_pulse;
  logic dst_ready_pulse;

  logic src_valid_sync_pulse;
  logic src_ready_sync_pulse;
  logic dst_valid_sync_pulse;
  logic dst_ready_sync_pulse;

  logic src_valid_meta_pulse;
  logic src_ready_meta_pulse;
  logic dst_valid_meta_pulse;
  logic dst_ready_meta_pulse;

  // Source clock domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_ready_sync <= 1'b0;
      src_data_sync <= RESET_MSG;
    end else begin
      src_valid_sync <= src_valid_i;
      src_ready_sync <= src_ready_o;
      src_data_sync <= src_data_i;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_meta <= 1'b0;
      src_ready_meta <= 1'b0;
    end else begin
      src_valid_meta <= src_valid_sync;
      src_ready_meta <= src_ready_sync;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_pulse <= 1'b0;
      src_ready_pulse <= 1'b0;
    end else begin
      src_valid_pulse <= src_valid_sync && !src_valid_meta;
      src_ready_pulse <= src_ready_sync && !src_ready_meta;
    end
  end

  // Destination clock domain
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_ready_sync <= 1'b0;
      dst_data_sync <= RESET_MSG;
    end else begin
      dst_valid_sync <= dst_valid_o;
      dst_ready_sync <= dst_ready_i;
      dst_data_sync <= dst_data_o;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_meta <= 1'b0;
      dst_ready_meta <= 1'b0;
    end else begin
      dst_valid_meta <= dst_valid_sync;
      dst_ready_meta <= dst_ready_sync;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_pulse <= 1'b0;
      dst_ready_pulse <= 1'b0;
    end else begin
      dst_valid_pulse <= dst_valid_sync && !dst_valid_meta;
      dst_ready_pulse <= dst_ready_sync && !dst_ready_meta;
    end
  end

  // Clock domain crossing
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync_pulse <= 1'b0;
    end else begin
      src_valid_sync_pulse <= src_valid_pulse;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync_pulse <= 1'b0;
    end else begin
      dst_valid_sync_pulse <= dst_valid_pulse;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_sync_pulse <= 1'b0;
    end else begin
      src_ready_sync_pulse <= src_ready_pulse;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_sync_pulse <= 1'b0;
    end else begin
      dst_ready_sync_pulse <= dst_ready_pulse;
    end
  end

  // Four-phase handshake
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_meta_pulse <= 1'b0;
      src_ready_meta_pulse <= 1'b0;
    end else begin
      src_valid_meta_pulse <= src_valid_sync_pulse;
      src_ready_meta_pulse <= src_ready_sync_pulse;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_meta_pulse <= 1'b0;
      dst_ready_meta_pulse <= 1'b0;
    end else begin
      dst_valid_meta_pulse <= dst_valid_sync_pulse;
      dst_ready_meta_pulse <= dst_ready_sync_pulse;
    end
  end

  // Output logic
  assign src_ready_o = src_ready_meta_pulse;
  assign dst_valid_o = dst_valid_meta_pulse;
  assign dst_data_o = dst_data_sync;

  // Decoupled option
  if (DECOUPLED) begin
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni) begin
        src_ready_o <= 1'b0;
      end else begin
        src_ready_o <= src_ready_meta_pulse || src_valid_sync;
      end
    end
  end

  // Reset message behavior
  if (SEND_RESET_MSG) begin
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni) begin
        src_data_sync <= RESET_MSG;
      end else if (src_valid_i && src_ready_o) begin
        src_data_sync <= src_data_i;
      end
    end
  end

endmodule
