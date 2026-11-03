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

  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [ASIZE-1:0] wptr_a, wptr_b, rptr_a, rptr_b;
  reg [ASIZE-1:0] wptr_a_gray, wptr_b_gray, rptr_a_gray, rptr_b_gray;
  reg [ASIZE-1:0] wptr_a_bin, wptr_b_bin, rptr_a_bin, rptr_b_bin;
  reg [ASIZE:0]  cnt;
  reg [ASIZE:0]  cnt_bin;
  wire           full, empty;
  reg            a_full_int, a_afull_int, a_empty_int, a_aempty_int;
  reg            b_full_int, b_afull_int, b_empty_int, b_aempty_int;

  assign full  = (cnt == (1 << ASIZE) - 1);
  assign empty = (cnt == 0);

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wptr_a <= 0;
      rptr_a <=0;
      wptr_a_gray <= 0;
      rptr_a_gray <= 0;
      wptr_a_bin <= 0;
      rptr_a_bin <= 0;
      cnt <= 0;
      cnt_bin <= 0;
      a_full_int <= 1'b0;
      a_afull_int <= 1'b0;
      a_empty_int <= 1'b1;
      a_aempty_int <= 1'b1;
    end else begin
      if (a_winc && !full) begin
        mem[wptr_a] <= a_wdata;
        wptr_a <= wptr_a + 1;
        wptr_a_gray <= (wptr_a + 1) ^ ((wptr_a + 1) >> 1);
        cnt <= cnt + 1;
        cnt_bin <= cnt + 1;
        a_full_int <= (cnt + 1 == (1 << ASIZE) - 1);
        a_afull_int <= (cnt + 1 >= (1 << ASIZE) - 2);
        a_empty_int <= 1'b0;
        a_aempty_int <= 1'b0;
      end
      if (a_rinc && !empty && a_dir) begin
        a_rdata <= mem[rptr_a];
        rptr_a <= rptr_a + 1;
        rptr_a_gray <= (rptr_a + 1) ^ ((rptr_a + 1) >> 1);
        cnt <= cnt - 1;
        cnt_bin <= cnt - 1;
        a_full_int <= (cnt - 1 == (1 << ASIZE) - 1);
        a_afull_int <= (cnt - 1 >= (1 << ASIZE) - 2);
        a_empty_int <= (cnt - 1 == 0);
        a_aempty_int <= (cnt - 1 <= 1);
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wptr_b <= 0;
      rptr_b <= 0;
      wptr_b_gray <= 0;
      rptr_b_gray <= 0;
      wptr_b_bin <= 0;
      rptr_b_bin <= 0;
      b_full_int <= 1'b0;
      b_afull_int <= 1'b0;
      b_empty_int <= 1'b1;
      b_aempty_int <= 1'b1;
    end else begin
      if (b_winc && !full) begin
        mem[wptr_b] <= b_wdata;
        wptr_b <= wptr_b + 1;
        wptr_b_gray <= (wptr_b + 1) ^ ((wptr_b + 1) >> 1);
        cnt <= cnt + 1;
        cnt_bin <= cnt + 1;
        b_full_int <= (cnt + 1 == (1 << ASIZE) - 1);
        b_afull_int <= (cnt + 1 >= (1 << ASIZE) - 2);
        b_empty_int <= 1'b0;
        b_aempty_int <= 1'b0;
      end
      if (b_rinc && !empty && !b_dir) begin
        b_rdata <= mem[rptr_b];
        rptr_b <= rptr_b + 1;
        rptr_b_gray <= (rptr_b + 1) ^ ((rptr_b + 1) >> 1);
        cnt <= cnt - 1;
        cnt_bin <= cnt - 1;
        b_full_int <= (cnt - 1 == (1 << ASIZE) - 1);
        b_afull_int <= (cnt - 1 >= (1 << ASIZE) - 2);
        b_empty_int <= (cnt - 1 == 0);
        b_aempty_int <= (cnt - 1 <= 1);
      end
    end
  end

  always @(posedge a_clk) begin
    wptr_b_bin <= wptr_b_gray;
    rptr_b_bin <= rptr_b_gray;
  end

  always @(posedge b_clk) begin
    wptr_a_bin <= wptr_a_gray;
    rptr_a_bin <= rptr_a_gray;
  end

  assign a_full  = a_full_int;
  assign a_afull = a_afull_int;
  assign a_empty = a_empty_int;
  assign a_aempty = a_aempty_int;
  assign b_full  = b_full_int;
  assign b_afull = b_afull_int;
  assign b_empty = b_empty_int;
  assign b_aempty = b_aempty_int;

  assign a_rdata = (a_dir && !empty) ? mem[rptr_a] : {DSIZE{1'b0}};
  assign b_rdata = (!b_dir && !empty) ? mem[rptr_b] : {DSIZE{1'b0}};

endmodule
