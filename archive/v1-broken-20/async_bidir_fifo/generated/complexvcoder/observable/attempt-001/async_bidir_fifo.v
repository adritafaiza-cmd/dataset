`timescale 1ns / 1ps

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

  // Internal signals
  reg [DSIZE-1:0] a_fifo [0:2**ASIZE-1];
  reg [DSIZE-1:0] b_fifo [0:2**ASIZE-1];
  reg [ASIZE-1:0] a_head;
  reg [ASIZE-1:0] a_tail;
  reg [ASIZE-1:0] b_head;
  reg [ASIZE-1:0] b_tail;
  reg a_empty_reg;
  reg b_empty_reg;

  // FIFO Core for direction a
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_head <= 0;
      a_tail <= 0;
      a_empty_reg <= 1;
    end else begin
      if (a_winc && !a_full) begin
        a_fifo[a_head] <= a_wdata;
        a_head <= (a_head + 1) % (2**ASIZE);
      end
      if (a_rinc && !a_empty_reg) begin
        a_tail <= (a_tail + 1) % (2**ASIZE);
      end
      a_empty_reg <= (a_head == a_tail);
    end
  end

  // FIFO Core for direction b
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_head <= 0;
      b_tail <= 0;
      b_empty_reg <= 1;
    end else begin
      if (b_winc && !b_full) begin
        b_fifo[b_head] <= b_wdata;
        b_head <= (b_head + 1) % (2**ASIZE);
      end
      if (b_rinc && !b_empty_reg) begin
        b_tail <= (b_tail + 1) % (2**ASIZE);
      end
      b_empty_reg <= (b_head == b_tail);
    end
  end

  // Direction control
  always @(posedge a_clk or negedge a_rst_n or posedge b_clk or negedge b_rst_n) begin
    if (!a_rst_n || !b_rst_n) begin
      a_empty <= 1;
      a_afull <= 0;
      a_full <= 0;
      a_aempty <= 1;
      b_empty <= 1;
      b_afull <= 0;
      b_full <= 0;
      b_aempty <= 1;
    end else begin
      a_empty <= a_empty_reg;
      a_afull <= (a_head == (a_tail + 1) % (2**ASIZE));
      a_full <= (a_head == a_tail);
      a_aempty <= (a_head == a_tail);
      b_empty <= b_empty_reg;
      b_afull <= (b_head == (b_tail + 1) % (2**ASIZE));
      b_full <= (b_head == b_tail);
      b_aempty <= (b_head == b_tail);
    end
  end

  // Output data
  always @(posedge a_clk or posedge b_clk) begin
    if (a_rinc && !a_empty_reg) begin
      a_rdata <= a_fifo[a_tail];
    end
    if (b_rinc && !b_empty_reg) begin
      b_rdata <= b_fifo[b_tail];
    end
  end

endmodule
