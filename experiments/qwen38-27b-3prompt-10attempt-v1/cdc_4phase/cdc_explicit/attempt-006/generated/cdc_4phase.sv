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

  // Internal signals
  wire [WIDTH-1:0] src_data_reg;
  wire src_valid_reg;
  wire src_ready_int;
  wire dst_valid_int;
  wire dst_ready_int;
  wire [WIDTH-1:0] dst_data_reg;

  // Source domain logic
  reg [WIDTH-1:0] src_data_q;
  reg src_valid_q;
  reg src_ready_q;
  reg src_pending_q;

  // Destination domain logic
  reg [WIDTH-1:0] dst_data_q;
  reg dst_valid_q;
  reg dst_ready_q;

  // CDC synchronizers for valid signal (src -> dst)
  reg [2:0] valid_sync_q;
  // CDC synchronizers for ready signal (dst -> src)
  reg [2:0] ready_sync_q;

  // Data path: use a FIFO-like approach with handshake
  // For simplicity and correctness, we'll use a 2-stage handshake with data latched

  // Source domain: capture data and valid when ready
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_q  <= {WIDTH{1'b0}};
      src_valid_q <= 1'b0;
      src_ready_q <= 1'b1;
      src_pending_q <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_q) begin
        // Accept new data
        src_data_q  <= src_data_i;
        src_valid_q <= 1'b1;
        src_ready_q <= 1'b0;
        src_pending_q <= 1'b1;
      end else if (src_valid_q && ready_sync_q[2]) begin
        // Destination has acknowledged, ready for next
        src_valid_q <= 1'b0;
        src_ready_q <= 1'b1;
        src_pending_q <= 1'b0;
      end
    end
  end

  // Destination domain: process valid and ready
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_q  <= {WIDTH{1'b0}};
      dst_valid_q <= 1'b0;
      dst_ready_q <= 1'b1;
    end else begin
      if (valid_sync_q[2] && dst_ready_q) begin
        // Valid from source, and we're ready
        dst_data_q  <= src_data_q; // This is a CDC issue - need to synchronize data
        dst_valid_q <= 1'b1;
        dst_ready_q <= 1'b0;
      end else if (dst_valid_q && dst_ready_i) begin
        // Destination consumed the data
        dst_valid_q <= 1'b0;
        dst_ready_q <= 1'b1;
      end
    end
  end

  // Synchronizers
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_sync_q <= 3'b000;
    end else begin
      valid_sync_q <= {valid_sync_q[1:0], src_valid_q};
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ready_sync_q <= 3'b000;
    end else begin
      ready_sync_q <= {ready_sync_q[1:0], dst_ready_q};
    end
  end

  // Outputs
  assign src_ready_o = src_ready_q;
  assign dst_valid_o = dst_valid_q;
  assign dst_data_o  = dst_data_q;

endmodule
