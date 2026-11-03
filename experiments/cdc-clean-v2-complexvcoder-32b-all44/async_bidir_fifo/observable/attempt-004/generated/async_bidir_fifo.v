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

  // FIFO core from a_clk to b_clk
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_core_a_to_b (
    .clk         (a_clk),
    .rst_n       (a_rst_n),
    .winc        (a_winc & a_dir),
    .wdata       (a_wdata),
    .clk_other   (b_clk),
    .rinc        (b_rinc & ~b_dir),
    .rdata       (b_rdata),
    .full        (a_full),
    .afull       (a_afull),
    .empty       (b_empty),
    .aempty      (b_aempty),
    .dir         (a_dir)
  );

  // FIFO core from b_clk to a_clk
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_core_b_to_a (
    .clk         (b_clk),
    .rst_n       (b_rst_n),
    .winc        (b_winc & b_dir),
    .wdata       (b_wdata),
    .clk_other   (a_clk),
    .rinc        (a_rinc & ~a_dir),
    .rdata       (a_rdata),
    .full        (b_full),
    .afull       (b_afull),
    .empty       (a_empty),
    .aempty      (a_aempty),
    .dir         (b_dir)
  );

endmodule

module fifo_core
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              clk_other,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty,
       input wire              dir
       );

  localparam DEPTH = 2**ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE-1:0] wr_ptr, rd_ptr;
  reg [ASIZE-1:0] wr_ptr_gray, rd_ptr_gray;
  reg [ASIZE-1:0] rd_ptr_gray_sync, rd_ptr_sync;
  reg [ASIZE-1:0] wr_ptr_gray_sync, wr_ptr_sync;
  reg               full_flag, afull_flag, empty_flag, aempty_flag;

  // Binary to Gray code conversion
  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    bin2gray = bin ^ (bin >> 1);
  endfunction

  // Gray to Binary code conversion
  function [ASIZE-1:0] gray2bin;
    input [ASIZE-1:0] gray;
    integer i;
    reg [ASIZE-1:0] bin;
    bin = gray;
    for (i = ASIZE-2; i >= 0; i = i - 1)
      bin[i] = bin[i+1] ^ gray[i];
    gray2bin = bin;
  endfunction

  // Write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (winc && !full_flag) begin
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= bin2gray(wr_ptr + 1);
    end
  end

  // Read pointer logic
  always @(posedge clk_other or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rinc && !empty_flag) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= bin2gray(rd_ptr + 1);
    end
  end

  // Synchronize write pointer gray code to read clock domain
  always @(posedge clk_other or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_sync <= 0;
      wr_ptr_sync <= 0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
      wr_ptr_sync <= gray2bin(wr_ptr_gray_sync);
    end
  end

  // Synchronize read pointer gray code to write clock domain
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray_sync <= 0;
      rd_ptr_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
      rd_ptr_sync <= gray2bin(rd_ptr_gray_sync);
    end
  end

  // Memory write operation
  always @(posedge clk) begin
    if (winc && !full_flag)
      mem[wr_ptr] <= wdata;
  end

  // Memory read operation
  assign rdata = mem[rd_ptr_sync];

  // Full flag logic
  assign full_flag = (wr_ptr_gray == (rd_ptr_gray_sync ^ {ASIZE{1'b1}}));
  assign afull_flag = (wr_ptr_gray == (rd_ptr_gray_sync ^ {ASIZE{1'b1}}) && (wr_ptr_gray_sync[ASIZE-1] != wr_ptr_gray[ASIZE-1]));

  // Empty flag logic
  assign empty_flag = (wr_ptr_gray_sync == rd_ptr_gray);
  assign aempty_flag = (wr_ptr_gray_sync == rd_ptr_gray) && (wr_ptr_gray[ASIZE-1] == rd_ptr_gray[ASIZE-1]);

  // Full and almost full flags
  assign full = full_flag;
  assign afull = afull_flag;

  // Empty and almost empty flags
  assign empty = empty_flag;
  assign aempty = aempty_flag;

endmodule
