The following is the complete SystemVerilog code for the two-phase valid/ready channel that transfers WIDTH-bit data between asynchronous clocks.

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
  wire dst_valid_wire;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;

  // Source side
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
    end else if (src_valid_i && src_ready_wire) begin
      src_data_reg <= src_data_i;
      src_valid_reg <= 1'b1;
    end else if (dst_ready_wire) begin
      src_valid_reg <= 1'b0;
    end
  end

  assign src_ready_o = src_ready_wire;

  // Destination side
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else if (src_valid_reg && dst_ready_wire) begin
      dst_data_reg <= src_data_reg;
      dst_valid_reg <= 1'b1;
    end else if (dst_valid_reg && dst_ready_i) begin
      dst_valid_reg <= 1'b0;
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Ready signal
  assign src_ready_wire = dst_ready_wire && !dst_valid_reg;
  assign dst_ready_wire = src_ready_wire && !src_valid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        state <= 3'b000;
        data_out <= 8'h00;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], data_in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], data_in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], data_in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], data_in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], data_in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], data_in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], data_in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {data_in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
    end
end

assign data_out = shift_