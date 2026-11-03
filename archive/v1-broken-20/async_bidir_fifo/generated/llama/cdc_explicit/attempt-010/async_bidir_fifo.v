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
  reg [ASIZE-1:0] a_wptr_gray, a_rptr_gray, b_wptr_gray, b_rptr_gray;
  reg [ASIZE-1:0] a_wptr_sync, a_rptr_sync, b_wptr_sync, b_rptr_sync;
  reg [ASIZE-1:0] a_wptr_sync_gray, a_rptr_sync_gray, b_wptr_sync_gray, b_rptr_sync_gray;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;
  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  // Gray encoding
  always @(posedge a_clk) begin
    a_wptr_gray <= {a_wptr[ASIZE-2:0], 1'b0} ^ {a_wptr[ASIZE-1], a_wptr[ASIZE-2:1]};
    a_rptr_gray <= {a_rptr[ASIZE-2:0], 1'b0} ^ {a_rptr[ASIZE-1], a_rptr[ASIZE-2:1]};
  end

  always @(posedge b_clk) begin
    b_wptr_gray <= {b_wptr[ASIZE-2:0], 1'b0} ^ {b_wptr[ASIZE-1], b_wptr[ASIZE-2:1]};
    b_rptr_gray <= {b_rptr[ASIZE-2:0], 1'b0} ^ {b_rptr[ASIZE-1], b_rptr[ASIZE-2:1]};
  end

  // Synchronization
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_wptr_sync <= 0;
      a_rptr_sync <= 0;
    end else begin
      a_wptr_sync <= b_wptr_sync;
      a_rptr_sync <= b_rptr_sync;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_wptr_sync <= 0;
      b_rptr_sync <= 0;
    end else begin
      b_wptr_sync <= a_wptr_sync;
      b_rptr_sync <= a_rptr_sync;
    end
  end

  always @(posedge a_clk) begin
    a_wptr_sync_gray <= {a_wptr_sync[ASIZE-2:0], 1'b0} ^ {a_wptr_sync[ASIZE-1], a_wptr_sync[ASIZE-2:1]};
    a_rptr_sync_gray <= {a_rptr_sync[ASIZE-2:0], 1'b0} ^ {a_rptr_sync[ASIZE-1], a_rptr_sync[ASIZE-2:1]};
  end

  always @(posedge b_clk) begin
    b_wptr_sync_gray <= {b_wptr_sync[ASIZE-2:0], 1'b0} ^ {b_wptr_sync[ASIZE-1], b_wptr_sync[ASIZE-2:1]};
    b_rptr_sync_gray <= {b_rptr_sync[ASIZE-2:0], 1'b0} ^ {b_rptr_sync[ASIZE-1], b_rptr_sync[ASIZE-2:1]};
  end

  // Write logic
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_wptr <= 0;
    end else if (a_dir && a_winc && !a_full_reg) begin
      mem[a_wptr] <= a_wdata;
      a_wptr <= a_wptr + 1;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_wptr <= 0;
    end else if (b_dir && b_winc && !b_full_reg) begin
      mem[b_wptr] <= b_wdata;
      b_wptr <= b_wptr + 1;
    end
  end

  // Read logic
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_rptr <= 0;
      a_rdata_reg <= 0;
    end else if (!a_dir && a_rinc && !a_empty_reg) begin
      a_rdata_reg <= mem[a_rptr];
      a_rptr <= a_rptr + 1;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_rptr <= 0;
      b_rdata_reg <= 0;
    end else if (!b_dir && b_rinc && !b_empty_reg) begin
      b_rdata_reg <= mem[b_rptr];
      b_rptr <= b_rptr + 1;
    end
  end

  // Flags
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_full_reg <= 0;
      a_afull_reg <= 0;
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else begin
      a_full_reg <= (a_wptr == {a_rptr_sync_gray[ASIZE-2:0], 1'b0} ^ {a_rptr_sync_gray[ASIZE-1], a_rptr_sync_gray[ASIZE-2:1]} + 1);
      a_afull_reg <= (a_wptr == {a_rptr_sync_gray[ASIZE-2:0], 1'b0} ^ {a_rptr_sync_gray[ASIZE-1], a_rptr_sync_gray[ASIZE-2:1]} + 2**ASIZE - 2);
      a_empty_reg <= (a_rptr == a_wptr);
      a_aempty_reg <= (a_rptr == {a_wptr_sync_gray[ASIZE-2:0], 1'b0} ^ {a_wptr_sync_gray[ASIZE-1], a_wptr_sync_gray[ASIZE-2:1]} + 1);
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_full_reg <= 0;
      b_afull_reg <= 0;
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else begin
      b_full_reg <= (b_wptr == {b_rptr_sync_gray[ASIZE-2:0], 1'b0} ^ {b_rptr_sync_gray[ASIZE-1], b_rptr_sync_gray[ASIZE-2:1]} + 1);
      b_afull_reg <= (b_wptr == {b_rptr_sync_gray[ASIZE-2:0], 1'b0} ^ {b_rptr_sync_gray[ASIZE-1], b_rptr_sync_gray[ASIZE-2:1]} + 2**ASIZE - 2);
      b_empty_reg <= (b_rptr == b_wptr);
      b_aempty_reg <= (b_rptr == {b_wptr_sync_gray[ASIZE-2:0], 1'b0} ^ {b_wptr_sync_gray[ASIZE-1], b_wptr_sync_gray[ASIZE-2:1]} + 1);
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
