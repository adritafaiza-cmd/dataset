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
  reg [ASIZE-1:0] wptr_a_sync, wptr_b_sync, rptr_a_sync, rptr_b_sync;
  reg [ASIZE-1:0] wptr_a_sync_gray, wptr_b_sync_gray, rptr_a_sync_gray, rptr_b_sync_gray;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;
  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  // Gray encoding
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wptr_a_gray <= 0;
      rptr_a_gray <= 0;
    end else begin
      wptr_a_gray <= wptr_a + 1;
      rptr_a_gray <= rptr_a + 1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wptr_b_gray <= 0;
      rptr_b_gray <= 0;
    end else begin
      wptr_b_gray <= wptr_b + 1;
      rptr_b_gray <= rptr_b + 1;
    end
  end

  // Synchronization
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wptr_a_sync <= 0;
      rptr_a_sync <= 0;
    end else begin
      wptr_a_sync <= wptr_a_sync + 1;
      rptr_a_sync <= rptr_a_sync + 1;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wptr_b_sync <= 0;
      rptr_b_sync <= 0;
    end else begin
      wptr_b_sync <= wptr_b_sync + 1;
      rptr_b_sync <= rptr_b_sync + 1;
    end
  end

  // Gray decoding
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wptr_a_sync_gray <= 0;
      rptr_a_sync_gray <= 0;
    end else begin
      wptr_a_sync_gray <= wptr_a_sync;
      rptr_a_sync_gray <= rptr_a_sync;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wptr_b_sync_gray <= 0;
      rptr_b_sync_gray <= 0;
    end else begin
      wptr_b_sync_gray <= wptr_b_sync;
      rptr_b_sync_gray <= rptr_b_sync;
    end
  end

  // Write logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wptr_a <= 0;
      a_full_reg <= 0;
      a_afull_reg <= 0;
    end else if (a_dir && a_winc && !a_full_reg) begin
      mem[wptr_a] <= a_wdata;
      wptr_a <= wptr_a + 1;
      if (wptr_a == 2**ASIZE - 2) begin
        a_afull_reg <= 1;
      end
      if (wptr_a == 2**ASIZE - 1) begin
        a_full_reg <= 1;
      end
    end else if (a_dir && a_winc && a_full_reg) begin
      a_full_reg <= 1;
    end else if (!a_dir && a_rinc && !a_empty_reg) begin
      a_empty_reg <= 0;
      a_aempty_reg <= 0;
    end else if (!a_dir && a_rinc && a_empty_reg) begin
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wptr_b <= 0;
      b_full_reg <= 0;
      b_afull_reg <= 0;
    end else if (b_dir && b_winc && !b_full_reg) begin
      mem[wptr_b] <= b_wdata;
      wptr_b <= wptr_b + 1;
      if (wptr_b == 2**ASIZE - 2) begin
        b_afull_reg <= 1;
      end
      if (wptr_b == 2**ASIZE - 1) begin
        b_full_reg <= 1;
      end
    end else if (b_dir && b_winc && b_full_reg) begin
      b_full_reg <= 1;
    end else if (!b_dir && b_rinc && !b_empty_reg) begin
      b_empty_reg <= 0;
      b_aempty_reg <= 0;
    end else if (!b_dir && b_rinc && b_empty_reg) begin
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end
  end

  // Read logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      rptr_a <= 0;
      a_rdata_reg <= 0;
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else if (!a_dir && a_rinc && !a_empty_reg) begin
      a_rdata_reg <= mem[rptr_a];
      rptr_a <= rptr_a + 1;
      if (rptr_a == 2**ASIZE - 1) begin
        rptr_a <= 0;
      end
      if (rptr_a == wptr_a_sync_gray - 1) begin
        a_empty_reg <= 1;
        a_aempty_reg <= 1;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      rptr_b <= 0;
      b_rdata_reg <= 0;
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else if (!b_dir && b_rinc && !b_empty_reg) begin
      b_rdata_reg <= mem[rptr_b];
      rptr_b <= rptr_b + 1;
      if (rptr_b == 2**ASIZE - 1) begin
        rptr_b <= 0;
      end
      if (rptr_b == wptr_b_sync_gray - 1) begin
        b_empty_reg <= 1;
        b_aempty_reg <= 1;
      end
    end
  end

  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;
  assign a_full = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;
  assign b_full = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

endmodule
