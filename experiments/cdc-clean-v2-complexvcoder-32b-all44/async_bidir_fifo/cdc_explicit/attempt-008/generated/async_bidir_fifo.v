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

  wire [DSIZE-1:0] fifo_a_to_b_rdata;
  wire fifo_a_to_b_full;
  wire fifo_a_to_b_afull;
  wire fifo_a_to_b_empty;
  wire fifo_a_to_b_aempty;

  wire [DSIZE-1:0] fifo_b_to_a_rdata;
  wire fifo_b_to_a_full;
  wire fifo_b_to_a_afull;
  wire fifo_b_to_a_empty;
  wire fifo_b_to_a_aempty;

  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_a_to_b (
       .clk_src(a_clk),
       .rst_n_src(a_rst_n),
       .winc(a_winc & a_dir),
       .wdata(a_wdata),
       .clk_dst(b_clk),
       .rst_n_dst(b_rst_n),
       .rinc(b_rinc & ~b_dir),
       .rdata(fifo_a_to_b_rdata),
       .full(fifo_a_to_b_full),
       .afull(fifo_a_to_b_afull),
       .empty(fifo_a_to_b_empty),
       .aempty(fifo_a_to_b_aempty)
       );

  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_b_to_a (
       .clk_src(b_clk),
       .rst_n_src(b_rst_n),
       .winc(b_winc & b_dir),
       .wdata(b_wdata),
       .clk_dst(a_clk),
       .rst_n_dst(a_rst_n),
       .rinc(a_rinc & ~a_dir),
       .rdata(fifo_b_to_a_rdata),
       .full(fifo_b_to_a_full),
       .afull(fifo_b_to_a_afull),
       .empty(fifo_b_to_a_empty),
       .aempty(fifo_b_to_a_aempty)
       );

  assign a_rdata = fifo_b_to_a_rdata;
  assign a_full = fifo_b_to_a_full;
  assign a_afull = fifo_b_to_a_afull;
  assign a_empty = fifo_b_to_a_empty;
  assign a_aempty = fifo_b_to_a_aempty;

  assign b_rdata = fifo_a_to_b_rdata;
  assign b_full = fifo_a_to_b_full;
  assign b_afull = fifo_a_to_b_afull;
  assign b_empty = fifo_a_to_b_empty;
  assign b_aempty = fifo_a_to_b_aempty;

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk_src,
       input wire              rst_n_src,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              clk_dst,
       input wire              rst_n_dst,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [ASIZE:0] wr_ptr;
  reg [ASIZE:0] rd_ptr;
  reg [ASIZE:0] wr_ptr_gray;
  reg [ASIZE:0] rd_ptr_gray;
  reg [ASIZE:0] rd_ptr_gray_sync1;
  reg [ASIZE:0] rd_ptr_gray_sync2;
  reg [ASIZE:0] wr_ptr_gray_sync1;
  reg [ASIZE:0] wr_ptr_gray_sync2;

  always @(posedge clk_src or negedge rst_n_src) begin
    if (!rst_n_src) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (winc && !full) begin
      mem[wr_ptr[ASIZE-1:0]] <= wdata;
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= wr_ptr + 1;
    end
  end

  always @(posedge clk_dst or negedge rst_n_dst) begin
    if (!rst_n_dst) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
      rd_ptr_gray_sync1 <= 0;
      rd_ptr_gray_sync2 <= 0;
      wr_ptr_gray_sync1 <= 0;
      wr_ptr_gray_sync2 <= 0;
    end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;

      if (rinc && !empty) begin
        rd_ptr <= rd_ptr + 1;
        rd_ptr_gray <= rd_ptr + 1;
      end
    end
  end

  assign rdata = mem[rd_ptr[ASIZE-1:0]];
  assign full = (wr_ptr_gray[ASIZE] ^ rd_ptr_gray_sync2[ASIZE]) & (wr_ptr_gray[ASIZE-1:0] == rd_ptr_gray_sync2[ASIZE-1:0]);
  assign afull = (wr_ptr_gray[ASIZE] ^ rd_ptr_gray_sync2[ASIZE]) & (wr_ptr_gray[ASIZE-1:1] == rd_ptr_gray_sync2[ASIZE-1:1]);
  assign empty = (wr_ptr_gray_sync2[ASIZE] ^ rd_ptr_gray[ASIZE]) & (wr_ptr_gray_sync2[ASIZE-1:0] == rd_ptr_gray[ASIZE-1:0]);
  assign aempty = (wr_ptr_gray_sync2[ASIZE] ^ rd_ptr_gray[ASIZE]) & (wr_ptr_gray_sync2[ASIZE-1:1] == rd_ptr_gray[ASIZE-1:1]);

endmodule
