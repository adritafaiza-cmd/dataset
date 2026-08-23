module cdc_2phase #(
  parameter WIDTH = 1
)(
  input                  src_rst_ni,
  input                  src_clk_i,
  input      [WIDTH-1:0] src_data_i,
  input                  src_valid_i,
  output                 src_ready_o,

  input                  dst_rst_ni,
  input                  dst_clk_i,
  output     [WIDTH-1:0] dst_data_o,
  output                 dst_valid_o,
  input                  dst_ready_i
);

  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;

  reg dst_valid_r;
  reg dst_ready_r;

  reg [1:0] state;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_data_r <= 0;
      src_valid_r <= 0;
      src_ready_r <= 1;
      state <= 2'b00;
    end else begin
      case (state)
        2'b00: begin
          src_data_r <= src_data_i;
          src_valid_r <= src_valid_i;
          src_ready_r <= 1;
          state <= 2'b01;
        end
        2'b01: begin
          src_ready_r <= 0;
          state <= 2'b10;
        end
        2'b10: begin
          src_ready_r <= 1;
          state <= 2'b00;
        end
      endcase
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_valid_r <= 0;
      dst_ready_r <= 1;
    end else begin
      case (state)
        2'b00: begin
          dst_valid_r <= src_valid_i;
          dst_ready_r <= dst_ready_i;
          state <= 2'b01;
        end
        2'b01: begin
          dst_valid_r <= 0;
          dst_ready_r <= 1;
          state <= 2'b10;
        end
        2'b10: begin
          dst_valid_r <= dst_valid_i;
          dst_ready_r <= dst_ready_i;
          state <= 2'b00;
        end
      endcase
    end
  end

  assign src_ready_o = src_ready_r;
  assign dst_data_o = src_data_r;
  assign dst_valid_o = dst_valid_r;


endmodule
