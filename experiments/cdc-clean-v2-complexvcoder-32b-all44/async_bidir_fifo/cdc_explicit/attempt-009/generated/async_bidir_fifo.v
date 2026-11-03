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

  // Asynchronous FIFO from a_clk to b_clk
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_a_to_b (
       .clk_wr    (a_clk),
       .rst_n_wr  (a_rst_n),
       .wr_en     (a_winc & a_dir),
       .wr_data   (a_wdata),
       .clk_rd    (b_clk),
       .rst_n_rd  (b_rst_n),
       .rd_en     (b_rinc & b_dir),
       .rd_data   (b_rdata),
       .full      (b_full),
       .afull     (b_afull),
       .empty     (b_empty),
       .aempty    (b_aempty)
       );

  // Asynchronous FIFO from b_clk to a_clk
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_b_to_a (
       .clk_wr    (b_clk),
       .rst_n_wr  (b_rst_n),
       .wr_en     (b_winc & b_dir),
       .wr_data   (b_wdata),
       .clk_rd    (a_clk),
       .rst_n_rd  (a_rst_n),
       .rd_en     (a_rinc & a_dir),
       .rd_data   (a_rdata),
       .full      (a_full),
       .afull     (a_afull),
       .empty     (a_empty),
       .aempty    (a_aempty)
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
       input wire [DSIZE-1:0]  wr_data,
       input wire              clk_rd,
       input wire              rst_n_rd,
       input wire              rd_en,
       output wire [DSIZE-1:0] rd_data,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  localparam DEPTH = 1 << ASIZE;
  reg [DSIZE-1:0] mem [DEPTH-1:0];
  reg [ASIZE:0] wr_ptr, rd_ptr;
  reg [ASIZE:0] wr_ptr_gray, rd_ptr_gray;
  reg [ASIZE:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
  reg [ASIZE:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

  // Gray code conversion
  function [ASIZE:0] bin2gray;
    input [ASIZE:0] bin;
    bin2gray = bin ^ (bin >> 1);
  endfunction

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      wr_ptr <= 0;
    end else if (wr_en && !full) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      rd_ptr <= 0;
    end else if (rd_en && !empty) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Gray code conversion and synchronization for CDC
  assign wr_ptr_gray = bin2gray(wr_ptr);
  assign rd_ptr_gray = bin2gray(rd_ptr);

  // Synchronize wr_ptr_gray to read domain
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      wr_ptr_gray_sync1 <= 0;
      wr_ptr_gray_sync2 <= 0;
    end else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
  end

  // Synchronize rd_ptr_gray to write domain
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      rd_ptr_gray_sync1 <= 0;
      rd_ptr_gray_sync2 <= 0;
    end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
  end

  // Read data output
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      rd_data <= 0;
    end else if (rd_en && !empty) begin
      rd_data <= mem[rd_ptr[ASIZE-1:0]];
    end
  end

  // Write data to memory
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr && wr_en && !full) begin
      mem[wr_ptr[ASIZE-1:0]] <= wr_data;
    end
  end

  // Full and almost full flags
  wire [ASIZE:0] wr_ptr_bin_sync2;
  wire [ASIZE:0] rd_ptr_bin_sync2;

  // Binary conversion for full/afull logic
  function [ASIZE:0] gray2bin;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray[ASIZE];
    for (i = ASIZE-1; i >= 0; i = i - 1) begin
      bin[i] = bin[i+1] ^ gray[i];
    end
    gray2bin = bin;
  endfunction

  assign wr_ptr_bin_sync2 = gray2bin(wr_ptr_gray_sync2);
  assign rd_ptr_bin_sync2 = gray2bin(rd_ptr_gray_sync2);

  assign full   = (wr_ptr_bin_sync2 == {rd_ptr_bin_sync2[ASIZE], ~rd_ptr_bin_sync2[ASIZE-1:0]});
  assign afull  = (wr_ptr_bin_sync2 == {rd_ptr_bin_sync2[ASIZE], ~rd_ptr_bin_sync2[ASIZE-1:0]} + 1);

  // Empty and almost empty flags
  assign empty  = (wr_ptr_gray_sync2 == rd_ptr_gray_sync2);
  assign aempty = (wr_ptr_gray_sync2 == rd_ptr_gray_sync2 + 1);

endmodule
