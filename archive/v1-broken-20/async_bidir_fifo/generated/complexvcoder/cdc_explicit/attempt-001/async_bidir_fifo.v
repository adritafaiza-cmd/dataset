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

  // FIFO cores
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .dir(a_dir),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .dir(b_dir),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty)
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
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  localparam DEPTH = 2**ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE:0] head_a, tail_a, head_b, tail_b;

  assign full = (head_a - tail_a) == DEPTH;
  assign afull = (head_a - tail_a) >= DEPTH - 1;
  assign empty = head_a == tail_a;
  assign aempty = (head_a - tail_a) <= 1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head_a <= 0;
      tail_a <= 0;
      head_b <= 0;
      tail_b <= 0;
    end else begin
      if (dir && winc) begin
        mem[head_a] <= wdata;
        head_a <= head_a + 1;
      end else if (!dir && rinc) begin
        tail_b <= tail_b + 1;
      end

      if (!dir && winc) begin
        mem[head_b] <= wdata;
        head_b <= head_b + 1;
      end else if (dir && rinc) begin
        tail_a <= tail_a + 1;
      end
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= 0;
    end else begin
      if (dir) begin
        if (tail_b < head_b) begin
          rdata <= mem[tail_b];
        end else begin
          rdata <= 0;
        end
      end else begin
        if (tail_a < head_a) begin
          rdata <= mem[tail_a];
        end else begin
          rdata <= 0;
        end
      end
    end
  end

endmodule
