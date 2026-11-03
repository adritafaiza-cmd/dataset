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

  localparam FIFO_SIZE = 1 << ASIZE;
  localparam FULL_MASK = FIFO_SIZE - 1;
  localparam AFULL_MASK = FIFO_SIZE - 2;
  localparam EMPTY_MASK = 0;
  localparam AEMPTY_MASK = 1;

  reg [ASIZE-1:0] a_head, a_tail, b_head, b_tail;
  reg [DSIZE-1:0] a_fifo[FIFO_SIZE-1:0];
  reg [DSIZE-1:0] b_fifo[FIFO_SIZE-1:0];
  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_head <= 0;
      a_tail <= 0;
      a_full_reg <= 0;
      a_afull_reg <= 0;
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else begin
      if (a_dir && !a_full_reg) begin
        a_fifo[a_tail] <= a_wdata;
        a_tail <= (a_tail + 1) & FULL_MASK;
        a_full_reg <= (a_tail == a_head);
        a_afull_reg <= (a_tail == (a_head + 1) & FULL_MASK);
        a_empty_reg <= 0;
        a_aempty_reg <= 0;
      end else if (!a_dir && !a_empty_reg) begin
        a_rdata <= a_fifo[a_head];
        a_head <= (a_head + 1) & FULL_MASK;
        a_full_reg <= 0;
        a_afull_reg <= 0;
        a_empty_reg <= (a_head == a_tail);
        a_aempty_reg <= (a_head == (a_tail - 1) & FULL_MASK);
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_head <= 0;
      b_tail <= 0;
      b_full_reg <= 0;
      b_afull_reg <= 0;
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else begin
      if (b_dir && !b_full_reg) begin
        b_fifo[b_tail] <= b_wdata;
        b_tail <= (b_tail + 1) & FULL_MASK;
        b_full_reg <= (b_tail == b_head);
        b_afull_reg <= (b_tail == (b_head + 1) & FULL_MASK);
        b_empty_reg <= 0;
        b_aempty_reg <= 0;
      end else if (!b_dir && !b_empty_reg) begin
        b_rdata <= b_fifo[b_head];
        b_head <= (b_head + 1) & FULL_MASK;
        b_full_reg <= 0;
        b_afull_reg <= 0;
        b_empty_reg <= (b_head == b_tail);
        b_aempty_reg <= (b_head == (b_tail - 1) & FULL_MASK);
      end
    end
  end

  assign a_full = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;

  assign b_full = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

endmodule
