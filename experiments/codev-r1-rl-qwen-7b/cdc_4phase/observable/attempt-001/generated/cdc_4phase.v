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

  // Source to destination domain crossing
  reg [1:0] src_phase;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;

  // Synchronized signals
  reg dst_ready_sync1, dst_ready_sync;

  // Destination to source domain crossing
  reg [1:0] dst_phase;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_ready_reg;

  // Synchronized signals
  reg src_valid_sync1, src_valid_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase <= 2'b00;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      dst_ready_sync1 <= 1'b0;
      dst_ready_sync <= 1'b0;
    end else begin
      dst_ready_sync1 <= dst_ready_i;
      dst_ready_sync <= dst_ready_sync1;

      case (src_phase)
        2'b00: begin // Idle
          if (src_valid_i && !src_ready_reg) begin
            src_data_reg <= src_data_i;
            src_phase <= 2'b01;
            src_ready_reg <= 1'b1;
          end
        end
        2'b01: begin // Wait for dst_ready
          if (dst_ready_sync) begin
            src_phase <= 2'b10;
            src_valid_reg <= 1'b1;
          end
        end
        2'b10: begin // Data transfer
          if (dst_ready_sync) begin
            src_phase <= 2'b11;
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b0;
          end
        end
        2'b11: begin // Wait for dst to deassert valid
          if (!dst_valid_sync) begin
            src_phase <= 2'b00;
            src_ready_reg <= 1'b1;
          end
        end
      endcase
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase <= 2'b00;
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      src_valid_sync1 <= 1'b0;
      src_valid_sync <= 1'b0;
    end else begin
      src_valid_sync1 <= src_valid_reg;
      src_valid_sync <= src_valid_sync1;

      case (dst_phase)
        2'b00: begin // Idle
          if (src_valid_sync) begin
            dst_data_reg <= src_data_reg;
            dst_valid_reg <= 1'b1;
            dst_phase <= 2'b01;
            dst_ready_reg <= 1'b1;
          end
        end
        2'b01: begin // Wait for data transfer
          if (dst_ready_i) begin
            dst_phase <= 2'b10;
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b0;
          end
        end
        2'b10: begin // Wait for src to deassert valid
          if (!src_valid_sync) begin
            dst_phase <= 2'b11;
            dst_ready_reg <= 1'b1;
          end
        end
        2'b11: begin // Ready to accept new data
          if (src_valid_sync) begin
            dst_phase <= 2'b00;
            dst_valid_reg <= 1'b1;
            dst_ready_reg <= 1'b1;
          end
        end
      endcase
    end
  end

  assign src_ready_o = (src_phase == 2'b00) && src_valid_i;
  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o = dst_data_reg;

endmodule
