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
  reg [ASIZE-1:0] a_wptr, a_rptr, b_wptr, b_rptr;
  reg [ASIZE-1:0] a_wptr_gray, a_rptr_gray, b_wptr_gray, b_rptr_gray;
  reg [ASIZE-1:0] a_wptr_gray_sync, a_rptr_gray_sync, b_wptr_gray_sync, b_rptr_gray_sync;
  reg             a_full_int, a_empty_int, b_full_int, b_empty_int;
  reg [DSIZE-1:0] a_wdata_reg, b_wdata_reg, a_rdata_reg, b_rdata_reg;
  reg             a_winc_reg, b_winc_reg, a_rinc_reg, b_rinc_reg;

  // Gray code conversion
  function [ASIZE-1:0] binary_to_gray;
    input [ASIZE-1:0] bin;
    binary_to_gray = bin ^ (bin >> 1);
  endfunction

  // Gray code to binary conversion
  function [ASIZE-1:0] gray_to_binary;
    input [ASIZE-1:0] gray;
    integer i;
    reg [ASIZE-1:0] bin;
    bin = gray;
    for (i = ASIZE-2; i >= 0; i = i - 1)
      bin[i] = bin[i+1] ^ gray[i];
    gray_to_binary = bin;
  endfunction

  // Side A logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wptr <= 0;
      a_rptr <= 0;
      a_full_int <= 0;
      a_empty_int <= 1;
      a_wdata_reg <= 0;
    end else begin
      // Write pointer update
      if (a_winc && !a_full_int) begin
        a_wptr <= a_wptr + 1;
        a_wdata_reg <= a_wdata;
      end

      // Read pointer update
      if (a_rinc && !a_empty_int) begin
        a_rptr <= a_rptr + 1;
      end

      // Full and empty flags
      a_wptr_gray <= binary_to_gray(a_wptr);
      a_rptr_gray <= binary_to_gray(a_rptr);
      a_full_int <= (a_wptr_gray == a_rptr_gray_sync + 1);
      a_empty_int <= (a_wptr_gray == a_rptr_gray_sync);
    end
  end

  // Side B logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wptr <= 0;
      b_rptr <= 0;
      b_full_int <= 0;
      b_empty_int <= 1;
      b_wdata_reg <= 0;
    end else begin
      // Write pointer update
      if (b_winc && !b_full_int) begin
        b_wptr <= b_wptr + 1;
        b_wdata_reg <= b_wdata;
      end

      // Read pointer update
      if (b_rinc && !b_empty_int) begin
        b_rptr <= b_rptr + 1;
      end

      // Full and empty flags
      b_wptr_gray <= binary_to_gray(b_wptr);
      b_rptr_gray <= binary_to_gray(b_rptr);
      b_full_int <= (b_wptr_gray == b_rptr_gray_sync + 1);
      b_empty_int <= (b_wptr_gray == b_rptr_gray_sync);
    end
  end

  // Cross-domain synchronization for gray pointers
  sync_gray_counter a_gray_sync (
    .clk_src(a_clk),
    .clk_dst(b_clk),
    .rst_n(b_rst_n),
    .gray_src(a_wptr_gray),
    .gray_dst(a_wptr_gray_sync)
  );

  sync_gray_counter a_gray_sync_rptr (
    .clk_src(a_clk),
    .clk_dst(b_clk),
    .rst_n(b_rst_n),
    .gray_src(a_rptr_gray),
    .gray_dst(a_rptr_gray_sync)
  );

  sync_gray_counter b_gray_sync (
    .clk_src(b_clk),
    .clk_dst(a_clk),
    .rst_n(a_rst_n),
    .gray_src(b_wptr_gray),
    .gray_dst(b_wptr_gray_sync)
  );

  sync_gray_counter b_gray_sync_rptr (
    .clk_src(b_clk),
    .clk_dst(a_clk),
    .rst_n(a_rst_n),
    .gray_src(b_rptr_gray),
    .gray_dst(b_rptr_gray_sync)
  );

  // Output flags
  assign a_full = a_full_int;
  assign a_empty = a_empty_int;
  assign a_afull = (a_wptr_gray == a_rptr_gray_sync + 1'b1);
  assign a_aempty = (a_wptr_gray == a_rptr_gray_sync + {ASIZE{1'b1}} - 1'b1);

  assign b_full = b_full_int;
  assign b_empty = b_empty_int;
  assign b_afull = (b_wptr_gray == b_rptr_gray_sync + 1'b1);
  assign b_aempty = (b_wptr_gray == b_rptr_gray_sync + {ASIZE{1'b1}} - 1'b1);

  // RAM interface
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_winc_reg <= 0;
      a_rinc_reg <= 0;
    end else begin
      a_winc_reg <= a_winc;
      a_rinc_reg <= a_rinc;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_winc_reg <= 0;
      b_rinc_reg <= 0;
    end else begin
      b_winc_reg <= b_winc;
      b_rinc_reg <= b_rinc;
    end
  end

  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata_reg;
  assign o_ram_a_addr = a_wptr[ASIZE-2:0]; // Assuming circular buffer addressing
  assign o_ram_a_winc = a_winc_reg;
  assign o_ram_a_rinc = a_rinc_reg;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata_reg;
  assign o_ram_b_addr = b_wptr[ASIZE-2:0]; // Assuming circular buffer addressing
  assign o_ram_b_winc = b_winc_reg;
  assign o_ram_b_rinc = b_rinc_reg;

  // Read data output
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata_reg <= 0;
    else if (a_rinc_reg)
      a_rdata_reg <= i_ram_a_rdata;
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata_reg <= 0;
    else if (b_rinc_reg)
      b_rdata_reg <= i_ram_b_rdata;
  end

  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

endmodule

module sync_gray_counter
  (
    input wire clk_src,
    input wire clk_dst,
    input wire rst_n,
    input wire [ASIZE-1:0] gray_src,
    output reg [ASIZE-1:0] gray_dst
  );

  reg [ASIZE-1:0] gray_sync;

  always @(posedge clk_src or negedge rst_n) begin
    if (!rst_n)
      gray_sync <= 0;
    else
      gray_sync <= gray_src;
  end

  always @(posedge clk_dst or negedge rst_n) begin
    if (!rst_n)
      gray_dst <= 0;
    else
      gray_dst <= gray_sync;
  end

endmodule
