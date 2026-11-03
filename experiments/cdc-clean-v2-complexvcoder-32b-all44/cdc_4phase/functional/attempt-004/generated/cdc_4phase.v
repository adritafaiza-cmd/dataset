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
  logic [WIDTH-1:0] async_fifo_data;
  logic async_fifo_valid;
  logic async_fifo_ready;

  // Instantiate the async_fifo module
  async_fifo #(
    .WIDTH(WIDTH)
  ) async_fifo_inst (
    .rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .dst_clk_i(dst_clk_i),
    .data_o(async_fifo_data),
    .valid_o(async_fifo_valid),
    .ready_i(async_fifo_ready)
  );

  // Destination domain logic
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= SEND_RESET_MSG ? RESET_MSG : '0;
      dst_valid_reg <= SEND_RESET_MSG;
    end else begin
      if (async_fifo_valid && async_fifo_ready) begin
        dst_data_reg <= async_fifo_data;
        dst_valid_reg <= 1'b1;
      end else if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  // Ready signal to the async FIFO
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      if (DECOUPLED || !dst_valid_reg) begin
        dst_ready_reg <= 1'b1;
      end else begin
        dst_ready_reg <= dst_ready_i;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;
  assign async_fifo_ready = dst_ready_reg;

endmodule

module async_fifo #(
  parameter WIDTH = 1
)(
  input  rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  dst_clk_i,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  // FIFO parameters
  localparam DEPTH = 4;
  localparam ADDR_WIDTH = $clog2(DEPTH);

  // FIFO signals
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [ADDR_WIDTH:0] src_wr_ptr, src_rd_ptr_gray, dst_wr_ptr_gray, dst_rd_ptr;
  logic [ADDR_WIDTH:0] src_wr_ptr_gray, dst_wr_ptr;
  logic src_empty, dst_empty, src_full;

  // Gray code conversion
  function automatic [ADDR_WIDTH:0] bin_to_gray;
    input [ADDR_WIDTH:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Source domain logic
  always_ff @(posedge src_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      src_wr_ptr <= '0;
    end else if (valid_i && !src_full) begin
      mem[src_wr_ptr[ADDR_WIDTH-1:0]] <= data_i;
      src_wr_ptr <= src_wr_ptr + 1;
    end
  end

  assign src_wr_ptr_gray = bin_to_gray(src_wr_ptr);
  assign src_full = (src_wr_ptr_gray[ADDR_WIDTH-1:0] == dst_rd_ptr[ADDR_WIDTH-1:0]) && (src_wr_ptr_gray[ADDR_WIDTH] != dst_rd_ptr[ADDR_WIDTH]);

  // Destination domain logic
  always_ff @(posedge dst_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      dst_rd_ptr <= '0;
    end else if (valid_o && ready_i) begin
      dst_rd_ptr <= dst_rd_ptr + 1;
    end
  end

  assign dst_rd_ptr_gray = bin_to_gray(dst_rd_ptr);
  assign dst_empty = (dst_wr_ptr_gray[ADDR_WIDTH-1:0] == dst_rd_ptr_gray[ADDR_WIDTH-1:0]) && (dst_wr_ptr_gray[ADDR_WIDTH] == dst_rd_ptr_gray[ADDR_WIDTH]);

  // Cross-domain signals
  always_ff @(posedge src_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      dst_wr_ptr_gray <= '0;
    end else begin
      dst_wr_ptr_gray <= dst_wr_ptr_gray;
    end
  end

  always_ff @(posedge dst_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      src_rd_ptr_gray <= '0;
    end else begin
      src_rd_ptr_gray <= src_rd_ptr_gray;
    end
  end

  // Output assignments
  assign valid_o = !dst_empty;
  assign data_o = mem[dst_rd_ptr[ADDR_WIDTH-1:0]];
  assign ready_o = !src_full;

endmodule
