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

  // Internal signals for FIFO core outputs
  wire [DSIZE-1:0] fifo_core_a_to_b_rdata;
  wire             fifo_core_a_to_b_full;
  wire             fifo_core_a_to_b_afull;
  wire             fifo_core_a_to_b_empty;
  wire             fifo_core_a_to_b_aempty;

  wire [DSIZE-1:0] fifo_core_b_to_a_rdata;
  wire             fifo_core_b_to_a_full;
  wire             fifo_core_b_to_a_afull;
  wire             fifo_core_b_to_a_empty;
  wire             fifo_core_b_to_a_aempty;

  // Internal signals for cross-domain synchronization
  wire sync_a_empty_to_b_data_out;
  wire sync_b_empty_to_a_data_out;

  // FIFO cores for bidirectional data transfer
  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_core_a_to_b (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(b_rinc),
    .rdata(fifo_core_a_to_b_rdata),
    .full(fifo_core_a_to_b_full),
    .afull(fifo_core_a_to_b_afull),
    .empty(fifo_core_a_to_b_empty),
    .aempty(fifo_core_a_to_b_aempty)
  );

  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_core_b_to_a (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(a_rinc),
    .rdata(fifo_core_b_to_a_rdata),
    .full(fifo_core_b_to_a_full),
    .afull(fifo_core_b_to_a_afull),
    .empty(fifo_core_b_to_a_empty),
    .aempty(fifo_core_b_to_a_aempty)
  );

  // Cross-domain synchronization for a_empty to b_clk domain
  cross_domain_sync sync_a_empty_to_b (
    .clk_src(a_clk),
    .data_in(fifo_core_a_to_b_empty),
    .clk_dst(b_clk),
    .data_out(sync_a_empty_to_b_data_out)
  );

  // Cross-domain synchronization for b_empty to a_clk domain
  cross_domain_sync sync_b_empty_to_a (
    .clk_src(b_clk),
    .data_in(fifo_core_b_to_a_empty),
    .clk_dst(a_clk),
    .data_out(sync_b_empty_to_a_data_out)
  );

  // Output assignments
  assign a_rdata = fifo_core_a_to_b_rdata;
  assign a_full  = fifo_core_a_to_b_full;
  assign a_afull = fifo_core_a_to_b_afull;
  assign a_empty = fifo_core_a_to_b_empty;
  assign a_aempty = fifo_core_a_to_b_aempty;

  assign b_rdata = fifo_core_b_to_a_rdata;
  assign b_full  = fifo_core_b_to_a_full;
  assign b_afull = fifo_core_b_to_a_afull;
  assign b_empty = fifo_core_b_to_a_empty;
  assign b_aempty = fifo_core_b_to_a_aempty;

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

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [ASIZE:0] wptr, rptr;
  reg [ASIZE:0] wptr_gray, rptr_gray;
  reg [ASIZE:0] wptr_gray_sync, rptr_gray_sync;

  // Gray code conversion
  assign wptr_gray = wptr ^ (wptr >> 1);
  assign rptr_gray = rptr ^ (rptr >> 1);

  // Gray code synchronization
  sync_gray_code sync_gray_code_wptr (
    .clk_src(clk),
    .data_in(wptr_gray),
    .clk_dst(clk),
    .data_out(wptr_gray_sync)
  );

  sync_gray_code sync_gray_code_rptr (
    .clk_src(clk),
    .data_in(rptr_gray),
    .clk_dst(clk),
    .data_out(rptr_gray_sync)
  );

  // Binary conversion
  binary_code wptr_bin_sync (
    .gray_in(wptr_gray_sync),
    .bin_out(wptr)
  );

  binary_code rptr_bin_sync (
    .gray_in(rptr_gray_sync),
    .bin_out(rptr)
  );

  // Write operation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= 0;
    end else if (winc && !full) begin
      mem[wptr[ASIZE-1:0]] <= wdata;
      wptr <= wptr + 1;
    end
  end

  // Read operation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rptr <= 0;
    end else if (rinc && !empty) begin
      rptr <= rptr + 1;
    end
  end

  // Read data output
  assign rdata = mem[rptr[ASIZE-1:0]];

  // Full and almost full status
  assign full = (wptr_gray_sync == {~rptr_gray_sync[ASIZE], rptr_gray_sync[ASIZE-1:0]});
  assign afull = (wptr_gray_sync == {~rptr_gray_sync[ASIZE], rptr_gray_sync[ASIZE-1:0]} + 1);

  // Empty and almost empty status
  assign empty = (wptr_gray_sync == rptr_gray_sync);
  assign aempty = (wptr_gray_sync == rptr_gray_sync + 1);

endmodule

module sync_gray_code
  (
    input wire clk_src,
    input wire [ASIZE:0] data_in,
    input wire clk_dst,
    output reg [ASIZE:0] data_out
  );

  reg [ASIZE:0] sync_stage1;

  // Two-stage synchronizer
  always @(posedge clk_dst or negedge rst_n) begin
    if (!rst_n) begin
      sync_stage1 <= 0;
      data_out <= 0;
    end else begin
      sync_stage1 <= data_in;
      data_out <= sync_stage1;
    end
  end

endmodule

module binary_code
  (
    input wire [ASIZE:0] gray_in,
    output reg [ASIZE:0] bin_out
  );

  // Gray to binary conversion
  always @(*) begin
    bin_out[ASIZE] = gray_in[ASIZE];
    for (int i = ASIZE-1; i >= 0; i = i - 1) begin
      bin_out[i] = bin_out[i+1] ^ gray_in[i];
    end
  end

endmodule
