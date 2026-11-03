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

  localparam DEPTH = 1 << ASIZE;

  reg [DSIZE-1:0] mem_a [0:DEPTH-1];
  reg [DSIZE-1:0] mem_b [0:DEPTH-1];

  reg [ASIZE:0] wptr_a, rptr_a, wptr_b, rptr_b;
  reg [ASIZE:0] wptr_a_sync, rptr_a_sync, wptr_b_sync, rptr_b_sync;

  reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;

  // Synchronization for pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wptr_b_sync <= 0;
      rptr_b_sync <= 0;
    end else begin
      wptr_b_sync <= wptr_b;
      rptr_b_sync <= rptr_b;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wptr_a_sync <= 0;
      rptr_a_sync <= 0;
    end else begin
      wptr_a_sync <= wptr_a;
      rptr_a_sync <= rptr_a;
    end
  end

  // Write and read operations for side A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      wptr_a <= 0;
      rptr_a <= 0;
    end else begin
      if (a_dir && !a_full) begin
        mem_a[wptr_a[ASIZE-1:0]] <= a_wdata;
        wptr_a <= wptr_a + 1;
      end
      if (!a_dir && !a_empty) begin
        rptr_a <= rptr_a + 1;
      end
    end
  end

  // Write and read operations for side B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      wptr_b <= 0;
      rptr_b <= 0;
    end else begin
      if (b_dir && !b_full) begin
        mem_b[wptr_b[ASIZE-1:0]] <= b_wdata;
        wptr_b <= wptr_b + 1;
      end
      if (!b_dir && !b_empty) begin
        rptr_b <= rptr_b + 1;
      end
    end
  end

  // Read data for side A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= 0;
    end else if (!a_dir && !a_empty) begin
      a_rdata_reg <= mem_b[rptr_a_sync[ASIZE-1:0]];
    end
  end

  // Read data for side B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= 0;
    end else if (!b_dir && !b_empty) begin
      b_rdata_reg <= mem_a[rptr_b_sync[ASIZE-1:0]];
    end
  end

  // Full and empty flags for side A
  assign a_full   = (wptr_a[ASIZE:0] == {1'b1, rptr_a_sync[ASIZE-1:0]});
  assign a_afull  = (wptr_a[ASIZE:0] == {rptr_a_sync[ASIZE-1:0], 1'b1});
  assign a_empty  = (wptr_a_sync[ASIZE:0] == rptr_a[ASIZE:0]);
  assign a_aempty = (wptr_a_sync[ASIZE:0] == {rptr_a[ASIZE-1:0], 1'b0});

  // Full and empty flags for side B
  assign b_full   = (wptr_b[ASIZE:0] == {1'b1, rptr_b_sync[ASIZE-1:0]});
  assign b_afull  = (wptr_b[ASIZE:0] == {rptr_b_sync[ASIZE-1:0], 1'b1});
  assign b_empty  = (wptr_b_sync[ASIZE:0] == rptr_b[ASIZE:0]);
  assign b_aempty = (wptr_b_sync[ASIZE:0] == {rptr_b[ASIZE-1:0], 1'b0});

  // Output data
  assign a_rdata = a_rdata_reg;
  assign b_rdata = b_rdata_reg;

endmodule
