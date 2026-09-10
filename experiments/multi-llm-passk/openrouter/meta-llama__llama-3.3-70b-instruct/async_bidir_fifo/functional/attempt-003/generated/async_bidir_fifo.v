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
  reg [ASIZE-1:0] a_wr_ptr;
  reg [ASIZE-1:0] a_rd_ptr;
  reg [ASIZE-1:0] b_wr_ptr;
  reg [ASIZE-1:0] b_rd_ptr;
  reg [ASIZE-1:0] a_cnt;
  reg [ASIZE-1:0] b_cnt;
  reg [ASIZE-1:0] a_afull_cnt;
  reg [ASIZE-1:0] b_afull_cnt;

  assign a_full = (a_cnt == (2**ASIZE - 1));
  assign a_afull = (a_afull_cnt > 0);
  assign a_empty = (a_cnt == 0);
  assign a_aempty = (a_cnt == 1);
  assign b_full = (b_cnt == (2**ASIZE - 1));
  assign b_afull = (b_afull_cnt > 0);
  assign b_empty = (b_cnt == 0);
  assign b_aempty = (b_cnt == 1);

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_cnt <= 0;
      a_afull_cnt <= 0;
    end else if (a_dir) begin
      if (a_winc && !a_full) begin
        mem[a_wr_ptr] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1;
        a_cnt <= a_cnt + 1;
        if (a_cnt == (2**ASIZE - 2)) begin
          a_afull_cnt <= 1;
        end else if (a_cnt == (2**ASIZE - 1)) begin
          a_afull_cnt <= 2;
        end
      end
    end else if (a_rinc && !a_empty) begin
      a_rd_ptr <= a_rd_ptr + 1;
      a_cnt <= a_cnt - 1;
      if (a_cnt == (2**ASIZE - 3)) begin
        a_afull_cnt <= 0;
      end else if (a_cnt == (2**ASIZE - 2)) begin
        a_afull_cnt <= 1;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_cnt <= 0;
      b_afull_cnt <= 0;
    end else if (b_dir) begin
      if (b_winc && !b_full) begin
        mem[b_wr_ptr] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1;
        b_cnt <= b_cnt + 1;
        if (b_cnt == (2**ASIZE - 2)) begin
          b_afull_cnt <= 1;
        end else if (b_cnt == (2**ASIZE - 1)) begin
          b_afull_cnt <= 2;
        end
      end
    end else if (b_rinc && !b_empty) begin
      b_rd_ptr <= b_rd_ptr + 1;
      b_cnt <= b_cnt - 1;
      if (b_cnt == (2**ASIZE - 3)) begin
        b_afull_cnt <= 0;
      end else if (b_cnt == (2**ASIZE - 2)) begin
        b_afull_cnt <= 1;
      end
    end
  end

  always @(posedge a_clk) begin
    if (a_dir) begin
      if (FALLTHROUGH == "TRUE" && a_empty) begin
        a_rdata <= a_wdata;
      end else if (!a_empty) begin
        a_rdata <= mem[a_rd_ptr];
      end
    end
  end

  always @(posedge b_clk) begin
    if (b_dir) begin
      if (FALLTHROUGH == "TRUE" && b_empty) begin
        b_rdata <= b_wdata;
      end else if (!b_empty) begin
        b_rdata <= mem[b_rd_ptr];
      end
    end
  end

endmodule
