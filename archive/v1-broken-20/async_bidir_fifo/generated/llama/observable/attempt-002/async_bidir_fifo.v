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
  reg [ASIZE-1:0] a_ptr, a_ptr_gray, b_ptr, b_ptr_gray;
  reg [ASIZE-1:0] a_ptr_sync, b_ptr_sync;
  reg [ASIZE-1:0] a_ptr_sync_gray, b_ptr_sync_gray;
  reg [ASIZE-1:0] a_cnt, b_cnt;
  reg a_empty_int, a_full_int, b_empty_int, b_full_int;
  reg a_afull_int, b_afull_int;
  reg a_aempty_int, b_aempty_int;

  assign a_empty = a_empty_int;
  assign a_full = a_full_int;
  assign b_empty = b_empty_int;
  assign b_full = b_full_int;
  assign a_afull = a_afull_int;
  assign b_afull = b_afull_int;
  assign a_aempty = a_aempty_int;
  assign b_aempty = b_aempty_int;

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_ptr <= 0;
      a_ptr_gray <= 0;
      a_cnt <= 0;
      a_empty_int <= 1;
      a_full_int <= 0;
      a_afull_int <= 0;
      a_aempty_int <= 1;
    end else begin
      if (a_winc &&!a_full_int) begin
        mem[a_ptr] <= a_wdata;
        a_ptr <= a_ptr + 1;
        a_cnt <= a_cnt + 1;
        if (a_cnt == 2**ASIZE - 1) begin
          a_full_int <= 1;
        end
        if (a_cnt == 2**ASIZE - 2) begin
          a_afull_int <= 1;
        end
      end
      if (a_rinc &&!a_empty_int) begin
        a_rdata <= mem[a_ptr];
        a_ptr <= a_ptr + 1;
        a_cnt <= a_cnt - 1;
        if (a_cnt == 0) begin
          a_empty_int <= 1;
        end
        if (a_cnt == 1) begin
          a_aempty_int <= 1;
        end
        if (a_cnt == 2**ASIZE - 3) begin
          a_afull_int <= 0;
        end
        if (a_cnt == 2**ASIZE - 2) begin
          a_full_int <= 0;
        end
      end
      a_ptr_gray <= a_ptr + (a_ptr >> 1);
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_ptr <= 0;
      b_ptr_gray <= 0;
      b_cnt <= 0;
      b_empty_int <= 1;
      b_full_int <= 0;
      b_afull_int <= 0;
      b_aempty_int <= 1;
    end else begin
      if (b_winc &&!b_full_int) begin
        mem[b_ptr] <= b_wdata;
        b_ptr <= b_ptr + 1;
        b_cnt <= b_cnt + 1;
        if (b_cnt == 2**ASIZE - 1) begin
          b_full_int <= 1;
        end
        if (b_cnt == 2**ASIZE - 2) begin
          b_afull_int <= 1;
        end
      end
      if (b_rinc &&!b_empty_int) begin
        b_rdata <= mem[b_ptr];
        b_ptr <= b_ptr + 1;
        b_cnt <= b_cnt - 1;
        if (b_cnt == 0) begin
          b_empty_int <= 1;
        end
        if (b_cnt == 1) begin
          b_aempty_int <= 1;
        end
        if (b_cnt == 2**ASIZE - 3) begin
          b_afull_int <= 0;
        end
        if (b_cnt == 2**ASIZE - 2) begin
          b_full_int <= 0;
        end
      end
      b_ptr_gray <= b_ptr + (b_ptr >> 1);
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_ptr_sync <= 0;
      a_ptr_sync_gray <= 0;
    end else begin
      a_ptr_sync_gray <= b_ptr_gray;
      a_ptr_sync <= a_ptr_sync_gray - (a_ptr_sync_gray >> 1);
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_ptr_sync <= 0;
      b_ptr_sync_gray <= 0;
    end else begin
      b_ptr_sync_gray <= a_ptr_gray;
      b_ptr_sync <= b_ptr_sync_gray - (b_ptr_sync_gray >> 1);
    end

  assign a_rdata = (a_dir &&!a_empty_int)? mem[a_ptr] : (a_dir && a_empty_int)? {DSIZE{1'bz}} : mem[a_ptr_sync];
  assign b_rdata = (b_dir &&!b_empty_int)? mem[b_ptr] : (b_dir && b_empty_int)? {DSIZE{1'bz}} : mem[b_ptr_sync];

endmodule
