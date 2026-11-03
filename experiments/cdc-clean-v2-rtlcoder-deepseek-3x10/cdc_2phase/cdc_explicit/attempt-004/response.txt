Sure, here is the complete Verilog code for the two-phase valid/ready channel:

```
module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_wire;

  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
    end
  end

  assign src_ready_wire = dst_ready_i;
  assign src_ready_o = src_ready_wire;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      dst_data_reg <= src_data_reg;
      dst_valid_reg <= src_valid_reg;
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_ready_wire = src_ready_wire;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 1;
    #10;
    data_in = 8'h0D;
    valid_in = 1;
    #10;
    data_in = 8'h0E;
    valid_in = 1;
    #10;
    data_in = 8'h0F;
    valid_in = 1;
    #10;

    // End simulation
    $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_2phase #(
    .WIDTH(8)
  ) dut (
    .src_rst_ni(rst_n),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(rst_n),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #10 rst_n = 1;
  end

  // Testbench
  initial begin
    // Initialize inputs
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    valid_in = 0;

    // Wait for reset to complete
    #10;

    // Send data
    data_in = 8'h01;
    valid_in = 1;
    #10;
    data_in = 8'h02;
    valid_in = 1;
    #10;
    data_in = 8'h03;
    valid_in = 1;
    #10;
    data_in = 8'h04;
    valid_in = 1;
    #10;
    data_in = 8'h05;
    valid_in = 1;
    #10;
    data_in = 8'h06;
    valid_in = 1;
    #10;
    data_in = 8'h07;
    valid_in = 1;
    #10;
    data_in = 8'h08;
    valid_in = 1;
    #10;
    data_in = 8'h09;
    valid_in = 1;
    #10;
    data_in = 8'h0A;
    valid_in = 1;
    #10;
    data_in = 8'h0B;
    valid_in = 1;
    #10;
    data_in = 8'h0C;
    valid_in = 