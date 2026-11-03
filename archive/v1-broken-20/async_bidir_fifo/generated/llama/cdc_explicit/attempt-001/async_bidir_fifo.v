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
  reg [ASIZE-1:0] a_ptr, a_ptr_gray, a_ptr_bin;
  reg [ASIZE-1:0] b_ptr, b_ptr_gray, b_ptr_bin;
  reg [ASIZE-1:0] a_ptr_sync, b_ptr_sync;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;
  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  // Gray code conversion
  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_ptr_gray <= '0;
      a_ptr_bin <= '0;
    end else if (a_winc && a_dir) begin
      a_ptr_bin <= a_ptr_bin + 1;
      a_ptr_gray <= a_ptr_bin ^ (a_ptr_bin >> 1);
    end else if (a_rinc && !a_dir) begin
      a_ptr_bin <= a_ptr_bin - 1;
      a_ptr_gray <= a_ptr_bin ^ (a_ptr_bin >> 1);
    end

  // Synchronize gray code to b_clk domain
  reg [ASIZE-1:0] a_ptr_sync_reg [1:0];
  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      a_ptr_sync_reg[0] <= '0;
      a_ptr_sync_reg[1] <= '0;
    end else begin
      a_ptr_sync_reg[0] <= a_ptr_gray;
      a_ptr_sync_reg[1] <= a_ptr_sync_reg[0];
    end
  assign a_ptr_sync = a_ptr_sync_reg[1];

  // Gray code conversion
  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_ptr_gray <= '0;
      b_ptr_bin <= '0;
    end else if (b_winc && b_dir) begin
      b_ptr_bin <= b_ptr_bin + 1;
      b_ptr_gray <= b_ptr_bin ^ (b_ptr_bin >> 1);
    end else if (b_rinc && !b_dir) begin
      b_ptr_bin <= b_ptr_bin - 1;
      b_ptr_gray <= b_ptr_bin ^ (b_ptr_bin >> 1);
    end

  // Synchronize gray code to a_clk domain
  reg [ASIZE-1:0] b_ptr_sync_reg [1:0];
  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      b_ptr_sync_reg[0] <= '0;
      b_ptr_sync_reg[1] <= '0;
    end else begin
      b_ptr_sync_reg[0] <= b_ptr_gray;
      b_ptr_sync_reg[1] <= b_ptr_sync_reg[0];
    end
  assign b_ptr_sync = b_ptr_sync_reg[1];

  // Write logic
  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_ptr <= '0;
    end else if (a_winc && a_dir) begin
      mem[a_ptr] <= a_wdata;
      a_ptr <= a_ptr + 1;
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_ptr <= '0;
    end else if (b_winc && b_dir) begin
      mem[b_ptr] <= b_wdata;
      b_ptr <= b_ptr + 1;
    end

  // Read logic
  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_rdata_reg <= '0;
    end else if (a_rinc && !a_dir) begin
      a_rdata_reg <= mem[a_ptr];
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_rdata_reg <= '0;
    end else if (b_rinc && !b_dir) begin
      b_rdata_reg <= mem[b_ptr];
    end

  // Full/empty flags
  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_full_reg <= 1'b0;
      a_afull_reg <= 1'b0;
      a_empty_reg <= 1'b1;
      a_aempty_reg <= 1'b1;
    end else begin
      if (a_winc && a_dir) begin
        if (a_ptr_bin == 2**ASIZE - 2) begin
          a_afull_reg <= 1'b1;
        end else if (a_ptr_bin == 2**ASIZE - 1) begin
          a_full_reg <= 1'b1;
        end
      end else if (a_rinc && !a_dir) begin
        if (a_ptr_bin == 1) begin
          a_aempty_reg <= 1'b0;
        end else if (a_ptr_bin == 0) begin
          a_empty_reg <= 1'b0;
        end
      end
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_full_reg <= 1'b0;
      b_afull_reg <= 1'b0;
      b_empty_reg <= 1'b1;
      b_aempty_reg <= 1'b1;
    end else begin
      if (b_winc && b_dir) begin
        if (b_ptr_bin == 2**ASIZE - 2) begin
          b_afull_reg <= 1'b1;
        end else if (b_ptr_bin == 2**ASIZE - 1) begin
          b_full_reg <= 1'b1;
        end
      end else if (b_rinc && !b_dir) begin
        if (b_ptr_bin == 1) begin
          b_aempty_reg <= 1'b0;
        end else if (b_ptr_bin == 0) begin
          b_empty_reg <= 1'b0;
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
