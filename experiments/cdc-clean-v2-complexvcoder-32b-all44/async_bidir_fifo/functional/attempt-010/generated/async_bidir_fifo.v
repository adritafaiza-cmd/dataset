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

  wire a_winc_filtered, b_winc_filtered;
  wire a_rinc_filtered, b_rinc_filtered;

  // Filter winc and rinc based on a_dir and b_dir
  assign a_winc_filtered = a_winc & a_dir;
  assign a_rinc_filtered = a_rinc & ~a_dir;
  assign b_winc_filtered = b_winc & b_dir;
  assign b_rinc_filtered = b_rinc & ~b_dir;

  async_fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) a_to_b_fifo (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc_filtered),
    .wdata(a_wdata),
    .rinc(b_rinc_filtered),
    .rdata(b_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

  async_fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) b_to_a_fifo (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc_filtered),
    .wdata(b_wdata),
    .rinc(a_rinc_filtered),
    .rdata(a_rdata),
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
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  wire [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [ASIZE-1:0] wr_ptr;
  reg [ASIZE-1:0] wr_ptr_gray;
  reg [ASIZE-1:0] rd_ptr;
  reg [ASIZE-1:0] rd_ptr_gray;
  reg [ASIZE-1:0] wr_ptr_gray_sync;
  reg [ASIZE-1:0] rd_ptr_gray_sync;
  reg wr_full;
  reg wr_afull;
  reg rd_empty;
  reg rd_aempty;

  // Write side logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
      wr_ptr_gray_sync <= 0;
      wr_full <= 0;
      wr_afull <= 0;
    end else begin
      if (winc && !wr_full) begin
        mem[wr_ptr] <= wdata;
        wr_ptr <= wr_ptr + 1;
        wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
      end
      wr_ptr_gray_sync <= wr_ptr_gray;
      wr_full <= (wr_ptr_gray_sync == (rd_ptr_gray ^ (rd_ptr_gray >> 1)));
      wr_afull <= (wr_ptr_gray_sync == (rd_ptr_gray ^ (rd_ptr_gray >> 1) ^ (1 << (ASIZE - 1))));
    end
  end

  // Read side logic
  always @(posedge rinc or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
      rd_ptr_gray_sync <= 0;
      rd_empty <= 1;
      rd_aempty <= 1;
    end else begin
      if (rinc && !rd_empty) begin
        rd_ptr <= rd_ptr + 1;
        rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
      end
      rd_ptr_gray_sync <= rd_ptr_gray;
      rd_empty <= (wr_ptr_gray_sync == rd_ptr_gray);
      rd_aempty <= (wr_ptr_gray_sync == (rd_ptr_gray ^ (1 << (ASIZE - 1))));
    end
  end

  // Read data output
  always @(posedge rinc or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= 0;
    end else begin
      if (rinc && !rd_empty) begin
        rdata <= mem[rd_ptr];
      end
    end
  end

  assign full = wr_full;
  assign afull = wr_afull;
  assign empty = rd_empty;
  assign aempty = rd_aempty;

endmodule
