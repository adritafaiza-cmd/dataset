Sure, here is the complete Verilog code for the cdc_2phase_clearable module:

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
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;
  reg clear_pending_reg;
  reg clear_reg;
  reg [SYNC_STAGES-1:0] sync_reg;
  wire [SYNC_STAGES-1:0] sync_next;
  wire [SYNC_STAGES-1:0] sync_clear;
  wire [SYNC_STAGES-1:0] sync_clear_pending;
  wire [SYNC_STAGES-1:0] sync_valid;
  wire [SYNC_STAGES-1:0] sync_ready;
  wire [SYNC_STAGES-1:0] sync_data;
  wire [SYNC_STAGES-1:0] sync_clear_next;
  wire [SYNC_STAGES-1:0] sync_clear_pending_next;
  wire [SYNC_STAGES-1:0] sync_valid_next;
  wire [SYNC_STAGES-1:0] sync_ready_next;
  wire [SYNC_STAGES-1:0] sync_data_next;

  // Synchronization registers
  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      sync_reg <= sync_next;
    end
  end

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      sync_reg <= sync_next;
    end
  end

  // Synchronization logic
  assign sync_next = {sync_reg[SYNC_STAGES-2:0], src_valid_i};
  assign sync_clear = {sync_reg[SYNC_STAGES-2:0], src_clear_i};
  assign sync_clear_pending = {sync_reg[SYNC_STAGES-2:0], clear_pending_reg};
  assign sync_valid = {sync_reg[SYNC_STAGES-2:0], valid_reg};
  assign sync_ready = {sync_reg[SYNC_STAGES-2:0], ready_reg};
  assign sync_data = {sync_reg[SYNC_STAGES-2:0], data_reg};
  assign sync_clear_next = {sync_reg[SYNC_STAGES-2:0], src_clear_i};
  assign sync_clear_pending_next = {sync_reg[SYNC_STAGES-2:0], clear_pending_reg};
  assign sync_valid_next = {sync_reg[SYNC_STAGES-2:0], valid_reg};
  assign sync_ready_next = {sync_reg[SYNC_STAGES-2:0], ready_reg};
  assign sync_data_next = {sync_reg[SYNC_STAGES-2:0], data_reg};

  // Clear logic
  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      clear_reg <= 1'b0;
    end else if (src_clear_i) begin
      clear_reg <= 1'b1;
    end else if (sync_clear_next[SYNC_STAGES-1]) begin
      clear_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      clear_reg <= 1'b0;
    end else if (dst_clear_i) begin
      clear_reg <= 1'b1;
    end else if (sync_clear_next[SYNC_STAGES-1]) begin
      clear_reg <= 1'b0;
    end
  end

  // Clear pending logic
  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      clear_pending_reg <= 1'b0;
    end else if (src_clear_i) begin
      clear_pending_reg <= 1'b1;
    end else if (sync_clear_pending_next[SYNC_STAGES-1]) begin
      clear_pending_reg <= 1'b0;
    end
  end

  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      clear_pending_reg <= 1'b0;
    end else if (dst_clear_i) begin
      clear_pending_reg <= 1'b1;
    end else if (sync_clear_pending_next[SYNC_STAGES-1]) begin
      clear_pending_reg <= 1'b0;
    end
  end

  // Source domain logic
  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
      data_reg <= {WIDTH{1'b0}};
    end else if (src_clear_i) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
      data_reg <= {WIDTH{1'b0}};
    end else if (src_valid_i && src_ready_o) begin
      valid_reg <= 1'b1;
      ready_reg <= 1'b0;
      data_reg <= src_data_i;
    end else if (sync_clear_next[SYNC_STAGES-1]) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
      data_reg <= {WIDTH{1'b0}};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= {WIDTH{1'b0}};
    end else if (dst_clear_i) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= {WIDTH{1'b0}};
    end else if (sync_valid[SYNC_STAGES-1] && dst_ready_i) begin
      dst_valid_o <= 1'b1;
      dst_data_o <= sync_data[SYNC_STAGES-1];
    end else if (sync_clear_next[SYNC_STAGES-1]) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= {WIDTH{1'b0}};
    end
  end

  // Output assignments
  assign src_clear_pending_o = sync_clear_pending[SYNC_STAGES-1];
  assign src_ready_o = sync_ready[SYNC_STAGES-1];
  assign dst_clear_pending_o = sync_clear_pending[SYNC_STAGES-1];

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in[0]};
        data_out <= shift_reg[7];
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