The following code implements a clearable two-phase valid/ready channel between asynchronous clocks:

```
module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_wire;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;
  reg [SYNC_STAGES-1:0] src_clear_sync;
  reg [SYNC_STAGES-1:0] dst_clear_sync;
  reg [SYNC_STAGES-1:0] src_valid_sync;
  reg [SYNC_STAGES-1:0] dst_ready_sync;
  reg [SYNC_STAGES-1:0] dst_valid_sync;
  reg [SYNC_STAGES-1:0] src_ready_sync;

  // Synchronization FIFO
  generate
    if (SYNC_STAGES > 0) begin
      fifo_v3_2_1_sync #(
        .FIFO_WIDTH(WIDTH+2),
        .FIFO_DEPTH(SYNC_STAGES)
      ) src_fifo (
        .rst(~src_rst_ni),
        .wr_clk(src_clk_i),
        .rd_clk(dst_clk_i),
        .din({src_data_i, src_valid_i, src_ready_wire}),
        .wr_en(src_valid_i & src_ready_wire),
        .rd_en(dst_ready_wire & dst_valid_reg),
        .dout({src_data_reg, src_valid_reg, src_ready_wire}),
        .full(),
        .empty(),
        .valid(),
        .underflow(),
        .overflow()
      );

      fifo_v3_2_1_sync #(
        .FIFO_WIDTH(WIDTH+2),
        .FIFO_DEPTH(SYNC_STAGES)
      ) dst_fifo (
        .rst(~dst_rst_ni),
        .wr_clk(dst_clk_i),
        .rd_clk(src_clk_i),
        .din({dst_data_reg, dst_valid_reg, dst_ready_wire}),
        .wr_en(dst_valid_reg & dst_ready_wire),
        .rd_en(src_ready_wire & src_valid_reg),
        .dout({dst_data_i, dst_valid_o, dst_ready_wire}),
        .full(),
        .empty(),
        .valid(),
        .underflow(),
        .overflow()
      );
    end else begin
      assign src_data_reg = src_data_i;
      assign src_valid_reg = src_valid_i;
      assign src_ready_wire = src_ready_o;
      assign dst_data_i = dst_data_reg;
      assign dst_valid_o = dst_valid_reg;
      assign dst_ready_wire = dst_ready_i;
    end
  endgenerate

  // Clear logic
  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0) begin
      src_clear_pending_reg <= 1'b0;
      src_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_pending_reg <= src_clear_i;
      src_clear_sync <= {src_clear_sync[SYNC_STAGES-2:0], src_clear_i};
    end
  end

  always @(posedge dst_clk_i) begin
    if (dst_rst_ni == 1'b0) begin
      dst_clear_pending_reg <= 1'b0;
      dst_clear_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_pending_reg <= dst_clear_i;
      dst_clear_sync <= {dst_clear_sync[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0) begin
      src_valid_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_sync <= {src_valid_sync[SYNC_STAGES-2:0], src_valid_reg};
    end
  end

  always @(posedge dst_clk_i) begin
    if (dst_rst_ni == 1'b0) begin
      dst_ready_sync <= {SYNC_STAGES{1'b0}};
      dst_valid_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_ready_sync <= {dst_ready_sync[SYNC_STAGES-2:0], dst_ready_wire};
      dst_valid_sync <= {dst_valid_sync[SYNC_STAGES-2:0], dst_valid_reg};
    end
  end

  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0) begin
      src_ready_sync <= {SYNC_STAGES{1'b0}};
    end else begin
      src_ready_sync <= {src_ready_sync[SYNC_STAGES-2:0], src_ready_wire};
    end
  end

  always @(posedge src_clk_i) begin
    if (src_rst_ni == 1'b0 || src_clear_i == 1'b1) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else if (src_valid_i == 1'b1 && src_ready_wire == 1'b1) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1'b1;
    end else if (src_valid_reg == 1'b1 && src_ready_wire == 1'b1) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i) begin
    if (dst_rst_ni == 1'b0 || dst_clear_i == 1'b1) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else if (dst_ready_wire == 1'b1 && dst_valid_reg == 1'b0) begin
      dst_data_reg <= src_data_reg;
      dst_valid_reg <= 1'b1;
    end else if (dst_ready_wire == 1'b1 && dst_valid_reg == 1'b1) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end
  end

  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

  assign src_ready_o = src_ready_wire;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Input generation
  initial begin
    in = 0;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 in = 4;
    #10 in = 5;
    #10 in = 6;
    #10 in = 7;
    #10 in = 8;
    #10 in = 9;
    #10 in = 10;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (out !== in * 2) begin
      $display("Error: out = %d, expected = %d", out, in * 2);
      $finish;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
  input clk,
  input rst_n,
  input [31:0] in,
  output reg [31:0] out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out <= 0;
    end else begin
      out <= in * 2;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [31:0] in;

  // Outputs
  wire [31:0] out;

  // Instantiate the DUT
  my_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
  );

