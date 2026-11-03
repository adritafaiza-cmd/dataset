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
  wire [ASIZE-1:0] a_side_wr_ptr_gray_sync;
  wire [ASIZE-1:0] b_side_wr_ptr_gray;
  wire [ASIZE-1:0] b_side_wr_ptr_gray_sync;

  async_fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  a_side (
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
    .rd_ptr_gray(b_side_wr_ptr_gray),
    .rd_ptr_gray_sync(b_side_wr_ptr_gray_sync),
    .wr_ptr_gray(a_side_wr_ptr_gray),
    .wr_ptr_gray_sync(a_side_wr_ptr_gray_sync),
    .o_ram_clk(o_ram_a_clk),
    .o_ram_wdata(o_ram_a_wdata),
    .i_ram_rdata(i_ram_a_rdata),
    .o_ram_addr(o_ram_a_addr),
    .o_ram_rinc(o_ram_a_rinc),
    .o_ram_winc(o_ram_a_winc)
  );

  async_fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  b_side (
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
    .rd_ptr_gray(a_side_wr_ptr_gray),
    .rd_ptr_gray_sync(a_side_wr_ptr_gray_sync),
    .wr_ptr_gray(b_side_wr_ptr_gray),
    .wr_ptr_gray_sync(b_side_wr_ptr_gray_sync),
    .o_ram_clk(o_ram_b_clk),
    .o_ram_wdata(o_ram_b_wdata),
    .i_ram_rdata(i_ram_b_rdata),
    .o_ram_addr(o_ram_b_addr),
    .o_ram_rinc(o_ram_b_rinc),
    .o_ram_winc(o_ram_b_winc)
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
       input wire [ASIZE-1:0]  rd_ptr_gray,
       output wire [ASIZE-1:0] rd_ptr_gray_sync,
       output wire [ASIZE-1:0] wr_ptr_gray,
       input wire [ASIZE-1:0]  wr_ptr_gray_sync,
       output wire             o_ram_clk,
       output wire [DSIZE-1:0] o_ram_wdata,
       input wire [DSIZE-1:0]  i_ram_rdata,
       output wire [ASIZE-1:0] o_ram_addr,
       output wire             o_ram_rinc,
       output wire             o_ram_winc
       );

  reg [ASIZE-1:0] wr_ptr_bin;
  reg [ASIZE-1:0] rd_ptr_bin;
  reg [ASIZE-1:0] rd_ptr_gray_local;
  reg [ASIZE-1:0] rd_ptr_gray_sync1;
  reg [ASIZE-1:0] wr_ptr_gray_local;
  reg [ASIZE-1:0] wr_ptr_gray_sync1;
  reg               fifo_full;
  reg               fifo_afull;
  reg               fifo_empty;
  reg               fifo_aempty;
  reg [ASIZE-1:0] read_addr;
  reg [ASIZE-1:0] write_addr;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_bin <= 0;
      wr_ptr_gray_local <= 0;
      wr_ptr_gray_sync1 <= 0;
      rd_ptr_gray_local <= 0;
      rd_ptr_gray_sync1 <= 0;
    end else begin
      wr_ptr_bin <= wr_ptr_bin + winc;
      wr_ptr_gray_local <= bin2gray(wr_ptr_bin);
      wr_ptr_gray_sync1 <= wr_ptr_gray_local;

      rd_ptr_gray_local <= rd_ptr_gray;
      rd_ptr_gray_sync1 <= rd_ptr_gray_local;
    end
  end

  assign wr_ptr_gray = wr_ptr_gray_local;
  assign rd_ptr_gray_sync = rd_ptr_gray_sync1;

  assign read_addr = dir ? gray2bin(rd_ptr_gray_sync1) : gray2bin(rd_ptr_gray);
  assign write_addr = gray2bin(wr_ptr_gray_local);

  assign fifo_full = (wr_ptr_gray_local == {~rd_ptr_gray_sync1[ASIZE-1], rd_ptr_gray_sync1[ASIZE-2:0]});
  assign fifo_afull = (wr_ptr_gray_local == {~rd_ptr_gray_sync1[ASIZE-1:1], ~rd_ptr_gray_sync1[0]});
  assign fifo_empty = (wr_ptr_gray_local == rd_ptr_gray_sync1);
  assign fifo_aempty = (wr_ptr_gray_local == {rd_ptr_gray_sync1[ASIZE-1:1], ~rd_ptr_gray_sync1[0]});

  assign full = fifo_full;
  assign afull = fifo_afull;
  assign empty = fifo_empty;
  assign aempty = fifo_aempty;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= 0;
    end else if (rinc && !fifo_empty) begin
      rdata <= i_ram_rdata;
    end
  end

  assign o_ram_clk = clk;
  assign o_ram_wdata = wdata;
  assign o_ram_addr = write_addr;
  assign o_ram_rinc = rinc;
  assign o_ram_winc = winc;

  function [ASIZE-1:0] bin2gray;
    input [ASIZE-1:0] bin;
    begin
      bin2gray = bin ^ (bin >> 1);
    end
  endfunction

  function [ASIZE-1:0] gray2bin;
    input [ASIZE-1:0] gray;
    integer i;
    reg [ASIZE-1:0] bin;
    begin
      bin = gray;
      for (i = ASIZE-2; i >= 0; i = i - 1) begin
        bin[i] = bin[i+1] ^ gray[i];
      end
      gray2bin = bin;
    end
  endfunction

endmodule
