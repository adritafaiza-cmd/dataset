Here is the complete Verilog code for the four-phase valid/ready channel:

```
module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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

  // Internal signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_wire;
  wire [WIDTH-1:0] dst_data_wire;
  wire dst_valid_wire;
  reg dst_ready_reg;

  // Source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_wire) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
      end else begin
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      if (dst_ready_i) begin
        dst_ready_reg <= 1'b1;
      end else begin
        dst_ready_reg <= 1'b0;
      end
    end
  end

  // Transfer contract
  assign src_ready_o = src_ready_wire;
  assign dst_data_o = dst_data_wire;
  assign dst_valid_o = dst_valid_wire;

  // Transfer logic
  assign src_ready_wire = (DECOUPLED) ? (dst_ready_reg) : (dst_ready_reg && !dst_valid_wire);
  assign dst_data_wire = (dst_valid_wire) ? (src_data_reg) : (dst_data_o);
  assign dst_valid_wire = (src_valid_reg && src_ready_wire) ? (1'b1) : (dst_valid_wire);

  // Reset logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= (SEND_RESET_MSG) ? (RESET_MSG) : ({WIDTH{1'b0}});
      src_valid_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out) begin
      if (data_out !== data_in) begin
        $display("Error: data mismatch at time %0t", $time);
        $finish;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out) begin
      if (data_out !== data_in) begin
        $display("Error: data mismatch at time %0t", $time);
        $finish;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out) begin
      if (data_out !== data_in) begin
        $display("Error: data mismatch at time %0t", $time);
        $finish;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out) begin
      if (data_out !== data_in) begin
        $display("Error: data mismatch at time %0t", $time);
        $finish;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out) begin
      if (data_out !== data_in) begin
        $display("Error: data mismatch at time %0t", $time);
        $finish;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out) begin
      if (data_out !== data_in) begin
        $display("Error: data mismatch at time %0t", $time);
        $finish;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out) begin
      if (data_out !== data_in) begin
        $display("Error: data mismatch at time %0t", $time);
        $finish;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate the DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
  ) dut (
    .src_rst_ni(~rst),
    .src_clk_i(clk),
    .src_data_i(data_in),
    .src_valid_i(valid_in),
    .src_ready_o(),
    .dst_rst_ni(1'b1),
    .dst_clk_i(clk),
    .dst_data_o(data_out),
    .dst_valid_o(valid_out),
    .dst_ready_i(1'b1)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1'b1;
    #10 rst = 1'b0;
  end

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 1'b0;
    #10 data_in = 8'h01;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h02;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h03;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h04;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h05;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h06;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h07;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h08;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 data_in = 8'h09;
    valid_in = 1'b1;
    #10 valid_in = 1'b0;
    #10 $finish;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out) begin
      if (data_out !== data_in) begin
        $display("Error: data mismatch at time %0t", $time);
        $finish;
      end
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs