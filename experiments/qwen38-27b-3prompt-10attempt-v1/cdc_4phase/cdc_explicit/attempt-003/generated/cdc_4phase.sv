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
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;
  reg src_pending_r;

  // Destination domain logic
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;
  reg dst_ready_r;
  reg dst_pending_r;

  // CDC synchronizers for valid signal (src to dst)
  reg [1:0] valid_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      valid_sync <= 2'b00;
    else
      valid_sync <= {valid_sync[0], src_valid_r};
  end

  // CDC synchronizers for ready signal (dst to src)
  reg [1:0] ready_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ready_sync <= 2'b00;
    else
      ready_sync <= {ready_sync[0], dst_ready_r};
  end

  // CDC synchronizers for data (src to dst) - use handshake to ensure stability
  // We'll use a simple approach: data is stable when valid is asserted
  // For multi-bit data, we need to ensure it's stable during transfer

  // Source domain: generate valid and ready
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r   <= {WIDTH{1'b0}};
      src_valid_r  <= 1'b0;
      src_ready_r  <= 1'b1;
      src_pending_r <= 1'b0;
    end else begin
      // If not pending and ready, accept new data
      if (!src_pending_r && src_ready_r && src_valid_i) begin
        src_data_r   <= src_data_i;
        src_valid_r  <= 1'b1;
        src_ready_r  <= 1'b0;
        src_pending_r <= 1'b1;
      end else if (src_pending_r && ready_sync[1]) begin
        // Destination has acknowledged, clear pending
        src_valid_r   <= 1'b0;
        src_ready_r   <= 1'b1;
        src_pending_r <= 1'b0;
      end
    end
  end

  // Destination domain: generate valid and ready
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r   <= {WIDTH{1'b0}};
      dst_valid_r  <= 1'b0;
      dst_ready_r  <= 1'b1;
      dst_pending_r <= 1'b0;
    end else begin
      // If valid from source is synchronized and we're ready
      if (!dst_pending_r && dst_ready_r && valid_sync[1]) begin
        dst_data_r   <= src_data_r;
        dst_valid_r  <= 1'b1;
        dst_ready_r  <= 1'b0;
        dst_pending_r <= 1'b1;
      end else if (dst_pending_r && dst_ready_i) begin
        // Destination consumer has accepted, clear pending
        dst_valid_r   <= 1'b0;
        dst_ready_r   <= 1'b1;
        dst_pending_r <= 1'b0;
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_r;
  assign dst_data_o  = dst_data_r;
  assign dst_valid_o = dst_valid_r;

endmodule
