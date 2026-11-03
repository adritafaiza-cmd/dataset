module async_bidir_ramif_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
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
       input wire              b_dir,
       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,
       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

  // Internal signals
  reg [ASIZE-1:0] a_wptr, a_rptr, b_wptr, b_rptr;
  reg [ASIZE-1:0] a_wptr_sync, a_rptr_sync, b_wptr_sync, b_rptr_sync;
  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;
  reg a_full_reg, a_afull_reg, a_empty_reg, a_aempty_reg;
  reg b_full_reg, b_afull_reg, b_empty_reg, b_aempty_reg;

  // CDC synchronizers
  cdc_sync #(.WIDTH(ASIZE)) a2b_wptr_sync (
    .a_clk(a_clk), .a_rst_n(a_rst_n), .a_data(a_wptr),
    .b_clk(b_clk), .b_rst_n(b_rst_n), .b_data(b_wptr_sync)
  );

  cdc_sync #(.WIDTH(ASIZE)) b2a_wptr_sync (
    .a_clk(b_clk), .a_rst_n(b_rst_n), .a_data(b_wptr),
    .b_clk(a_clk), .b_rst_n(a_rst_n), .b_data(a_wptr_sync)
  );

  cdc_sync #(.WIDTH(ASIZE)) a2b_rptr_sync (
    .a_clk(a_clk), .a_rst_n(a_rst_n), .a_data(a_rptr),
    .b_clk(b_clk), .b_rst_n(b_rst_n), .b_data(b_rptr_sync)
  );

  cdc_sync #(.WIDTH(ASIZE)) b2a_rptr_sync (
    .a_clk(b_clk), .a_rst_n(b_rst_n), .a_data(b_rptr),
    .b_clk(a_clk), .b_rst_n(a_rst_n), .b_data(a_rptr_sync)
  );

  // a_clk domain logic
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wptr <= 0;
      a_rptr <= 0;
      a_full_reg <= 0;
      a_afull_reg <= 0;
      a_empty_reg <= 1;
      a_aempty_reg <= 1;
    end else begin
      if (a_winc && !a_full_reg) begin
        a_wptr <= a_wptr + 1;
      end
      if (a_rinc && !a_empty_reg) begin
        a_rptr <= a_rptr + 1;
      end

      // Update flags
      a_full_reg <= (a_wptr_sync + 1) == a_rptr_sync;
      a_afull_reg <= (a_wptr_sync + 2) == a_rptr_sync;
      a_empty_reg <= a_wptr == a_rptr;
      a_aempty_reg <= (a_wptr + 1) == a_rptr;

      // Read data
      if (a_rinc && !a_empty_reg) begin
        a_rdata_reg <= i_ram_a_rdata;
      end
    end
  end

  // b_clk domain logic
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wptr <= 0;
      b_rptr <= 0;
      b_full_reg <= 0;
      b_afull_reg <= 0;
      b_empty_reg <= 1;
      b_aempty_reg <= 1;
    end else begin
      if (b_winc && !b_full_reg) begin
        b_wptr <= b_wptr + 1;
      end
      if (b_rinc && !b_empty_reg) begin
        b_rptr <= b_rptr + 1;
      end

      // Update flags
      b_full_reg <= (b_wptr_sync + 1) == b_rptr_sync;
      b_afull_reg <= (b_wptr_sync + 2) == b_rptr_sync;
      b_empty_reg <= b_wptr == b_rptr;
      b_aempty_reg <= (b_wptr + 1) == b_rptr;

      // Read data
      if (b_rinc && !b_empty_reg) begin
        b_rdata_reg <= i_ram_b_rdata;
      end
    end
  end

  // Output assignments
  assign a_rdata = a_rdata_reg;
  assign a_full = a_full_reg;
  assign a_afull = a_afull_reg;
  assign a_empty = a_empty_reg;
  assign a_aempty = a_aempty_reg;

  assign b_rdata = b_rdata_reg;
  assign b_full = b_full_reg;
  assign b_afull = b_afull_reg;
  assign b_empty = b_empty_reg;
  assign b_aempty = b_aempty_reg;

  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = a_wptr;
  assign o_ram_a_rinc = a_rinc;
  assign o_ram_a_winc = a_winc;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = b_wptr;
  assign o_ram_b_rinc = b_rinc;
  assign o_ram_b_winc = b_winc;

endmodule

// CDC synchronizer module
module cdc_sync
  #(
    parameter WIDTH = 8
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire [WIDTH-1:0]  a_data,
       input wire              b_clk,
       input wire              b_rst_n,
       output reg [WIDTH-1:0]  b_data
       );

  reg [WIDTH-1:0] sync_reg [0:2];

  // Sync stages in a_clk domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      sync_reg[0] <= 0;
      sync_reg[1] <= 0;
    end else begin
      sync_reg[0] <= a_data;
      sync_reg[1] <= sync_reg[0];
    end
  end

  // Sync stages in b_clk domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      sync_reg[2] <= 0;
      b_data <= 0;
    end else begin
      sync_reg[2] <= sync_reg[1];
      b_data <= sync_reg[2];
    end
  end

endmodule
