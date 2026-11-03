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

  // FIFO for data transfer from A to B
  fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
    fifo_a_to_b (
      .clk    (a_clk),
      .rst_n  (a_rst_n),
      .winc   (a_winc & a_dir),
      .wdata  (a_wdata),
      .rinc   (b_rinc & ~b_dir),
      .rdata  (b_rdata),
      .full   (b_full),
      .afull  (b_afull),
      .empty  (b_empty),
      .aempty (b_aempty)
    );

  // FIFO for data transfer from B to A
  fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
    fifo_b_to_a (
      .clk    (b_clk),
      .rst_n  (b_rst_n),
      .winc   (b_winc & b_dir),
      .wdata  (b_wdata),
      .rinc   (a_rinc & ~a_dir),
      .rdata  (a_rdata),
      .full   (a_full),
      .afull  (a_afull),
      .empty  (a_empty),
      .aempty (a_aempty)
    );

endmodule

module fifo_side
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

  // Internal signals
  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [ASIZE-1:0] wr_ptr, rd_ptr;
  reg [ASIZE-1:0] wr_ptr_gray, rd_ptr_gray;
  reg [ASIZE-1:0] wr_ptr_gray_next, rd_ptr_gray_next;
  reg [ASIZE-1:0] wr_ptr_bin, rd_ptr_bin;
  reg               full_flag, afull_flag, empty_flag, aempty_flag;

  // Gray code conversion functions
  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    bin2gray = bin ^ (bin >> 1);
  endfunction

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
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rinc && !empty_flag) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= bin2gray(rd_ptr + 1);
    end
  end

  // Cross-domain pointer synchronization
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray_next <= 0;
    end else begin
      rd_ptr_gray_next <= rd_ptr_gray;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_next <= 0;
    end else begin
      wr_ptr_gray_next <= wr_ptr_gray;
    end
  end

  // Binary conversion of synchronized pointers
  always @(*) begin
    rd_ptr_bin = gray2bin(rd_ptr_gray_next);
    wr_ptr_bin = gray2bin(wr_ptr_gray_next);
  end

  // Memory write operation
  always @(posedge clk) begin
    if (winc && !full_flag)
      mem[wr_ptr] <= wdata;
  end

  // Memory read operation
  always @(*) begin
    rdata = mem[rd_ptr];
  end

  // Full flag logic
  always @(*) begin
    full_flag = (wr_ptr_gray_next == bin2gray(rd_ptr_bin + 2**ASIZE - 1));
  end

  // Almost full flag logic
  always @(*) begin
    afull_flag = (wr_ptr_gray_next == bin2gray(rd_ptr_bin + 2**ASIZE - 2));
  end

  // Empty flag logic
  always @(*) begin
    empty_flag = (wr_ptr_gray_next == rd_ptr_gray_next);
  end

  // Almost empty flag logic
  always @(*) begin
    aempty_flag = (wr_ptr_gray_next == bin2gray(rd_ptr_bin + 1));
  end

  // Output flags
  assign full  = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;

endmodule
