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

  // Internal signals for FIFO A
  reg [DSIZE-1:0] a_fifo [0:(2**ASIZE)-1];
  reg [ASIZE:0] a_write_ptr, a_read_ptr;
  reg [ASIZE:0] a_count;

  // Internal signals for FIFO B
  reg [DSIZE-1:0] b_fifo [0:(2**ASIZE)-1];
  reg [ASIZE:0] b_write_ptr, b_read_ptr;
  reg [ASIZE:0] b_count;

  // FIFO A logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_write_ptr <= 0;
      a_read_ptr <= 0;
      a_count <= 0;
    end else begin
      if (a_winc && a_dir && a_count < (2**ASIZE)) begin
        a_fifo[a_write_ptr] <= a_wdata;
        a_write_ptr <= a_write_ptr + 1;
        a_count <= a_count + 1;
      end
      if (a_rinc && !a_dir && a_count > 0) begin
        a_read_ptr <= a_read_ptr + 1;
        a_count <= a_count - 1;
      end
    end
  end

  assign a_rdata = a_fifo[a_read_ptr];
  assign a_full = (a_count == (2**ASIZE));
  assign a_afull = (a_count == (2**ASIZE - 1));
  assign a_empty = (a_count == 0);
  assign a_aempty = (a_count == 1);

  // FIFO B logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_write_ptr <= 0;
      b_read_ptr <= 0;
      b_count <= 0;
    end else begin
      if (b_winc && !a_dir && b_count < (2**ASIZE)) begin
        b_fifo[b_write_ptr] <= b_wdata;
        b_write_ptr <= b_write_ptr + 1;
        b_count <= b_count + 1;
      end
      if (b_rinc && a_dir && b_count > 0) begin
        b_read_ptr <= b_read_ptr + 1;
        b_count <= b_count - 1;
      end
    end
  end

  assign b_rdata = b_fifo[b_read_ptr];
  assign b_full = (b_count == (2**ASIZE));
  assign b_afull = (b_count == (2**ASIZE - 1));
  assign b_empty = (b_count == 0);
  assign b_aempty = (b_count == 1);

endmodule
