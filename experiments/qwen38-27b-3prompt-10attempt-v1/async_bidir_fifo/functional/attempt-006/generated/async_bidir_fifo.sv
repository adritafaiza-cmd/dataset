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
  localparam PTR_W = ASIZE + 1;

  // Internal signals for A side
  reg [DSIZE-1:0] mem_a [0:DEPTH-1];
  reg [PTR_W-1:0] a_wr_ptr;
  reg [PTR_W-1:0] a_rd_ptr;
  reg [PTR_W-1:0] a_wr_ptr_gray;
  reg [PTR_W-1:0] a_rd_ptr_gray;

  // Internal signals for B side
  reg [DSIZE-1:0] mem_b [0:DEPTH-1];
  reg [PTR_W-1:0] b_wr_ptr;
  reg [PTR_W-1:0] b_rd_ptr;
  reg [PTR_W-1:0] b_wr_ptr_gray;
  reg [PTR_W-1:0] b_rd_ptr_gray;

  // Gray code conversion functions
  function [PTR_W-1:0] bin2gray;
    input [PTR_W-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  function [PTR_W-1:0] gray2bin;
    input [PTR_W-1:0] gray;
    reg [PTR_W-1:0] bin;
    integer i;
    begin
      bin[PTR_W-1] = gray[PTR_W-1];
      for (i = PTR_W-2; i >= 0; i = i - 1)
        bin[i] = gray[i] ^ bin[i+1];
      gray2bin = bin;
    end
  endfunction

  // A side: write pointer update
  wire a_write_en = a_dir & a_winc & ~a_full;
  wire a_read_en  = ~a_dir & a_rinc & ~a_empty;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {PTR_W{1'b0}};
      a_rd_ptr <= {PTR_W{1'b0}};
    end else begin
      if (a_write_en)
        a_wr_ptr <= a_wr_ptr + 1'b1;
      if (a_read_en)
        a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  // A side: gray code pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr_gray <= {PTR_W{1'b0}};
      a_rd_ptr_gray <= {PTR_W{1'b0}};
    end else begin
      if (a_write_en)
        a_wr_ptr_gray <= bin2gray(a_wr_ptr + 1'b1);
      if (a_read_en)
        a_rd_ptr_gray <= bin2gray(a_rd_ptr + 1'b1);
    end
  end

  // B side: write pointer update
  wire b_write_en = b_dir & b_winc & ~b_full;
  wire b_read_en  = ~b_dir & b_rinc & ~b_empty;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {PTR_W{1'b0}};
      b_rd_ptr <= {PTR_W{1'b0}};
    end else begin
      if (b_write_en)
        b_wr_ptr <= b_wr_ptr + 1'b1;
      if (b_read_en)
        b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

  // B side: gray code pointers
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr_gray <= {PTR_W{1'b0}};
      b_rd_ptr_gray <= {PTR_W{1'b0}};
    end else begin
      if (b_write_en)
        b_wr_ptr_gray <= bin2gray(b_wr_ptr + 1'b1);
      if (b_read_en)
        b_rd_ptr_gray <= bin2gray(b_rd_ptr + 1'b1);
    end
  end

  // A side: memory write
  always @(posedge a_clk) begin
    if (a_write_en)
      mem_a[a_wr_ptr[ASIZE-1:0]] <= a_wdata;
  end

  // B side: memory write
  always @(posedge b_clk) begin
    if (b_write_en)
      mem_b[b_wr_ptr[ASIZE-1:0]] <= b_wdata;
  end

  // A side: read data
  reg [DSIZE-1:0] a_rdata_reg;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata_reg <= {DSIZE{1'b0}};
    else if (a_read_en)
      a_rdata_reg <= mem_a[a_rd_ptr[ASIZE-1:0]];
  end

  // B side: read data
  reg [DSIZE-1:0] b_rdata_reg;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata_reg <= {DSIZE{1'b0}};
    else if (b_read_en)
      b_rdata_reg <= mem_b[b_rd_ptr[ASIZE-1:0]];
  end

  // A side: full/empty flags
  // Full: write pointer has lapped read pointer by DEPTH
  // Empty: write pointer equals read pointer
  wire [PTR_W-1:0] a_wr_ptr_full = a_wr_ptr + 1'b1;
  wire a_full_internal = (a_wr_ptr_full[ASIZE-1:0] == a_rd_ptr[ASIZE-1:0]) && 
                         (a_wr_ptr_full[ASIZE] != a_rd_ptr[ASIZE]);
  wire a_empty_internal = (a_wr_ptr == a_rd_ptr);

  // Almost full: one less than full
  wire [PTR_W-1:0] a_wr_ptr_afull = a_wr_ptr + 2'b10;
  wire a_afull_internal = (a_wr_ptr_afull[ASIZE-1:0] == a_rd_ptr[ASIZE-1:0]) && 
                          (a_wr_ptr_afull[ASIZE] != a_rd_ptr[ASIZE]);

  // Almost empty: one more than empty
  wire [PTR_W-1:0] a_rd_ptr_aempty = a_rd_ptr + 1'b1;
  wire a_aempty_internal = (a_wr_ptr == a_rd_ptr_aempty);

  assign a_full   = a_full_internal;
  assign a_afull  = a_afull_internal;
  assign a_empty  = a_empty_internal;
  assign a_aempty = a_aempty_internal;

  // B side: full/empty flags
  wire [PTR_W-1:0] b_wr_ptr_full = b_wr_ptr + 1'b1;
  wire b_full_internal = (b_wr_ptr_full[ASIZE-1:0] == b_rd_ptr[ASIZE-1:0]) && 
                         (b_wr_ptr_full[ASIZE] != b_rd_ptr[ASIZE]);
  wire b_empty_internal = (b_wr_ptr == b_rd_ptr);

  wire [PTR_W-1:0] b_wr_ptr_afull = b_wr_ptr + 2'b10;
  wire b_afull_internal = (b_wr_ptr_afull[ASIZE-1:0] == b_rd_ptr[ASIZE-1:0]) && 
                          (b_wr_ptr_afull[ASIZE] != b_rd_ptr[ASIZE]);

  wire [PTR_W-1:0] b_rd_ptr_aempty = b_rd_ptr + 1'b1;
  wire b_aempty_internal = (b_wr_ptr == b_rd_ptr_aempty);

  assign b_full   = b_full_internal;
  assign b_afull  = b_afull_internal;
  assign b_empty  = b_empty_internal;
  assign b_aempty = b_aempty_internal;

  // Output data
  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

endmodule
