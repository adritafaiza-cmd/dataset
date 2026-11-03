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
  reg [ASIZE-1:0] a_wr_ptr, a_wr_ptr_gray, a_wr_ptr_gray_sync, a_rd_ptr, a_rd_ptr_gray, a_rd_ptr_gray_sync;
  reg [ASIZE-1:0] b_wr_ptr, b_wr_ptr_gray, b_wr_ptr_gray_sync, b_rd_ptr, b_rd_ptr_gray, b_rd_ptr_gray_sync;
  reg             a_full_flag, a_afull_flag, a_empty_flag, a_aempty_flag;
  reg             b_full_flag, b_afull_flag, b_empty_flag, b_aempty_flag;

  // Binary to Gray code conversion
  function [ASIZE-1:0] bin_to_gray;
    input [ASIZE-1:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Synchronizers
  async_fifo_sync #(.WIDTH(ASIZE)) sync_a_wr_ptr_gray (
    .clk_in(a_clk),
    .rst_n_in(a_rst_n),
    .data_in(a_wr_ptr_gray),
    .clk_out(b_clk),
    .rst_n_out(b_rst_n),
    .data_out(a_wr_ptr_gray_sync)
  );

  async_fifo_sync #(.WIDTH(ASIZE)) sync_a_rd_ptr_gray (
    .clk_in(a_clk),
    .rst_n_in(a_rst_n),
    .data_in(a_rd_ptr_gray),
    .clk_out(b_clk),
    .rst_n_out(b_rst_n),
    .data_out(a_rd_ptr_gray_sync)
  );

  async_fifo_sync #(.WIDTH(ASIZE)) sync_b_wr_ptr_gray (
    .clk_in(b_clk),
    .rst_n_in(b_rst_n),
    .data_in(b_wr_ptr_gray),
    .clk_out(a_clk),
    .rst_n_out(a_rst_n),
    .data_out(b_wr_ptr_gray_sync)
  );

  async_fifo_sync #(.WIDTH(ASIZE)) sync_b_rd_ptr_gray (
    .clk_in(b_clk),
    .rst_n_in(b_rst_n),
    .data_in(b_rd_ptr_gray),
    .clk_out(a_clk),
    .rst_n_out(a_rst_n),
    .data_out(b_rd_ptr_gray_sync)
  );

  // a_clk domain logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr <= 0;
      a_rd_ptr_gray <= 0;
    end else begin
      if (a_winc && !a_full_flag) begin
        a_wr_ptr <= a_wr_ptr + 1;
        a_wr_ptr_gray <= bin_to_gray(a_wr_ptr + 1);
      end
      if (a_rinc && !a_empty_flag) begin
        a_rd_ptr <= a_rd_ptr + 1;
        a_rd_ptr_gray <= bin_to_gray(a_rd_ptr + 1);
      end
    end
  end

  // b_clk domain logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr <= 0;
      b_rd_ptr_gray <= 0;
    end else begin
      if (b_winc && !b_full_flag) begin
        b_wr_ptr <= b_wr_ptr + 1;
        b_wr_ptr_gray <= bin_to_gray(b_wr_ptr + 1);
      end
      if (b_rinc && !b_empty_flag) begin
        b_rd_ptr <= b_rd_ptr + 1;
        b_rd_ptr_gray <= bin_to_gray(b_rd_ptr + 1);
      end
    end
  end

  // Flags
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_flag <= 0;
      a_afull_flag <= 0;
      a_empty_flag <= 1;
      a_aempty_flag <= 1;
    end else begin
      a_full_flag <= (a_wr_ptr_gray_sync == (a_rd_ptr_gray + 1) % (1 << ASIZE));
      a_afull_flag <= (a_wr_ptr_gray_sync == (a_rd_ptr_gray + 2) % (1 << ASIZE));
      a_empty_flag <= (a_wr_ptr_gray == a_rd_ptr_gray);
      a_aempty_flag <= (a_wr_ptr_gray == (a_rd_ptr_gray + 1) % (1 << ASIZE));
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_flag <= 0;
      b_afull_flag <= 0;
      b_empty_flag <= 1;
      b_aempty_flag <= 1;
    end else begin
      b_full_flag <= (b_wr_ptr_gray_sync == (b_rd_ptr_gray + 1) % (1 << ASIZE));
      b_afull_flag <= (b_wr_ptr_gray_sync == (b_rd_ptr_gray + 2) % (1 << ASIZE));
      b_empty_flag <= (b_wr_ptr_gray == b_rd_ptr_gray);
      b_aempty_flag <= (b_wr_ptr_gray == (b_rd_ptr_gray + 1) % (1 << ASIZE));
    end
  end

  // Outputs
  assign a_rdata = a_rinc ? i_ram_a_rdata : a_rdata;
  assign b_rdata = b_rinc ? i_ram_b_rdata : b_rdata;
  assign a_full = a_full_flag;
  assign a_afull = a_afull_flag;
  assign a_empty = a_empty_flag;
  assign a_aempty = a_aempty_flag;
  assign b_full = b_full_flag;
  assign b_afull = b_afull_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_aempty_flag;

  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = a_wr_ptr;
  assign o_ram_a_winc = a_winc;
  assign o_ram_a_rinc = a_rinc;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wr_ptr;
  assign o_ram_b_winc = b_winc;
  assign o_ram_b_rinc = b_rinc;

endmodule

// Synchronizer module
module async_fifo_sync
  #(
    parameter WIDTH = 4
    ) (
       input wire clk_in,
       input wire rst_n_in,
       input wire [WIDTH-1:0] data_in,
       input wire clk_out,
       input wire rst_n_out,
       output reg [WIDTH-1:0] data_out
       );

  reg [WIDTH-1:0] sync_reg [1:0];

  always @(posedge clk_in or negedge rst_n_in) begin
    if (!rst_n_in) begin
      sync_reg[0] <= 0;
      sync_reg[1] <= 0;
    end else begin
      sync_reg[0] <= data_in;
      sync_reg[1] <= sync_reg[0];
    end
  end

  always @(posedge clk_out or negedge rst_n_out) begin
    if (!rst_n_out) begin
      data_out <= 0;
    end else begin
      data_out <= sync_reg[1];
    end
  end

endmodule
