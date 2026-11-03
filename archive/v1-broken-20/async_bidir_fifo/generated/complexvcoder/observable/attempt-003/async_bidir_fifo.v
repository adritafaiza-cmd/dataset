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

  // FIFO core for 'a' side
  fifo_core fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty),
    .dir(a_dir)
  );

  // FIFO core for 'b' side
  fifo_core fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty),
    .dir(b_dir)
  );

  // Clock domain crossing for 'a' to 'b' direction
  wire [DSIZE-1:0] cdc_a_to_b_rdata;
  wire cdc_a_to_b_aempty;
  wire cdc_a_to_b_empty;
  clock_domain_crossing cdc_a_to_b (
    .clk_a(a_clk),
    .clk_b(b_clk),
    .rst_n_a(a_rst_n),
    .rst_n_b(b_rst_n),
    .data_a(fifo_a.rdata),
    .empty_a(fifo_a.empty),
    .data_b(cdc_a_to_b_rdata),
    .empty_b(cdc_a_to_b_empty)
  );

  assign fifo_b.rdata = cdc_a_to_b_rdata;
  assign fifo_b.empty = cdc_a_to_b_empty;
  assign fifo_b.aempty = cdc_a_to_b_aempty;

  // Clock domain crossing for 'b' to 'a' direction
  wire [DSIZE-1:0] cdc_b_to_a_rdata;
  wire cdc_b_to_a_aempty;
  wire cdc_b_to_a_empty;
  clock_domain_crossing cdc_b_to_a (
    .clk_a(b_clk),
    .clk_b(a_clk),
    .rst_n_a(b_rst_n),
    .rst_n_b(a_rst_n),
    .data_a(fifo_b.rdata),
    .empty_a(fifo_b.empty),
    .data_b(cdc_b_to_a_rdata),
    .empty_b(cdc_b_to_a_empty)
  );

  assign fifo_a.rdata = cdc_b_to_a_rdata;
  assign fifo_a.empty = cdc_b_to_a_empty;
  assign fifo_a.aempty = cdc_b_to_a_aempty;

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
       output wire             aempty,
       input wire              dir
       );

  reg [DSIZE-1:0] mem [0:(2**ASIZE-1)];
  reg [ASIZE:0] wptr, rptr;
  reg wenable, renable;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr <= 0;
      rptr <= 0;
      wenable <= 0;
      renable <= 0;
    end else begin
      wenable <= winc & (dir ? 1'b1 : 1'b0);
      renable <= rinc & (dir ? 1'b0 : 1'b1);
      if (wenable)
        mem[wptr] <= wdata;
      if (renable)
        rptr <= rptr + 1;
      if (wptr < 2**ASIZE - 1)
        wptr <= wptr + 1;
      if (rptr > 0)
        rptr <= rptr - 1;
    end
  end

  assign full = wptr == rptr + 1;
  assign afull = (wptr == rptr + 2) || (wptr == 2**ASIZE - 1 && rptr == 0);
  assign empty = wptr == rptr;
  assign aempty = (wptr == rptr - 1) || (wptr == 0 && rptr == 2**ASIZE - 1);
  assign rdata = mem[rptr];

endmodule

module clock_domain_crossing
  #(
    parameter DSIZE         = 8
    ) (
       input wire              clk_a,
       input wire              clk_b,
       input wire              rst_n_a,
       input wire              rst_n_b,
       input wire [DSIZE-1:0]  data_a,
       input wire              empty_a,
       output wire [DSIZE-1:0] data_b,
       output wire             empty_b
       );

  reg [DSIZE-1:0] shift_reg_a;
  reg [DSIZE-1:0] shift_reg_b;
  reg shift_reg_empty_a;
  reg shift_reg_empty_b;

  always @(posedge clk_a or negedge rst_n_a) begin
    if (!rst_n_a) begin
      shift_reg_a <= 0;
      shift_reg_empty_a <= 1'b1;
    end else begin
      shift_reg_a <= data_a;
      shift_reg_empty_a <= empty_a;
    end
  end

  always @(posedge clk_b or negedge rst_n_b) begin
    if (!rst_n_b) begin
      shift_reg_b <= 0;
      shift_reg_empty_b <= 1'b1;
    end else begin
      shift_reg_b <= shift_reg_a;
      shift_reg_empty_b <= shift_reg_empty_a;
    end
  end

  assign data_b = shift_reg_b;
  assign empty_b = shift_reg_empty_b;

endmodule
