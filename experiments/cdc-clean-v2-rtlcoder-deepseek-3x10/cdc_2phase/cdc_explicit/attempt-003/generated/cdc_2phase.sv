The following code implements a two-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks.

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

  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;

  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      data_reg <= src_data_i;
      valid_reg <= 1'b1;
      ready_reg <= 1'b0;
    end else if (dst_valid_o && dst_ready_i) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b1;
    end
  end

  assign src_ready_o = ready_reg;
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else if (dst_valid_o && dst_ready_i) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b1;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

parameter IDLE = 3'b000;
parameter SHIFT = 3'b001;
parameter OUTPUT = 3'b010;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= IDLE;
        data_out <= 8'h00;
    end else begin
        case (state)
            IDLE: begin
                shift_reg <= data_in;
                state <= SHIFT;
            end
            SHIFT: begin
                shift_reg <= {shift_reg[6:0], shift_reg[7]};
                state <= OUTPUT;
            end
            OUTPUT: begin
                data_out <= shift_reg;
                state <= IDLE;
            end
        endcase
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

