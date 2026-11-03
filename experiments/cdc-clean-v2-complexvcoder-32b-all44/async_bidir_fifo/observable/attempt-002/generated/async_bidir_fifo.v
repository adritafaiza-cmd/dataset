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
  async_fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_a_to_b (
    .clk_wr(a_clk),
    .rst_n_wr(a_rst_n),
    .wr_en(a_winc),
    .din(a_wdata),
    .clk_rd(b_clk),
    .rst_n_rd(b_rst_n),
    .rd_en(b_rinc),
    .dout(b_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

  // FIFO from b_clk to a_clk
  async_fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_b_to_a (
    .clk_wr(b_clk),
    .rst_n_wr(b_rst_n),
    .wr_en(b_winc),
    .din(b_wdata),
    .clk_rd(a_clk),
    .rst_n_rd(a_rst_n),
    .rd_en(a_rinc),
    .dout(a_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk_wr,
       input wire              rst_n_wr,
       input wire              wr_en,
       input wire [DSIZE-1:0]  din,
       input wire              clk_rd,
       input wire              rst_n_rd,
       input wire              rd_en,
       output wire [DSIZE-1:0] dout,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [ASIZE-1:0] wr_ptr, rd_ptr;
  reg [ASIZE-1:0] wr_ptr_gray, rd_ptr_gray;
  reg [ASIZE-1:0] rd_ptr_gray_meta, wr_ptr_gray_meta;
  reg [ASIZE-1:0] rd_ptr_gray_sync, wr_ptr_gray_sync;
  reg full_flag, afull_flag, empty_flag, aempty_flag;

  // Write side logic
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
      full_flag <= 0;
      afull_flag <= 0;
    end else if (wr_en && !full_flag) begin
      mem[wr_ptr] <= din;
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
      full_flag <= (wr_ptr_gray == rd_ptr_gray_sync);
      afull_flag <= (wr_ptr_gray == (rd_ptr_gray_sync ^ (1 << (ASIZE - 1))));
    end
  end

  // Read side logic
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
      empty_flag <= 1;
      aempty_flag <= 1;
    end else if (rd_en && !empty_flag) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
      empty_flag <= (wr_ptr_gray_sync == rd_ptr_gray);
      aempty_flag <= (wr_ptr_gray_sync == (rd_ptr_gray ^ (1 << (ASIZE - 1))));
    end
  end

  // Cross-clock domain synchronization
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      rd_ptr_gray_meta <= 0;
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_meta <= rd_ptr_gray;
      rd_ptr_gray_sync <= rd_ptr_gray_meta;
    end
  end

  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      wr_ptr_gray_meta <= 0;
      wr_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_meta <= wr_ptr_gray;
      wr_ptr_gray_sync <= wr_ptr_gray_meta;
    end
  end

  // Data output
  assign dout = mem[rd_ptr];

  // Full and almost full flags
  assign full = full_flag;
  assign afull = afull_flag;

  // Empty and almost empty flags
  assign empty = empty_flag;
  assign aempty = aempty_flag;

endmodule
