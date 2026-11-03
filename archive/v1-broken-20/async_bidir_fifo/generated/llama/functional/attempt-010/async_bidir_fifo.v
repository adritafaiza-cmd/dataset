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
  reg [ASIZE-1:0] a_full_cnt, a_empty_cnt, b_full_cnt, b_empty_cnt;
  reg [ASIZE-1:0] a_afull_cnt, a_aempty_cnt, b_afull_cnt, b_aempty_cnt;
  reg a_full_flag, a_empty_flag, b_full_flag, b_empty_flag;
  reg a_afull_flag, a_aempty_flag, b_afull_flag, b_aempty_flag;

  assign a_full = a_full_flag;
  assign a_afull = a_afull_flag;
  assign a_empty = a_empty_flag;
  assign a_aempty = a_aempty_flag;
  assign b_full = b_full_flag;
  assign b_afull = b_afull_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_aempty_flag;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_full_cnt <= 0;
      a_empty_cnt <= 2**ASIZE;
      a_afull_cnt <= 0;
      a_aempty_cnt <= 2**ASIZE;
      a_full_flag <= 0;
      a_empty_flag <= 1;
      a_afull_flag <= 0;
      a_aempty_flag <= 1;
    end else begin
      if (a_dir && a_winc) begin
        mem[a_wr_ptr] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1;
        a_full_cnt <= a_full_cnt + 1;
        a_empty_cnt <= a_empty_cnt - 1;
        if (a_full_cnt == 2**ASIZE - 1) begin
          a_full_flag <= 1;
        end else begin
          a_full_flag <= 0;
        end
        if (a_empty_cnt == 0) begin
          a_empty_flag <= 1;
        end else begin
          a_empty_flag <= 0;
        end
        if (a_afull_cnt == 2**ASIZE - 2) begin
          a_afull_flag <= 1;
        end else begin
          a_afull_flag <= 0;
        end
        if (a_aempty_cnt == 1) begin
          a_aempty_flag <= 1;
        end else begin
          a_aempty_flag <= 0;
        end
      end
      if (!a_dir && a_rinc) begin
        a_rdata <= mem[a_rd_ptr];
        a_rd_ptr <= a_rd_ptr + 1;
        a_full_cnt <= a_full_cnt - 1;
        a_empty_cnt <= a_empty_cnt + 1;
        if (a_full_cnt == 0) begin
          a_full_flag <= 0;
        end
        if (a_empty_cnt == 2**ASIZE) begin
          a_empty_flag <= 1;
        end else begin
          a_empty_flag <= 0;
        end
        if (a_afull_cnt == 0) begin
          a_afull_flag <= 0;
        end
        if (a_aempty_cnt == 2**ASIZE - 1) begin
          a_aempty_flag <= 1;
        end else begin
          a_aempty_flag <= 0;
        end
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_full_cnt <= 0;
      b_empty_cnt <= 2**ASIZE;
      b_afull_cnt <= 0;
      b_aempty_cnt <= 2**ASIZE;
      b_full_flag <= 0;
      b_empty_flag <= 1;
      b_afull_flag <= 0;
      b_aempty_flag <= 1;
    end else begin
      if (b_dir && b_winc) begin
        mem[b_wr_ptr] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1;
        b_full_cnt <= b_full_cnt + 1;
        b_empty_cnt <= b_empty_cnt - 1;
        if (b_full_cnt == 2**ASIZE - 1) begin
          b_full_flag <= 1;
        end else begin
          b_full_flag <= 0;
        end
        if (b_empty_cnt == 0) begin
          b_empty_flag <= 1;
        end else begin
          b_empty_flag <= 0;
        end
        if (b_afull_cnt == 2**ASIZE - 2) begin
          b_afull_flag <= 1;
        end else begin
          b_afull_flag <= 0;
        end
        if (b_aempty_cnt == 1) begin
          b_aempty_flag <= 1;
        end else begin
          b_aempty_flag <= 0;
        end
      end
      if (!b_dir && b_rinc) begin
        b_rdata <= mem[b_rd_ptr];
        b_rd_ptr <= b_rd_ptr + 1;
        b_full_cnt <= b_full_cnt - 1;
        b_empty_cnt <= b_empty_cnt + 1;
        if (b_full_cnt == 0) begin
          b_full_flag <= 0;
        end
        if (b_empty_cnt == 2**ASIZE) begin
          b_empty_flag <= 1;
        end else begin
          b_empty_flag <= 0;
        end
        if (b_afull_cnt == 0) begin
          b_afull_flag <= 0;
        end
        if (b_aempty_cnt == 2**ASIZE - 1) begin
          b_aempty_flag <= 1;
        end else begin
          b_aempty_flag <= 0;
        end
      end
    end
  end

  always @(posedge a_clk) begin
    a_wr_ptr_gray <= {a_wr_ptr[ASIZE-2:0], 1'b0};
    a_rd_ptr_gray <= {a_rd_ptr[ASIZE-2:0], 1'b0};
  end

  always @(posedge b_clk) begin
    b_wr_ptr_gray <= {b_wr_ptr[ASIZE-2:0], 1'b0};
    b_rd_ptr_gray <= {b_rd_ptr[ASIZE-2:0], 1'b0};
  end

  always @(posedge a_clk) begin
    a_wr_ptr_sync <= a_wr_ptr;
    a_rd_ptr_sync <= a_rd_ptr;
  end

  always @(posedge b_clk) begin
    b_wr_ptr_sync <= b_wr_ptr;
    b_rd_ptr_sync <= b_rd_ptr;
  end

  always @(posedge a_clk) begin
    a_wr_ptr_sync_gray <= {a_wr_ptr_sync[ASIZE-2:0], 1'b0};
    a_rd_ptr_sync_gray <= {a_rd_ptr_sync[ASIZE-2:0], 1'b0};
  end

  always @(posedge b_clk) begin
    b_wr_ptr_sync_gray <= {b_wr_ptr_sync[ASIZE-2:0], 1'b0};
    b_rd_ptr_sync_gray <= {b_rd_ptr_sync[ASIZE-2:0], 1'b0};
  end

endmodule
