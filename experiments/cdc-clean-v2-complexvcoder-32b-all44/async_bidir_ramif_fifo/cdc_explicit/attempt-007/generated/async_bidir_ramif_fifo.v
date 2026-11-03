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

  wire [ASIZE-1:0] a_side_wr_ptr_gray;
  wire [ASIZE-1:0] a_side_wr_ptr_gray_synced;
  wire [ASIZE-1:0] a_side_rd_ptr_gray;
  wire [ASIZE-1:0] a_side_rd_ptr_gray_synced;

  wire [ASIZE-1:0] b_side_wr_ptr_gray;
  wire [ASIZE-1:0] b_side_wr_ptr_gray_synced;
  wire [ASIZE-1:0] b_side_rd_ptr_gray;
  wire [ASIZE-1:0] b_side_rd_ptr_gray_synced;

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
    .rd_ptr_gray_synced(b_side_wr_ptr_gray_synced),
    .wr_ptr_gray(a_side_wr_ptr_gray),
    .ram_clk(o_ram_a_clk),
    .ram_wdata(o_ram_a_wdata),
    .ram_addr(o_ram_a_addr),
    .ram_rinc(o_ram_a_rinc),
    .ram_winc(o_ram_a_winc),
    .ram_rdata(i_ram_a_rdata)
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
    .rd_ptr_gray_synced(a_side_wr_ptr_gray_synced),
    .wr_ptr_gray(b_side_wr_ptr_gray),
    .ram_clk(o_ram_b_clk),
    .ram_wdata(o_ram_b_wdata),
    .ram_addr(o_ram_b_addr),
    .ram_rinc(o_ram_b_rinc),
    .ram_winc(o_ram_b_winc),
    .ram_rdata(i_ram_b_rdata)
  );

  cdc_sync #(
    .DATA_WIDTH(ASIZE)
  ) wr_ptr_gray_cdc_sync_a_to_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .src_data(a_side_wr_ptr_gray),
    .dest_data(a_side_wr_ptr_gray_synced)
  );

  cdc_sync #(
    .DATA_WIDTH(ASIZE)
  ) wr_ptr_gray_cdc_sync_b_to_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .src_data(b_side_wr_ptr_gray),
    .dest_data(b_side_wr_ptr_gray_synced)
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
       input wire [ASIZE-1:0]  rd_ptr_gray_synced,
       output wire [ASIZE-1:0] wr_ptr_gray,
       output wire             ram_clk,
       output wire [DSIZE-1:0] ram_wdata,
       output wire [ASIZE-1:0] ram_addr,
       output wire             ram_rinc,
       output wire             ram_winc,
       input wire [DSIZE-1:0]  ram_rdata
       );

  wire [ASIZE-1:0] wr_ptr_bin;
  wire [ASIZE-1:0] rd_ptr_bin;
  wire [ASIZE-1:0] rd_ptr_bin_synced;
  wire [ASIZE-1:0] wr_ptr_gray_synced;

  wire fifo_full;
  wire fifo_afull;
  wire fifo_empty;
  wire fifo_aempty;

  gray_counter #(
    .DATA_WIDTH(ASIZE)
  ) wr_ptr_gray_counter (
    .clk(clk),
    .rst_n(rst_n),
    .inc(winc),
    .gray(wr_ptr_gray)
  );

  gray_to_bin #(
    .DATA_WIDTH(ASIZE)
  ) wr_ptr_gray_to_bin (
    .gray(wr_ptr_gray),
    .bin(wr_ptr_bin)
  );

  gray_to_bin #(
    .DATA_WIDTH(ASIZE)
  ) rd_ptr_gray_synced_to_bin (
    .gray(rd_ptr_gray_synced),
    .bin(rd_ptr_bin_synced)
  );

  gray_counter #(
    .DATA_WIDTH(ASIZE)
  ) rd_ptr_gray_counter (
    .clk(clk),
    .rst_n(rst_n),
    .inc(rinc),
    .gray(rd_ptr_gray)
  );

  gray_to_bin #(
    .DATA_WIDTH(ASIZE)
  ) rd_ptr_gray_to_bin (
    .gray(rd_ptr_gray),
    .bin(rd_ptr_bin)
  );

  cdc_sync #(
    .DATA_WIDTH(ASIZE)
  ) wr_ptr_gray_cdc_sync (
    .clk(clk),
    .rst_n(rst_n),
    .src_data(wr_ptr_gray),
    .dest_data(wr_ptr_gray_synced)
  );

  assign fifo_full = (wr_ptr_bin + 1) == rd_ptr_bin_synced;
  assign fifo_afull = (wr_ptr_bin + 2) == rd_ptr_bin_synced;
  assign fifo_empty = wr_ptr_bin == rd_ptr_bin;
  assign fifo_aempty = wr_ptr_bin == rd_ptr_bin_synced;

  assign full = fifo_full;
  assign afull = fifo_afull;
  assign empty = fifo_empty;
  assign aempty = fifo_aempty;

  assign ram_clk = clk;
  assign ram_wdata = wdata;
  assign ram_addr = wr_ptr_bin;
  assign ram_winc = winc & ~fifo_full;
  assign ram_rinc = rinc & ~fifo_empty;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= {DSIZE{1'b0}};
    end else begin
      if (ram_rinc) begin
        rdata <= ram_rdata;
      end
    end
  end

endmodule

module gray_counter
  #(
    parameter DATA_WIDTH = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              inc,
       output reg [DATA_WIDTH-1:0] gray
       );

  reg [DATA_WIDTH-1:0] bin;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bin <= {DATA_WIDTH{1'b0}};
      gray <= {DATA_WIDTH{1'b0}};
    end else begin
      if (inc) begin
        bin <= bin + 1;
        gray <= bin ^ (bin >> 1);
      end
    end
  end

endmodule

module gray_to_bin
  #(
    parameter DATA_WIDTH = 4
    ) (
       input wire [DATA_WIDTH-1:0] gray,
       output wire [DATA_WIDTH-1:0] bin
       );

  wire [DATA_WIDTH-1:0] shifted;

  assign shifted = {gray[DATA_WIDTH-2:0], 1'b0};

  assign bin = gray ^ shifted;

endmodule

module cdc_sync
  #(
    parameter DATA_WIDTH = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire [DATA_WIDTH-1:0] src_data,
       output reg [DATA_WIDTH-1:0] dest_data
       );

  reg [DATA_WIDTH-1:0] stage1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1 <= {DATA_WIDTH{1'b0}};
      dest_data <= {DATA_WIDTH{1'b0}};
    end else begin
      stage1 <= src_data;
      dest_data <= stage1;
    end
  end

endmodule
