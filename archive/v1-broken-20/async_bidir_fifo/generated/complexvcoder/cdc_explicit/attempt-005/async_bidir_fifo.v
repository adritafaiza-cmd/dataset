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
  reg [DSIZE-1:0] fifo_a_wdata_reg;
  reg [DSIZE-1:0] fifo_b_wdata_reg;

  // FIFO cores for both sides
  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(fifo_a_wdata_reg),
    .rinc(a_rinc),
    .dir(a_dir),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty),
    .rdata(a_rdata)
  );

  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(fifo_b_wdata_reg),
    .rinc(b_rinc),
    .dir(b_dir),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty),
    .rdata(b_rdata)
  );

  // Cross-clock-domain logic for data transfer
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      fifo_a_wdata_reg <= 0;
    end else if (a_dir && a_winc) begin
      fifo_a_wdata_reg <= a_wdata;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      fifo_b_wdata_reg <= 0;
    end else if (!b_dir && b_winc) begin
      fifo_b_wdata_reg <= b_wdata;
    end
  end

endmodule
