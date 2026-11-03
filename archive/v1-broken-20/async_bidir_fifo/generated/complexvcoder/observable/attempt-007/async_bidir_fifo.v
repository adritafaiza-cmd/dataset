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

  // FIFO cores
  fifo_core a_fifo (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

  fifo_core b_fifo (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

  // Clock domain crossing for a to b
  clock_domain_crossing a_to_b (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .data_in(a_fifo.rdata),
    .data_out(b_fifo.wdata),
    .valid_in(a_fifo.rinc),
    .valid_out(b_fifo.winc)
  );

  // Clock domain crossing for b to a
  clock_domain_crossing b_to_a (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .data_in(b_fifo.rdata),
    .data_out(a_fifo.wdata),
    .valid_in(b_fifo.rinc),
    .valid_out(a_fifo.winc)
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
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  localparam DEPTH = 2**ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE-1:0] wr_ptr, rd_ptr, wr_ptr_n, rd_ptr_n;
  reg [ASIZE-1:0] count, count_n;
  reg full_n, empty_n;

  // Write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
    end else if (winc && !full_n) begin
      wr_ptr <= wr_ptr_n;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_n <= 0;
    end else if (winc && !full_n) begin
      wr_ptr_n <= wr_ptr_n + 1;
    end
  end

  // Read pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
    end else if (rinc && !empty_n) begin
      rd_ptr <= rd_ptr_n;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_n <= 0;
    end else if (rinc && !empty_n) begin
      rd_ptr_n <= rd_ptr_n + 1;
    end
  end

  // Count logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count <= 0;
    end else if (winc && !full_n) begin
      count <= count_n;
    end else if (rinc && !empty_n) begin
      count <= count_n;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count_n <= 0;
    end else if (winc && !full_n) begin
      count_n <= count_n + 1;
    end else if (rinc && !empty_n) begin
      count_n <= count_n - 1;
    end
  end

  // Full and empty flags
  assign full_n = (count_n == DEPTH-1) ? 1 : 0;
  assign empty_n = (count_n == 0) ? 1 : 0;

  // Output assignments
  assign full = full_n;
  assign afull = full_n;
  assign empty = empty_n;
  assign aempty = empty_n;
  assign rdata = mem[rd_ptr];

endmodule

module clock_domain_crossing
  (
       input wire              clk,
       input wire              rst_n,
       input wire [DSIZE-1:0]  data_in,
       output wire [DSIZE-1:0] data_out,
       input wire              valid_in,
       output wire             valid_out
       );

  reg [DSIZE-1:0] data_reg;
  reg valid_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= 0;
      valid_reg <= 0;
    end else if (valid_in) begin
      data_reg <= data_in;
      valid_reg <= 1;
    end else begin
      valid_reg <= 0;
    end
  end

  assign data_out = data_reg;
  assign valid_out = valid_reg;

endmodule
