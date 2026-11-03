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

  // Internal signals
  wire [DSIZE-1:0] a_fifo_wdata, a_fifo_rdata;
  wire a_fifo_winc, a_fifo_rinc, a_fifo_full, a_fifo_afull, a_fifo_empty, a_fifo_aempty;
  wire [DSIZE-1:0] b_fifo_wdata, b_fifo_rdata;
  wire b_fifo_winc, b_fifo_rinc, b_fifo_full, b_fifo_afull, b_fifo_empty, b_fifo_aempty;

  // FIFO cores
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) a_fifo (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_fifo_winc),
    .wdata(a_fifo_wdata),
    .rinc(a_fifo_rinc),
    .rdata(a_fifo_rdata),
    .full(a_fifo_full),
    .afull(a_fifo_afull),
    .empty(a_fifo_empty),
    .aempty(a_fifo_aempty)
  );

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) b_fifo (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_fifo_winc),
    .wdata(b_fifo_wdata),
    .rinc(b_fifo_rinc),
    .rdata(b_fifo_rdata),
    .full(b_fifo_full),
    .afull(b_fifo_afull),
    .empty(b_fifo_empty),
    .aempty(b_fifo_aempty)
  );

  // Direction selectors
  dir_selector #(.DSIZE(DSIZE)) dir_select_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .dir(a_dir),
    .winc(a_winc),
    .rinc(a_rinc),
    .wdata(a_wdata),
    .rdata(a_fifo_rdata)
  );

  dir_selector #(.DSIZE(DSIZE)) dir_select_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .dir(b_dir),
    .winc(b_winc),
    .rinc(b_rinc),
    .wdata(b_wdata),
    .rdata(b_fifo_rdata)
  );

  // Connections between direction selectors and FIFOs
  assign a_fifo_winc = dir_select_a.winc;
  assign a_fifo_wdata = dir_select_a.wdata;
  assign a_fifo_rinc = dir_select_a.rinc;
  assign b_fifo_winc = dir_select_b.winc;
  assign b_fifo_wdata = dir_select_b.wdata;
  assign b_fifo_rinc = dir_select_b.rinc;

  // Assign outputs
  assign a_rdata = dir_select_a.rdata;
  assign a_full = a_fifo_full;
  assign a_afull = a_fifo_afull;
  assign a_empty = a_fifo_empty;
  assign a_aempty = a_fifo_aempty;
  assign b_rdata = dir_select_b.rdata;
  assign b_full = b_fifo_full;
  assign b_afull = b_fifo_afull;
  assign b_empty = b_fifo_empty;
  assign b_aempty = b_fifo_aempty;

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
       output wire             aempty
       );

  // Internal signals
  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [ASIZE:0] wr_ptr, rd_ptr;
  reg [ASIZE:0] wr_cnt, rd_cnt;
  reg [ASIZE:0] wr_cnt_prev, rd_cnt_prev;

  // Write pointer and count
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      wr_cnt <= 0;
    end else begin
      wr_cnt_prev <= wr_cnt;
      if (winc && !full) begin
        mem[wr_ptr] <= wdata;
        wr_ptr <= wr_ptr + 1;
        wr_cnt <= wr_cnt + 1;
      end
    end
  end

  // Read pointer and count
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      rd_cnt <= 0;
    end else begin
      rd_cnt_prev <= rd_cnt;
      if (rinc && !empty) begin
        rd_ptr <= rd_ptr + 1;
        rd_cnt <= rd_cnt + 1;
      end
    end
  end

  // Flags
  assign full = (wr_cnt == ((1<<ASIZE) - 1));
  assign afull = (wr_cnt == ((1<<ASIZE) - 2));
  assign empty = (rd_cnt == 0);
  assign aempty = (rd_cnt == 1);

  // Read data
  assign rdata = mem[rd_ptr];

endmodule

module dir_selector
  #(
    parameter DSIZE         = 8
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              dir,
       input wire              winc,
       input wire              rinc,
       input wire [DSIZE-1:0]  wdata,
       output wire [DSIZE-1:0] rdata
       );

  // Internal signals
  reg [DSIZE-1:0] reg_rdata;

  // Direction selection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_rdata <= 0;
    end else begin
      if (dir) begin
        reg_rdata <= wdata;
      end else begin
        reg_rdata <= rdata;
      end
    end
  end

  // Assign outputs
  assign rdata = reg_rdata;

endmodule
