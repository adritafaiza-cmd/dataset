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

  // FIFO core for side A
  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .dir(a_dir),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty),
    .rdata(b_rdata)
  );

  // FIFO core for side B
  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .dir(b_dir),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty),
    .rdata(a_rdata)
  );

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
       input wire              dir,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty,
       output wire [DSIZE-1:0] rdata
       );

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [ASIZE:0] wp, rp;
  reg [ASIZE:0] wp_n, rp_n;
  reg [1:0] wp_cnt, rp_cnt;
  reg [1:0] wp_cnt_n, rp_cnt_n;
  reg wp_inc, rp_inc;
  reg [DSIZE-1:0] wp_data;

  // Write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wp <= 0;
    end else if (winc && !full) begin
      wp <= wp_n;
    end
  end

  assign wp_n = wp + wp_cnt_n;

  // Read pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rp <= 0;
    end else if (rinc && !empty) begin
      rp <= rp_n;
    end
  end

  assign rp_n = rp + rp_cnt_n;

  // Write count logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wp_cnt <= 0;
    end else begin
      wp_cnt <= wp_cnt_n;
    end
  end

  assign wp_cnt_n = dir ? wp_cnt + 2'b01 : wp_cnt;

  // Read count logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rp_cnt <= 0;
    end else begin
      rp_cnt <= rp_cnt_n;
    end
  end

  assign rp_cnt_n = dir ? rp_cnt + 2'b01 : rp_cnt;

  // Write data logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem[wp] <= 0;
    end else if (winc && !full) begin
      mem[wp] <= wp_data;
    end
  end

  assign wp_data = dir ? wdata : mem[rp];

  // Full and empty flags
  assign full = wp_n == rp && rp_n != 0;
  assign empty = wp == rp_n;
  assign aempty = empty;
  assign afull = full;

  // Read data logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= 0;
    end else if (rinc && !empty) begin
      rdata <= mem[rp];
    end
  end

endmodule
