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

  // Phase detector for source clock
  phase_detector #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) pd_src (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .phase_o() // phase_o is not used in this implementation
  );

  // Phase detector for destination clock
  phase_detector #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) pd_dst (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .phase_o() // phase_o is not used in this implementation
  );

  // Asynchronous FIFO for data transfer
  fifo #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) async_fifo (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_data_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .dst_ready_i(dst_ready_i),
    .dst_data_o(dst_data_o),
    .dst_valid_o(dst_valid_o)
  );

endmodule

module phase_detector #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  rst_ni,
  input  clk_i,
  output reg [1:0] phase_o
);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      phase_o <= 2'b00;
    end else begin
      phase_o <= phase_o + 1;
    end
  end

endmodule

module fifo #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output reg src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_ready_i,
  output reg [WIDTH-1:0] dst_data_o,
  output reg dst_valid_o
);

  localparam DEPTH = 4; // Depth of the FIFO
  localparam ADDR_WIDTH = $clog2(DEPTH);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [ADDR_WIDTH:0] src_wr_ptr, src_wr_ptr_gray, src_wr_ptr_gray_nxt;
  reg [ADDR_WIDTH:0] src_rd_ptr, src_rd_ptr_gray, src_rd_ptr_gray_nxt;
  reg [ADDR_WIDTH:0] dst_wr_ptr, dst_wr_ptr_gray, dst_wr_ptr_gray_nxt;
  reg [ADDR_WIDTH:0] dst_rd_ptr, dst_rd_ptr_gray, dst_rd_ptr_gray_nxt;

  // Gray code conversion
  function [ADDR_WIDTH:0] bin_to_gray;
    input [ADDR_WIDTH:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Binary conversion
  function [ADDR_WIDTH:0] gray_to_bin;
    input [ADDR_WIDTH:0] gray;
    integer i;
    reg [ADDR_WIDTH:0] bin;
    bin = gray;
    for (i = ADDR_WIDTH-1; i > 0; i = i - 1) begin
      bin[i-1] = bin[i] ^ bin[i-1];
    end
    gray_to_bin = bin;
  endfunction

  // Write pointer logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_wr_ptr <= '0;
      src_wr_ptr_gray <= '0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_wr_ptr <= src_wr_ptr + 1;
        src_wr_ptr_gray <= bin_to_gray(src_wr_ptr + 1);
      end
    end
  end

  // Read pointer logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_rd_ptr <= '0;
      dst_rd_ptr_gray <= '0;
    end else begin
      if (dst_valid_o && dst_ready_i) begin
        dst_rd_ptr <= dst_rd_ptr + 1;
        dst_rd_ptr_gray <= bin_to_gray(dst_rd_ptr + 1);
      end
    end
  end

  // FIFO full and empty flags
  wire src_full = src_wr_ptr_gray_nxt[ADDR_WIDTH] != src_rd_ptr_gray[ADDR_WIDTH] &&
                  src_wr_ptr_gray_nxt[ADDR_WIDTH-1:0] == src_rd_ptr_gray[ADDR_WIDTH-1:0];
  wire src_empty = src_wr_ptr_gray == src_rd_ptr_gray;

  // FIFO write logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_wr_ptr_gray_nxt <= '0;
    end else begin
      src_wr_ptr_gray_nxt <= src_wr_ptr_gray;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      mem[gray_to_bin(src_wr_ptr_gray)] <= RESET_MSG;
    end else if (src_valid_i && src_ready_o) begin
      mem[gray_to_bin(src_wr_ptr_gray)] <= src_data_i;
    end
  end

  // FIFO read logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_rd_ptr_gray_nxt <= '0;
    end else begin
      dst_rd_ptr_gray_nxt <= dst_rd_ptr_gray;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= RESET_MSG;
      dst_valid_o <= 0;
    end else begin
      if (dst_ready_i && dst_valid_o) begin
        dst_rd_ptr <= dst_rd_ptr + 1;
        dst_rd_ptr_gray <= bin_to_gray(dst_rd_ptr + 1);
        dst_data_o <= mem[gray_to_bin(dst_rd_ptr_gray)];
        dst_valid_o <= !src_empty;
      end else if (!dst_valid_o && !src_empty) begin
        dst_data_o <= mem[gray_to_bin(dst_rd_ptr_gray)];
        dst_valid_o <= 1;
      end else if (dst_valid_o && !dst_ready_i) begin
        dst_data_o <= dst_data_o;
        dst_valid_o <= dst_valid_o;
      end
    end
  end

  // Source ready signal
  always_comb begin
    if (DECOUPLED) begin
      src_ready_o = ~src_full;
    end else begin
      src_ready_o = ~src_full & dst_ready_i;
    end
  end

endmodule
