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

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        data_reg <= src_data_i;
        valid_reg <= 1'b1;
        ready_reg <= 1'b0;
      end else if (dst_valid_o && dst_ready_i) begin
        valid_reg <= 1'b0;
        ready_reg <= 1'b1;
      end
    end
  end

  assign src_ready_o = ready_reg;
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in, shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        data_out <= 8'b0;
    end else begin
        data_out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        data_out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in};
                state <= 3'b1