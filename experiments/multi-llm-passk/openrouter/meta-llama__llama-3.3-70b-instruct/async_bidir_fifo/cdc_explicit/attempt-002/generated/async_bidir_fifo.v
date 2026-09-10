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
  reg [ASIZE-1:0] a_empty_cnt, b_empty_cnt;
  reg [ASIZE-1:0] a_aempty_cnt, b_aempty_cnt;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;

  wire a_full_wire, a_afull_wire, a_empty_wire, a_aempty_wire;
  wire b_full_wire, b_afull_wire, b_empty_wire, b_aempty_wire;

  assign a_full_wire = (a_full_cnt == (2**ASIZE-1));
  assign a_afull_wire = (a_afull_cnt == (2**ASIZE-2));
  assign a_empty_wire = (a_empty_cnt == (2**ASIZE-1));
  assign a_aempty_wire = (a_aempty_cnt == (2**ASIZE-2));
  assign b_full_wire = (b_full_cnt == (2**ASIZE-1));
  assign b_afull_wire = (b_afull_cnt == (2**ASIZE-2));
  assign b_empty_wire = (b_empty_cnt == (2**ASIZE-1));
  assign b_aempty_wire = (b_aempty_cnt == (2**ASIZE-2));

  assign a_full = a_full_wire;
  assign a_afull = a_afull_wire;
  assign a_empty = a_empty_wire;
  assign a_aempty = a_aempty_wire;
  assign b_full = b_full_wire;
  assign b_afull = b_afull_wire;
  assign b_empty = b_empty_wire;
  assign b_aempty = b_aempty_wire;

  always @(posedge a_clk or negedge a_rst_n)
  begin
    if (!a_rst_n)
    begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_wr_ptr_gray <= 0;
      a_rd_ptr_gray <= 0;
      a_full_cnt <= 0;
      a_afull_cnt <= 0;
      a_empty_cnt <= (2**ASIZE-1);
      a_aempty_cnt <= (2**ASIZE-2);
    end
    else
    begin
      if (a_dir)
      begin
        if (a_winc && !a_full_wire)
        begin
          mem[a_wr_ptr] <= a_wdata;
          a_wr_ptr <= a_wr_ptr + 1;
          a_wr_ptr_gray <= a_wr_ptr_gray + 1;
          a_full_cnt <= a_full_cnt + 1;
          a_empty_cnt <= a_empty_cnt - 1;
          if (a_full_cnt == (2**ASIZE-2))
          begin
            a_afull_cnt <= a_afull_cnt + 1;
          end
          else if (a_full_cnt == (2**ASIZE-1))
          begin
            a_afull_cnt <= a_afull_cnt - 1;
          end
        end
      end
      else
      begin
        if (a_rinc && !a_empty_wire)
        begin
          a_rdata_reg <= mem[a_rd_ptr];
          a_rd_ptr <= a_rd_ptr + 1;
          a_rd_ptr_gray <= a_rd_ptr_gray + 1;
          a_full_cnt <= a_full_cnt - 1;
          a_empty_cnt <= a_empty_cnt + 1;
          if (a_empty_cnt == (2**ASIZE-2))
          begin
            a_aempty_cnt <= a_aempty_cnt + 1;
          end
          else if (a_empty_cnt == (2**ASIZE-1))
          begin
            a_aempty_cnt <= a_aempty_cnt - 1;
          end
        end
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n)
  begin
    if (!b_rst_n)
    begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_wr_ptr_gray <= 0;
      b_rd_ptr_gray <= 0;
      b_full_cnt <= 0;
      b_afull_cnt <= 0;
      b_empty_cnt <= (2**ASIZE-1);
      b_aempty_cnt <= (2**ASIZE-2);
    end
    else
    begin
      if (b_dir)
      begin
        if (b_winc && !b_full_wire)
        begin
          mem[b_wr_ptr] <= b_wdata;
          b_wr_ptr <= b_wr_ptr + 1;
          b_wr_ptr_gray <= b_wr_ptr_gray + 1;
          b_full_cnt <= b_full_cnt + 1;
          b_empty_cnt <= b_empty_cnt - 1;
          if (b_full_cnt == (2**ASIZE-2))
          begin
            b_afull_cnt <= b_afull_cnt + 1;
          end
          else if (b_full_cnt == (2**ASIZE-1))
          begin
            b_afull_cnt <= b_afull_cnt - 1;
          end
        end
      end
      else
      begin
        if (b_rinc && !b_empty_wire)
        begin
          b_rdata_reg <= mem[b_rd_ptr];
          b_rd_ptr <= b_rd_ptr + 1;
          b_rd_ptr_gray <= b_rd_ptr_gray + 1;
          b_full_cnt <= b_full_cnt - 1;
          b_empty_cnt <= b_empty_cnt + 1;
          if (b_empty_cnt == (2**ASIZE-2))
          begin
            b_aempty_cnt <= b_aempty_cnt + 1;
          end
          else if (b_empty_cnt == (2**ASIZE-1))
          begin
            b_aempty_cnt <= b_aempty_cnt - 1;
          end
        end
      end
    end
  end

  // CDC for a_wr_ptr
  always @(posedge a_clk or negedge a_rst_n)
  begin
    if (!a_rst_n)
    begin
      a_wr_ptr_sync <= 0;
      a_wr_ptr_sync_gray <= 0;
    end
    else
    begin
      a_wr_ptr_sync <= a_wr_ptr;
      a_wr_ptr_sync_gray <= a_wr_ptr_gray;
    end
  end

  // CDC for a_rd_ptr
  always @(posedge a_clk or negedge a_rst_n)
  begin
    if (!a_rst_n)
    begin
      a_rd_ptr_sync <= 0;
      a_rd_ptr_sync_gray <= 0;
    end
    else
    begin
      a_rd_ptr_sync <= a_rd_ptr;
      a_rd_ptr_sync_gray <= a_rd_ptr_gray;
    end
  end

  // CDC for b_wr_ptr
  always @(posedge b_clk or negedge b_rst_n)
  begin
    if (!b_rst_n)
    begin
      b_wr_ptr_sync <= 0;
      b_wr_ptr_sync_gray <= 0;
    end
    else
    begin
      b_wr_ptr_sync <= b_wr_ptr;
      b_wr_ptr_sync_gray <= b_wr_ptr_gray;
    end
  end

  // CDC for b_rd_ptr
  always @(posedge b_clk or negedge b_rst_n)
  begin
    if (!b_rst_n)
    begin
      b_rd_ptr_sync <= 0;
      b_rd_ptr_sync_gray <= 0;
    end
    else
    begin
      b_rd_ptr_sync <= b_rd_ptr;
      b_rd_ptr_sync_gray <= b_rd_ptr_gray;
    end
  end

  // Output assignments
  assign a_rdata = (FALLTHROUGH == "TRUE") ? (a_empty_wire ? {DSIZE{1'b0}} : mem[a_rd_ptr]) : a_rdata_reg;
  assign b_rdata = (FALLTHROUGH == "TRUE") ? (b_empty_wire ? {DSIZE{1'b0}} : mem[b_rd_ptr]) : b_rdata_reg;

endmodule
