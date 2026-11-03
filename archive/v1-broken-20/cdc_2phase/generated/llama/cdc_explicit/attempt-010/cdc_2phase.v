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

  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic [WIDTH-1:0] dst_data_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b0;
      end else if (~src_valid_i) begin
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '0;
    end else begin
      if (src_valid_reg && ~dst_valid_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end else if (dst_ready_i && dst_valid_reg) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  always_comb begin
    src_ready_o = src_ready_reg;
    dst_data_o = dst_data_reg;
    dst_valid_o = dst_valid_reg;
  end

  // CDC handshake
  logic src_handshake;
  logic dst_handshake;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_handshake <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        src_handshake <= 1'b1;
      end else if (~src_valid_i) begin
        src_handshake <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_handshake <= 1'b0;
    end else begin
      if (dst_ready_i && dst_valid_reg) begin
        dst_handshake <= 1'b1;
      end else if (~dst_ready_i) begin
        dst_handshake <= 1'b0;
      end
    end
  end

  // Gray code handshake
  logic [1:0] src_gray;
  logic [1:0] dst_gray;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_gray <= 2'b00;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        src_gray <= src_gray + 1'b1;
      end else if (~src_valid_i) begin
        src_gray <= 2'b00;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_gray <= 2'b00;
    end else begin
      if (dst_ready_i && dst_valid_reg) begin
        dst_gray <= dst_gray + 1'b1;
      end else if (~dst_ready_i) begin
        dst_gray <= 2'b00;
      end
    end
  end

  // CDC synchronizer
  logic [1:0] src_sync;
  logic [1:0] dst_sync;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_sync <= 2'b00;
    end else begin
      src_sync[0] <= src_handshake;
      src_sync[1] <= src_sync[0];
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_sync <= 2'b00;
    end else begin
      dst_sync[0] <= dst_handshake;
      dst_sync[1] <= dst_sync[0];
    end
  end

endmodule
