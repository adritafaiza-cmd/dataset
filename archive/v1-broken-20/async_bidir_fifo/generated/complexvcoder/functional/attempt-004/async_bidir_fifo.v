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

  localparam FIFO_SIZE = 2**ASIZE;

  reg [DSIZE-1:0] a_fifo [0:FIFO_SIZE-1];
  reg [DSIZE-1:0] b_fifo [0:FIFO_SIZE-1];
  reg [ASIZE:0] a_head, a_tail, b_head, b_tail;
  reg [ASIZE:0] a_count, b_count;

  wire a_read_en, a_write_en, b_read_en, b_write_en;

  assign a_read_en = a_rinc & !a_dir;
  assign a_write_en = a_winc & a_dir;
  assign b_read_en = b_rinc & !b_dir;
  assign b_write_en = b_winc & b_dir;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_head <= 0;
      a_tail <= 0;
      a_count <= 0;
    end else begin
      if (a_write_en)
        a_fifo[a_tail] <= a_wdata;
      if (a_read_en)
        a_tail <= a_tail + 1;
      if (a_count < FIFO_SIZE) begin
        if (a_write_en)
          a_count <= a_count + 1;
      end else begin
        if (a_write_en && !a_read_en && FALLTHROUGH == "TRUE")
          a_count <= a_count + 1;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_head <= 0;
      b_tail <= 0;
      b_count <= 0;
    end else begin
      if (b_write_en)
        b_fifo[b_tail] <= b_wdata;
      if (b_read_en)
        b_tail <= b_tail + 1;
      if (b_count < FIFO_SIZE) begin
        if (b_write_en)
          b_count <= b_count + 1;
      end else begin
        if (b_write_en && !b_read_en && FALLTHROUGH == "TRUE")
          b_count <= b_count + 1;
      end
    end
  end

  assign a_rdata = a_fifo[a_head];
  assign a_full = (a_count == FIFO_SIZE);
  assign a_afull = (a_count == FIFO_SIZE - 1);
  assign a_empty = (a_count == 0);
  assign a_aempty = (a_count == 1);

  assign b_rdata = b_fifo[b_head];
  assign b_full = (b_count == FIFO_SIZE);
  assign b_afull = (b_count == FIFO_SIZE - 1);
  assign b_empty = (b_count == 0);
  assign b_aempty = (b_count == 1);

endmodule
