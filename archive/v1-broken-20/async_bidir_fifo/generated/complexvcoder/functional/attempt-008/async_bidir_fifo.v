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

  // FIFO instances
  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

  // Direction selectors
  direction_selector #(.DSIZE(DSIZE)) dir_selector_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .dir(a_dir),
    .fifo_a_wdata(a_wdata),
    .fifo_b_rdata(b_rdata),
    .fifo_a_rdata(a_rdata),
    .fifo_b_wdata(b_wdata)
  );

  direction_selector #(.DSIZE(DSIZE)) dir_selector_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .dir(b_dir),
    .fifo_a_wdata(a_wdata),
    .fifo_b_rdata(b_rdata),
    .fifo_a_rdata(a_rdata),
    .fifo_b_wdata(b_wdata)
  );

endmodule

module fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4
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
       output wire             aempty
       );

  reg [DSIZE-1:0] mem [0:2**ASIZE-1];
  reg [ASIZE:0] wr_ptr, rd_ptr;
  reg [ASIZE:0] wr_cnt, rd_cnt;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      wr_cnt <= 0;
      rd_cnt <= 0;
    end else begin
      if (winc && !full) begin
        mem[wr_ptr] <= wdata;
        wr_ptr <= wr_ptr + 1;
        wr_cnt <= wr_cnt + 1;
      end
      if (rinc && !empty) begin
        rd_ptr <= rd_ptr + 1;
        rd_cnt <= rd_cnt - 1;
      end
    end
  end

  assign full = wr_cnt == 2**ASIZE;
  assign afull = wr_cnt >= 2**ASIZE - 1;
  assign empty = rd_cnt == 0;
  assign aempty = rd_cnt <= 1;

  assign rdata = mem[rd_ptr];

endmodule

module direction_selector
  #(
    parameter DSIZE         = 8
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              dir,
       input wire [DSIZE-1:0]  fifo_a_wdata,
       input wire [DSIZE-1:0]  fifo_b_rdata,
       input wire [DSIZE-1:0]  fifo_a_rdata,
       input wire [DSIZE-1:0]  fifo_b_wdata
       );

  reg [DSIZE-1:0] wdata, rdata;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wdata <= 0;
      rdata <= 0;
    end else begin
      if (dir) begin
        wdata <= fifo_a_wdata;
        rdata <= fifo_b_rdata;
      end else begin
        wdata <= fifo_b_wdata;
        rdata <= fifo_a_rdata;
      end
    end
  end

  assign fifo_a_wdata = wdata;
  assign fifo_b_rdata = rdata;

endmodule
