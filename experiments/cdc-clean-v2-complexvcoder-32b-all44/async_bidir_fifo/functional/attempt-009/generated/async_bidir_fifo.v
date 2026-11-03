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

  wire [DSIZE-1:0] a_to_b_wdata;
  wire a_to_b_winc;
  wire a_to_b_rinc;
  wire [DSIZE-1:0] a_to_b_rdata;
  wire a_to_b_full;
  wire a_to_b_afull;
  wire a_to_b_empty;
  wire a_to_b_aempty;

  wire [DSIZE-1:0] b_to_a_wdata;
  wire b_to_a_winc;
  wire b_to_a_rinc;
  wire [DSIZE-1:0] b_to_a_rdata;
  wire b_to_a_full;
  wire b_to_a_afull;
  wire b_to_a_empty;
  wire b_to_a_aempty;

  async_fifo_side #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) a_side (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_dir ? a_winc : 1'b0),
    .wdata(a_dir ? a_wdata : {DSIZE{1'b0}}),
    .rinc(a_dir ? 1'b0 : a_rinc),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty),
    .dir(a_dir),
    .other_clk(b_clk),
    .other_rst_n(b_rst_n),
    .other_winc(b_to_a_winc),
    .other_wdata(b_to_a_wdata),
    .other_rinc(b_to_a_rinc),
    .other_rdata(b_to_a_rdata),
    .other_full(b_to_a_full),
    .other_afull(b_to_a_afull),
    .other_empty(b_to_a_empty),
    .other_aempty(b_to_a_aempty)
  );

  async_fifo_side #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) b_side (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_dir ? b_winc : 1'b0),
    .wdata(b_dir ? b_wdata : {DSIZE{1'b0}}),
    .rinc(b_dir ? 1'b0 : b_rinc),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty),
    .dir(b_dir),
    .other_clk(a_clk),
    .other_rst_n(a_rst_n),
    .other_winc(a_to_b_winc),
    .other_wdata(a_to_b_wdata),
    .other_rinc(a_to_b_rinc),
    .other_rdata(a_to_b_rdata),
    .other_full(a_to_b_full),
    .other_afull(a_to_b_afull),
    .other_empty(a_to_b_empty),
    .other_aempty(a_to_b_aempty)
  );

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
       input wire              other_clk,
       input wire              other_rst_n,
       output wire             other_winc,
       output wire [DSIZE-1:0] other_wdata,
       output wire             other_rinc,
       output wire [DSIZE-1:0] other_rdata,
       output wire             other_full,
       output wire             other_afull,
       output wire             other_empty,
       output wire             other_aempty
       );

  wire [DSIZE-1:0] buffer [0:(1<<ASIZE)-1];
  wire [ASIZE:0] write_ptr, read_ptr, other_write_ptr, other_read_ptr;
  wire [ASIZE:0] write_gray, read_gray, other_write_gray, other_read_gray;

  gray_counter #(
    .SIZE(ASIZE+1)
  ) write_counter (
    .clk(clk),
    .rst_n(rst_n),
    .inc(winc),
    .gray(write_gray)
  );

  gray_counter #(
    .SIZE(ASIZE+1)
  ) read_counter (
    .clk(clk),
    .rst_n(rst_n),
    .inc(rinc),
    .gray(read_gray)
  );

  gray_counter #(
    .SIZE(ASIZE+1)
  ) other_write_counter (
    .clk(other_clk),
    .rst_n(other_rst_n),
    .inc(other_winc),
    .gray(other_write_gray)
  );

  gray_counter #(
    .SIZE(ASIZE+1)
  ) other_read_counter (
    .clk(other_clk),
    .rst_n(other_rst_n),
    .inc(other_rinc),
    .gray(other_read_gray)
  );

  gray_to_bin #(
    .SIZE(ASIZE+1)
  ) write_gray_to_bin (
    .gray(write_gray),
    .bin(write_ptr)
  );

  gray_to_bin #(
    .SIZE(ASIZE+1)
  ) read_gray_to_bin (
    .gray(read_gray),
    .bin(read_ptr)
  );

  gray_to_bin #(
    .SIZE(ASIZE+1)
  ) other_write_gray_to_bin (
    .gray(other_write_gray),
    .bin(other_write_ptr)
  );

  gray_to_bin #(
    .SIZE(ASIZE+1)
  ) other_read_gray_to_bin (
    .gray(other_read_gray),
    .bin(other_read_ptr)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      buffer <= '{default: {DSIZE{1'b0}}};
    end else if (winc) begin
      buffer[write_ptr[ASIZE:0]] <= wdata;
    end
  end

  assign rdata = buffer[read_ptr[ASIZE:0]];

  assign full = (write_gray[ASIZE] != read_gray[ASIZE]) && (write_gray[ASIZE-1:0] == read_gray[ASIZE-1:0]);
  assign afull = (write_gray[ASIZE] == read_gray[ASIZE]) && (write_gray[ASIZE-1:0] == read_gray[ASIZE-1:0] + 1);
  assign empty = (write_gray == read_gray);
  assign aempty = (write_gray[ASIZE] != read_gray[ASIZE]) && (write_gray[ASIZE-1:0] == read_gray[ASIZE-1:0] + (1<<ASIZE) - 1);

  assign other_winc = (dir) ? winc : 1'b0;
  assign other_wdata = (dir) ? wdata : {DSIZE{1'b0}};
  assign other_rinc = (!dir) ? rinc : 1'b0;
  assign other_rdata = (dir) ? {DSIZE{1'b0}} : rdata;

  assign other_full = (other_write_gray[ASIZE] != other_read_gray[ASIZE]) && (other_write_gray[ASIZE-1:0] == other_read_gray[ASIZE-1:0]);
  assign other_afull = (other_write_gray[ASIZE] == other_read_gray[ASIZE]) && (other_write_gray[ASIZE-1:0] == other_read_gray[ASIZE-1:0] + 1);
  assign other_empty = (other_write_gray == other_read_gray);
  assign other_aempty = (other_write_gray[ASIZE] != other_read_gray[ASIZE]) && (other_write_gray[ASIZE-1:0] == other_read_gray[ASIZE-1:0] + (1<<ASIZE) - 1);

endmodule

module gray_counter
  #(
    parameter SIZE = 4
    ) (
       input wire clk,
       input wire rst_n,
       input wire inc,
       output reg [SIZE-1:0] gray
       );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      gray <= {SIZE{1'b0}};
    end else if (inc) begin
      gray <= gray ^ (gray >> 1) ^ 1;
    end
  end

endmodule

module gray_to_bin
  #(
    parameter SIZE = 4
    ) (
       input wire [SIZE-1:0] gray,
       output wire [SIZE-1:0] bin
       );

  assign bin[SIZE-1] = gray[SIZE-1];
  genvar i;
  generate
    for (i = SIZE-2; i >= 0; i = i - 1) begin: g_gray_to_bin
      assign bin[i] = bin[i+1] ^ gray[i];
    end
  endgenerate

endmodule
