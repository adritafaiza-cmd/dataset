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

  reg [ASIZE-1:0] a_ptr, b_ptr;
  reg [ASIZE-1:0] a_ptr_gray, b_ptr_gray;
  reg [ASIZE-1:0] a_ptr_sync, b_ptr_sync;
  reg [ASIZE-1:0] a_ptr_sync2, b_ptr_sync2;
  reg [ASIZE-1:0] a_ptr_sync3, b_ptr_sync3;
  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [DSIZE-1:0] a_rdata_reg;
  reg [DSIZE-1:0] b_rdata_reg;

  assign a_full = (a_ptr_gray == (b_ptr_sync3 + 1'b1));
  assign a_afull = (a_ptr_gray == (b_ptr_sync3 + 2'b10));
  assign a_empty = (a_ptr_gray == b_ptr_sync3);
  assign a_aempty = (a_ptr_gray == (b_ptr_sync3 + 1'b1));

  assign b_full = (b_ptr_gray == (a_ptr_sync3 + 1'b1));
  assign b_afull = (b_ptr_gray == (a_ptr_sync3 + 2'b10));
  assign b_empty = (b_ptr_gray == a_ptr_sync3);
  assign b_aempty = (b_ptr_gray == (a_ptr_sync3 + 1'b1));

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_ptr <= 0;
      a_ptr_gray <= 0;
    end else begin
      if (a_winc &&!a_full) begin
        mem[a_ptr] <= a_wdata;
        a_ptr <= a_ptr + 1'b1;
      end
      a_ptr_gray <= {a_ptr[ASIZE-2:0], a_ptr[ASIZE-1]};
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_ptr <= 0;
      b_ptr_gray <= 0;
    end else begin
      if (b_winc &&!b_full) begin
        mem[(2**ASIZE-1) - b_ptr] <= b_wdata;
        b_ptr <= b_ptr + 1'b1;
      end
      b_ptr_gray <= {b_ptr[ASIZE-2:0], b_ptr[ASIZE-1]};
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_ptr_sync <= 0;
      a_ptr_sync2 <= 0;
      a_ptr_sync3 <= 0;
    end else begin
      a_ptr_sync <= b_ptr_gray;
      a_ptr_sync2 <= a_ptr_sync;
      a_ptr_sync3 <= a_ptr_sync2;
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_ptr_sync <= 0;
      b_ptr_sync2 <= 0;
      b_ptr_sync3 <= 0;
    end else begin
      b_ptr_sync <= a_ptr_gray;
      b_ptr_sync2 <= b_ptr_sync;
      b_ptr_sync3 <= b_ptr_sync2;
    end

  always @(posedge a_clk or negedge a_rst_n)
    if (!a_rst_n) begin
      a_rdata_reg <= 0;
    end else if (a_rinc &&!a_empty) begin
      if (a_dir) begin
        a_rdata_reg <= mem[a_ptr_sync3];
      end else begin
        a_rdata_reg <= mem[(2**ASIZE-1) - a_ptr_sync3];
      end
    end

  always @(posedge b_clk or negedge b_rst_n)
    if (!b_rst_n) begin
      b_rdata_reg <= 0;
    end else if (b_rinc &&!b_empty) begin
      if (b_dir) begin
        b_rdata_reg <= mem[b_ptr_sync3];
      end else begin
        b_rdata_reg <= mem[(2**ASIZE-1) - b_ptr_sync3];
      end
    end

  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

endmodule
