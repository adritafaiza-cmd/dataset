module cdc_2phase #(
  parameter WIDTH = 1
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
  logic src_state_idle, src_state_busy;
  logic src_data_reg;

  // Destination domain state
  logic dst_state_idle, dst_state_busy;
  logic dst_data_reg;

  // ------------------------------------------------------------------
  // Source Domain Logic
  // ------------------------------------------------------------------
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state_idle <= 1'b1;
      src_state_busy <= 1'b0;
      src_data_reg   <= 1'b0;
    end else begin
      if (src_state_idle) begin
        src_state_idle <= 1'b0;
        src_state_busy <= 1'b1;
        src_data_reg   <= src_data_i;
        src_ready_o    <= 1'b0; // Cannot accept new data while processing
      end else if (src_state_busy) begin
        src_state_idle <= 1'b1;
        src_state_busy <= 1'b0;
        src_data_reg   <= 1'b0;
        src_ready_o    <= 1'b1; // Ready to accept next item
      end
    end
  end

  // ------------------------------------------------------------------
  // Destination Domain Logic
  // ------------------------------------------------------------------
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state_idle <= 1'b1;
      dst_state_busy <= 1'b0;
      dst_data_reg   <= 1'b0;
      dst_valid_o    <= 1'b0;
    end else begin
      if (dst_state_idle) begin
        dst_state_idle <= 1'b0;
        dst_state_busy <= 1'b1;
        dst_data_reg   <= src_data_reg;
        dst_valid_o    <= 1'b1;
      end else if (dst_state_busy) begin
        dst_state_idle <= 1'b1;
        dst_state_busy <= 1'b0;
        dst_data_reg   <= 1'b0;
        dst_valid_o    <= 1'b0;
      end
    end
  end

  // ------------------------------------------------------------------
  // Handshake Logic
  // ------------------------------------------------------------------
  // Source ready is high only when in idle state
  assign src_ready_o = src_state_idle;

  // Destination data is stable when valid is high
  assign dst_data_o = dst_data_reg;

endmodule<|im_end|>
