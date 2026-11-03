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
  wire [DSIZE-1:0] fifo_a_wdata;
  wire [DSIZE-1:0] fifo_a_rdata;
  wire [DSIZE-1:0] fifo_b_wdata;
  wire [DSIZE-1:0] fifo_b_rdata;

  // FIFOs
  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc && a_dir),
    .wdata(a_wdata),
    .rinc(a_rinc && a_dir),
    .rdata(fifo_a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty)
  );

  fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc && b_dir),
    .wdata(b_wdata),
    .rinc(b_rinc && b_dir),
    .rdata(fifo_b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty)
  );

  // CDC for side A to side B
  cdc #(.DSIZE(DSIZE)) cdc_a_to_b (
    .clk_a(a_clk),
    .rst_n_a(a_rst_n),
    .clk_b(b_clk),
    .rst_n_b(b_rst_n),
    .dir(a_dir),
    .full_a(a_full),
    .empty_a(a_empty),
    .winc_a(a_winc),
    .wdata_a(a_wdata),
    .rinc_b(b_rinc),
    .rdata_b(b_rdata),
    .full_b(b_full),
    .empty_b(b_empty)
  );

  // CDC for side B to side A
  cdc #(.DSIZE(DSIZE)) cdc_b_to_a (
    .clk_a(b_clk),
    .rst_n_a(b_rst_n),
    .clk_b(a_clk),
    .rst_n_b(a_rst_n),
    .dir(b_dir),
    .full_a(b_full),
    .empty_a(b_empty),
    .winc_a(b_winc),
    .wdata_a(b_wdata),
    .rinc_b(a_rinc),
    .rdata_b(a_rdata),
    .full_b(a_full),
    .empty_b(a_empty)
  );

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

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [ASIZE:0] wr_ptr;
  reg [ASIZE:0] rd_ptr;
  reg [ASIZE:0] wr_cnt;
  reg [ASIZE:0] rd_cnt;

  // Write pointer
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
    end else if (winc && !full) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read pointer
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
    end else if (rinc && !empty) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Write count
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_cnt <= 0;
    end else if (winc && !full) begin
      wr_cnt <= wr_cnt + 1;
    end else if (rinc && !empty) begin
      wr_cnt <= wr_cnt - 1;
    end
  end

  // Read count
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_cnt <= 0;
    end else if (rinc && !empty) begin
      rd_cnt <= rd_cnt + 1;
    end else if (winc && !full) begin
      rd_cnt <= rd_cnt - 1;
    end
  end

  // Memory
  always @(posedge clk) begin
    if (winc && !full) begin
      mem[wr_ptr] <= wdata;
    end
  end

  // Output data
  assign rdata = mem[rd_ptr];

  // Flags
  assign full = (wr_cnt == (1<<ASIZE));
  assign afull = (wr_cnt == (1<<ASIZE) - 1);
  assign empty = (rd_cnt == 0);
  assign aempty = (rd_cnt == 1);

endmodule

module cdc
  #(
    parameter DSIZE         = 8
    ) (
       input wire              clk_a,
       input wire              rst_n_a,
       input wire              clk_b,
       input wire              rst_n_b,
       input wire              dir,
       input wire              full_a,
       input wire              empty_a,
       input wire              winc_a,
       input wire [DSIZE-1:0]  wdata_a,
       input wire              rinc_b,
       output wire [DSIZE-1:0] rdata_b,
       output wire             full_b,
       output wire             empty_b
       );

  // Internal signals
  reg [DSIZE-1:0] rdata_a_reg;
  reg [DSIZE-1:0] rdata_b_reg;
  reg full_a_reg;
  reg empty_a_reg;

  // Register for A to B direction
  always @(posedge clk_a or negedge rst_n_a) begin
    if (!rst_n_a) begin
      full_a_reg <= 0;
      empty_a_reg <= 1;
      rdata_a_reg <= 0;
    end else if (winc_a && dir) begin
      full_a_reg <= 1;
      empty_a_reg <= 0;
      rdata_a_reg <= wdata_a;
    end else if (rinc_b && !dir) begin
      full_a_reg <= 0;
      empty_a_reg <= 1;
    end
  end

  // Register for B to A direction
  always @(posedge clk_b or negedge rst_n_b) begin
    if (!rst_n_b) begin
      full_b <= 0;
      empty_b <= 1;
      rdata_b_reg <= 0;
    end else if (winc_b && !dir) begin
      full_b <= 1;
      empty_b <= 0;
      rdata_b_reg <= wdata_b;
    end else if (rinc_a && dir) begin
      full_b <= 0;
      empty_b <= 1;
    end
  end

  // Output data
  assign rdata_b = rdata_b_reg;

endmodule
