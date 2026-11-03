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
  reg [ASIZE-1:0] a_wptr, a_rptr, b_wptr, b_rptr;
  reg [ASIZE-1:0] a_wptr_sync, b_wptr_sync, a_rptr_sync, b_rptr_sync;
  reg [ASIZE-1:0] a_wptr_gray, b_wptr_gray, a_rptr_gray, b_rptr_gray;
  reg [ASIZE-1:0] a_wptr_gray_sync, b_wptr_gray_sync, a_rptr_gray_sync, b_rptr_gray_sync;
  reg a_full_int, b_full_int;
  reg a_empty_int, b_empty_int;
  reg a_afull_int, b_afull_int;
  reg a_aempty_int, b_aempty_int;

  assign a_full = a_full_int;
  assign b_full = b_full_int;
  assign a_empty = a_empty_int;
  assign b_empty = b_empty_int;
  assign a_afull = a_afull_int;
  assign b_afull = b_afull_int;
  assign a_aempty = a_aempty_int;
  assign b_aempty = b_aempty_int;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wptr <= 0;
      a_rptr <= 0;
      a_wptr_gray <= 0;
      a_rptr_gray <= 0;
      a_full_int <= 0;
      a_empty_int <= 1;
      a_afull_int <= 0;
      a_aempty_int <= 1;
    end else begin
      if (a_winc && !a_full_int) begin
        mem[a_wptr] <= a_wdata;
        a_wptr <= a_wptr + 1;
        a_wptr_gray <= (a_wptr + 1) ^ ((a_wptr + 1) >> 1);
        if (a_wptr == (2**ASIZE - 1)) begin
          a_full_int <= 1;
        end
      end
      if (a_rinc && !a_empty_int) begin
        a_rptr <= a_rptr + 1;
        a_rptr_gray <= (a_rptr + 1) ^ ((a_rptr + 1) >> 1);
        if (a_rptr == (2**ASIZE - 1)) begin
          a_empty_int <= 1;
        end
      end
      if (a_winc && !a_full_int) begin
        if (a_wptr - a_rptr == (2**(ASIZE-1) - 1)) begin
          a_afull_int <= 1;
        end else begin
          a_afull_int <= 0;
        end
      end else if (!a_winc && a_full_int) begin
        if (a_wptr - a_rptr == (2**(ASIZE-1))) begin
          a_afull_int <= 1;
        end else begin
          a_afull_int <= 0;
        end
      end
      if (a_rinc && !a_empty_int) begin
        if (a_rptr - a_wptr == 1) begin
          a_aempty_int <= 1;
        end else begin
          a_aempty_int <= 0;
        end
      end else if (!a_rinc && a_empty_int) begin
        if (a_rptr - a_wptr == 0) begin
          a_aempty_int <= 1;
        end else begin
          a_aempty_int <= 0;
        end
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wptr <= 0;
      b_rptr <= 0;
      b_wptr_gray <= 0;
      b_rptr_gray <= 0;
      b_full_int <= 0;
      b_empty_int <= 1;
      b_afull_int <= 0;
      b_aempty_int <= 1;
    end else begin
      if (b_winc && !b_full_int) begin
        mem[b_wptr] <= b_wdata;
        b_wptr <= b_wptr + 1;
        b_wptr_gray <= (b_wptr + 1) ^ ((b_wptr + 1) >> 1);
        if (b_wptr == (2**ASIZE - 1)) begin
          b_full_int <= 1;
        end
      end
      if (b_rinc && !b_empty_int) begin
        b_rptr <= b_rptr + 1;
        b_rptr_gray <= (b_rptr + 1) ^ ((b_rptr + 1) >> 1);
        if (b_rptr == (2**ASIZE - 1)) begin
          b_empty_int <= 1;
        end
      end
      if (b_winc && !b_full_int) begin
        if (b_wptr - b_rptr == (2**(ASIZE-1) - 1)) begin
          b_afull_int <= 1;
        end else begin
          b_afull_int <= 0;
        end
      end else if (!b_winc && b_full_int) begin
        if (b_wptr - b_rptr == (2**(ASIZE-1))) begin
          b_afull_int <= 1;
        end else begin
          b_afull_int <= 0;
        end
      end
      if (b_rinc && !b_empty_int) begin
        if (b_rptr - b_wptr == 1) begin
          b_aempty_int <= 1;
        end else begin
          b_aempty_int <= 0;
        end
      end else if (!b_rinc && b_empty_int) begin
        if (b_rptr - b_wptr == 0) begin
          b_aempty_int <= 1;
        end else begin
          b_aempty_int <= 0;
        end
      end
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata <= 0;
    end else if (a_rinc && !a_empty_int) begin
      a_rdata <= mem[a_rptr];
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata <= 0;
    end else if (b_rinc && !b_empty_int) begin
      b_rdata <= mem[b_rptr];
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wptr_sync <= 0;
      a_rptr_sync <= 0;
      a_wptr_gray_sync <= 0;
      a_rptr_gray_sync <= 0;
    end else begin
      a_wptr_sync <= b_wptr;
      a_rptr_sync <= b_rptr;
      a_wptr_gray_sync <= b_wptr_gray;
      a_rptr_gray_sync <= b_rptr_gray;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wptr_sync <= 0;
      b_rptr_sync <= 0;
      b_wptr_gray_sync <= 0;
      b_rptr_gray_sync <= 0;
    end else begin
      b_wptr_sync <= a_wptr;
      b_rptr_sync <= a_rptr;
      b_wptr_gray_sync <= a_wptr_gray;
      b_rptr_gray_sync <= a_rptr_gray;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_empty_int <= 1;
    end else if (a_dir && a_rinc && !a_empty_int) begin
      if (a_rptr == a_wptr_sync) begin
        a_empty_int <= 1;
      end
    end else if (!a_dir && a_winc && !a_full_int) begin
      if (a_wptr == a_rptr_sync) begin
        a_empty_int <= 0;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_empty_int <= 1;
    end else if (b_dir && b_rinc && !b_empty_int) begin
      if (b_rptr == b_wptr_sync) begin
        b_empty_int <= 1;
      end
    end else if (!b_dir && b_winc && !b_full_int) begin
      if (b_wptr == b_rptr_sync) begin
        b_empty_int <= 0;
      end
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_int <= 0;
    end else if (a_dir && a_winc && !a_full_int) begin
      if (a_wptr == (a_rptr_sync + (2**ASIZE - 1))) begin
        a_full_int <= 1;
      end
    end else if (!a_dir && a_rinc && !a_empty_int) begin
      if (a_rptr == (a_wptr_sync + 1)) begin
        a_full_int <= 0;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_int <= 0;
    end else if (b_dir && b_winc && !b_full_int) begin
      if (b_wptr == (b_rptr_sync + (2**ASIZE - 1))) begin
        b_full_int <= 1;
      end
    end else if (!b_dir && b_rinc && !b_empty_int) begin
      if (b_rptr == (b_wptr_sync + 1)) begin
        b_full_int <= 0;
      end
    end
  end

endmodule
