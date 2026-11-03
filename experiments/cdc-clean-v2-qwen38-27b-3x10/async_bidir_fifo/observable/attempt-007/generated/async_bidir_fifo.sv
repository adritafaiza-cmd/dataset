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

  localparam DEPTH = 1 << ASIZE;
  localparam HALF  = DEPTH / 2;
  localparam AFULL_THRESH  = DEPTH - 2;
  localparam AEMPTY_THRESH = 1;

  // A-side FIFO (A writes, B reads)
  wire [ASIZE:0] a_wr_ptr;
  wire [ASIZE:0] a_rd_ptr;
  wire [ASIZE:0] a_rd_ptr_gray;
  wire [ASIZE:0] a_rd_ptr_gray_sync;
  wire [ASIZE:0] a_rd_ptr_gray_sync2;
  wire [ASIZE:0] a_rd_ptr_bin;
  wire [ASIZE:0] a_rd_ptr_bin_sync;
  wire [ASIZE:0] a_rd_ptr_bin_sync2;
  wire [ASIZE:0] a_wr_ptr_gray;
  wire [ASIZE:0] a_wr_ptr_gray_sync;
  wire [ASIZE:0] a_wr_ptr_gray_sync2;
  wire [ASIZE:0] a_wr_ptr_bin;
  wire [ASIZE:0] a_wr_ptr_bin_sync;
  wire [ASIZE:0] a_wr_ptr_bin_sync2;

  wire a_full;
  wire a_empty;
  wire a_afull;
  wire a_aempty;

  // B-side FIFO (B writes, A reads)
  wire [ASIZE:0] b_wr_ptr;
  wire [ASIZE:0] b_rd_ptr;
  wire [ASIZE:0] b_rd_ptr_gray;
  wire [ASIZE:0] b_rd_ptr_gray_sync;
  wire [ASIZE:0] b_rd_ptr_gray_sync2;
  wire [ASIZE:0] b_rd_ptr_bin;
  wire [ASIZE:0] b_rd_ptr_bin_sync;
  wire [ASIZE:0] b_rd_ptr_bin_sync2;
  wire [ASIZE:0] b_wr_ptr_gray;
  wire [ASIZE:0] b_wr_ptr_gray_sync;
  wire [ASIZE:0] b_wr_ptr_gray_sync2;
  wire [ASIZE:0] b_wr_ptr_bin;
  wire [ASIZE:0] b_wr_ptr_bin_sync;
  wire [ASIZE:0] b_wr_ptr_bin_sync2;

  wire b_full;
  wire b_empty;
  wire b_afull;
  wire b_aempty;

  // A-side FIFO memory
  reg [DSIZE-1:0] a_mem [0:DEPTH-1];

  // B-side FIFO memory
  reg [DSIZE-1:0] b_mem [0:DEPTH-1];

  // A-side write pointer (A clock domain)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wr_ptr <= {1'b0, {ASIZE{1'b0}}};
    else if (a_winc && !a_full)
      a_wr_ptr <= a_wr_ptr + 1'b1;
  end

  // A-side read pointer (B clock domain)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      a_rd_ptr <= {1'b0, {ASIZE{1'b0}}};
    else if (b_rinc && !a_empty)
      a_rd_ptr <= a_rd_ptr + 1'b1;
  end

  // A-side write data
  always @(posedge a_clk) begin
    if (a_winc && !a_full)
      a_mem[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
  end

  // A-side read data (B clock domain)
  assign a_rdata = a_mem[a_rd_ptr[ASIZE-1:0]];

  // Gray code conversions
  assign a_wr_ptr_gray = a_wr_ptr ^ (a_wr_ptr >> 1);
  assign a_rd_ptr_gray = a_rd_ptr ^ (a_rd_ptr >> 1);

  // Synchronize A write pointer gray to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync  <= {1'b0, {ASIZE{1'b0}}};
      a_wr_ptr_gray_sync2 <= {1'b0, {ASIZE{1'b0}}};
    end else begin
      a_wr_ptr_gray_sync  <= a_wr_ptr_gray;
      a_wr_ptr_gray_sync2 <= a_wr_ptr_gray_sync;
    end
  end

  // Synchronize A read pointer gray to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr_gray_sync  <= {1'b0, {ASIZE{1'b0}}};
      a_rd_ptr_gray_sync2 <= {1'b0, {ASIZE{1'b0}}};
    end else begin
      a_rd_ptr_gray_sync  <= a_rd_ptr_gray;
      a_rd_ptr_gray_sync2 <= a_rd_ptr_gray_sync;
    end
  end

  // Binary conversions for full/empty
  // Gray to binary
  function [ASIZE:0] gray2bin;
    input [ASIZE:0] gray;
    integer i;
    begin
      gray2bin[ASIZE] = gray[ASIZE];
      for (i = ASIZE-1; i >= 0; i = i-1)
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
  endfunction

  assign a_wr_ptr_bin = gray2bin(a_wr_ptr_gray);
  assign a_rd_ptr_bin = gray2bin(a_rd_ptr_gray);

  // Synchronize A write pointer binary to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_bin_sync  <= {1'b0, {ASIZE{1'b0}}};
      a_wr_ptr_bin_sync2 <= {1'b0, {ASIZE{1'b0}}};
    end else begin
      a_wr_ptr_bin_sync  <= a_wr_ptr_bin;
      a_wr_ptr_bin_sync2 <= a_wr_ptr_bin_sync;
    end
  end

  // Synchronize A read pointer binary to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rd_ptr_bin_sync  <= {1'b0, {ASIZE{1'b0}}};
      a_rd_ptr_bin_sync2 <= {1'b0, {ASIZE{1'b0}}};
    end else begin
      a_rd_ptr_bin_sync  <= a_rd_ptr_bin;
      a_rd_ptr_bin_sync2 <= a_rd_ptr_bin_sync;
    end
  end

  // A-side full (A domain): write pointer caught up to read pointer
  assign a_full = (a_wr_ptr_bin_sync2 == a_rd_ptr_bin_sync2) && (a_wr_ptr[ASIZE] != a_rd_ptr_bin_sync2[ASIZE]);

  // A-side empty (B domain): read pointer caught up to write pointer
  assign a_empty = (a_rd_ptr_bin_sync2 == a_wr_ptr_bin_sync2) && (a_rd_ptr[ASIZE] != a_wr_ptr_bin_sync2[ASIZE]);

  // A-side almost full (A domain)
  assign a_afull = (a_wr_ptr_bin_sync2 - a_rd_ptr_bin_sync2) >= AFULL_THRESH;

  // A-side almost empty (B domain)
  assign a_aempty = (a_wr_ptr_bin_sync2 - a_rd_ptr_bin_sync2) <= AEMPTY_THRESH;

  // B-side write pointer (B clock domain)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wr_ptr <= {1'b0, {ASIZE{1'b0}}};
    else if (b_winc && !b_full)
      b_wr_ptr <= b_wr_ptr + 1'b1;
  end

  // B-side read pointer (A clock domain)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      b_rd_ptr <= {1'b0, {ASIZE{1'b0}}};
    else if (a_rinc && !b_empty)
      b_rd_ptr <= b_rd_ptr + 1'b1;
  end

  // B-side write data
  always @(posedge b_clk) begin
    if (b_winc && !b_full)
      b_mem[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
  end

  // B-side read data (A clock domain)
  assign b_rdata = b_mem[b_rd_ptr[ASIZE-1:0]];

  // Gray code conversions for B
  assign b_wr_ptr_gray = b_wr_ptr ^ (b_wr_ptr >> 1);
  assign b_rd_ptr_gray = b_rd_ptr ^ (b_rd_ptr >> 1);

  // Synchronize B write pointer gray to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync  <= {1'b0, {ASIZE{1'b0}}};
      b_wr_ptr_gray_sync2 <= {1'b0, {ASIZE{1'b0}}};
    end else begin
      b_wr_ptr_gray_sync  <= b_wr_ptr_gray;
      b_wr_ptr_gray_sync2 <= b_wr_ptr_gray_sync;
    end
  end

  // Synchronize B read pointer gray to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rd_ptr_gray_sync  <= {1'b0, {ASIZE{1'b0}}};
      b_rd_ptr_gray_sync2 <= {1'b0, {ASIZE{1'b0}}};
    end else begin
      b_rd_ptr_gray_sync  <= b_rd_ptr_gray;
      b_rd_ptr_gray_sync2 <= b_rd_ptr_gray_sync;
    end
  end

  assign b_wr_ptr_bin = gray2bin(b_wr_ptr_gray);
  assign b_rd_ptr_bin = gray2bin(b_rd_ptr_gray);

  // Synchronize B write pointer binary to A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_bin_sync  <= {1'b0, {ASIZE{1'b0}}};
      b_wr_ptr_bin_sync2 <= {1'b0, {ASIZE{1'b0}}};
    end else begin
      b_wr_ptr_bin_sync  <= b_wr_ptr_bin;
      b_wr_ptr_bin_sync2 <= b_wr_ptr_bin_sync;
    end
  end

  // Synchronize B read pointer binary to B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rd_ptr_bin_sync  <= {1'b0, {ASIZE{1'b0}}};
      b_rd_ptr_bin_sync2 <= {1'b0, {ASIZE{1'b0}}};
    end else begin
      b_rd_ptr_bin_sync  <= b_rd_ptr_bin;
      b_rd_ptr_bin_sync2 <= b_rd_ptr_bin_sync;
    end
  end

  // B-side full (B domain)
  assign b_full = (b_wr_ptr_bin_sync2 == b_rd_ptr_bin_sync2) && (b_wr_ptr[ASIZE] != b_rd_ptr_bin_sync2[ASIZE]);

  // B-side empty (A domain)
  assign b_empty = (b_rd_ptr_bin_sync2 == b_wr_ptr_bin_sync2) && (b_rd_ptr[ASIZE] != b_wr_ptr_bin_sync2[ASIZE]);

  // B-side almost full (B domain)
  assign b_afull = (b_wr_ptr_bin_sync2 - b_rd_ptr_bin_sync2) >= AFULL_THRESH;

  // B-side almost empty (A domain)
  assign b_aempty = (b_wr_ptr_bin_sync2 - b_rd_ptr_bin_sync2) <= AEMPTY_THRESH;

endmodule
