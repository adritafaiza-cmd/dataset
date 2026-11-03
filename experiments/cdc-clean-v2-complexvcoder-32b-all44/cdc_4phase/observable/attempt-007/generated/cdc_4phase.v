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

  // Internal signals for the four-phase handshake
  reg [1:0] phase_src;
  reg [1:0] phase_dst;
  reg [WIDTH-1:0] fifo_buffer;
  reg fifo_valid;

  // Synchronized signals for cross-clock domain communication
  reg [WIDTH-1:0] src_data_sync;
  reg src_valid_sync;
  reg [WIDTH-1:0] dst_data_sync;
  reg dst_valid_sync;

  // Synchronize src_data_i and src_valid_i to dst_clk_i
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= RESET_MSG;
      src_valid_sync <= 1'b0;
    end else begin
      src_data_sync <= src_data_i;
      src_valid_sync <= src_valid_i;
    end
  end

  // Synchronize dst_data_sync and dst_valid_sync to src_clk_i
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_data_sync <= RESET_MSG;
      dst_valid_sync <= 1'b0;
    end else begin
      dst_data_sync <= dst_data_o;
      dst_valid_sync <= dst_valid_o;
    end
  end

  // Four-phase handshake logic on src_clk_i
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      phase_src <= 2'b00;
      fifo_valid <= 1'b0;
      fifo_buffer <= RESET_MSG;
      src_ready_o <= 1'b0;
    end else begin
      case (phase_src)
        2'b00: begin
          if (src_valid_i && (!fifo_valid || DECOUPLED)) begin
            fifo_buffer <= src_data_i;
            fifo_valid <= 1'b1;
            phase_src <= 2'b01;
          end
          src_ready_o <= (!fifo_valid || DECOUPLED) && src_valid_i;
        end
        2'b01: begin
          if (phase_dst == 2'b10) begin
            phase_src <= 2'b10;
          end
        end
        2'b10: begin
          if (phase_dst == 2'b11) begin
            phase_src <= 2'b11;
          end
        end
        2'b11: begin
          fifo_valid <= 1'b0;
          phase_src <= 2'b00;
        end
      endcase
    end
  end

  // Four-phase handshake logic on dst_clk_i
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      phase_dst <= 2'b00;
      dst_valid_o <= 1'b0;
      dst_data_o <= RESET_MSG;
    end else begin
      case (phase_dst)
        2'b00: begin
          if (phase_src == 2'b01) begin
            phase_dst <= 2'b01;
          end
        end
        2'b01: begin
          if (phase_src == 2'b10) begin
            phase_dst <= 2'b10;
            dst_valid_o <= 1'b1;
            dst_data_o <= src_data_sync;
          end
        end
        2'b10: begin
          if (phase_src == 2'b11) begin
            phase_dst <= 2'b11;
          end
        end
        2'b11: begin
          if (dst_ready_i) begin
            phase_dst <= 2'b00;
            dst_valid_o <= 1'b0;
          end
        end
      endcase
    end
  end

endmodule
