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
  reg [WIDTH-1:0] src_data_sync;
  reg src_valid_sync;
  reg [WIDTH-1:0] dst_data_sync;
  reg dst_valid_sync;
  reg src_ready;
  reg dst_ready;
  reg [1:0] src_state;
  reg [1:0] dst_state;
  reg src_reset;
  reg dst_reset;
  reg src_valid_reg;
  reg dst_valid_reg;
  reg [WIDTH-1:0] src_data_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // Reset signals
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reset <= 1'b1;
    end else begin
      src_reset <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reset <= 1'b1;
    end else begin
      dst_reset <= 1'b0;
    end
  end

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
      src_valid_reg <= 1'b0;
      src_data_reg <= RESET_MSG;
      src_state <= 2'b00;
    end else begin
      case (src_state)
        2'b00: begin
          if (src_valid_i && src_ready) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            src_state <= 2'b01;
          end
        end
        2'b01: begin
          src_data_sync <= src_data_reg;
          src_state <= 2'b10;
        end
        2'b10: begin
          src_valid_sync <= src_valid_reg;
          src_state <= 2'b11;
        end
        2'b11: begin
          src_ready <= (DECOUPLED || !src_valid_sync);
          if (!src_valid_sync) begin
            src_state <= 2'b00;
          end
        end
        default: begin
          src_state <= 2'b00;
        end
      endcase
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready <= 1'b0;
      dst_valid_reg <= 1'b0;
      dst_data_reg <= RESET_MSG;
      dst_state <= 2'b00;
    end else begin
      case (dst_state)
        2'b00: begin
          dst_data_reg <= src_data_sync;
          dst_valid_reg <= src_valid_sync;
          dst_state <= 2'b01;
        end
        2'b01: begin
          dst_data_sync <= dst_data_reg;
          dst_state <= 2'b10;
        end
        2'b10: begin
          dst_valid_sync <= dst_valid_reg;
          dst_state <= 2'b11;
        end
        2'b11: begin
          dst_ready <= dst_ready_i;
          if (dst_ready_i && dst_valid_sync) begin
            dst_state <= 2'b00;
          end
        end
        default: begin
          dst_state <= 2'b00;
        end
      endcase
    end
  end

  // Outputs
  assign src_ready_o = src_ready;
  assign dst_data_o = (SEND_RESET_MSG && dst_reset) ? RESET_MSG : dst_data_sync;
  assign dst_valid_o = (SEND_RESET_MSG && dst_reset) ? 1'b1 : dst_valid_sync;

endmodule
