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
  fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_a_to_b (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc & a_dir),
    .wdata(a_wdata),
    .clk_out(b_clk),
    .rinc(b_rinc & ~b_dir),
    .rdata(b_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

  // FIFO from b_clk to a_clk
  fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_b_to_a (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc & b_dir),
    .wdata(b_wdata),
    .clk_out(a_clk),
    .rinc(a_rinc & ~a_dir),
    .rdata(a_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

endmodule

module fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              clk_out,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  localparam DEPTH = 1 << ASIZE;
  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE:0] wr_ptr, rd_ptr;
  reg [ASIZE:0] wr_ptr_gray, rd_ptr_gray;
  reg [ASIZE:0] rd_ptr_gray_sync;

  // Gray code conversion functions
  function [ASIZE:0] bin_to_gray;
    input [ASIZE:0] bin;
    bin_to_gray = (bin >> 1) ^ bin;
  endfunction

  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray;
    for (i = ASIZE; i > 0; i = i - 1) begin
      bin[i-1] = bin[i] ^ bin[i-1];
    end
    gray_to_bin = bin;
  endfunction

  // Write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (winc && !full) begin
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
    end
  end

  // Read pointer logic
  always @(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rinc && !empty) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
    end
  end

  // Synchronize read pointer gray code to write clock domain
  reg [ASIZE:0] rd_ptr_gray_sync1;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray_sync1 <= 0;
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync <= rd_ptr_gray_sync1;
    end
  end

  // Full and almost full flags
  assign full = (wr_ptr_gray == {~rd_ptr_gray_sync[ASIZE], rd_ptr_gray_sync[ASIZE-1:0]});
  assign afull = (wr_ptr_gray == {~rd_ptr_gray_sync[ASIZE-1], rd_ptr_gray_sync[ASIZE-2:0], ~rd_ptr_gray_sync[ASIZE]});

  // Read pointer logic
  reg [ASIZE:0] wr_ptr_gray_sync;
  reg [ASIZE:0] wr_ptr_gray_sync1;
  always @(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_sync1 <= 0;
      wr_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync <= wr_ptr_gray_sync1;
    end
  end

  // Empty and almost empty flags
  assign empty = (rd_ptr_gray == {~wr_ptr_gray_sync[ASIZE], wr_ptr_gray_sync[ASIZE-1:0]});
  assign aempty = (rd_ptr_gray == {~wr_ptr_gray_sync[ASIZE-1], wr_ptr_gray_sync[ASIZE-2:0], ~wr_ptr_gray_sync[ASIZE]});

  // Write data to memory
  always @(posedge clk) begin
    if (winc && !full) begin
      mem[wr_ptr[ASIZE-1:0]] <= wdata;
    end
  end

  // Read data from memory
  reg [DSIZE-1:0] rdata_reg;
  always @(posedge clk_out) begin
    if (rinc && !empty) begin
      rdata_reg <= mem[rd_ptr[ASIZE-1:0]];
    end
  end

  // Output read data
  assign rdata = rdata_reg;

endmodule
