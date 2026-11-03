Sure, here is the complete Verilog code for the four-phase valid/ready channel:

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
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  wire src_ready_w;
  wire [WIDTH-1:0] dst_data_w;
  wire dst_valid_w;
  reg dst_ready_r;

  // Source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
    end else begin
      src_data_r <= src_data_i;
      src_valid_r <= src_valid_i;
    end
  end

  assign src_ready_o = src_ready_w;

  // Destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= {WIDTH{1'b0}};
      dst_valid_o <= 1'b0;
      dst_ready_r <= 1'b0;
    end else begin
      dst_data_o <= dst_data_w;
      dst_valid_o <= dst_valid_w;
      dst_ready_r <= dst_ready_i;
    end
  end

  // Crossing logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_w <= 1'b0;
    end else begin
      src_ready_w <= dst_ready_r;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_w <= {WIDTH{1'b0}};
      dst_valid_w <= 1'b0;
    end else begin
      dst_data_w <= src_data_r;
      dst_valid_w <= src_valid_r & src_ready_w;
    end
  end

  // Reset logic
  reg [1:0] reset_count;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      reset_count <= 2'b00;
    end else begin
      if (src_valid_i && src_ready_w) begin
        reset_count <= 2'b00;
      end else begin
        reset_count <= reset_count + 1'b1;
      end
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= {WIDTH{1'b0}};
      dst_valid_o <= 1'b0;
    end else begin
      if (reset_count == 2'b00) begin
        dst_data_o <= dst_data_w;
        dst_valid_o <= dst_valid_w;
      end else if (reset_count == 2'b01 && SEND_RESET_MSG) begin
        dst_data_o <= RESET_MSG;
        dst_valid_o <= 1'b1;
      end else begin
        dst_data_o <= {WIDTH{1'b0}};
        dst_valid_o <= 1'b0;
      end
    end
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_in = 1;
    #10 data_in = 8'h08;
    valid_in = 1;
    #10 data_in = 8'h09;
    valid_in = 1;
    #10 data_in = 8'h0a;
    valid_in = 1;
    #10 data_in = 8'h0b;
    valid_in = 1;
    #10 data_in = 8'h0c;
    valid_in = 1;
    #10 data_in = 8'h0d;
    valid_in = 1;
    #10 data_in = 8'h0e;
    valid_in = 1;
    #10 data_in = 8'h0f;
    valid_in = 1;
    #10 $finish;
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
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG({8{1'b0}})
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

  // Data input generation
  initial begin
    data_in = 8'h00;
    valid_in = 0;
    #10 data_in = 8'h01;
    valid_in = 1;
    #10 data_in = 8'h02;
    valid_in = 1;
    #10 data_in = 8'h03;
    valid_in = 1;
    #10 data_in = 8'h04;
    valid_in = 1;
    #10 data_in = 8'h05;
    valid_in = 1;
    #10 data_in = 8'h06;
    valid_in = 1;
    #10 data_in = 8'h07;
    valid_