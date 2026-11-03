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
  wire             fifo_a_to_b_full;
  wire             fifo_a_to_b_afull;
  wire             fifo_a_to_b_empty;
  wire             fifo_a_to_b_aempty;

  wire [DSIZE-1:0] fifo_b_to_a_rdata;
  wire             fifo_b_to_a_full;
  wire             fifo_b_to_a_afull;
  wire             fifo_b_to_a_empty;
  wire             fifo_b_to_a_aempty;

  fifo_async #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_a_to_b (
       .a_clk    (a_clk),
       .a_rst_n  (a_rst_n),
       .a_winc   (a_dir ? a_winc : 1'b0),
       .a_wdata  (a_dir ? a_wdata : {DSIZE{1'b0}}),
       .b_clk    (b_clk),
       .b_rst_n  (b_rst_n),
       .b_rinc   (b_dir ? 1'b0 : b_rinc),
       .b_rdata  (fifo_a_to_b_rdata),
       .b_full   (fifo_a_to_b_full),
       .b_afull  (fifo_a_to_b_afull),
       .b_empty  (fifo_a_to_b_empty),
       .b_aempty (fifo_a_to_b_aempty)
       );

  fifo_async #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_b_to_a (
       .a_clk    (b_clk),
       .a_rst_n  (b_rst_n),
       .a_winc   (b_dir ? b_winc : 1'b0),
       .a_wdata  (b_dir ? b_wdata : {DSIZE{1'b0}}),
       .b_clk    (a_clk),
       .b_rst_n  (a_rst_n),
       .b_rinc   (a_dir ? 1'b0 : a_rinc),
       .b_rdata  (fifo_b_to_a_rdata),
       .b_full   (fifo_b_to_a_full),
       .b_afull  (fifo_b_to_a_afull),
       .b_empty  (fifo_b_to_a_empty),
       .b_aempty (fifo_b_to_a_aempty)
       );

  assign a_rdata  = a_dir ? {DSIZE{1'b0}} : fifo_b_to_a_rdata;
  assign a_full   = a_dir ? fifo_a_to_b_full   : 1'b0;
  assign a_afull  = a_dir ? fifo_a_to_b_afull  : 1'b0;
  assign a_empty  = a_dir ? 1'b0             : fifo_b_to_a_empty;
  assign a_aempty = a_dir ? 1'b0             : fifo_b_to_a_aempty;

  assign b_rdata  = b_dir ? {DSIZE{1'b0}} : fifo_a_to_b_rdata;
  assign b_full   = b_dir ? fifo_b_to_a_full   : 1'b0;
  assign b_afull  = b_dir ? fifo_b_to_a_afull  : 1'b0;
  assign b_empty  = b_dir ? 1'b0             : fifo_a_to_b_empty;
  assign b_aempty = b_dir ? 1'b0             : fifo_a_to_b_aempty;

endmodule

module fifo_async
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty
       );

  localparam DEPTH = 1 << ASIZE;

  reg [ASIZE-1:0] a_wptr, a_rptr;
  reg [ASIZE-1:0] b_wptr_gray, b_rptr_gray;
  reg [ASIZE-1:0] b_wptr_sync, b_rptr_sync;
  reg [ASIZE-1:0] a_wptr_gray, a_rptr_gray;
  reg [ASIZE-1:0] a_wptr_sync, a_rptr_sync;

  reg [DSIZE-1:0] fifo_mem [0:DEPTH-1];

  reg a_full_flag, a_afull_flag;
  reg b_empty_flag, b_aempty_flag;

  // Gray code conversion
  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    bin2gray = bin ^ (bin >> 1);
  endfunction

  // Binary code conversion
  function [ASIZE-1:0] gray2bin;
    input [ASIZE-1:0] gray;
    integer i;
    reg [ASIZE-1:0] bin;
    bin = gray;
    for (i = ASIZE-2; i >= 0; i = i-1) begin
      bin[i] = bin[i+1] ^ gray[i];
    end
    gray2bin = bin;
  endfunction

  // Write pointer logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wptr <= 0;
      a_wptr_gray <= 0;
    end else if (a_winc && !a_full_flag) begin
      a_wptr <= a_wptr + 1;
      a_wptr_gray <= bin2gray(a_wptr + 1);
    end
  end

  // Read pointer logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rptr <= 0;
      b_rptr_gray <= 0;
    end else if (b_rinc && !b_empty_flag) begin
      b_rptr <= b_rptr + 1;
      b_rptr_gray <= bin2gray(b_rptr + 1);
    end
  end

  // Write pointer synchronization
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wptr_sync <= 0;
    end else begin
      b_wptr_sync <= b_wptr_gray;
    end
  end

  // Read pointer synchronization
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rptr_sync <= 0;
    end else begin
      a_rptr_sync <= a_rptr_gray;
    end
  end

  // Write to FIFO
  always @(posedge a_clk) begin
    if (a_winc && !a_full_flag) begin
      fifo_mem[a_wptr] <= a_wdata;
    end
  end

  // Read from FIFO
  always @(posedge b_clk) begin
    if (b_rinc && !b_empty_flag) begin
      b_rdata <= fifo_mem[b_rptr];
    end
  end

  // Full flag logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_flag <= 0;
      a_afull_flag <= 0;
    end else begin
      a_full_flag <= (bin2gray(a_wptr + 1) == a_rptr_sync);
      a_afull_flag <= (bin2gray(a_wptr + 2) == a_rptr_sync);
    end
  end

  // Empty flag logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_empty_flag <= 1;
      b_aempty_flag <= 1;
    end else begin
      b_empty_flag <= (b_wptr_sync == b_rptr_gray);
      b_aempty_flag <= (b_wptr_sync == bin2gray(b_rptr_gray + 1));
    end
  end

  // Full/Empty outputs
  assign b_full = a_full_flag;
  assign b_afull = a_afull_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_aempty_flag;

endmodule
