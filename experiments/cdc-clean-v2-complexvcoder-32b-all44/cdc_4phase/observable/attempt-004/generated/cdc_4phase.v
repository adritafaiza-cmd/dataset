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

  cdc_4phase_fifo #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) fifo_inst (
    .clk_src(src_clk_i),
    .rst_src_ni(src_rst_ni),
    .data_in(src_data_i),
    .valid_in(src_valid_i),
    .ready_out(src_ready_o),
    .clk_dst(dst_clk_i),
    .rst_dst_ni(dst_rst_ni),
    .data_out(dst_data_o),
    .valid_out(dst_valid_o),
    .ready_in(dst_ready_i)
  );

endmodule

module cdc_4phase_fifo #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  clk_src,
  input  rst_src_ni,
  input  [WIDTH-1:0] data_in,
  input  valid_in,
  output ready_out,
  input  clk_dst,
  input  rst_dst_ni,
  output [WIDTH-1:0] data_out,
  output valid_out,
  input  ready_in
);

  reg [1:0] phase_src, phase_dst;
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;

  always @(posedge clk_src or negedge rst_src_ni) begin
    if (!rst_src_ni) begin
      phase_src <= 2'b00;
      if (SEND_RESET_MSG)
        data_reg <= RESET_MSG;
      else
        data_reg <= {WIDTH{1'b0}};
      valid_reg <= 1'b0;
    end else begin
      case (phase_src)
        2'b00: begin
          if (valid_in && ready_out) begin
            data_reg <= data_in;
            valid_reg <= 1'b1;
            phase_src <= 2'b01;
          end
        end
        2'b01: phase_src <= 2'b10;
        2'b10: phase_src <= 2'b11;
        2'b11: phase_src <= 2'b00;
      endcase
    end
  end

  always @(posedge clk_dst or negedge rst_dst_ni) begin
    if (!rst_dst_ni) begin
      phase_dst <= 2'b00;
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      case (phase_dst)
        2'b00: begin
          if (phase_src == 2'b01) begin
            data_out <= data_reg;
            valid_out <= valid_reg;
            phase_dst <= 2'b01;
          end
        end
        2'b01: begin
          if (phase_src == 2'b10) begin
            phase_dst <= 2'b10;
          end
        end
        2'b10: begin
          if (phase_src == 2'b11) begin
            phase_dst <= 2'b11;
          end
        end
        2'b11: begin
          if (phase_src == 2'b00) begin
            if (DECOUPLED || ready_in) begin
              valid_out <= 1'b0;
              phase_dst <= 2'b00;
            end
          end else begin
            phase_dst <= 2'b00;
          end
        end
      endcase
      if (phase_src == 2'b00 || (phase_src == 2'b11 && (DECOUPLED || ready_in))) begin
        ready_reg <= 1'b1;
      end else begin
        ready_reg <= 1'b0;
      end
    end
  end

  assign ready_out = ready_reg;

endmodule
