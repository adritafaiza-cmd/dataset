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

  localparam FIFO_DEPTH = 2**ASIZE;
  localparam FULL_FLAG = FIFO_DEPTH - 1;
  localparam AEMPTY_FLAG = FIFO_DEPTH - 1;

  // FIFO cores for both sides
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_dir ? a_winc : 0),
    .wdata(a_dir ? a_wdata : 0),
    .rinc(a_dir ? 0 : a_rinc),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_dir ? b_winc : 0),
    .wdata(b_dir ? b_wdata : 0),
    .rinc(b_dir ? 0 : b_rinc),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

  // Direction select for both sides
  direction_select dir_select_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .dir(a_dir),
    .fifo_in(a_winc),
    .fifo_out(a_rinc)
  );

  direction_select dir_select_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .dir(b_dir),
    .fifo_in(b_winc),
    .fifo_out(b_rinc)
  );

  // Crossing sync from A to B
  crossing_sync sync_a_to_b (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .data(fifo_a.rdata),
    .sync_data(fifo_b.wdata)
  );

  // Crossing sync from B to A
  crossing_sync sync_b_to_a (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .data(fifo_b.rdata),
    .sync_data(fifo_a.wdata)
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

  localparam FIFO_DEPTH = 2**ASIZE;
  localparam FULL_FLAG = FIFO_DEPTH - 1;
  localparam AEMPTY_FLAG = FIFO_DEPTH - 1;

  reg [DSIZE-1:0] mem [0:FIFO_DEPTH-1];
  reg [ASIZE:0] head;
  reg [ASIZE:0] tail;
  reg [ASIZE:0] count;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head <= 0;
      tail <= 0;
      count <= 0;
    end else begin
      if (winc && (count < FIFO_DEPTH)) begin
        mem[head] <= wdata;
        head <= head + 1;
        count <= count + 1;
      end

      if (rinc && (count > 0)) begin
        tail <= tail + 1;
        count <= count - 1;
      end
    end
  end

  assign rdata = mem[tail];
  assign full = (count == FIFO_DEPTH);
  assign afull = (count == (FIFO_DEPTH - 1));
  assign empty = (count == 0);
  assign aempty = (count == 1);

endmodule

module direction_select
  (
    input wire              clk,
    input wire              rst_n,
    input wire              dir,
    input wire              fifo_in,
    output wire             fifo_out
    );

  reg fifo_out_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fifo_out_reg <= 0;
    end else begin
      if (dir) begin
        fifo_out_reg <= fifo_in;
      end else begin
        fifo_out_reg <= 0;
      end
    end
  end

  assign fifo_out = fifo_out_reg;

endmodule

module crossing_sync
  (
    input wire              clk,
    input wire              rst_n,
    input wire [DSIZE-1:0]  data,
    output wire [DSIZE-1:0] sync_data
    );

  reg [DSIZE-1:0] sync_data_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_data_reg <= 0;
    end else begin
      sync_data_reg <= data;
    end
  end

  assign sync_data = sync_data_reg;

endmodule
