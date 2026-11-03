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

  localparam FIFO_SIZE = 1 << ASIZE;
  localparam HALF_FIFO_SIZE = FIFO_SIZE / 2;

  reg [DSIZE-1:0] mem [0:FIFO_SIZE-1];
  reg [ASIZE:0] a_wr_ptr;
  reg [ASIZE:0] a_rd_ptr;
  reg [ASIZE:0] b_wr_ptr;
  reg [ASIZE:0] b_rd_ptr;

  reg [ASIZE:0] a_count;
  reg [ASIZE:0] b_count;

  reg a_read;
  reg b_read;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_count <= 0;
      a_full <= 0;
      a_afull <= 0;
      a_empty <= 1;
      a_aempty <= 1;
    end else begin
      if (a_winc && !a_full) begin
        mem[a_wr_ptr] <= a_wdata;
        a_wr_ptr <= a_wr_ptr + 1;
        a_count <= a_count + 1;
        if (a_count == (FIFO_SIZE - 1)) begin
          a_full <= 1;
        end else if (a_count == (FIFO_SIZE - HALF_FIFO_SIZE - 1)) begin
          a_afull <= 1;
        end
      end else if (a_rinc && !a_empty) begin
        a_rd_ptr <= a_rd_ptr + 1;
        a_count <= a_count - 1;
        if (a_count == 0) begin
          a_empty <= 1;
        end else if (a_count == HALF_FIFO_SIZE) begin
          a_aempty <= 1;
        end
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_count <= 0;
      b_full <= 0;
      b_afull <= 0;
      b_empty <= 1;
      b_aempty <= 1;
    end else begin
      if (b_winc && !b_full) begin
        mem[b_wr_ptr] <= b_wdata;
        b_wr_ptr <= b_wr_ptr + 1;
        b_count <= b_count + 1;
        if (b_count == (FIFO_SIZE - 1)) begin
          b_full <= 1;
        end else if (b_count == (FIFO_SIZE - HALF_FIFO_SIZE - 1)) begin
          b_afull <= 1;
        end
      end else if (b_rinc && !b_empty) begin
        b_rd_ptr <= b_rd_ptr + 1;
        b_count <= b_count - 1;
        if (b_count == 0) begin
          b_empty <= 1;
        end else if (b_count == HALF_FIFO_SIZE) begin
          b_aempty <= 1;
        end
      end
    end
  end

  assign a_rdata = mem[a_rd_ptr];
  assign b_rdata = mem[b_rd_ptr];

  assign a_full = (a_count == (FIFO_SIZE - 1));
  assign a_afull = (a_count == (FIFO_SIZE - HALF_FIFO_SIZE - 1));
  assign a_empty = (a_count == 0);
  assign a_aempty = (a_count == HALF_FIFO_SIZE);

  assign b_full = (b_count == (FIFO_SIZE - 1));
  assign b_afull = (b_count == (FIFO_SIZE - HALF_FIFO_SIZE - 1));
  assign b_empty = (b_count == 0);
  assign b_aempty = (b_count == HALF_FIFO_SIZE);

endmodule
