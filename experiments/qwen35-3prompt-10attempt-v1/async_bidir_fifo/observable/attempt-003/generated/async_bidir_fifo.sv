```verilog
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

  // Internal pointers
  reg [ASIZE-1:0] w_ptr_a, r_ptr_a;
  reg [ASIZE-1:0] w_ptr_b, r_ptr_b;

  // Data memory
  reg [DSIZE-1:0] mem [0: {1, ASIZE}-1];

  // Status flags
  reg a_full_int, a_empty_int;
  reg b_full_int, b_empty_int;

  // Crossed pointers for status indication
  wire [ASIZE-1:0] w_ptr_a_crossed;
  wire [ASIZE-1:0] r_ptr_a_crossed;
  wire [ASIZE-1:0] w_ptr_b_crossed;
  wire [ASIZE-1:0] r_ptr_b_crossed;

  // Write pointer crossing logic (A -> B)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      w_ptr_b <= 0;
    else if (b_winc)
      w_ptr_b <= w_ptr_b + 1'b1;
  end

  // Read pointer crossing logic (A -> B)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      r_ptr_b <= 0;
    else if (b_rinc)
      r_ptr_b <= r_ptr_b + 1'b1;
  end

  // Write pointer crossing logic (B -> A)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      w_ptr_a <= 0;
    else if (a_winc)
      w_ptr_a <= w_ptr_a + 1'b1;
  end

  // Read pointer crossing logic (B -> A)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      r_ptr_a <= 0;
    else if (a_rinc)
      r_ptr_a <= r_ptr_a + 1'b1;
  end

  // Generate crossed pointers for status
  assign w_ptr_a_crossed = w_ptr_a;
  assign r_ptr_a_crossed = r_ptr_a;
  assign w_ptr_b_crossed = w_ptr_b;
  assign r_ptr_b_crossed = r_ptr_b;

  // Full/Empty logic for A side
  assign a_full_int = (w_ptr_a == r_ptr_a) && (a_dir == 1'b1);
  assign a_empty_int = (w_ptr_a == r_ptr_a) && (a_dir == 1'b0);

  // Full/Empty logic for B side
  assign b_full_int = (w_ptr_b == r_ptr_b) && (b_dir == 1'b1);
  assign b_empty_int = (w_ptr_b == r_ptr_b) && (b_dir == 1'b0);

  // Output status signals
  assign a_full = a_full_int;
  assign a_afull = (w_ptr_a == r_ptr_a) && (a_dir == 1'b1);
  assign a_empty = a_empty_int;
  assign a_aempty = (w_ptr_a == r_ptr_a) && (a_dir == 1'b0);

  assign b_full = b_full_int;
  assign b_afull = (w_ptr_b == r_ptr_b) && (b_dir == 1'b1);
  assign b_empty = b_empty_int;
  assign b_aempty = (w_ptr_b == r_ptr_b) && (b_dir == 1'b0);

  // Write data to memory
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      w_ptr_a <= 0;
      r_ptr_a <= 0;
      mem <= 0;
    end else if (a_winc) begin
      w_ptr_a <= w_ptr_a + 1'b1;
      mem[w_ptr_a] <= a_wdata;
    end
  end

  // Read data from memory
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      w_ptr_b <= 0;
      r_ptr_b <= 0;
      mem <= 0;
    end else if (b_winc) begin
      w_ptr_b <= w_ptr_b + 1'b1;
      mem[w_ptr_b] <= b_wdata;
    end
  end

  // Read data output
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rdata <= 0;
    else if (a_rinc)
      a_rdata <= mem[r_ptr_a];
  end

  // Read data output
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rdata <= 0;
    else if (b_rinc)
      b_rdata <= mem[r_ptr_b];
  end

endmodule
```<|im_end|>
