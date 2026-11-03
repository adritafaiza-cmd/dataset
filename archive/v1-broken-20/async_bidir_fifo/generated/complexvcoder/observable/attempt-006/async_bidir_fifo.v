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
  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) fifo_a (
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

  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) fifo_b (
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

  // Clock-domain crossing for data transfer
  wire [DSIZE-1:0] a_to_b_data;
  wire [DSIZE-1:0] b_to_a_data;

  // Data transfer from a_clk to b_clk domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_to_b_data <= 8'b0;
    end else if (a_winc && !a_full) begin
      a_to_b_data <= a_wdata;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      fifo_b.winc <= 1'b0;
      fifo_b.wdata <= 8'b0;
    end else if (!fifo_b.full && a_to_b_data != 8'b0) begin
      fifo_b.winc <= 1'b1;
      fifo_b.wdata <= a_to_b_data;
      a_to_b_data <= 8'b0;
    end
  end

  // Data transfer from b_clk to a_clk domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_to_a_data <= 8'b0;
    end else if (b_winc && !b_full) begin
      b_to_a_data <= b_wdata;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      fifo_a.winc <= 1'b0;
      fifo_a.wdata <= 8'b0;
    end else if (!fifo_a.full && b_to_a_data != 8'b0) begin
      fifo_a.winc <= 1'b1;
      fifo_a.wdata <= b_to_a_data;
      b_to_a_data <= 8'b0;
    end
  end

endmodule
