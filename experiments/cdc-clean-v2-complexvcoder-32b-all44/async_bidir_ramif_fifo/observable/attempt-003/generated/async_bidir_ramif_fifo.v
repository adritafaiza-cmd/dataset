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

  wire [DSIZE-1:0] fifo_a_to_b_dout;
  wire fifo_a_to_b_full;
  wire fifo_a_to_b_afull;
  wire fifo_a_to_b_empty;
  wire fifo_a_to_b_aempty;

  wire [DSIZE-1:0] fifo_b_to_a_dout;
  wire fifo_b_to_a_full;
  wire fifo_b_to_a_afull;
  wire fifo_b_to_a_empty;
  wire fifo_b_to_a_aempty;

  wire [DSIZE-1:0] ram_ctrl_a_wdata_out;
  wire [DSIZE-1:0] ram_ctrl_b_wdata_out;
  wire [ASIZE-1:0] ram_ctrl_a_addr;
  wire [ASIZE-1:0] ram_ctrl_b_addr;
  wire ram_ctrl_a_winc_out;
  wire ram_ctrl_b_winc_out;
  wire ram_ctrl_a_rinc_out;
  wire ram_ctrl_b_rinc_out;

  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_a_to_b (
    .clk_wr(a_clk),
    .rst_n(a_rst_n),
    .wr_en(a_winc),
    .din(a_wdata),
    .clk_rd(b_clk),
    .rd_en(b_rinc),
    .dout(fifo_a_to_b_dout),
    .full(fifo_a_to_b_full),
    .afull(fifo_a_to_b_afull),
    .empty(fifo_a_to_b_empty),
    .aempty(fifo_a_to_b_aempty)
  );

  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_b_to_a (
    .clk_wr(b_clk),
    .rst_n(b_rst_n),
    .wr_en(b_winc),
    .din(b_wdata),
    .clk_rd(a_clk),
    .rd_en(a_rinc),
    .dout(fifo_b_to_a_dout),
    .full(fifo_b_to_a_full),
    .afull(fifo_b_to_a_afull),
    .empty(fifo_b_to_a_empty),
    .aempty(fifo_b_to_a_aempty)
  );

  ram_controller #(.DSIZE(DSIZE), .ASIZE(ASIZE))
  ram_ctrl_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(i_ram_a_rdata),
    .addr(ram_ctrl_a_addr),
    .rinc_out(ram_ctrl_a_rinc_out),
    .winc_out(ram_ctrl_a_winc_out),
    .wdata_out(ram_ctrl_a_wdata_out)
  );

  ram_controller #(.DSIZE(DSIZE), .ASIZE(ASIZE))
  ram_ctrl_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(i_ram_b_rdata),
    .addr(ram_ctrl_b_addr),
    .rinc_out(ram_ctrl_b_rinc_out),
    .winc_out(ram_ctrl_b_winc_out),
    .wdata_out(ram_ctrl_b_wdata_out)
  );

  assign o_ram_a_clk = a_clk;
  assign o_ram_b_clk = b_clk;

  assign o_ram_a_wdata = ram_ctrl_a_wdata_out;
  assign o_ram_b_wdata = ram_ctrl_b_wdata_out;

  assign o_ram_a_addr = ram_ctrl_a_addr;
  assign o_ram_b_addr = ram_ctrl_b_addr;

  assign o_ram_a_winc = ram_ctrl_a_winc_out;
  assign o_ram_b_winc = ram_ctrl_b_winc_out;

  assign o_ram_a_rinc = ram_ctrl_a_rinc_out;
  assign o_ram_b_rinc = ram_ctrl_b_rinc_out;

  assign a_rdata = fifo_b_to_a_dout;
  assign b_rdata = fifo_a_to_b_dout;

  assign a_full = fifo_a_to_b_full;
  assign a_afull = fifo_a_to_b_afull;
  assign a_empty = fifo_b_to_a_empty;
  assign a_aempty = fifo_b_to_a_aempty;

  assign b_full = fifo_b_to_a_full;
  assign b_afull = fifo_b_to_a_afull;
  assign b_empty = fifo_a_to_b_empty;
  assign b_aempty = fifo_a_to_b_aempty;

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
    ) (
       input wire              clk_wr,
       input wire              rst_n,
       input wire              wr_en,
       input wire [DSIZE-1:0]  din,
       input wire              clk_rd,
       input wire              rd_en,
       output wire [DSIZE-1:0] dout,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [ASIZE-1:0] wr_ptr_bin;
  reg [ASIZE-1:0] wr_ptr_gray;
  reg [ASIZE-1:0] wr_ptr_gray_nxt;
  reg [ASIZE-1:0] rd_ptr_bin;
  reg [ASIZE-1:0] rd_ptr_gray;
  reg [ASIZE-1:0] rd_ptr_gray_nxt;
  reg [ASIZE:0] wr_ptr_bin_sync;
  reg [ASIZE:0] rd_ptr_bin_sync;

  wire [ASIZE:0] wr_ptr_bin_sync_nxt;
  wire [ASIZE:0] rd_ptr_bin_sync_nxt;
  wire [ASIZE:0] wr_ptr_bin_plus1;
  wire [ASIZE:0] rd_ptr_bin_plus1;
  wire [ASIZE:0] full_cnt;
  wire [ASIZE:0] afull_cnt;
  wire [ASIZE:0] empty_cnt;
  wire [ASIZE:0] aempty_cnt;

  assign wr_ptr_bin_plus1 = wr_ptr_bin + 1;
  assign rd_ptr_bin_plus1 = rd_ptr_bin + 1;

  assign full_cnt = wr_ptr_bin_plus1 - rd_ptr_bin_sync;
  assign afull_cnt = wr_ptr_bin_plus1 - rd_ptr_bin_sync - 1;
  assign empty_cnt = rd_ptr_bin_plus1 - wr_ptr_bin_sync;
  assign aempty_cnt = rd_ptr_bin_plus1 - wr_ptr_bin_sync - 1;

  assign full = full_cnt[ASIZE];
  assign afull = afull_cnt[ASIZE];
  assign empty = empty_cnt[ASIZE];
  assign aempty = aempty_cnt[ASIZE];

  assign wr_ptr_gray_nxt = (wr_ptr_bin_plus1 >> 1) ^ wr_ptr_bin_plus1;
  assign rd_ptr_gray_nxt = (rd_ptr_bin_plus1 >> 1) ^ rd_ptr_bin_plus1;

  always @(posedge clk_wr or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_bin <= 0;
      wr_ptr_gray <= 0;
    end else begin
      if (wr_en && !full) begin
        mem[wr_ptr_bin] <= din;
        wr_ptr_bin <= wr_ptr_bin_plus1[ASIZE-1:0];
        wr_ptr_gray <= wr_ptr_gray_nxt;
      end
    end
  end

  always @(posedge clk_rd or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_bin <= 0;
      rd_ptr_gray <= 0;
    end else begin
      if (rd_en && !empty) begin
        rd_ptr_bin <= rd_ptr_bin_plus1[ASIZE-1:0];
        rd_ptr_gray <= rd_ptr_gray_nxt;
      end
    end
  end

  always @(posedge clk_wr or negedge rst_n) begin
    if (!rst_n)
      wr_ptr_bin_sync <= 0;
    else
      wr_ptr_bin_sync <= wr_ptr_bin_sync_nxt;
  end

  always @(posedge clk_rd or negedge rst_n) begin
    if (!rst_n)
      rd_ptr_bin_sync <= 0;
    else
      rd_ptr_bin_sync <= rd_ptr_bin_sync_nxt;
  end

  assign wr_ptr_bin_sync_nxt = {wr_ptr_gray, wr_ptr_gray ^ wr_ptr_gray[ASIZE-1:0]};
  assign rd_ptr_bin_sync_nxt = {rd_ptr_gray, rd_ptr_gray ^ rd_ptr_gray[ASIZE-1:0]};

  always @(posedge clk_rd or negedge rst_n) begin
    if (!rst_n)
      dout <= 0;
    else if (rd_en && !empty)
      dout <= mem[rd_ptr_bin];
  end

endmodule

module ram_controller
  #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       input wire [DSIZE-1:0]  rdata,
       output wire [ASIZE-1:0] addr,
       output wire             rinc_out,
       output wire             winc_out,
       output wire [DSIZE-1:0] wdata_out
       );

  reg [ASIZE-1:0] wr_addr;
  reg [ASIZE-1:0] rd_addr;
  reg [ASIZE-1:0] wr_addr_nxt;
  reg [ASIZE-1:0] rd_addr_nxt;

  assign wdata_out = wdata;
  assign addr = wr_addr;
  assign rinc_out = rinc;
  assign winc_out = winc;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_addr <= 0;
      rd_addr <= 0;
    end else begin
      if (winc)
        wr_addr <= wr_addr_nxt;
      if (rinc)
        rd_addr <= rd_addr_nxt;
    end
  end

  always @(*) begin
    wr_addr_nxt = wr_addr;
    rd_addr_nxt = rd_addr;
    if (winc)
      wr_addr_nxt = wr_addr + 1;
    if (rinc)
      rd_addr_nxt = rd_addr + 1;
  end

endmodule
