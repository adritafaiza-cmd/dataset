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

  reg [DSIZE-1:0] mem [0:((1<<ASIZE)-1)];
  reg [ASIZE:0] head_a, tail_a, head_b, tail_b;
  reg [ASIZE:0] count_a, count_b;
  reg [ASIZE:0] almost_full_a, almost_empty_a, almost_full_b, almost_empty_b;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      head_a <= 0;
      tail_a <= 0;
      count_a <= 0;
      almost_full_a <= 0;
      almost_empty_a <= 1;
    end else begin
      if (a_dir && a_winc) begin
        mem[tail_a] <= a_wdata;
        tail_a <= tail_a + 1;
        if (count_a < (1<<ASIZE) - 1) begin
          count_a <= count_a + 1;
        end
        if (count_a == (1<<ASIZE) - 2) begin
          almost_full_a <= 1;
        end
        almost_empty_a <= 0;
      end else if (!a_dir && a_rinc) begin
        head_a <= head_a + 1;
        if (count_a > 0) begin
          count_a <= count_a - 1;
        end
        if (count_a == 1) begin
          almost_empty_a <= 1;
        end
        almost_full_a <= 0;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      head_b <= 0;
      tail_b <= 0;
      count_b <= 0;
      almost_full_b <= 0;
      almost_empty_b <= 1;
    end else begin
      if (b_dir && b_winc) begin
        mem[tail_b] <= b_wdata;
        tail_b <= tail_b + 1;
        if (count_b < (1<<ASIZE) - 1) begin
          count_b <= count_b + 1;
        end
        if (count_b == (1<<ASIZE) - 2) begin
          almost_full_b <= 1;
        end
        almost_empty_b <= 0;
      end else if (!b_dir && b_rinc) begin
        head_b <= head_b + 1;
        if (count_b > 0) begin
          count_b <= count_b - 1;
        end
        if (count_b == 1) begin
          almost_empty_b <= 1;
        end
        almost_full_b <= 0;
      end
    end
  end

  assign a_rdata = (a_dir && !b_rinc) ? mem[head_b] : 0;
  assign a_full = (count_a == (1<<ASIZE) - 1);
  assign a_afull = almost_full_a;
  assign a_empty = (count_a == 0);
  assign a_aempty = almost_empty_a;

  assign b_rdata = (!a_dir && !a_rinc) ? mem[head_a] : 0;
  assign b_full = (count_b == (1<<ASIZE) - 1);
  assign b_afull = almost_full_b;
  assign b_empty = (count_b == 0);
  assign b_aempty = almost_empty_b;

endmodule
