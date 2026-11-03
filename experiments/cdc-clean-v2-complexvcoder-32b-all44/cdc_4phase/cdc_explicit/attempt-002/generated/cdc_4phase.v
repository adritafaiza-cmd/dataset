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
  logic src_valid_synced;
  logic dst_ready_synced;
  logic fifo_full;
  logic fifo_empty;

  // Instantiate sync_register for src_valid_i to dst_clk_i
  sync_register src_sync_valid (
    .async_in(src_valid_i),
    .sync_out(src_valid_synced),
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni)
  );

  // Instantiate sync_register for dst_ready_i to src_clk_i
  sync_register dst_sync_ready (
    .async_in(dst_ready_i),
    .sync_out(dst_ready_synced),
    .clk(src_clk_i),
    .rst_n(src_rst_ni)
  );

  // Instantiate sync_fifo for data transfer
  sync_fifo #(.WIDTH(WIDTH)) async_fifo (
    .wr_clk(src_clk_i),
    .wr_rst_n(src_rst_ni),
    .wr_en(src_valid_i),
    .din(src_data_i),
    .full(fifo_full),
    .rd_clk(dst_clk_i),
    .rd_rst_n(dst_rst_ni),
    .rd_en(dst_ready_i),
    .dout(dst_data_o),
    .empty(fifo_empty)
  );

  // Source ready output
  assign src_ready_o = dst_ready_synced & ~fifo_full;

  // Destination valid output
  assign dst_valid_o = src_valid_synced & ~fifo_empty;

endmodule

// Sync register module
module sync_register (
  input  async_in,
  output sync_out,
  input  clk,
  input  rst_n
);

  // Internal registers for synchronization
  logic sync_reg1;
  logic sync_reg2;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_reg1 <= 1'b0;
      sync_reg2 <= 1'b0;
    end else begin
      sync_reg1 <= async_in;
      sync_reg2 <= sync_reg1;
    end
  end

  assign sync_out = sync_reg2;

endmodule

// Sync FIFO module
module sync_fifo #(
  parameter WIDTH = 1
)(
  input  wr_clk,
  input  wr_rst_n,
  input  wr_en,
  input  [WIDTH-1:0] din,
  output full,
  input  rd_clk,
  input  rd_rst_n,
  input  rd_en,
  output [WIDTH-1:0] dout,
  output empty
);

  localparam DEPTH = 4; // 2^2 = 4 entries for 4-phase
  localparam ADDR_WIDTH = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [DEPTH-1:0];
  logic [ADDR_WIDTH:0] wr_ptr;
  logic [ADDR_WIDTH:0] rd_ptr;
  logic [ADDR_WIDTH:0] wr_ptr_gray;
  logic [ADDR_WIDTH:0] rd_ptr_gray;
  logic [ADDR_WIDTH:0] wr_ptr_gray_sync;
  logic [ADDR_WIDTH:0] rd_ptr_gray_sync;

  // Write pointer and memory update
  always_ff @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
      wr_ptr <= '0;
      wr_ptr_gray <= '0;
    end else if (wr_en & ~full) begin
      mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
    end
  end

  // Read pointer update
  always_ff @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
      rd_ptr <= '0;
      rd_ptr_gray <= '0;
    end else if (rd_en & ~empty) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
    end
  end

  // Gray code synchronization
  sync_register wr_ptr_gray_sync_reg (
    .async_in(wr_ptr_gray),
    .sync_out(wr_ptr_gray_sync),
    .clk(rd_clk),
    .rst_n(rd_rst_n)
  );

  sync_register rd_ptr_gray_sync_reg (
    .async_in(rd_ptr_gray),
    .sync_out(rd_ptr_gray_sync),
    .clk(wr_clk),
    .rst_n(wr_rst_n)
  );

  // Full and empty flags
  assign full = (wr_ptr_gray_sync[ADDR_WIDTH] != rd_ptr_gray[ADDR_WIDTH]) & (wr_ptr_gray_sync[ADDR_WIDTH-1:0] == rd_ptr_gray[ADDR_WIDTH-1:0]);
  assign empty = (wr_ptr_gray_sync == rd_ptr_gray_sync);

  // Data output
  assign dout = mem[rd_ptr[ADDR_WIDTH-1:0]];

endmodule
