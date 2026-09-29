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

  // Source domain signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_toggle;
  reg src_valid_reg;

  // Destination domain signals
  reg sync_toggle_d1, sync_toggle_d2;
  reg dest_ack_toggle;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Synchronization of ack toggle back to source
  reg ack_toggle_d1, ack_toggle_d2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_toggle <= 0;
      src_data_reg <= RESET_MSG;
      src_valid_reg <= SEND_RESET_MSG;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_toggle <= ~src_toggle;
        src_valid_reg <= 1;
      end else if (src_valid_reg && (ack_toggle_d2 == src_toggle)) begin
        src_valid_reg <= 0;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_toggle_d1 <= 0;
      sync_toggle_d2 <= 0;
      dest_ack_toggle <= 0;
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
    end else begin
      // Synchronize toggle from source
      sync_toggle_d1 <= src_toggle;
      sync_toggle_d2 <= sync_toggle_d1;

      // Capture data and toggle ack when toggle changes
      if (sync_toggle_d2 != dest_ack_toggle) begin
        dst_data_reg <= src_data_reg;
        dest_ack_toggle <= ~dest_ack_toggle;
        dst_valid_reg <= 1;
      end

      // Clear valid when destination is ready
      if (dst_ready_i && dst_valid_reg) begin
        dst_valid_reg <= 0;
      end
    end
  end

  // Synchronize ack toggle back to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_toggle_d1 <= 0;
      ack_toggle_d2 <= 0;
    end else begin
      ack_toggle_d1 <= dest_ack_toggle;
      ack_toggle_d2 <= ack_toggle_d1;
    end
  end

  // Source ready logic with DECOUPLED option
  assign src_ready_o = (src_toggle == ack_toggle_d2) || (DECOUPLED && !src_valid_reg);

  // Output assignments
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule
