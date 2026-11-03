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

  wire [DSIZE-1:0] fifo_a_to_b_rdata;
  wire fifo_a_to_b_full, fifo_a_to_b_afull, fifo_a_to_b_empty, fifo_a_to_b_aempty;
  wire [DSIZE-1:0] fifo_b_to_a_rdata;
  wire fifo_b_to_a_full, fifo_b_to_a_afull, fifo_b_to_a_empty, fifo_b_to_a_aempty;

  async_fifo_side #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_a_to_b (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(b_rinc),
    .rdata(fifo_a_to_b_rdata),
    .full(fifo_a_to_b_full),
    .afull(fifo_a_to_b_afull),
    .empty(fifo_a_to_b_empty),
    .aempty(fifo_a_to_b_aempty),
    .dir(a_dir),
    .op_clk(b_clk)
  );

  async_fifo_side #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_b_to_a (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(a_rinc),
    .rdata(fifo_b_to_a_rdata),
    .full(fifo_b_to_a_full),
    .afull(fifo_b_to_a_afull),
    .empty(fifo_b_to_a_empty),
    .aempty(fifo_b_to_a_aempty),
    .dir(b_dir),
    .op_clk(a_clk)
  );

  assign a_rdata = fifo_b_to_a_rdata;
  assign a_full  = fifo_b_to_a_full;
  assign a_afull = fifo_b_to_a_afull;
  assign a_empty = fifo_b_to_a_empty;
  assign a_aempty = fifo_b_to_a_aempty;

  assign b_rdata = fifo_a_to_b_rdata;
  assign b_full  = fifo_a_to_b_full;
  assign b_afull = fifo_a_to_b_afull;
  assign b_empty = fifo_a_to_b_empty;
  assign b_aempty = fifo_a_to_b_aempty;

endmodule

module async_fifo_side
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty,
       input wire              dir,
       input wire              op_clk
       );

  localparam DEPTH = 1 << ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE:0] wr_ptr, rd_ptr, wr_ptr_op, rd_ptr_op;
  reg [ASIZE:0] wr_ptr_gray, rd_ptr_gray, wr_ptr_gray_op, rd_ptr_gray_op;

  // Gray code conversion
  function [ASIZE:0] bin_to_gray;
    input [ASIZE:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Cross-domain synchronization
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_op <= 0;
      wr_ptr_op <= 0;
    end else begin
      wr_ptr_gray_op <= wr_ptr_gray;
      wr_ptr_op <= wr_ptr;
    end
  end

  always @(posedge op_clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray_op <= 0;
      rd_ptr_op <= 0;
    end else begin
      rd_ptr_gray_op <= rd_ptr_gray;
      rd_ptr_op <= rd_ptr;
    end
  end

  // Write pointer update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (winc && !full) begin
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
    end
  end

  // Read pointer update
  always @(posedge op_clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rinc && !empty) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
    end
  end

  // Write operation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Do nothing
    end else if (winc && !full) begin
      mem[wr_ptr] <= wdata;
    end
  end

  // Read operation
  always @(posedge op_clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= 0;
    end else if (rinc && !empty) begin
      rdata <= mem[rd_ptr];
    end
  end

  // Full and almost full flags
  wire [ASIZE:0] wr_ptr_gray_op_bin;
  wire [ASIZE:0] rd_ptr_gray_op_bin;

  assign wr_ptr_gray_op_bin = {wr_ptr_gray_op[ASIZE], wr_ptr_gray_op[ASIZE-1:0] ^ wr_ptr_gray_op[ASIZE:1]};
  assign rd_ptr_gray_op_bin = {rd_ptr_gray_op[ASIZE], rd_ptr_gray_op[ASIZE-1:0] ^ rd_ptr_gray_op[ASIZE:1]};

  assign full = (wr_ptr_gray_op_bin == bin_to_gray(rd_ptr + DEPTH));
  assign afull = (wr_ptr_gray_op_bin == bin_to_gray(rd_ptr + DEPTH - 1));

  // Empty and almost empty flags
  assign empty = (wr_ptr_gray == rd_ptr_gray_op);
  assign aempty = (wr_ptr_gray == bin_to_gray(rd_ptr_op + 1));

endmodule
