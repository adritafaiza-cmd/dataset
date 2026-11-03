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
  reg [ASIZE:0] a_wrptr;
  reg [ASIZE:0] a_rdptr;
  reg [ASIZE:0] b_wrptr;
  reg [ASIZE:0] b_rdptr;
  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [DSIZE-1:0] a_rdata_reg;
  reg [DSIZE-1:0] b_rdata_reg;
  reg a_full_reg;
  reg b_full_reg;
  reg a_empty_reg;
  reg b_empty_reg;

  // Clock domain crossing for a_clk domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wrptr <= 0;
      a_rdptr <= 0;
      a_full_reg <= 0;
      a_empty_reg <= 1;
      a_rdata_reg <= 0;
    end else begin
      if (a_dir) begin
        if (!a_full_reg) begin
          mem[a_wrptr] <= a_wdata;
          a_wrptr <= a_wrptr + 1;
          a_full_reg <= (a_wrptr == a_rdptr + (1<<ASIZE));
        end
      end else begin
        if (!a_empty_reg) begin
          a_rdata_reg <= mem[a_rdptr];
          a_rdptr <= a_rdptr + 1;
          a_empty_reg <= (a_rdptr == a_wrptr);
        end
      end
    end
  end

  // Clock domain crossing for b_clk domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wrptr <= 0;
      b_rdptr <= 0;
      b_full_reg <= 0;
      b_empty_reg <= 1;
      b_rdata_reg <= 0;
    end else begin
      if (b_dir) begin
        if (!b_full_reg) begin
          mem[b_wrptr] <= b_wdata;
          b_wrptr <= b_wrptr + 1;
          b_full_reg <= (b_wrptr == b_rdptr + (1<<ASIZE));
        end
      end else begin
        if (!b_empty_reg) begin
          b_rdata_reg <= mem[b_rdptr];
          b_rdptr <= b_rdptr + 1;
          b_empty_reg <= (b_rdptr == b_wrptr);
        end
      end
    end
  end

  // Output assignments
  assign a_rdata = a_rdata_reg;
  assign a_full = a_full_reg;
  assign a_afull = (a_full_reg && (a_wrptr == a_rdptr + (1<<(ASIZE-1))));
  assign a_empty = a_empty_reg;
  assign a_aempty = (a_empty_reg && (a_wrptr == a_rdptr + 1));
  assign b_rdata = b_rdata_reg;
  assign b_full = b_full_reg;
  assign b_afull = (b_full_reg && (b_wrptr == b_rdptr + (1<<(ASIZE-1))));
  assign b_empty = b_empty_reg;
  assign b_aempty = (b_empty_reg && (b_wrptr == b_rdptr + 1));

endmodule
