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

  // FIFO instances
  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) a_fifo (
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

  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) b_fifo (
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

  // Direction control logic
  wire [DSIZE-1:0] a_wdata_reg;
  wire [DSIZE-1:0] b_wdata_reg;
  wire a_winc_reg;
  wire b_winc_reg;
  wire a_rinc_reg;
  wire b_rinc_reg;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_winc_reg <= 1'b0;
      a_wdata_reg <= {DSIZE{1'b0}};
      a_rinc_reg <= 1'b0;
    end else begin
      a_winc_reg <= a_winc;
      a_wdata_reg <= a_wdata;
      a_rinc_reg <= a_rinc;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_winc_reg <= 1'b0;
      b_wdata_reg <= {DSIZE{1'b0}};
      b_rinc_reg <= 1'b0;
    end else begin
      b_winc_reg <= b_winc;
      b_wdata_reg <= b_wdata;
      b_rinc_reg <= b_rinc;
    end
  end

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_winc <= 1'b0;
      a_wdata <= {DSIZE{1'b0}};
      a_rinc <= 1'b0;
    end else begin
      if (a_dir) begin
        a_winc <= a_winc_reg;
        a_wdata <= a_wdata_reg;
        a_rinc <= 1'b0;
      end else begin
        a_winc <= 1'b0;
        a_wdata <= {DSIZE{1'b0}};
        a_rinc <= a_rinc_reg;
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_winc <= 1'b0;
      b_wdata <= {DSIZE{1'b0}};
      b_rinc <= 1'b0;
    end else begin
      if (b_dir) begin
        b_winc <= b_winc_reg;
        b_wdata <= b_wdata_reg;
        b_rinc <= 1'b0;
      end else begin
        b_winc <= 1'b0;
        b_wdata <= {DSIZE{1'b0}};
        b_rinc <= b_rinc_reg;
      end
    end
  end

endmodule

module fifo
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

  reg [ASIZE:0] wr_ptr;
  reg [ASIZE:0] rd_ptr;
  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

  assign full = (wr_ptr == rd_ptr) & ~empty;
  assign afull = (wr_ptr == rd_ptr) & ~aempty;
  assign empty = (wr_ptr == rd_ptr) & empty;
  assign aempty = (wr_ptr == rd_ptr) & aempty;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
    end else begin
      if (winc && !full) begin
        mem[wr_ptr] <= wdata;
        wr_ptr <= wr_ptr + 1;
      end
      if (rinc && !empty) begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

  assign rdata = mem[rd_ptr];

endmodule
