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

  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;

  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else if (src_valid_i && ready_reg) begin
      data_reg <= src_data_i;
      valid_reg <= 1'b1;
      ready_reg <= 1'b0;
    end else if (dst_ready_i && valid_reg) begin
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
    end else if (dst_ready_i && valid_reg) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b1;
    end else if (src_valid_i && ready_reg) begin
      data_reg <= src_data_i;
      valid_reg <= 1'b1;
      ready_reg <= 1'b0;
    end
  end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk) begin
    if (reset) begin
        shift_count <= 0;
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg[0] <= shift_reg[1];
        shift_reg[1] <= shift_reg[2];
        shift_reg[2] <= shift_reg[3];
        shift_reg[3] <= shift_reg[4];
        shift_reg[4] <= shift_reg[5];
        shift_reg[5] <= shift_reg[6];
        shift_reg[6] <= shift_reg[7];
        shift_reg[7] <= data_in;
        shift_count <= shift_count + 1;
        if (shift_count == 7) begin
            data_out <= shift_reg[0];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(