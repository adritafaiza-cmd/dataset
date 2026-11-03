module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir
       );

  // FIFO from a_clk to b_clk
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  a_to_b_fifo (
       .src_clk   (a_clk),
       .src_rst_n (a_rst_n),
       .src_winc  (a_winc && a_dir),
       .src_wdata (a_wdata),
       .dst_clk   (b_clk),
       .dst_rst_n (b_rst_n),
       .dst_rinc  (b_rinc && !b_dir),
       .dst_rdata (b_rdata),
       .dst_full  (b_full),
       .dst_afull (b_afull),
       .dst_empty (a_empty),
       .dst_aempty(a_aempty)
       );

  // FIFO from b_clk to a_clk
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  b_to_a_fifo (
       .src_clk   (b_clk),
       .src_rst_n (b_rst_n),
       .src_winc  (b_winc && b_dir),
       .src_wdata (b_wdata),
       .dst_clk   (a_clk),
       .dst_rst_n (a_rst_n),
       .dst_rinc  (a_rinc && !a_dir),
       .dst_rdata (a_rdata),
       .dst_full  (a_full),
       .dst_afull (a_afull),
       .dst_empty (b_empty),
       .dst_aempty(b_aempty)
       );

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              src_clk,
       input wire              src_rst_n,
       input wire              src_winc,
       input wire [DSIZE-1:0]  src_wdata,
       input wire              dst_clk,
       input wire              dst_rst_n,
       input wire              dst_rinc,
       output wire [DSIZE-1:0] dst_rdata,
       output wire             dst_full,
       output wire             dst_afull,
       output wire             dst_empty,
       output wire             dst_aempty
       );

  localparam DEPTH = 1 << ASIZE;
  localparam AWIDTH = ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [AWIDTH:0] src_wr_ptr, src_wr_ptr_gray, src_wr_ptr_gray_sync;
  reg [AWIDTH:0] dst_rd_ptr, dst_rd_ptr_gray, dst_rd_ptr_gray_sync;

  // Write pointer logic
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      src_wr_ptr <= 0;
    end else if (src_winc && !dst_full) begin
      src_wr_ptr <= src_wr_ptr + 1;
    end
  end

  // Gray encoding and synchronization of write pointer
  assign src_wr_ptr_gray = src_wr_ptr ^ (src_wr_ptr >> 1);

  reg [AWIDTH:0] src_wr_ptr_gray_sync_stage1;
  always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      src_wr_ptr_gray_sync_stage1 <= 0;
      src_wr_ptr_gray_sync <= 0;
    end else begin
      src_wr_ptr_gray_sync_stage1 <= src_wr_ptr_gray;
      src_wr_ptr_gray_sync <= src_wr_ptr_gray_sync_stage1;
    end
  end

  // Read pointer logic
  always @(posedge dst_clk or negedge dst_rst_n) begin
    if (!dst_rst_n) begin
      dst_rd_ptr <= 0;
    end else if (dst_rinc && !dst_empty) begin
      dst_rd_ptr <= dst_rd_ptr + 1;
    end
  end

  // Gray encoding and synchronization of read pointer
  assign dst_rd_ptr_gray = dst_rd_ptr ^ (dst_rd_ptr >> 1);

  reg [AWIDTH:0] dst_rd_ptr_gray_sync_stage1;
  always @(posedge src_clk or negedge src_rst_n) begin
    if (!src_rst_n) begin
      dst_rd_ptr_gray_sync_stage1 <= 0;
      dst_rd_ptr_gray_sync <= 0;
    end else begin
      dst_rd_ptr_gray_sync_stage1 <= dst_rd_ptr_gray;
      dst_rd_ptr_gray_sync <= dst_rd_ptr_gray_sync_stage1;
    end
  end

  // Write data to memory
  always @(posedge src_clk) begin
    if (src_winc && !dst_full) begin
      mem[src_wr_ptr[AWIDTH-1:0]] <= src_wdata;
    end
  end

  // Read data from memory
  reg [DSIZE-1:0] dst_rdata_reg;
  always @(posedge dst_clk) begin
    if (dst_rinc && !dst_empty) begin
      dst_rdata_reg <= mem[dst_rd_ptr[AWIDTH-1:0]];
    end
  end

  assign dst_rdata = dst_rdata_reg;

  // Full and almost-full flags
  wire [AWIDTH:0] src_wr_ptr_gray_sync_bin = {src_wr_ptr_gray_sync[AWIDTH], src_wr_ptr_gray_sync[AWIDTH-1:0] ^ src_wr_ptr_gray_sync[AWIDTH:1]};
  wire [AWIDTH:0] dst_rd_ptr_gray_sync_bin = {dst_rd_ptr_gray_sync[AWIDTH], dst_rd_ptr_gray_sync[AWIDTH-1:0] ^ dst_rd_ptr_gray_sync[AWIDTH:1]};

  assign dst_full = (src_wr_ptr_gray_sync_bin == {dst_rd_ptr_gray_sync_bin[AWIDTH], ~dst_rd_ptr_gray_sync_bin[AWIDTH-1:0]});
  assign dst_afull = (src_wr_ptr_gray_sync_bin == {dst_rd_ptr_gray_sync_bin[AWIDTH], ~dst_rd_ptr_gray_sync_bin[AWIDTH-1:0] + 1'b1});

  // Empty and almost-empty flags
  assign dst_empty = (src_wr_ptr_gray_sync_bin == dst_rd_ptr_gray_sync_bin);
  assign dst_aempty = (src_wr_ptr_gray_sync_bin == dst_rd_ptr_gray_sync_bin + 1'b1);

endmodule
