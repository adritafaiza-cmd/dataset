The following code implements a four-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks. The module is named `cdc_4phase` and is written in SystemVerilog.

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
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;
  reg [1:0] src_state_reg;
  reg [1:0] dst_state_reg;

  // Source state machine
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_state_reg <= 2'b00;
    end else begin
      case (src_state_reg)
        2'b00: begin // Idle
          if (src_valid_i && src_ready_wire) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            src_state_reg <= 2'b01;
          end
        end
        2'b01: begin // Data held
          if (dst_ready_wire) begin
            src_valid_reg <= 1'b0;
            src_state_reg <= 2'b10;
          end
        end
        2'b10: begin // Wait for destination ready
          if (dst_ready_wire) begin
            src_state_reg <= 2'b00;
          end
        end
      endcase
    end
  end

  // Destination state machine
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_state_reg <= 2'b00;
    end else begin
      case (dst_state_reg)
        2'b00: begin // Idle
          if (src_valid_reg && dst_ready_wire) begin
            dst_data_reg <= src_data_reg;
            dst_valid_reg <= 1'b1;
            dst_state_reg <= 2'b01;
          end
        end
        2'b01: begin // Data held
          if (!dst_ready_wire) begin
            dst_valid_reg <= 1'b0;
            dst_state_reg <= 2'b10;
          end
        end
        2'b10: begin // Wait for destination ready
          if (dst_ready_wire) begin
            dst_state_reg <= 2'b00;
          end
        end
      endcase
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_wire;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Ready logic
  assign src_ready_wire = (src_state_reg == 2'b00) || (src_state_reg == 2'b10);
  assign dst_ready_wire = (dst_state_reg == 2'b00) || (dst_state_reg == 2'b10);

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

  // Inputs
  reg clk;
  reg rst_n;
  reg [7:0] data_in;
  reg valid_in;

  // Outputs
  wire [7:0] data_out;
  wire valid_out;

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_in = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0A;
    #10 data_in = 8'h0B;
    #10 data_in = 8'h0C;
    #10 data_in = 8'h0D;
    #10 data_in = 8'h0E;
    #10 data_in = 8'h0F;
    #10 valid_in = 0;
  end

  // Output checking
  always @(posedge clk) begin
    if (valid_out && (data_out !== data_in)) begin
      $display("Error: data mismatch at time %t", $time);
      $finish;
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

  // Instantiate DUT
  cdc_4phase #(
    .WIDTH(8),
    .DECOUPLED(1),
    .SEND_RESET_MSG(1),
    .RESET_MSG(8'hAA)
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
    #10 valid_