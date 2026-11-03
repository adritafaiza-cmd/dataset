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

  // FIFO core for side A
  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_a (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .write_inc(a_winc),
    .write_data(a_wdata),
    .read_inc(a_rinc),
    .direction(a_dir),
    .write_ready(a_full),
    .write_almost_ready(a_afull),
    .read_data(a_rdata),
    .read_ready(a_empty),
    .read_almost_ready(a_aempty)
  );

  // FIFO core for side B
  fifo_core #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) fifo_b (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .write_inc(b_winc),
    .write_data(b_wdata),
    .read_inc(b_rinc),
    .direction(b_dir),
    .write_ready(b_full),
    .write_almost_ready(b_afull),
    .read_data(b_rdata),
    .read_ready(b_empty),
    .read_almost_ready(b_aempty)
  );

  // Cross-connections between FIFOs
  assign fifo_a.read_data = fifo_b.write_data;
  assign fifo_b.read_data = fifo_a.write_data;
  assign fifo_a.write_ready = fifo_b.read_ready;
  assign fifo_b.write_ready = fifo_a.read_ready;
  assign fifo_a.write_almost_ready = fifo_b.read_almost_ready;
  assign fifo_b.write_almost_ready = fifo_a.read_almost_ready;

endmodule

module fifo_core
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              write_inc,
       input wire [DSIZE-1:0]  write_data,
       input wire              read_inc,
       input wire              direction,
       output wire             write_ready,
       output wire             write_almost_ready,
       output wire [DSIZE-1:0]  read_data,
       output wire             read_ready,
       output wire             read_almost_ready
       );

  reg [DSIZE-1:0] mem [0:((1<<ASIZE)-1)];
  reg [ASIZE:0] head_a, tail_a, head_b, tail_b;
  reg [ASIZE:0] count_a, count_b;

  assign write_ready = (count_a < (1<<ASIZE) - 1);
  assign write_almost_ready = (count_a < (1<<ASIZE) - 2);
  assign read_ready = (count_a > 0);
  assign read_almost_ready = (count_a > 1);
  assign a_full = (count_a == (1<<ASIZE) - 1);
  assign a_afull = (count_a == (1<<ASIZE) - 2);
  assign a_empty = (count_a == 0);
  assign a_aempty = (count_a == 1);
  assign b_full = (count_b == (1<<ASIZE) - 1);
  assign b_afull = (count_b == (1<<ASIZE) - 2);
  assign b_empty = (count_b == 0);
  assign b_aempty = (count_b == 1);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      head_a <= 0;
      tail_a <= 0;
      count_a <= 0;
      head_b <= 0;
      tail_b <= 0;
      count_b <= 0;
    end else begin
      if (direction) begin
        if (write_inc && write_ready) begin
          mem[tail_a] <= write_data;
          tail_a <= tail_a + 1;
          count_a <= count_a + 1;
        end
        if (read_inc && read_ready) begin
          head_a <= head_a + 1;
          count_a <= count_a - 1;
        end
      end else begin
        if (write_inc && write_ready) begin
          mem[tail_b] <= write_data;
          tail_b <= tail_b + 1;
          count_b <= count_b + 1;
        end
        if (read_inc && read_ready) begin
          head_b <= head_b + 1;
          count_b <= count_b - 1;
        end
      end
    end
  end

endmodule
