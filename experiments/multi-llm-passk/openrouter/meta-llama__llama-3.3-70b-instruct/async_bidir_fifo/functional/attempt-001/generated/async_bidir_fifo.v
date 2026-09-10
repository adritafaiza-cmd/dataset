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
  reg [ASIZE-1:0] a_ptr_gray_sync, b_ptr_gray_sync;
  reg [ASIZE-1:0] a_cnt, b_cnt;
  reg [ASIZE-1:0] a_cnt_sync, b_cnt_sync;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;
  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  // Gray code conversion
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_ptr_gray <= '0;
    end else begin
      a_ptr_gray <= a_ptr ^ (a_ptr >> 1);
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_ptr_gray <= '0;
    end else begin
      b_ptr_gray <= b_ptr ^ (b_ptr >> 1);
    end
  end

  // Synchronization of pointers and counts
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_ptr_sync <= '0;
      a_ptr_gray_sync <= '0;
      a_cnt_sync <= '0;
    end else begin
      a_ptr_sync <= b_ptr_gray;
      a_ptr_gray_sync <= b_ptr;
      a_cnt_sync <= b_cnt;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_ptr_sync <= '0;
      b_ptr_gray_sync <= '0;
      b_cnt_sync <= '0;
    end else begin
      b_ptr_sync <= a_ptr_gray;
      b_ptr_gray_sync <= a_ptr;
      b_cnt_sync <= a_cnt;
    end
  end

  // Write logic
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_ptr <= '0;
      a_cnt <= '0;
    end else if (a_dir && a_winc &&!a_full_reg) begin
      mem[a_ptr] <= a_wdata;
      a_ptr <= a_ptr + 1;
      a_cnt <= a_cnt + 1;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_ptr <= '0;
      b_cnt <= '0;
    end else if (b_dir && b_winc &&!b_full_reg) begin
      mem[b_ptr] <= b_wdata;
      b_ptr <= b_ptr + 1;
      b_cnt <= b_cnt + 1;
    end
  end

  // Read logic
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_rdata_reg <= '0;
    end else if (!a_dir && a_rinc &&!a_empty_reg) begin
      a_rdata_reg <= mem[a_ptr_sync];
      a_cnt <= a_cnt - 1;
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_rdata_reg <= '0;
    end else if (!b_dir && b_rinc &&!b_empty_reg) begin
      b_rdata_reg <= mem[b_ptr_sync];
      b_cnt <= b_cnt - 1;
    end
  end

  // Flag logic
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      a_full_reg <= 1'b0;
      a_afull_reg <= 1'b0;
      a_empty_reg <= 1'b1;
      a_aempty_reg <= 1'b1;
    end else begin
      a_full_reg <= (a_cnt == 2**ASIZE);
      a_afull_reg <= (a_cnt >= 2**ASIZE - 2);
      a_empty_reg <= (a_cnt == 0);
      a_aempty_reg <= (a_cnt <= 1);
    end
  end

  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      b_full_reg <= 1'b0;
      b_afull_reg <= 1'b0;
      b_empty_reg <= 1'b1;
      b_aempty_reg <= 1'b1;
    end else begin
      b_full_reg <= (b_cnt == 2**ASIZE);
      b_afull_reg <= (b_cnt >= 2**ASIZE - 2);
      b_empty_reg <= (b_cnt == 0);
      b_aempty_reg <= (b_cnt <= 1);
    end
  end

  assign a_rdata = (FALLTHROUGH == "TRUE" && a_empty_reg)? a_wdata : a_rdata_reg;
  assign b_rdata = (FALLTHROUGH == "TRUE" && b_empty_reg)? b_wdata : b_rdata_reg;
  assign a_full = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;
  assign b_full = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

endmodule
