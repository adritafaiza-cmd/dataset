module async_bidir_ramif_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
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
       input wire              b_dir,
       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,
       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

  // Internal signals
  reg [ASIZE-1:0] a_wr_ptr, a_rd_ptr, a_wr_ptr_gray, a_rd_ptr_gray;
  reg [ASIZE-1:0] a_wr_ptr_gray_meta, a_rd_ptr_gray_meta;
  reg [ASIZE-1:0] b_wr_ptr, b_rd_ptr, b_wr_ptr_gray, b_rd_ptr_gray;
  reg [ASIZE-1:0] b_wr_ptr_gray_meta, b_rd_ptr_gray_meta;
  reg             a_full_flag, a_empty_flag;
  reg             b_full_flag, b_empty_flag;
  reg             a_wr_en, a_rd_en;
  reg             b_wr_en, b_rd_en;

  // Gray code conversion function
  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    bin2gray = (bin >> 1) ^ bin;
  endfunction

  // a_clk domain logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_full_flag <= 0;
      a_empty_flag <= 1;
    end else begin
      a_wr_ptr_gray_meta <= bin2gray(a_wr_ptr);
      a_rd_ptr_gray_meta <= bin2gray(a_rd_ptr);

      // Update pointers
      if (a_wr_en) a_wr_ptr <= a_wr_ptr + 1;
      if (a_rd_en) a_rd_ptr <= a_rd_ptr + 1;

      // Update flags
      a_full_flag <= (a_wr_ptr_gray_meta == b_rd_ptr_gray);
      a_empty_flag <= (a_wr_ptr_gray == a_rd_ptr_gray_meta);
    end
  end

  // b_clk domain logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_full_flag <= 0;
      b_empty_flag <= 1;
    end else begin
      b_wr_ptr_gray_meta <= bin2gray(b_wr_ptr);
      b_rd_ptr_gray_meta <= bin2gray(b_rd_ptr);

      // Update pointers
      if (b_wr_en) b_wr_ptr <= b_wr_ptr + 1;
      if (b_rd_en) b_rd_ptr <= b_rd_ptr + 1;

      // Update flags
      b_full_flag <= (b_wr_ptr_gray_meta == a_rd_ptr_gray);
      b_empty_flag <= (b_wr_ptr_gray == b_rd_ptr_gray_meta);
    end
  end

  // a_clk domain control logic
  always @(*) begin
    a_wr_en = a_winc & !a_full_flag & (a_dir | b_empty_flag);
    a_rd_en = a_rinc & !a_empty_flag & (!a_dir | b_full_flag);
  end

  // b_clk domain control logic
  always @(*) begin
    b_wr_en = b_winc & !b_full_flag & (!b_dir | a_empty_flag);
    b_rd_en = b_rinc & !b_empty_flag & (b_dir | a_full_flag);
  end

  // a_clk domain outputs
  assign a_rdata = i_ram_a_rdata;
  assign a_full = a_full_flag;
  assign a_afull = (a_wr_ptr_gray_meta == {b_rd_ptr_gray[ASIZE-2:0], ~b_rd_ptr_gray[ASIZE-1]});
  assign a_empty = a_empty_flag;
  assign a_aempty = (a_wr_ptr_gray == {a_rd_ptr_gray_meta[ASIZE-2:0], ~a_rd_ptr_gray_meta[ASIZE-1]});
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = a_wr_ptr;
  assign o_ram_a_rinc = a_rd_en;
  assign o_ram_a_winc = a_wr_en;

  // b_clk domain outputs
  assign b_rdata = i_ram_b_rdata;
  assign b_full = b_full_flag;
  assign b_afull = (b_wr_ptr_gray_meta == {a_rd_ptr_gray[ASIZE-2:0], ~a_rd_ptr_gray[ASIZE-1]});
  assign b_empty = b_empty_flag;
  assign b_aempty = (b_wr_ptr_gray == {b_rd_ptr_gray_meta[ASIZE-2:0], ~b_rd_ptr_gray_meta[ASIZE-1]});
  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wr_ptr;
  assign o_ram_b_rinc = b_rd_en;
  assign o_ram_b_winc = b_wr_en;

endmodule
