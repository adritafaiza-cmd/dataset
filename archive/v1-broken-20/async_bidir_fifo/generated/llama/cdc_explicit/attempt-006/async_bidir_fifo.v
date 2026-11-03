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
  reg [ASIZE-1:0] a_wr_ptr, a_rd_ptr, b_wr_ptr, b_rd_ptr;
  reg [ASIZE-1:0] a_wr_ptr_gray, a_rd_ptr_gray, b_wr_ptr_gray, b_rd_ptr_gray;
  reg [ASIZE-1:0] a_wr_ptr_sync, a_rd_ptr_sync, b_wr_ptr_sync, b_rd_ptr_sync;
  reg [ASIZE-1:0] a_wr_ptr_sync_gray, a_rd_ptr_sync_gray, b_wr_ptr_sync_gray, b_rd_ptr_sync_gray;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;
  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  // Gray code conversion
  always @(posedge a_clk) begin
    a_wr_ptr_gray <= {a_wr_ptr[ASIZE-2:0], 1'b0} ^ {a_wr_ptr[ASIZE-1], a_wr_ptr[ASIZE-2:1]};
    a_rd_ptr_gray <= {a_rd_ptr[ASIZE-2:0], 1'b0} ^ {a_rd_ptr[ASIZE-1], a_rd_ptr[ASIZE-2:1]};
  end

  always @(posedge b_clk) begin
    b_wr_ptr_gray <= {b_wr_ptr[ASIZE-2:0], 1'b0} ^ {b_wr_ptr[ASIZE-1], b_wr_ptr[ASIZE-2:1]};
    b_rd_ptr_gray <= {b_rd_ptr[ASIZE-2:0], 1'b0} ^ {b_rd_ptr[ASIZE-1], b_rd_ptr[ASIZE-2:1]};
  end

  // Synchronization of pointers across clock domains
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_wr_ptr_sync <= 0;
      a_rd_ptr_sync <= 0;
    end else begin
      a_wr_ptr_sync <= b_wr_ptr_sync_gray;
      a_rd_ptr_sync <= b_rd_ptr_sync_gray;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_wr_ptr_sync <= 0;
      b_rd_ptr_sync <= 0;
    end else begin
      b_wr_ptr_sync <= a_wr_ptr_sync_gray;
      b_rd_ptr_sync <= a_rd_ptr_sync_gray;
    end
  end

  // Gray code conversion for synchronized pointers
  always @(posedge a_clk) begin
    a_wr_ptr_sync_gray <= {a_wr_ptr_sync[ASIZE-2:0], 1'b0} ^ {a_wr_ptr_sync[ASIZE-1], a_wr_ptr_sync[ASIZE-2:1]};
    a_rd_ptr_sync_gray <= {a_rd_ptr_sync[ASIZE-2:0], 1'b0} ^ {a_rd_ptr_sync[ASIZE-1], a_rd_ptr_sync[ASIZE-2:1]};
  end

  always @(posedge b_clk) begin
    b_wr_ptr_sync_gray <= {b_wr_ptr_sync[ASIZE-2:0], 1'b0} ^ {b_wr_ptr_sync[ASIZE-1], b_wr_ptr_sync[ASIZE-2:1]};
    b_rd_ptr_sync_gray <= {b_rd_ptr_sync[ASIZE-2:0], 1'b0} ^ {b_rd_ptr_sync[ASIZE-1], b_rd_ptr_sync[ASIZE-2:1]};
  end

  // Write logic
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
    end else if (a_dir && a_winc && !a_full_reg) begin
      mem[a_wr_ptr] <= a_wdata;
      a_wr_ptr <= a_wr_ptr + 1;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
    end else if (b_dir && b_winc && !b_full_reg) begin
      mem[b_wr_ptr] <= b_wdata;
      b_wr_ptr <= b_wr_ptr + 1;
    end
  end

  // Read logic
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_rd_ptr <= 0;
      a_rdata_reg <= 0;
    end else if (a_dir == 0 && a_rinc && !a_empty_reg) begin
      a_rdata_reg <= mem[a_rd_ptr];
      a_rd_ptr <= a_rd_ptr + 1;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_rd_ptr <= 0;
      b_rdata_reg <= 0;
    end else if (b_dir == 0 && b_rinc && !b_empty_reg) begin
      b_rdata_reg <= mem[b_rd_ptr];
      b_rd_ptr <= b_rd_ptr + 1;
    end
  end

  // Full and empty flags
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_full_reg <= 0;
      a_afull_reg <= 0;
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else begin
      a_full_reg <= (a_wr_ptr == {a_rd_ptr_sync[ASIZE-1], a_rd_ptr_sync[ASIZE-2:0]} + 1);
      a_afull_reg <= (a_wr_ptr == {a_rd_ptr_sync[ASIZE-1], a_rd_ptr_sync[ASIZE-2:0]} + 2**ASIZE - 2);
      a_empty_reg <= (a_wr_ptr == a_rd_ptr);
      a_aempty_reg <= (a_wr_ptr == a_rd_ptr + 1);
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_full_reg <= 0;
      b_afull_reg <= 0;
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else begin
      b_full_reg <= (b_wr_ptr == {a_wr_ptr_sync[ASIZE-1], a_wr_ptr_sync[ASIZE-2:0]} + 1);
      b_afull_reg <= (b_wr_ptr == {a_wr_ptr_sync[ASIZE-1], a_wr_ptr_sync[ASIZE-2:0]} + 2**ASIZE - 2);
      b_empty_reg <= (b_wr_ptr == b_rd_ptr);
      b_aempty_reg <= (b_wr_ptr == b_rd_ptr + 1);
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
