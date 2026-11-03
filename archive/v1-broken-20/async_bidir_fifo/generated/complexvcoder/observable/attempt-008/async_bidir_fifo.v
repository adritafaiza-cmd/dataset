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
  wire [DSIZE-1:0] a_rdata_int;
  wire [DSIZE-1:0] b_rdata_int;
  wire a_full_int;
  wire a_afull_int;
  wire a_empty_int;
  wire a_aempty_int;
  wire b_full_int;
  wire b_afull_int;
  wire b_empty_int;
  wire b_aempty_int;

  // FIFO cores
  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata_int),
    .full(a_full_int),
    .afull(a_afull_int),
    .empty(a_empty_int),
    .aempty(a_aempty_int)
  );

  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata_int),
    .full(b_full_int),
    .afull(b_afull_int),
    .empty(b_empty_int),
    .aempty(b_aempty_int)
  );

  // Direction selectors
  dir_selector dir_sel_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .dir(a_dir),
    .data_in(a_wdata),
    .data_out(a_rdata)
  );

  dir_selector dir_sel_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .dir(b_dir),
    .data_in(b_wdata),
    .data_out(b_rdata)
  );

  // Assign internal signals to outputs
  assign a_full = a_full_int;
  assign a_afull = a_afull_int;
  assign a_empty = a_empty_int;
  assign a_aempty = a_aempty_int;

  assign b_full = b_full_int;
  assign b_afull = b_afull_int;
  assign b_empty = b_empty_int;
  assign b_aempty = b_aempty_int;

endmodule

// FIFO core module
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

  // Internal signals
  reg [DSIZE-1:0] mem [0:2**ASIZE-1];
  reg [ASIZE-1:0] wr_ptr;
  reg [ASIZE-1:0] rd_ptr;
  reg [ASIZE-1:0] count;

  // Write process
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      count <= 0;
    end else if (winc && !full) begin
      mem[wr_ptr] <= wdata;
      wr_ptr <= wr_ptr + 1;
      count <= count + 1;
    end
  end

  // Read process
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
    end else if (rinc && !empty) begin
      rd_ptr <= rd_ptr + 1;
      count <= count - 1;
    end
  end

  // Full and empty flags
  assign full = count == 2**ASIZE;
  assign empty = count == 0;
  assign aempty = empty && FALLTHROUGH == "TRUE";
  assign afull = full && FALLTHROUGH == "TRUE";

  // Read data output
  assign rdata = mem[rd_ptr];

endmodule

// Direction selector module
module dir_selector
  (
    input wire              clk,
    input wire              rst_n,
    input wire              dir,
    input wire [DSIZE-1:0]  data_in,
    output wire [DSIZE-1:0] data_out
    );

  reg [DSIZE-1:0] data_out_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out_reg <= 0;
    end else if (dir) begin
      data_out_reg <= data_in;
    end
  end

  assign data_out = data_out_reg;

endmodule
