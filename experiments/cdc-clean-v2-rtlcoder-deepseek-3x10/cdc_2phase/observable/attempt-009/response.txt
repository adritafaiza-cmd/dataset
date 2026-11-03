The following is the complete SystemVerilog code for the two-phase valid/ready channel:

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
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg ready_reg;
  reg [1:0] state_reg;
  wire [1:0] next_state;

  // State machine
  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      state_reg <= 2'b00;
      valid_reg <= 1'b0;
      ready_reg <= 1'b0;
    end else begin
      state_reg <= next_state;
      valid_reg <= (state_reg == 2'b01) ? src_valid_i : valid_reg;
      ready_reg <= (state_reg == 2'b01) ? dst_ready_i : ready_reg;
    end
  end

  // Next state logic
  always @(*) begin
    case (state_reg)
      2'b00: next_state = (src_valid_i && dst_ready_i) ? 2'b01 : 2'b00;
      2'b01: next_state = (ready_reg) ? 2'b10 : 2'b01;
      2'b10: next_state = (valid_reg) ? 2'b01 : 2'b10;
      default: next_state = 2'b00;
    endcase
  end

  // Data transfer logic
  always @(posedge src_clk_i) begin
    if (!src_rst_ni) begin
      data_reg <= {WIDTH{1'b0}};
    end else begin
      case (state_reg)
        2'b00: data_reg <= data_reg;
        2'b01: data_reg <= src_data_i;
        2'b10: data_reg <= data_reg;
        default: data_reg <= {WIDTH{1'b0}};
      endcase
    end
  end

  // Output assignments
  assign src_ready_o = (state_reg == 2'b00) ? 1'b1 : 1'b0;
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;
            end
            3'b111: begin
                data_out <= shift_reg;
                state <= 3'b000;
            end
        endcase
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
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
                shift_reg <= {shift_reg[5:0], shift_reg[7]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], shift_reg[7:6]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], shift_reg[7:4]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], shift_reg[7:3]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], shift_reg[7:2]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], shift_reg[7:1]};
                state <= 3'b111;