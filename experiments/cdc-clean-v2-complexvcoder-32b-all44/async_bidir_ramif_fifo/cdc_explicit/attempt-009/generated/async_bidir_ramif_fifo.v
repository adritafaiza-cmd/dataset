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

  // Internal signals for synchronization
  wire [ASIZE:0] fifo_a_wr_ptr_gray_sync;
  wire [ASIZE:0] fifo_b_wr_ptr_gray_sync;

  // FIFO side for domain a
  async_fifo_side #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty),
    .dir(a_dir),
    .other_clk(b_clk),
    .other_rst_n(b_rst_n),
    .ram_clk(o_ram_a_clk),
    .ram_wdata(o_ram_a_wdata),
    .ram_rdata(i_ram_a_rdata),
    .ram_addr(o_ram_a_addr),
    .ram_rinc(o_ram_a_rinc),
    .ram_winc(o_ram_a_winc),
    .rd_ptr_gray_sync(fifo_b_wr_ptr_gray_sync)
  );

  // FIFO side for domain b
  async_fifo_side #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty),
    .dir(b_dir),
    .other_clk(a_clk),
    .other_rst_n(a_rst_n),
    .ram_clk(o_ram_b_clk),
    .ram_wdata(o_ram_b_wdata),
    .ram_rdata(i_ram_b_rdata),
    .ram_addr(o_ram_b_addr),
    .ram_rinc(o_ram_b_rinc),
    .ram_winc(o_ram_b_winc),
    .rd_ptr_gray_sync(fifo_a_wr_ptr_gray_sync)
  );

endmodule

module async_fifo_side
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
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
       output wire             aempty,
       input wire              dir,
       input wire              other_clk,
       input wire              other_rst_n,
       output wire             ram_clk,
       output wire [DSIZE-1:0] ram_wdata,
       input wire [DSIZE-1:0]  ram_rdata,
       output wire [ASIZE-1:0] ram_addr,
       output wire             ram_rinc,
       output wire             ram_winc,
       input wire [ASIZE:0]    rd_ptr_gray_sync
       );

  // Internal signals
  reg [ASIZE:0] wr_ptr_gray;
  reg [ASIZE:0] rd_ptr_gray;
  reg [ASIZE:0] wr_ptr_gray_sync;
  reg [ASIZE:0] rd_ptr_gray_bin;
  reg [ASIZE:0] wr_ptr_gray_bin;
  reg [ASIZE:0] wr_ptr_gray_bin_sync;
  reg [ASIZE:0] rd_ptr_gray_bin_sync;
  reg [DSIZE-1:0] ram_wdata_int;
  reg [DSIZE-1:0] ram_rdata_int;
  reg [ASIZE:0] next_wr_ptr_gray;
  reg [ASIZE:0] next_rd_ptr_gray;
  wire full_flag;
  wire afull_flag;
  wire empty_flag;
  wire aempty_flag;
  reg [ASIZE-1:0] ram_addr_int;
  reg ram_winc_int;
  reg ram_rinc_int;

  // Binary to Gray conversion
  function [ASIZE:0] bin_to_gray;
    input [ASIZE:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Gray to Binary conversion
  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray[ASIZE];
    for (i = ASIZE - 1; i >= 0; i = i - 1)
      bin[i] = bin[i + 1] ^ gray[i];
    gray_to_bin = bin;
  endfunction

  // Write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray <= 0;
    end else if (winc) begin
      wr_ptr_gray <= next_wr_ptr_gray;
    end
  end

  // Read pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray <= 0;
    end else if (rinc) begin
      rd_ptr_gray <= next_rd_ptr_gray;
    end
  end

  // Next write pointer
  always @(*) begin
    next_wr_ptr_gray = bin_to_gray(wr_ptr_gray_bin + 1);
  end

  // Next read pointer
  always @(*) begin
    next_rd_ptr_gray = bin_to_gray(rd_ptr_gray_bin + 1);
  end

  // Gray to binary conversion for pointers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_bin <= 0;
      rd_ptr_gray_bin <= 0;
      wr_ptr_gray_bin_sync <= 0;
      rd_ptr_gray_bin_sync <= 0;
    end else begin
      wr_ptr_gray_bin <= gray_to_bin(wr_ptr_gray);
      rd_ptr_gray_bin <= gray_to_bin(rd_ptr_gray);
      wr_ptr_gray_bin_sync <= gray_to_bin(wr_ptr_gray_sync);
      rd_ptr_gray_bin_sync <= gray_to_bin(rd_ptr_gray_sync);
    end
  end

  // Full flag
  assign full_flag = (wr_ptr_gray_bin + 1 == rd_ptr_gray_bin_sync);

  // Almost full flag
  assign afull_flag = (wr_ptr_gray_bin + 2 == rd_ptr_gray_bin_sync);

  // Empty flag
  assign empty_flag = (wr_ptr_gray_bin_sync == rd_ptr_gray_bin);

  // Almost empty flag
  assign aempty_flag = (wr_ptr_gray_bin_sync == rd_ptr_gray_bin + 1);

  // Output flags
  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;

  // RAM interface signals
  assign ram_addr_int = wr_ptr_gray_bin[ASIZE-1:0];
  assign ram_winc_int = winc;
  assign ram_rinc_int = rinc;

  // RAM data handling
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ram_wdata_int <= 0;
    end else if (winc) begin
      ram_wdata_int <= wdata;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ram_rdata_int <= 0;
    end else if (rinc) begin
      ram_rdata_int <= ram_rdata;
    end
  end

  // Output data
  assign rdata = ram_rdata_int;

  // Clock, write data, and enables
  assign ram_clk = clk;
  assign ram_wdata = ram_wdata_int;
  assign ram_addr = ram_addr_int;
  assign ram_winc = ram_winc_int;
  assign ram_rinc = ram_rinc_int;

endmodule
