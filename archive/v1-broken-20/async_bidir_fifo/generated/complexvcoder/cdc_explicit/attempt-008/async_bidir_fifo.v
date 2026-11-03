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

  // FIFO core for side A
  fifo_core fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_dir ? a_winc : 1'b0),
    .wdata(a_dir ? a_wdata : 8'b0),
    .rinc(a_dir ? 1'b0 : a_rinc),
    .dir(a_dir),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

  // FIFO core for side B
  fifo_core fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_dir ? b_winc : 1'b0),
    .wdata(b_dir ? b_wdata : 8'b0),
    .rinc(b_dir ? 1'b0 : b_rinc),
    .dir(b_dir),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

endmodule

module fifo_core
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
       input wire              dir,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  localparam FIFO_SIZE = 2**ASIZE;

  reg [DSIZE-1:0] mem [0:FIFO_SIZE-1];
  reg [ASIZE:0] wr_ptr;
  reg [ASIZE:0] rd_ptr;
  reg [ASIZE:0] count;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      count <= 0;
    end else begin
      if (winc && (count < FIFO_SIZE)) begin
        mem[wr_ptr] <= wdata;
        wr_ptr <= wr_ptr + 1;
        count <= count + 1;
      end
      if (rinc && (count > 0)) begin
        rd_ptr <= rd_ptr + 1;
        count <= count - 1;
      end
    end
  end

  assign rdata = dir ? mem[rd_ptr] : mem[wr_ptr];
  assign full = (count == FIFO_SIZE);
  assign afull = (count == FIFO_SIZE - 1);
  assign empty = (count == 0);
  assign aempty = (count == 1);

endmodule
