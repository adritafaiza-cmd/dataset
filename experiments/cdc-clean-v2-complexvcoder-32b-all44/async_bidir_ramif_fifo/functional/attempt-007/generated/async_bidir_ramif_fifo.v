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
  reg [ASIZE-1:0] a_wr_ptr, a_rd_ptr, b_wr_ptr, b_rd_ptr;
  reg [ASIZE-1:0] a_wr_ptr_gray, a_rd_ptr_gray, b_wr_ptr_gray, b_rd_ptr_gray;
  reg [ASIZE-1:0] a_wr_ptr_gray_sync, a_rd_ptr_gray_sync, b_wr_ptr_gray_sync, b_rd_ptr_gray_sync;
  reg a_full_flag, a_afull_flag, a_empty_flag, a_aempty_flag;
  reg b_full_flag, b_afull_flag, b_empty_flag, b_aempty_flag;
  reg a_ram_wen, a_ram_ren, b_ram_wen, b_ram_ren;

  // Binary to Gray conversion
  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    bin2gray = bin ^ (bin >> 1);
  endfunction

  // Asynchronous reset and pointer updates for side A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr_gray <= 0;
    end else begin
      if (a_dir && !a_full_flag) begin
        a_wr_ptr <= a_wr_ptr + 1;
        a_wr_ptr_gray <= bin2gray(a_wr_ptr + 1);
      end
      if (!a_dir && !a_empty_flag) begin
        a_rd_ptr <= a_rd_ptr + 1;
        a_rd_ptr_gray <= bin2gray(a_rd_ptr + 1);
      end
    end
  end

  // Asynchronous reset and pointer updates for side B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr_gray <= 0;
    end else begin
      if (b_dir && !b_full_flag) begin
        b_wr_ptr <= b_wr_ptr + 1;
        b_wr_ptr_gray <= bin2gray(b_wr_ptr + 1);
      end
      if (!b_dir && !b_empty_flag) begin
        b_rd_ptr <= b_rd_ptr + 1;
        b_rd_ptr_gray <= bin2gray(b_rd_ptr + 1);
      end
    end
  end

  // Gray code synchronization from A to B
  async_gray_sync #(.WIDTH(ASIZE))
    sync_a_wr_ptr_gray (
      .clk_src(a_clk),
      .clk_dst(b_clk),
      .rst_n(b_rst_n),
      .din(a_wr_ptr_gray),
      .dout(a_wr_ptr_gray_sync)
    );

  async_gray_sync #(.WIDTH(ASIZE))
    sync_a_rd_ptr_gray (
      .clk_src(a_clk),
      .clk_dst(b_clk),
      .rst_n(b_rst_n),
      .din(a_rd_ptr_gray),
      .dout(a_rd_ptr_gray_sync)
    );

  // Gray code synchronization from B to A
  async_gray_sync #(.WIDTH(ASIZE))
    sync_b_wr_ptr_gray (
      .clk_src(b_clk),
      .clk_dst(a_clk),
      .rst_n(a_rst_n),
      .din(b_wr_ptr_gray),
      .dout(b_wr_ptr_gray_sync)
    );

  async_gray_sync #(.WIDTH(ASIZE))
    sync_b_rd_ptr_gray (
      .clk_src(b_clk),
      .clk_dst(a_clk),
      .rst_n(a_rst_n),
      .din(b_rd_ptr_gray),
      .dout(b_rd_ptr_gray_sync)
    );

  // FIFO flags for side A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_flag <= 0;
      a_afull_flag <= 0;
      a_empty_flag <= 1;
      a_aempty_flag <= 1;
    end else begin
      a_full_flag <= (a_wr_ptr_gray_sync == bin2gray(a_rd_ptr + 1));
      a_afull_flag <= (a_wr_ptr_gray_sync == bin2gray(a_rd_ptr + 2));
      a_empty_flag <= (a_wr_ptr_gray == a_rd_ptr_gray);
      a_aempty_flag <= (a_wr_ptr_gray == bin2gray(a_rd_ptr + 1));
    end
  end

  // FIFO flags for side B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_flag <= 0;
      b_afull_flag <= 0;
      b_empty_flag <= 1;
      b_aempty_flag <= 1;
    end else begin
      b_full_flag <= (b_wr_ptr_gray_sync == bin2gray(b_rd_ptr + 1));
      b_afull_flag <= (b_wr_ptr_gray_sync == bin2gray(b_rd_ptr + 2));
      b_empty_flag <= (b_wr_ptr_gray == b_rd_ptr_gray);
      b_aempty_flag <= (b_wr_ptr_gray == bin2gray(b_rd_ptr + 1));
    end
  end

  // RAM write and read enable signals for side A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_ram_wen <= 0;
      a_ram_ren <= 0;
    end else begin
      a_ram_wen <= a_winc && !a_full_flag;
      a_ram_ren <= a_rinc && !a_empty_flag;
    end
  end

  // RAM write and read enable signals for side B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_ram_wen <= 0;
      b_ram_ren <= 0;
    end else begin
      b_ram_wen <= b_winc && !b_full_flag;
      b_ram_ren <= b_rinc && !b_empty_flag;
    end
  end

  // Output assignments for side A
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = a_wr_ptr;
  assign o_ram_a_winc = a_ram_wen;
  assign o_ram_a_rinc = a_ram_ren;
  assign a_rdata = a_ram_ren ? i_ram_a_rdata : 0;

  // Output assignments for side B
  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wr_ptr;
  assign o_ram_b_winc = b_ram_wen;
  assign o_ram_b_rinc = b_ram_ren;
  assign b_rdata = b_ram_ren ? i_ram_b_rdata : 0;

  // Output flags for side A
  assign a_full = a_full_flag;
  assign a_afull = a_afull_flag;
  assign a_empty = a_empty_flag;
  assign a_aempty = a_aempty_flag;

  // Output flags for side B
  assign b_full = b_full_flag;
  assign b_afull = b_afull_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_aempty_flag;

endmodule

// Asynchronous Gray code synchronizer
module async_gray_sync
  #(
    parameter WIDTH = 4
    ) (
       input wire              clk_src,
       input wire              clk_dst,
       input wire              rst_n,
       input wire [WIDTH-1:0]  din,
       output reg [WIDTH-1:0]  dout
       );

  reg [WIDTH-1:0] din_sync;

  always @(posedge clk_dst or negedge rst_n) begin
    if (!rst_n) begin
      din_sync <= 0;
      dout <= 0;
    end else begin
      din_sync <= din;
      dout <= din_sync;
    end
  end

endmodule
