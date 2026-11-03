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
  reg [DSIZE-1:0] a_rdata_out;
  reg [DSIZE-1:0] a_wdata_out;
  reg [DSIZE-1:0] b_rdata_out;
  reg [DSIZE-1:0] b_wdata_out;

  // FIFO core for side A
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_core_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata_out),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

  // FIFO core for side B
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_core_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata_out),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

  // Direction selector for side A
  direction_selector #(.DSIZE(DSIZE)) dir_select_a (
    .dir(a_dir),
    .rdata(fifo_core_a.rdata),
    .wdata(fifo_core_a.wdata),
    .rdata_out(a_rdata),
    .wdata_out(a_wdata_out)
  );

  // Direction selector for side B
  direction_selector #(.DSIZE(DSIZE)) dir_select_b (
    .dir(b_dir),
    .rdata(fifo_core_b.rdata),
    .wdata(fifo_core_b.wdata),
    .rdata_out(b_rdata),
    .wdata_out(b_wdata_out)
  );

  // Clock-domain crossing logic
  assign fifo_core_a.wdata = a_wdata_out;
  assign fifo_core_a.rinc = a_rinc;
  assign fifo_core_b.wdata = b_wdata_out;
  assign fifo_core_b.rinc = b_rinc;

  assign a_rdata = a_rdata_out;
  assign b_rdata = b_rdata_out;

endmodule

module fifo_core
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       output reg [DSIZE-1:0] rdata,
       output reg              full,
       output reg              afull,
       output reg              empty,
       output reg              aempty
       );

  reg [ASIZE-1:0] wr_ptr;
  reg [ASIZE-1:0] rd_ptr;
  reg [DSIZE*ASIZE-1:0] mem [0:ASIZE-1];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      full <= 0;
      afull <= 0;
      empty <= 1;
      aempty <= 1;
      rdata <= 0;
      mem <= 0;
    end else begin
      if (winc && !full && !afull) begin
        mem[wr_ptr] <= wdata;
        wr_ptr <= wr_ptr + 1;
        if (wr_ptr == ASIZE - 1) begin
          wr_ptr <= 0;
          if (rd_ptr == wr_ptr) begin
            afull <= 1;
          end
        end
        full <= 1;
      end
      if (rinc && !empty) begin
        rdata <= mem[rd_ptr];
        rd_ptr <= rd_ptr + 1;
        if (rd_ptr == ASIZE) begin
          rd_ptr <= 0;
          if (rd_ptr == wr_ptr) begin
            aempty <= 1;
          end
        end
        empty <= 0;
      end
    end
  end

endmodule

module direction_selector
  #(
    parameter DSIZE         = 8
    ) (
       input wire              dir,
       input wire [DSIZE-1:0]  rdata,
       input wire [DSIZE-1:0]  wdata,
       output reg [DSIZE-1:0] rdata_out,
       output reg [DSIZE-1:0] wdata_out
       );

  assign rdata_out = dir ? wdata : rdata;
  assign wdata_out = dir ? rdata : wdata;

endmodule
