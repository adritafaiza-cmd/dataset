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

  // Internal signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_wire;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;

  // Source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else if (src_valid_i && src_ready_wire) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1'b1;
    end else begin
      src_valid_reg <= 1'b0;
    end
  end

  assign src_ready_wire = dst_ready_i;
  assign src_ready_o = src_ready_wire;

  // Destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else if (dst_valid_reg && dst_ready_wire) begin
      dst_data_reg <= dst_data_reg;
      dst_valid_reg <= 1'b0;
    end else if (src_valid_reg && src_ready_wire) begin
      dst_data_reg <= src_data_reg;
      dst_valid_reg <= 1'b1;
    end
  end

  assign dst_ready_wire = src_ready_wire;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0;
        shift_reg[6] <= 8'b0;
        shift_reg[7] <= 8'b0;
        out <= 8'b0;
    end else begin
        shift_reg[0] <= in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        out <= shift_reg[shift_count];
        shift_count <= shift_count + 1;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'b0;
        shift_reg[1] <= 8'b0;
        shift_reg[2] <= 8'b0;
        shift_reg[3] <= 8'b0;
        shift_reg[4] <= 8'b0;
        shift_reg[5] <= 8'b0