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

  logic [1:0] src_state, dst_state;
  logic [WIDTH-1:0] src_data, dst_data;
  logic src_valid, dst_valid, src_ready, dst_ready;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= 2'b00;
      src_valid <= 1'b0;
      src_data <= RESET_MSG;
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
            if (DECOUPLED && src_valid_i) begin
              src_data <= src_data_i;
              src_valid <= 1'b1;
              src_state <= 2'b01;
            end else begin
              src_state <= 2'b00;
            end
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
      dst_data_o <= RESET_MSG;
      dst_valid_o <= 1'b0;
    end else begin
      case (dst_state)
        2'b00: begin
          if (dst_ready_i) begin
            dst_state <= 2'b01;
          end
        end
        2'b01: begin
          if (src_valid) begin
            dst_data_o <= src_data;
            dst_valid_o <= 1'b1;
            dst_state <= 2'b10;
          end
        end
        2'b10: begin
          if (dst_ready_i) begin
            dst_valid_o <= 1'b0;
            dst_state <= 2'b11;
          end
        end
        2'b11: begin
          if (src_valid) begin
            dst_state <= 2'b01;
          end else begin
            dst_state <= 2'b00;
          end
        end
        default: dst_state <= 2'b00;
      endcase
    end
  end

  assign src_ready_o = (src_state == 2'b00) || (src_state == 2'b01 && DECOUPLED);
  assign src_ready = (dst_state == 2'b11) || (dst_state == 2'b10 && dst_ready_i);
  assign dst_ready = dst_ready_i;

  // handshake signals
  logic src_valid_sync, dst_valid_sync;
  logic src_ready_sync, dst_ready_sync;

  // synchronize signals
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
    end else begin
      src_valid_sync <= src_valid;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
    end else begin
      dst_valid_sync <= dst_valid_o;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_sync <= 1'b0;
    end else begin
      src_ready_sync <= dst_ready_i;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_sync <= 1'b0;
    end else begin
      dst_ready_sync <= src_ready_o;
    end
  end

  assign src_valid = src_valid_sync;
  assign dst_valid = dst_valid_sync;
  assign src_ready = src_ready_sync;
  assign dst_ready = dst_ready_sync;

endmodule
