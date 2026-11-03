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
  reg [ASIZE-1:0] a_full_cnt, b_full_cnt;
  reg [ASIZE-1:0] a_afull_cnt, b_afull_cnt;
  reg a_empty_reg, b_empty_reg;
  reg a_aempty_reg, b_aempty_reg;
  reg a_full_reg, b_full_reg;
  reg a_afull_reg, b_afull_reg;

  assign a_rdata = (a_dir == 1'b0 && a_empty_reg == 1'b0) ? mem[a_rd_ptr] : {DSIZE{1'b0}};
  assign b_rdata = (b_dir == 1'b0 && b_empty_reg == 1'b0) ? mem[b_rd_ptr] : {DSIZE{1'b0}};

  assign a_full = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;
  assign b_full = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (~a_rst_n) begin
      a_wr_ptr <= {ASIZE{1'b0}};
      a_rd_ptr <= {ASIZE{1'b0}};
      a_wr_ptr_gray <= {ASIZE{1'b0}};
      a_rd_ptr_gray <= {ASIZE{1'b0}};
      a_full_cnt <= {ASIZE{1'b0}};
      a_afull_cnt <= {ASIZE{1'b0}};
      a_empty_reg <= 1'b1;
      a_aempty_reg <= 1'b1;
      a_full_reg <= 1'b0;
      a_afull_reg <= 1'b0;
    end else begin
      if (a_dir == 1'b1 && a_winc == 1'b1 && a_full_reg == 1'b0) begin
        mem[a_wr_ptr] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1'b1;
        a_wr_ptr_gray <= (a_wr_ptr + 1'b1) ^ ((a_wr_ptr + 1'b1) >> 1);
        a_full_cnt <= a_full_cnt + 1'b1;
        if (a_full_cnt == (2**ASIZE - 1)) begin
          a_full_reg <= 1'b1;
        end
        if (a_full_cnt == (2**ASIZE - 2)) begin
          a_afull_reg <= 1'b1;
        end
      end
      if (a_dir == 1'b0 && a_rinc == 1'b1 && a_empty_reg == 1'b0) begin
        a_rd_ptr <= a_rd_ptr + 1'b1;
        a_rd_ptr_gray <= (a_rd_ptr + 1'b1) ^ ((a_rd_ptr + 1'b1) >> 1);
        a_full_cnt <= a_full_cnt - 1'b1;
        if (a_full_cnt == (2**ASIZE - 2)) begin
          a_afull_reg <= 1'b0;
        end
        if (a_full_cnt == (2**ASIZE - 1)) begin
          a_full_reg <= 1'b0;
        end
        if (a_rd_ptr == a_wr_ptr) begin
          a_empty_reg <= 1'b1;
        end else begin
          a_empty_reg <= 1'b0;
        end
        if (a_rd_ptr == (a_wr_ptr - 1)) begin
          a_aempty_reg <= 1'b1;
        end else begin
          a_aempty_reg <= 1'b0;
        end
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (~b_rst_n) begin
      b_wr_ptr <= {ASIZE{1'b0}};
      b_rd_ptr <= {ASIZE{1'b0}};
      b_wr_ptr_gray <= {ASIZE{1'b0}};
      b_rd_ptr_gray <= {ASIZE{1'b0}};
      b_full_cnt <= {ASIZE{1'b0}};
      b_afull_cnt <= {ASIZE{1'b0}};
      b_empty_reg <= 1'b1;
      b_aempty_reg <= 1'b1;
      b_full_reg <= 1'b0;
      b_afull_reg <= 1'b0;
    end else begin
      if (b_dir == 1'b1 && b_winc == 1'b1 && b_full_reg == 1'b0) begin
        mem[b_wr_ptr] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1'b1;
        b_wr_ptr_gray <= (b_wr_ptr + 1'b1) ^ ((b_wr_ptr + 1'b1) >> 1);
        b_full_cnt <= b_full_cnt + 1'b1;
        if (b_full_cnt == (2**ASIZE - 1)) begin
          b_full_reg <= 1'b1;
        end
        if (b_full_cnt == (2**ASIZE - 2)) begin
          b_afull_reg <= 1'b1;
        end
      end
      if (b_dir == 1'b0 && b_rinc == 1'b1 && b_empty_reg == 1'b0) begin
        b_rd_ptr <= b_rd_ptr + 1'b1;
        b_rd_ptr_gray <= (b_rd_ptr + 1'b1) ^ ((b_rd_ptr + 1'b1) >> 1);
        b_full_cnt <= b_full_cnt - 1'b1;
        if (b_full_cnt == (2**ASIZE - 2)) begin
          b_afull_reg <= 1'b0;
        end
        if (b_full_cnt == (2**ASIZE - 1)) begin
          b_full_reg <= 1'b0;
        end
        if (b_rd_ptr == b_wr_ptr) begin
          b_empty_reg <= 1'b1;
        end else begin
          b_empty_reg <= 1'b0;
        end
        if (b_rd_ptr == (b_wr_ptr - 1)) begin
          b_aempty_reg <= 1'b1;
        end else begin
          b_aempty_reg <= 1'b0;
        end
      end
    end
  end

  always @(posedge a_clk) begin
    a_wr_ptr_sync <= a_wr_ptr;
    a_rd_ptr_sync <= a_rd_ptr;
    a_wr_ptr_sync_gray <= a_wr_ptr_gray;
    a_rd_ptr_sync_gray <= a_rd_ptr_gray;
  end

  always @(posedge b_clk) begin
    b_wr_ptr_sync <= b_wr_ptr;
    b_rd_ptr_sync <= b_rd_ptr;
    b_wr_ptr_sync_gray <= b_wr_ptr_gray;
    b_rd_ptr_sync_gray <= b_rd_ptr_gray;
  end

endmodule
