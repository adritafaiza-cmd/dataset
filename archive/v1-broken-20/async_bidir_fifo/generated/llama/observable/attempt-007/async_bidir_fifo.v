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

  reg [ASIZE-1:0] a_ptr;
  reg [ASIZE-1:0] b_ptr;
  reg [ASIZE-1:0] a_ptr_gray;
  reg [ASIZE-1:0] b_ptr_gray;
  reg [ASIZE-1:0] a_ptr_bin;
  reg [ASIZE-1:0] b_ptr_bin;
  reg [ASIZE-1:0] a_ptr_bin_d;
  reg [ASIZE-1:0] b_ptr_bin_d;
  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [DSIZE-1:0] a_rdata_reg;
  reg [DSIZE-1:0] b_rdata_reg;
  reg             a_full_reg;
  reg             a_afull_reg;
  reg             a_empty_reg;
  reg             a_aempty_reg;
  reg             b_full_reg;
  reg             b_afull_reg;
  reg             b_empty_reg;
  reg             b_aempty_reg;

  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;
  assign a_full  = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;
  assign b_full  = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_ptr <= 0;
      a_ptr_gray <= 0;
      a_ptr_bin <= 0;
      a_ptr_bin_d <= 0;
    end else begin
      if (a_winc && !a_full_reg) begin
        mem[a_ptr] <= a_wdata;
        a_ptr <= a_ptr + 1;
      end
      if (a_rinc && !a_empty_reg) begin
        a_ptr_bin_d <= a_ptr_bin - 1;
      end
      a_ptr_gray <= a_ptr ^ (a_ptr >> 1);
      a_ptr_bin <= a_ptr_gray;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_ptr <= 0;
      b_ptr_gray <= 0;
      b_ptr_bin <= 0;
      b_ptr_bin_d <= 0;
    end else begin
      if (b_winc && !b_full_reg) begin
        mem[(2**ASIZE-1) - b_ptr] <= b_wdata;
        b_ptr <= b_ptr + 1;
      end
      if (b_rinc && !b_empty_reg) begin
        b_ptr_bin_d <= b_ptr_bin - 1;
      end
      b_ptr_gray <= b_ptr ^ (b_ptr >> 1);
      b_ptr_bin <= b_ptr_gray;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= 0;
      a_full_reg <= 1;
      a_afull_reg <= 1;
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else begin
      if (a_rinc && !a_empty_reg) begin
        a_rdata_reg <= mem[a_ptr_bin_d];
      end
      if (a_dir) begin
        a_full_reg <= (a_ptr_bin == (2**ASIZE-1));
        a_afull_reg <= (a_ptr_bin >= (2**ASIZE-2));
        a_empty_reg <= (a_ptr_bin == b_ptr_bin);
        a_aempty_reg <= (a_ptr_bin == (b_ptr_bin + 1));
      end else begin
        a_full_reg <= (a_ptr_bin == b_ptr_bin);
        a_afull_reg <= (a_ptr_bin >= (b_ptr_bin + 2));
        a_empty_reg <= (a_ptr_bin == (2**ASIZE-1));
        a_aempty_reg <= (a_ptr_bin == (2**ASIZE-2));
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= 0;
      b_full_reg <= 1;
      b_afull_reg <= 1;
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else begin
      if (b_rinc && !b_empty_reg) begin
        b_rdata_reg <= mem[(2**ASIZE-1) - b_ptr_bin_d];
      end
      if (b_dir) begin
        b_full_reg <= (b_ptr_bin == (2**ASIZE-1));
        b_afull_reg <= (b_ptr_bin >= (2**ASIZE-2));
        b_empty_reg <= (b_ptr_bin == a_ptr_bin);
        b_aempty_reg <= (b_ptr_bin == (a_ptr_bin + 1));
      end else begin
        b_full_reg <= (b_ptr_bin == a_ptr_bin);
        b_afull_reg <= (b_ptr_bin >= (a_ptr_bin + 2));
        b_empty_reg <= (b_ptr_bin == (2**ASIZE-1));
        b_aempty_reg <= (b_ptr_bin == (2**ASIZE-2));
      end
    end
  end

endmodule
