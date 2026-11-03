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

  wire [ASIZE:0] a_side_rptr_gray_sync;
  wire [ASIZE:0] a_side_wptr_gray_sync;
  wire [ASIZE:0] b_side_rptr_gray_sync;
  wire [ASIZE:0] b_side_wptr_gray_sync;

  async_fifo_side #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) a_side (
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
    .other_rptr_gray(b_side_rptr_gray_sync),
    .other_wptr_gray(b_side_wptr_gray_sync)
  );

  async_fifo_side #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) b_side (
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
    .other_rptr_gray(a_side_rptr_gray_sync),
    .other_wptr_gray(a_side_wptr_gray_sync)
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
       input wire [ASIZE:0]    other_rptr_gray,
       input wire [ASIZE:0]    other_wptr_gray
       );

  reg [ASIZE-1:0] wptr;
  reg [ASIZE-1:0] rptr;
  reg [ASIZE:0] wptr_gray;
  reg [ASIZE:0] rptr_gray;
  reg [ASIZE:0] other_rptr_gray_sync;
  reg [ASIZE:0] other_wptr_gray_sync2;
  reg [ASIZE:0] gray_wptr;
  reg [ASIZE:0] gray_rptr;
  reg [ASIZE-1:0] wptr_bin;
  reg [ASIZE-1:0] rptr_bin;
  reg [ASIZE:0] wptr_gray_sync;
  reg [ASIZE:0] rptr_gray_sync;
  reg [ASIZE-1:0] wptr_gray_sync_bin;
  reg [ASIZE-1:0] rptr_gray_sync_bin;
  reg full_flag;
  reg afull_flag;
  reg empty_flag;
  reg aempty_flag;

  assign ram_clk = clk;
  assign ram_wdata = wdata;
  assign ram_addr = wptr;
  assign ram_winc = winc;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= 0;
      wptr_gray <= 0;
    end else if (winc && !full_flag) begin
      wptr <= wptr + 1;
      wptr_gray <= wptr ^ (wptr + 1);
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rptr <= 0;
      rptr_gray <= 0;
    end else if (rinc && !empty_flag) begin
      rptr <= rptr + 1;
      rptr_gray <= rptr ^ (rptr + 1);
    end
  end

  always @(posedge other_clk or negedge other_rst_n) begin
    if (!other_rst_n) begin
      other_rptr_gray_sync <= 0;
      other_rptr_gray_sync2 <= 0;
    end else begin
      other_rptr_gray_sync <= other_rptr_gray;
      other_rptr_gray_sync2 <= other_rptr_gray_sync;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      other_wptr_gray_sync <= 0;
    end else begin
      other_wptr_gray_sync <= other_wptr_gray;
    end
  end

  assign gray_wptr = wptr ^ (wptr + 1);
  assign gray_rptr = rptr ^ (rptr + 1);

  assign wptr_gray_sync = other_rptr_gray_sync2;
  assign rptr_gray_sync = other_wptr_gray_sync;

  assign wptr_gray_sync_bin = wptr_gray_sync ^ (wptr_gray_sync >> 1);
  assign rptr_gray_sync_bin = rptr_gray_sync ^ (rptr_gray_sync >> 1);

  assign full_flag = (wptr_gray == {1'b1, rptr_gray_sync_bin});
  assign afull_flag = (wptr_gray == {1'b1, (rptr_gray_sync_bin + 1)});
  assign empty_flag = (rptr_gray == {1'b0, wptr_gray_sync_bin});
  assign aempty_flag = (rptr_gray == {1'b0, (wptr_gray_sync_bin - 1)});

  assign ram_rinc = rinc;
  assign rdata = ram_rdata;

endmodule
