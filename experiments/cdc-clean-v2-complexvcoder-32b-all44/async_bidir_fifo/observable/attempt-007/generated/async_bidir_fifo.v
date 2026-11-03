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
  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_a_to_b (
    .clk_wr(a_clk),
    .rst_n_wr(a_rst_n),
    .clk_rd(b_clk),
    .rst_n_rd(b_rst_n),
    .wr_en(a_winc),
    .wr_data(a_wdata),
    .rd_en(b_rinc),
    .rd_data(b_rdata),
    .full_wr(a_full),
    .afull_wr(a_afull),
    .empty_rd(b_empty),
    .aempty_rd(b_aempty)
  );

  // FIFO from b_clk to a_clk
  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_b_to_a (
    .clk_wr(b_clk),
    .rst_n_wr(b_rst_n),
    .clk_rd(a_clk),
    .rst_n_rd(a_rst_n),
    .wr_en(b_winc),
    .wr_data(b_wdata),
    .rd_en(a_rinc),
    .rd_data(a_rdata),
    .full_wr(b_full),
    .afull_wr(b_afull),
    .empty_rd(a_empty),
    .aempty_rd(a_aempty)
  );

endmodule

module fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk_wr,
       input wire              rst_n_wr,
       input wire              clk_rd,
       input wire              rst_n_rd,
       input wire              wr_en,
       input wire [DSIZE-1:0]  wr_data,
       input wire              rd_en,
       output wire [DSIZE-1:0] rd_data,
       output wire             full_wr,
       output wire             afull_wr,
       output wire             empty_rd,
       output wire             aempty_rd
       );

  localparam DEPTH = 1 << ASIZE;
  localparam PTR_WIDTH = ASIZE + 1;

  reg [DSIZE-1:0] mem [DEPTH-1:0];
  reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
  reg [PTR_WIDTH-1:0] wr_ptr_gray, rd_ptr_gray;
  reg [PTR_WIDTH-1:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

  // Binary to Gray code conversion
  function [PTR_WIDTH-1:0] bin2gray;
    input [PTR_WIDTH-1:0] bin;
    bin2gray = (bin >> 1) ^ bin;
  endfunction

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (wr_en && !full_wr) begin
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= bin2gray(wr_ptr + 1);
    end
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rd_en && !empty_rd) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= bin2gray(rd_ptr + 1);
    end
  end

  // Synchronize write pointer gray code to read domain
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      wr_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Synchronize read pointer gray code to write domain
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // Write data into memory
  always @(posedge clk_wr) begin
    if (wr_en && !full_wr) begin
      mem[wr_ptr[ASIZE-1:0]] <= wr_data;
    end
  end

  // Read data from memory
  always @(posedge clk_rd) begin
    rd_data <= mem[rd_ptr[ASIZE-1:0]];
  end

  // Full flag logic
  assign full_wr = (wr_ptr_gray_sync[PTR_WIDTH-1:1] == rd_ptr_gray[PTR_WIDTH-1:1]) && (wr_ptr_gray_sync[0] != rd_ptr_gray[0]);

  // Almost full flag logic
  assign afull_wr = (wr_ptr_gray_sync[PTR_WIDTH-2:0] == {rd_ptr_gray[PTR_WIDTH-2:0], ~rd_ptr_gray[PTR_WIDTH-1]});

  // Empty flag logic
  assign empty_rd = (wr_ptr_gray[PTR_WIDTH-1:1] == rd_ptr_gray_sync[PTR_WIDTH-1:1]) && (wr_ptr_gray[0] == rd_ptr_gray_sync[0]);

  // Almost empty flag logic
  assign aempty_rd = (wr_ptr_gray[PTR_WIDTH-2:0] == {rd_ptr_gray_sync[PTR_WIDTH-2:0], ~rd_ptr_gray_sync[PTR_WIDTH-1]});

endmodule
