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

  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;
  reg dst_ready_r;
  reg [1:0] state;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else if (src_valid_i && dst_ready_i) begin
      src_ready_o <= 1'b0;
    end else if (src_valid_i && ~dst_ready_i) begin
      src_ready_o <= 1'b1;
    end else begin
      src_ready_o <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_data_o <= {WIDTH{1'b0}};
      dst_valid_o <= 1'b0;
      dst_ready_r <= 1'b0;
      state <= 2'b00;
    end else if (dst_valid_i && dst_ready_i) begin
      dst_data_o <= dst_data_r;
      dst_valid_o <= dst_valid_r;
      dst_ready_r <= 1'b0;
      state <= 2'b01;
    end else if (dst_ready_i && ~dst_valid_i) begin
      dst_data_o <= dst_data_r;
      dst_valid_o <= 1'b1;
      dst_ready_r <= 1'b1;
      state <= 2'b10;
    end else begin
      dst_data_o <= dst_data_r;
      dst_valid_o <= dst_valid_r;
      dst_ready_r <= dst_ready_i;
      state <= state;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      dst_data_r <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
    end else if (state == 2'b00) begin
      dst_data_r <= src_data_i;
      dst_valid_r <= src_valid_i;
      state <= 2'b01;
    end else if (state == 2'b01) begin
      dst_data_r <= src_data_i;
      dst_valid_r <= src_valid_i;
      state <= 2'b10;
    end else if (state == 2'b10) begin
      dst_data_r <= src_data_i;
      dst_valid_r <= src_valid_i;
      state <= 2'b00;
    end else begin
      dst_data_r <= dst_data_r;
      dst_valid_r <= dst_valid_r;
      state <= state;
    end
  end


endmodule
