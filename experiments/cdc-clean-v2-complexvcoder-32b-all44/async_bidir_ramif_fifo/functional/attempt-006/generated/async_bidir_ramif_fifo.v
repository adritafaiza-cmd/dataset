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
  reg [DSIZE-1:0] a_wdata_reg, b_wdata_reg, a_rdata_reg, b_rdata_reg;
  reg a_wr_en, a_rd_en, b_wr_en, b_rd_en;

  // Gray code conversion function
  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    bin2gray = bin ^ (bin >> 1);
  endfunction

  // Synchronization FIFO for a_wr_ptr_gray to b_clk
  sync_gray_code sync_a_wr_ptr_gray (
    .clk_src(a_clk),
    .rst_n_src(a_rst_n),
    .gray_src(a_wr_ptr_gray),
    .clk_dst(b_clk),
    .rst_n_dst(b_rst_n),
    .gray_dst(a_wr_ptr_gray_sync)
  );

  // Synchronization FIFO for a_rd_ptr_gray to b_clk
  sync_gray_code sync_a_rd_ptr_gray (
    .clk_src(a_clk),
    .rst_n_src(a_rst_n),
    .gray_src(a_rd_ptr_gray),
    .clk_dst(b_clk),
    .rst_n_dst(b_rst_n),
    .gray_dst(a_rd_ptr_gray_sync)
  );

  // Synchronization FIFO for b_wr_ptr_gray to a_clk
  sync_gray_code sync_b_wr_ptr_gray (
    .clk_src(b_clk),
    .rst_n_src(b_rst_n),
    .gray_src(b_wr_ptr_gray),
    .clk_dst(a_clk),
    .rst_n_dst(a_rst_n),
    .gray_dst(b_wr_ptr_gray_sync)
  );

  // Synchronization FIFO for b_rd_ptr_gray to a_clk
  sync_gray_code sync_b_rd_ptr_gray (
    .clk_src(b_clk),
    .rst_n_src(b_rst_n),
    .gray_src(b_rd_ptr_gray),
    .clk_dst(a_clk),
    .rst_n_dst(a_rst_n),
    .gray_dst(b_rd_ptr_gray_sync)
  );

  // a_clk domain logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr_gray <= 0;
      a_full_flag <= 0;
      a_afull_flag <= 0;
      a_empty_flag <= 1;
      a_aempty_flag <= 1;
    end else begin
      // Write enable generation
      a_wr_en <= a_winc & ~a_full_flag;

      // Read enable generation
      a_rd_en <= a_rinc & ~a_empty_flag;

      // Update write and read pointers
      if (a_wr_en) begin
        a_wr_ptr <= a_wr_ptr + 1;
        a_wr_ptr_gray <= bin2gray(a_wr_ptr + 1);
      end

      if (a_rd_en) begin
        a_rd_ptr <= a_rd_ptr + 1;
        a_rd_ptr_gray <= bin2gray(a_rd_ptr + 1);
      end

      // Update flags
      a_full_flag <= (a_wr_ptr_gray_sync == {~a_rd_ptr_gray[ASIZE-1], a_rd_ptr_gray[ASIZE-2:0]});
      a_afull_flag <= (a_wr_ptr_gray_sync == {a_rd_ptr_gray[ASIZE-1], ~a_rd_ptr_gray[ASIZE-2:0]});
      a_empty_flag <= (a_wr_ptr_gray == a_rd_ptr_gray);
      a_aempty_flag <= (a_wr_ptr_gray == {~a_rd_ptr_gray[ASIZE-1], a_rd_ptr_gray[ASIZE-2:0]});
    end
  end

  // b_clk domain logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr_gray <= 0;
      b_full_flag <= 0;
      b_afull_flag <= 0;
      b_empty_flag <= 1;
      b_aempty_flag <= 1;
    end else begin
      // Write enable generation
      b_wr_en <= b_winc & ~b_full_flag;

      // Read enable generation
      b_rd_en <= b_rinc & ~b_empty_flag;

      // Update write and read pointers
      if (b_wr_en) begin
        b_wr_ptr <= b_wr_ptr + 1;
        b_wr_ptr_gray <= bin2gray(b_wr_ptr + 1);
      end

      if (b_rd_en) begin
        b_rd_ptr <= b_rd_ptr + 1;
        b_rd_ptr_gray <= bin2gray(b_rd_ptr + 1);
      end

      // Update flags
      b_full_flag <= (b_wr_ptr_gray_sync == {~b_rd_ptr_gray[ASIZE-1], b_rd_ptr_gray[ASIZE-2:0]});
      b_afull_flag <= (b_wr_ptr_gray_sync == {b_rd_ptr_gray[ASIZE-1], ~b_rd_ptr_gray[ASIZE-2:0]});
      b_empty_flag <= (b_wr_ptr_gray == b_rd_ptr_gray);
      b_aempty_flag <= (b_wr_ptr_gray == {~b_rd_ptr_gray[ASIZE-1], b_rd_ptr_gray[ASIZE-2:0]});
    end
  end

  // a_clk domain outputs
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= 0;
    end else if (a_rinc & ~a_empty_flag) begin
      a_rdata_reg <= i_ram_a_rdata;
    end
  end

  // b_clk domain outputs
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= 0;
    end else if (b_rinc & ~b_empty_flag) begin
      b_rdata_reg <= i_ram_b_rdata;
    end
  end

  // Output assignments
  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;
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
  assign o_ram_a_rinc = a_rd_en;
  assign o_ram_a_winc = a_wr_en;
  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wr_ptr;
  assign o_ram_b_rinc = b_rd_en;
  assign o_ram_b_winc = b_wr_en;

endmodule

// Gray code synchronizer module
module sync_gray_code (
  input wire              clk_src,
  input wire              rst_n_src,
  input wire [ASIZE-1:0]  gray_src,
  input wire              clk_dst,
  input wire              rst_n_dst,
  output reg [ASIZE-1:0]  gray_dst
);

  reg [ASIZE-1:0] gray_meta;

  // Source clock domain
  always @(posedge clk_src or negedge rst_n_src) begin
    if (!rst_n_src) begin
      gray_meta <= 0;
    end else begin
      gray_meta <= gray_src;
    end
  end

  // Destination clock domain
  always @(posedge clk_dst or negedge rst_n_dst) begin
    if (!rst_n_dst) begin
      gray_dst <= 0;
    end else begin
      gray_dst <= gray_meta;
    end
  end

endmodule
