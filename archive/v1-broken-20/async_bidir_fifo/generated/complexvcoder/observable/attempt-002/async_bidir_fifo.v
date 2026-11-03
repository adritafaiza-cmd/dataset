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

  // FIFO core instances
  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) a_fifo (
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

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH)) b_fifo (
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

  // Mux instances
  mux #(.WIDTH(DSIZE)) a_to_b_mux (
    .sel(a_dir),
    .in0(a_rdata),
    .in1(b_fifo.rdata),
    .out(b_rdata)
  );

  mux #(.WIDTH(DSIZE)) b_to_a_mux (
    .sel(b_dir),
    .in0(b_rdata),
    .in1(a_fifo.rdata),
    .out(a_rdata)
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

  reg [ASIZE:0] wr_ptr;
  reg [ASIZE:0] rd_ptr;
  reg [DSIZE-1:0] mem [0:2**ASIZE-1];
  reg full_reg, empty_reg, aempty_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      full_reg <= 0;
      empty_reg <= 1;
      aempty_reg <= 1;
    end else begin
      if (winc && !full_reg) begin
        mem[wr_ptr] <= wdata;
        wr_ptr <= wr_ptr + 1;
        if (wr_ptr == 2**ASIZE - 1) begin
          full_reg <= 1;
        end
        if (empty_reg) begin
          empty_reg <= 0;
        end
      end

      if (rinc && !empty_reg) begin
        rd_ptr <= rd_ptr + 1;
        if (rd_ptr == 2**ASIZE - 1) begin
          empty_reg <= 1;
        end
        if (full_reg) begin
          full_reg <= 0;
        end
      end
    end
  end

  assign rdata = mem[rd_ptr];
  assign full = full_reg;
  assign afull = full_reg && (wr_ptr == rd_ptr);
  assign empty = empty_reg;
  assign aempty = empty_reg && (wr_ptr == rd_ptr);

endmodule

module mux #(
    parameter WIDTH = 8
  ) (
    input wire [WIDTH-1:0] in0,
    input wire [WIDTH-1:0] in1,
    input wire sel,
    output wire [WIDTH-1:0] out
  );

  assign out = sel ? in0 : in1;

endmodule
