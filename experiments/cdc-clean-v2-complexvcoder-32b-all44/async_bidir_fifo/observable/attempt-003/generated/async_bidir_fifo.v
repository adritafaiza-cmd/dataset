module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
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
       input wire              b_dir
       );

  wire [DSIZE-1:0] a_to_b_rdata, b_to_a_rdata;
  wire             a_to_b_full, a_to_b_afull, a_to_b_empty, a_to_b_aempty;
  wire             b_to_a_full, b_to_a_afull, b_to_a_empty, b_to_a_aempty;

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_core_inst_a_to_b (
       .clk(a_clk),
       .rst_n(a_rst_n),
       .winc(a_winc & a_dir),
       .wdata(a_wdata),
       .rinc(b_rinc & b_dir),
       .rdata(a_to_b_rdata),
       .full(a_to_b_full),
       .afull(a_to_b_afull),
       .empty(a_to_b_empty),
       .aempty(a_to_b_aempty),
       .clk_cross(b_clk)
       );

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_core_inst_b_to_a (
       .clk(b_clk),
       .rst_n(b_rst_n),
       .winc(b_winc & b_dir),
       .wdata(b_wdata),
       .rinc(a_rinc & a_dir),
       .rdata(b_to_a_rdata),
       .full(b_to_a_full),
       .afull(b_to_a_afull),
       .empty(b_to_a_empty),
       .aempty(b_to_a_aempty),
       .clk_cross(a_clk)
       );

  assign a_rdata = a_dir ? a_to_b_rdata : b_to_a_rdata;
  assign a_full  = a_dir ? a_to_b_full  : b_to_a_full;
  assign a_afull = a_dir ? a_to_b_afull : b_to_a_afull;
  assign a_empty = a_dir ? a_to_b_empty : b_to_a_empty;
  assign a_aempty= a_dir ? a_to_b_aempty: b_to_a_aempty;

  assign b_rdata = b_dir ? b_to_a_rdata : a_to_b_rdata;
  assign b_full  = b_dir ? b_to_a_full  : a_to_b_full;
  assign b_afull = b_dir ? b_to_a_afull : a_to_b_afull;
  assign b_empty = b_dir ? b_to_a_empty : a_to_b_empty;
  assign b_aempty= b_dir ? b_to_a_aempty: a_to_b_aempty;

endmodule

module fifo_core
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
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
       input wire              clk_cross
       );

  wire [ASIZE:0] wr_ptr_gray, rd_ptr_gray;
  wire [ASIZE:0] wr_ptr_gray_sync, rd_ptr_gray_sync;
  wire [ASIZE:0] wr_ptr_bin, rd_ptr_bin;
  wire           full_flag, afull_flag, empty_flag, aempty_flag;

  gray_counter #(.ASIZE(ASIZE)) gray_counter_inst_wr (
       .clk(clk),
       .rst_n(rst_n),
       .inc(winc),
       .gray_count(wr_ptr_gray)
       );

  gray_counter #(.ASIZE(ASIZE)) gray_counter_inst_rd (
       .clk(clk_cross),
       .rst_n(rst_n),
       .inc(rinc),
       .gray_count(rd_ptr_gray)
       );

  gray_to_bin #(.ASIZE(ASIZE)) gray_to_bin_inst_wr (
       .gray_count(wr_ptr_gray),
       .bin_count(wr_ptr_bin)
       );

  gray_to_bin #(.ASIZE(ASIZE)) gray_to_bin_inst_rd (
       .gray_count(rd_ptr_gray),
       .bin_count(rd_ptr_bin)
       );

  sync_reg #(.WIDTH(ASIZE+1)) sync_reg_inst_wr (
       .din(wr_ptr_gray),
       .clk(clk_cross),
       .rst_n(rst_n),
       .dout(wr_ptr_gray_sync)
       );

  sync_reg #(.WIDTH(ASIZE+1)) sync_reg_inst_rd (
       .din(rd_ptr_gray),
       .clk(clk),
       .rst_n(rst_n),
       .dout(rd_ptr_gray_sync)
       );

  dual_port_ram #(.DSIZE(DSIZE), .ASIZE(ASIZE)) dual_port_ram_inst (
       .clk_a(clk),
       .rst_n_a(rst_n),
       .we_a(winc),
       .addr_a(wr_ptr_bin),
       .din_a(wdata),
       .clk_b(clk_cross),
       .rst_n_b(rst_n),
       .addr_b(rd_ptr_bin),
       .dout_b(rdata)
       );

  assign full_flag   = (wr_ptr_gray_sync == {~rd_ptr_gray[ASIZE], rd_ptr_gray[ASIZE-1:0]});
  assign afull_flag  = (wr_ptr_gray_sync == {rd_ptr_gray[ASIZE], ~rd_ptr_gray[ASIZE-1:0]});
  assign empty_flag  = (wr_ptr_gray_sync == rd_ptr_gray_sync);
  assign aempty_flag = (wr_ptr_gray_sync == {rd_ptr_gray[ASIZE], rd_ptr_gray[ASIZE-1:0]});

  assign full  = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty= aempty_flag;

endmodule

module gray_counter
  #(
    parameter ASIZE = 4
    ) (
       input wire clk,
       input wire rst_n,
       input wire inc,
       output wire [ASIZE:0] gray_count
       );

  reg [ASIZE:0] count, next_count;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      count <= 0;
    else
      count <= next_count;
  end

  assign next_count = inc ? (count ^ (count >> 1) ^ 1) : count;
  assign gray_count = count ^ (count >> 1);

endmodule

module gray_to_bin
  #(
    parameter ASIZE = 4
    ) (
       input wire [ASIZE:0] gray_count,
       output wire [ASIZE:0] bin_count
       );

  reg [ASIZE:0] bin;

  always @(*) begin
    bin[ASIZE] = gray_count[ASIZE];
    for (int i = ASIZE-1; i >= 0; i = i - 1) begin
      bin[i] = bin[i+1] ^ gray_count[i];
    end
  end

  assign bin_count = bin;

endmodule

module sync_reg
  #(
    parameter WIDTH = 5
    ) (
       input wire [WIDTH-1:0] din,
       input wire clk,
       input wire rst_n,
       output reg [WIDTH-1:0] dout
       );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      dout <= 0;
    else begin
      dout <= din;
    end
  end

endmodule

module dual_port_ram
  #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
    ) (
       input wire clk_a,
       input wire rst_n_a,
       input wire we_a,
       input wire [ASIZE:0] addr_a,
       input wire [DSIZE-1:0] din_a,
       input wire clk_b,
       input wire rst_n_b,
       input wire [ASIZE:0] addr_b,
       output reg [DSIZE-1:0] dout_b
       );

  reg [DSIZE-1:0] mem [0:(1<<(ASIZE+1))-1];

  always @(posedge clk_a or negedge rst_n_a) begin
    if (!rst_n_a) begin
      for (int i = 0; i < (1<<(ASIZE+1)); i = i + 1) begin
        mem[i] <= 0;
      end
    end else if (we_a) begin
      mem[addr_a] <= din_a;
    end
  end

  always @(posedge clk_b or negedge rst_n_b) begin
    if (!rst_n_b) begin
      dout_b <= 0;
    end else begin
      dout_b <= mem[addr_b];
    end
  end

endmodule
