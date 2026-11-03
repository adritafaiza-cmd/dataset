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

  wire [ASIZE:0] a_side_wr_ptr_gray_synced;
  wire [ASIZE:0] b_side_wr_ptr_gray_synced;

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
    .ram_clk(o_ram_a_clk),
    .ram_wdata(o_ram_a_wdata),
    .ram_rdata(i_ram_a_rdata),
    .ram_addr(o_ram_a_addr),
    .ram_rinc(o_ram_a_rinc),
    .ram_winc(o_ram_a_winc),
    .rd_ptr_gray(b_side_wr_ptr_gray_synced),
    .wr_ptr_gray_sync(a_side_wr_ptr_gray_synced)
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
    .ram_clk(o_ram_b_clk),
    .ram_wdata(o_ram_b_wdata),
    .ram_rdata(i_ram_b_rdata),
    .ram_addr(o_ram_b_addr),
    .ram_rinc(o_ram_b_rinc),
    .ram_winc(o_ram_b_winc),
    .rd_ptr_gray(a_side_wr_ptr_gray_synced),
    .wr_ptr_gray_sync(b_side_wr_ptr_gray_synced)
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
       output wire             ram_clk,
       output wire [DSIZE-1:0] ram_wdata,
       input wire [DSIZE-1:0]  ram_rdata,
       output wire [ASIZE-1:0] ram_addr,
       output wire             ram_rinc,
       output wire             ram_winc,
       input wire [ASIZE:0]    rd_ptr_gray,
       output wire [ASIZE:0]   wr_ptr_gray_sync
       );

  wire [ASIZE:0] wr_ptr_gray;
  wire [ASIZE:0] rd_ptr_gray_sync;
  wire [ASIZE-1:0] wr_ptr_bin;
  wire [ASIZE-1:0] rd_ptr_bin;
  wire full_flag;
  wire afull_flag;
  wire empty_flag;
  wire aempty_flag;

  gray_counter #(
    .ASIZE(ASIZE)
  ) wr_gray_counter (
    .clk(clk),
    .rst_n(rst_n),
    .inc(winc),
    .gray_count(wr_ptr_gray)
  );

  gray_counter #(
    .ASIZE(ASIZE)
  ) rd_gray_counter (
    .clk(clk),
    .rst_n(rst_n),
    .inc(rinc),
    .gray_count(rd_ptr_gray)
  );

  gray_sync #(
    .ASIZE(ASIZE)
  ) wr_gray_sync (
    .clk(clk),
    .rst_n(rst_n),
    .async_in(wr_ptr_gray),
    .sync_out(wr_ptr_gray_sync)
  );

  gray_sync #(
    .ASIZE(ASIZE)
  ) rd_gray_sync (
    .clk(clk),
    .rst_n(rst_n),
    .async_in(rd_ptr_gray),
    .sync_out(rd_ptr_gray_sync)
  );

  gray2bin #(
    .ASIZE(ASIZE)
  ) wr_gray2bin (
    .gray(wr_ptr_gray_sync),
    .bin(wr_ptr_bin)
  );

  gray2bin #(
    .ASIZE(ASIZE)
  ) rd_gray2bin (
    .gray(rd_ptr_gray_sync),
    .bin(rd_ptr_bin)
  );

  assign ram_clk = clk;
  assign ram_wdata = wdata;
  assign ram_addr = wr_ptr_bin;
  assign ram_winc = winc;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ram_rinc <= 0;
    end else begin
      ram_rinc <= rinc;
    end
  end

  assign rdata = ram_rdata;

  assign full_flag = (wr_ptr_bin == rd_ptr_bin + 1);
  assign afull_flag = (wr_ptr_bin == rd_ptr_bin + (1 << ASIZE) - 1);
  assign empty_flag = (wr_ptr_bin == rd_ptr_bin);
  assign aempty_flag = (wr_ptr_bin == rd_ptr_bin - 1);

  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;

endmodule

module gray_counter
  #(
    parameter ASIZE = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              inc,
       output wire [ASIZE:0]   gray_count
       );

  reg [ASIZE:0] bin_count;
  reg [ASIZE:0] gray_count_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bin_count <= 0;
      gray_count_reg <= 0;
    end else if (inc) begin
      bin_count <= bin_count + 1;
      gray_count_reg <= (bin_count + 1) ^ ((bin_count + 1) >> 1);
    end
  end

  assign gray_count = gray_count_reg;

endmodule

module gray_sync
  #(
    parameter ASIZE = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire [ASIZE:0]    async_in,
       output wire [ASIZE:0]   sync_out
       );

  reg [ASIZE:0] sync_stage1;
  reg [ASIZE:0] sync_stage2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_stage1 <= 0;
      sync_stage2 <= 0;
    end else begin
      sync_stage1 <= async_in;
      sync_stage2 <= sync_stage1;
    end
  end

  assign sync_out = sync_stage2;

endmodule

module gray2bin
  #(
    parameter ASIZE = 4
    ) (
       input wire [ASIZE:0]    gray,
       output wire [ASIZE-1:0] bin
       );

  assign bin[ASIZE-1] = gray[ASIZE];
  generate
    genvar i;
    for (i = ASIZE-2; i >= 0; i = i - 1) begin: gen_gray2bin
      assign bin[i] = gray[i+1] ^ bin[i+1];
    end
  endgenerate

endmodule
