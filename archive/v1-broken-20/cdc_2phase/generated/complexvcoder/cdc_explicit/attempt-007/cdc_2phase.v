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

  // Internal signals
  logic [WIDTH-1:0] sync_data;
  logic sync_valid;
  logic sync_ready;
  logic [WIDTH-1:0] shift_reg;
  logic shift_reg_valid;
  logic shift_reg_ready;

  // Source synchronization
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      shift_reg <= 0;
      shift_reg_valid <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        shift_reg <= src_data_i;
        shift_reg_valid <= 1;
      end else if (shift_reg_valid && sync_ready) begin
        shift_reg_valid <= 0;
      end
    end
  end

  // Destination synchronization
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_data <= 0;
      sync_valid <= 0;
    end else begin
      if (shift_reg_valid && dst_ready_i) begin
        sync_data <= shift_reg;
        sync_valid <= 1;
      end else if (sync_valid && dst_ready_i) begin
        sync_valid <= 0;
      end
    end
  end

  // Handshaking between source and destination
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 0;
    end else begin
      if (shift_reg_valid && sync_ready) begin
        src_ready_o <= 0;
      end else begin
        src_ready_o <= 1;
      end
    end
  end

  // Output to destination
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= 0;
      dst_valid_o <= 0;
    end else begin
      if (sync_valid && dst_ready_i) begin
        dst_data_o <= sync_data;
        dst_valid_o <= 1;
      end else begin
        dst_valid_o <= 0;
      end
    end
  end

endmodule
