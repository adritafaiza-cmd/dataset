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
  wire a_full_core, a_afull_core, a_empty_core, a_aempty_core;
  wire b_full_core, b_afull_core, b_empty_core, b_aempty_core;

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE)) a_fifo (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata),
    .full(a_full_core),
    .afull(a_afull_core),
    .empty(a_empty_core),
    .aempty(a_aempty_core)
  );

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE)) b_fifo (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata),
    .full(b_full_core),
    .afull(b_afull_core),
    .empty(b_empty_core),
    .aempty(b_aempty_core)
  );

  // Crossbar
  wire [DSIZE-1:0] a_to_b_data;
  wire a_to_b_rinc, a_to_b_full;
  wire [DSIZE-1:0] b_to_a_data;
  wire b_to_a_winc, b_to_a_empty;
  wire a_dir, b_dir;

  fifo_crossbar #(.DSIZE(DSIZE)) fifo_crossbar (
    .a_to_b_data(a_to_b_data),
    .a_to_b_rinc(a_to_b_rinc),
    .a_to_b_full(a_to_b_full),
    .b_to_a_data(b_to_a_data),
    .b_to_a_winc(b_to_a_winc),
    .b_to_a_empty(b_to_a_empty),
    .a_dir(a_dir),
    .b_dir(b_dir)
  );

  // Connect crossbar to FIFOs
  assign a_to_b_rinc = a_rinc & ~a_full_core;
  assign a_to_b_full = a_full_core;
  assign b_to_a_winc = b_winc & ~b_empty_core;
  assign b_to_a_empty = b_empty_core;

  assign a_rinc = a_to_b_rinc & a_dir;
  assign a_full = a_to_b_full & a_dir;

  assign b_winc = b_to_a_winc & ~a_dir;
  assign b_empty = b_to_a_empty & ~a_dir;

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
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );
  reg [ASIZE-1:0] write_pointer;
  reg [ASIZE-1:0] read_pointer;
  reg [DSIZE-1:0] data_reg [0:15];
  reg [ASIZE-1:0] max_pointer;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_pointer <= 0;
      read_pointer <= 0;
      full <= 0;
      aempty <= 1;
    end else begin
      if (winc && ~full) begin
        data_reg[write_pointer] <= wdata;
        write_pointer <= write_pointer + 1;
        full <= (write_pointer == read_pointer);
        aempty <= 0;
      end

      if (rinc && ~empty) begin
        read_pointer <= read_pointer + 1;
        empty <= (write_pointer == read_pointer);
        aempty <= (write_pointer == read_pointer);
      end

      if (write_pointer == max_pointer) begin
        afull <= 1;
      end else begin
        afull <= 0;
      end
    end
  end

  assign rdata = data_reg[read_pointer];
  assign max_pointer = (1 << ASIZE) - 1;

endmodule

module fifo_crossbar
  #(
    parameter DSIZE         = 8
    ) (
       input wire [DSIZE-1:0] a_to_b_data,
       input wire              a_to_b_rinc,
       input wire              a_to_b_full,
       input wire [DSIZE-1:0] b_to_a_data,
       input wire              b_to_a_winc,
       input wire              b_to_a_empty,
       input wire              a_dir,
       input wire              b_dir
       );
  wire [DSIZE-1:0] data_out;
  wire rinc_out, full_out;
  wire winc_out, empty_out;

  assign data_out = a_dir ? a_to_b_data : b_to_a_data;
  assign rinc_out = a_dir ? a_to_b_rinc : b_to_a_winc;
  assign full_out = a_dir ? a_to_b_full : b_to_a_empty;
  assign winc_out = a_dir ? b_to_a_winc : a_to_b_rinc;
  assign empty_out = a_dir ? b_to_a_empty : a_to_b_full;

endmodule
