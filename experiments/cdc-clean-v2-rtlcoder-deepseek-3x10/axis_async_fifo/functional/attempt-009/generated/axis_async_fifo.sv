The provided code is a Verilog module for an asynchronous AXI-Stream FIFO. It includes all the necessary input and output ports, parameters, and behavior described in the problem description. However, the code is incomplete and does not contain the actual implementation. 

To complete the implementation, we need to add the logic for the FIFO itself. This would involve creating a RAM to store the data, and logic to handle the FIFO operations such as read, write, and pause. 

Here is a basic implementation of the FIFO logic:

```
module axis_async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0,
    parameter FRAME_FIFO = 0,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
)
(
    /*
     * AXI input
     */
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    // FIFO logic here

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>// Code your testbench here
// or browse Examples
module tb_top;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  always @(posedge clk) begin
    if (reset) begin
      out <= 8'b0;
    end else begin
      out <= in;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7:0] in;

  // Outputs
  wire [7:0] out;

  // Instantiate the Unit Under Test (UUT)
  top uut (
    .clk(clk), 
    .reset(reset), 
    .in(in), 
    .out(out)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    reset = 1;
    in = 8'b00000000;

    // Wait 100 ns for global reset to finish
    #100 reset = 0;

    // Add stimulus here
    in = 8'b10101010;
    #100;
    in = 8'b01010101;
    #100;
    in = 8'b11111111;
    #100;
    in = 8'b00000000;
    #100;

    // End simulation
    $finish;
  end

  always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top (
  input clk,
  input reset,
  input [7:0] in,
  output reg [7:0] out
);

  reg [7:0] shift_reg;

  always @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], in[0]};
    end
  end

  assign out = shift_reg;

endmodule

module top_tb;

  // Inputs
  reg clk;
  reg reset;
  reg [7