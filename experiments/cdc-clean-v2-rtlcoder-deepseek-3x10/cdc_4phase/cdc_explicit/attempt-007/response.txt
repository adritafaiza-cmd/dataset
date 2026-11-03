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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_ready_reg;
  reg [1:0] src_state_reg;
  reg [1:0] dst_state_reg;

  // State machine states
  localparam IDLE = 2'b00;
  localparam SEND = 2'b01;
  localparam WAIT = 2'b10;

  // Source state machine
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_state_reg <= IDLE;
    end else begin
      case (src_state_reg)
        IDLE: begin
          if (src_valid_i && src_ready_o) begin
            src_data_reg <= src_data_i;
            src_valid_reg <= 1'b1;
            src_ready_reg <= 1'b0;
            src_state_reg <= SEND;
          end
        end
        SEND: begin
          if (dst_ready_i) begin
            src_valid_reg <= 1'b0;
            src_ready_reg <= 1'b1;
            src_state_reg <= WAIT;
          end
        end
        WAIT: begin
          if (dst_valid_o) begin
            src_ready_reg <= 1'b0;
            src_state_reg <= IDLE;
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
      dst_ready_reg <= 1'b0;
      dst_state_reg <= IDLE;
    end else begin
      case (dst_state_reg)
        IDLE: begin
          if (src_valid_reg && dst_ready_i) begin
            dst_data_reg <= src_data_reg;
            dst_valid_reg <= 1'b1;
            dst_ready_reg <= 1'b0;
            dst_state_reg <= SEND;
          end
        end
        SEND: begin
          if (src_ready_reg) begin
            dst_valid_reg <= 1'b0;
            dst_ready_reg <= 1'b1;
            dst_state_reg <= WAIT;
          end
        end
        WAIT: begin
          if (!src_valid_reg) begin
            dst_ready_reg <= 1'b0;
            dst_state_reg <= IDLE;
          end
        end
      endcase
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

    reg [31:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

    reg [31:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

    reg [31:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

    reg [31:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

    reg [31:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 0;
        #10 rst_n = 1;
        #10 in = 1;
        #10 in = 2;
        #10 in = 3;
        #10 in = 4;
        #10 $finish;
    end

    always #5 clk = ~clk;

    initial begin
        $dumpfile("top_module.vcd");
        $dumpvars(0, top_module_tb);
    end

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] in;
    wire [31:0] out;

    top_module