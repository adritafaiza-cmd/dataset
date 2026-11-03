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

logic [WIDTH-1:0] src_data;
logic src_valid;
logic src_ready;
logic [WIDTH-1:0] dst_data;
logic dst_valid;
logic dst_ready;

logic [1:0] src_state;
logic [1:0] dst_state;

always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
  if (!src_rst_ni) begin
    src_state <= 2'b00;
    src_valid <= 1'b0;
  end else begin
    case (src_state)
      2'b00: begin
        if (src_valid_i) begin
          src_data <= src_data_i;
          src_valid <= 1'b1;
          src_state <= 2'b01;
        end
      end
      2'b01: begin
        if (src_ready) begin
          src_valid <= 1'b0;
          src_state <= 2'b00;
        end
      end
      default: src_state <= 2'b00;
    endcase
  end
end

always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
  if (!dst_rst_ni) begin
    dst_state <= 2'b00;
    dst_valid <= 1'b0;
  end else begin
    case (dst_state)
      2'b00: begin
        if (dst_ready_i) begin
          dst_data <= '0;
          dst_valid <= 1'b1;
          dst_state <= 2'b01;
        end
      end
      2'b01: begin
        if (dst_ready_i) begin
          dst_valid <= 1'b0;
          dst_state <= 2'b00;
        end
      end
      default: dst_state <= 2'b00;
    endcase
  end
end

always_comb begin
  src_ready_o = src_ready;
  dst_data_o = dst_data;
  dst_valid_o = dst_valid;
end

logic [WIDTH-1:0] src_data_sync;
logic src_valid_sync;
logic src_ready_sync;

always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
  if (!dst_rst_ni) begin
    src_data_sync <= '0;
    src_valid_sync <= 1'b0;
    src_ready_sync <= 1'b0;
  end else begin
    src_data_sync <= src_data;
    src_valid_sync <= src_valid;
    src_ready_sync <= src_ready;
  end
end

always_comb begin
  dst_data = src_data_sync;
  dst_valid = src_valid_sync;
  src_ready = src_ready_sync;
end

logic [WIDTH-1:0] dst_data_sync;
logic dst_valid_sync;
logic dst_ready_sync;

always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
  if (!src_rst_ni) begin
    dst_data_sync <= '0;
    dst_valid_sync <= 1'b0;
    dst_ready_sync <= 1'b0;
  end else begin
    dst_data_sync <= dst_data;
    dst_valid_sync <= dst_valid;
    dst_ready_sync <= dst_ready;
  end
end

always_comb begin
  src_data = dst_data_sync;
  src_valid = dst_valid_sync;
  dst_ready = dst_ready_sync;
end

endmodule
