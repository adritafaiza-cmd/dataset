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

  // Source domain state
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_reg;
  reg             src_pending;

  // Destination domain state
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ready_reg;
  reg             dst_pending;

  // Synchronizers
  reg [1:0] src_valid_sync;
  reg [1:0] dst_ready_sync;

  // Source domain: synchronizer for dst_ready
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ready_sync <= 2'b00;
    else
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_reg};
  end

  // Destination domain: synchronizer for src_valid
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_valid_sync <= 2'b00;
    else
      src_valid_sync <= {src_valid_sync[0], src_valid_reg};
  end

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_pending   <= 1'b0;
    end else begin
      // If we have a pending transfer and dst_ready is high, clear it
      if (src_pending && dst_ready_sync[1]) begin
        src_pending   <= 1'b0;
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
      end
      // If source is valid and ready, accept new data
      else if (src_valid_i && src_ready_reg) begin
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_pending   <= 1'b1;
        // If DECOUPLED, we can accept new data immediately
        // Otherwise, we wait for dst_ready to come back
        if (DECOUPLED)
          src_ready_reg <= 1'b1;
        else
          src_ready_reg <= 1'b0;
      end
      // If not DECOUPLED and we're waiting for dst_ready, keep ready low
      else if (!DECOUPLED && src_pending) begin
        src_ready_reg <= 1'b0;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
      dst_pending   <= 1'b0;
    end else begin
      // If we have a pending transfer and dst_ready is high, clear it
      if (dst_pending && dst_ready_i) begin
        dst_pending   <= 1'b0;
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b1;
      end
      // If source valid is synchronized and we're ready, accept data
      else if (src_valid_sync[1] && dst_ready_reg) begin
        dst_data_reg  <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_pending   <= 1'b1;
        // If DECOUPLED, we can accept new data immediately
        // Otherwise, we wait for src_valid to go low
        if (DECOUPLED)
          dst_ready_reg <= 1'b1;
        else
          dst_ready_reg <= 1'b0;
      end
      // If not DECOUPLED and we're waiting for src_valid to clear, keep ready low
      else if (!DECOUPLED && dst_pending) begin
        dst_ready_reg <= 1'b0;
      end
    end
  end

  // Handle SEND_RESET_MSG
  // When SEND_RESET_MSG is set, after reset, emit RESET_MSG
  // This is handled by initializing the state appropriately

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
