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
  localparam FULL_FLAG = FIFO_SIZE - 1;
  localparam AFULL_FLAG = FIFO_SIZE - 2;
  localparam EMPTY_FLAG = 0;
  localparam AEMPTY_FLAG = 1;

  reg [ASIZE-1:0] a_write_ptr;
  reg [ASIZE-1:0] a_read_ptr;
  reg [ASIZE-1:0] b_write_ptr;
  reg [ASIZE-1:0] b_read_ptr;
  reg [FIFO_SIZE-1:0][DSIZE-1:0] a_fifo;
  reg [FIFO_SIZE-1:0][DSIZE-1:0] b_fifo;
  reg [DSIZE-1:0] a_temp_data;
  reg [DSIZE-1:0] b_temp_data;

  wire [ASIZE-1:0] a_count = a_write_ptr - a_read_ptr;
  wire [ASIZE-1:0] b_count = b_write_ptr - b_read_ptr;

  assign a_full = (a_count == FULL_FLAG);
  assign a_afull = (a_count == AFULL_FLAG);
  assign a_empty = (a_count == EMPTY_FLAG);
  assign a_aempty = (a_count == AEMPTY_FLAG);

  assign b_full = (b_count == FULL_FLAG);
  assign b_afull = (b_count == AFULL_FLAG);
  assign b_empty = (b_count == EMPTY_FLAG);
  assign b_aempty = (b_count == AEMPTY_FLAG);

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_write_ptr <= EMPTY_FLAG;
      a_read_ptr <= EMPTY_FLAG;
    end else begin
      if (a_dir && !a_full) begin
        a_fifo[a_write_ptr] <= a_wdata;
        a_write_ptr <= a_write_ptr + 1;
      end else if (!a_dir && !a_empty) begin
        a_read_ptr <= a_read_ptr + 1;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_write_ptr <= EMPTY_FLAG;
      b_read_ptr <= EMPTY_FLAG;
    end else begin
      if (b_dir && !b_full) begin
        b_fifo[b_write_ptr] <= b_wdata;
        b_write_ptr <= b_write_ptr + 1;
      end else if (!b_dir && !b_empty) begin
        b_read_ptr <= b_read_ptr + 1;
      end
    end
  end

  always @(posedge a_clk) begin
    if (a_dir && !a_full) begin
      a_temp_data <= a_wdata;
    end
  end

  always @(posedge b_clk) begin
    if (b_dir && !b_full) begin
      b_temp_data <= b_wdata;
    end
  end

  always @(posedge a_clk) begin
    if (!a_dir && !a_empty) begin
      a_rdata <= a_fifo[a_read_ptr];
    end
  end

  always @(posedge b_clk) begin
    if (!b_dir && !b_empty) begin
      b_rdata <= b_fifo[b_read_ptr];
    end
  end

endmodule
