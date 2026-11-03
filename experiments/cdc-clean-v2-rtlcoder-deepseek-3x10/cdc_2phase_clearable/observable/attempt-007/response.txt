Sure, here is the complete SystemVerilog code for the module `cdc_2phase_clearable`:

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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  wire src_ready_wire;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;
  reg [SYNC_STAGES-1:0] src_clear_sync_reg;
  reg [SYNC_STAGES-1:0] dst_clear_sync_reg;
  reg [SYNC_STAGES-1:0] src_valid_sync_reg;
  reg [SYNC_STAGES-1:0] dst_valid_sync_reg;
  reg [SYNC_STAGES-1:0] src_ready_sync_reg;
  reg [SYNC_STAGES-1:0] dst_ready_sync_reg;

  // Synchronize clear signals
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      src_clear_sync_reg <= {src_clear_sync_reg[SYNC_STAGES-2:0], src_clear_i};
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_clear_sync_reg <= {dst_clear_sync_reg[SYNC_STAGES-2:0], dst_clear_i};
    end
  end

  // Synchronize valid and ready signals
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync_reg <= {SYNC_STAGES{1'b0}};
      src_ready_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      src_valid_sync_reg <= {src_valid_sync_reg[SYNC_STAGES-2:0], src_valid_i};
      src_ready_sync_reg <= {src_ready_sync_reg[SYNC_STAGES-2:0], src_ready_wire};
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync_reg <= {SYNC_STAGES{1'b0}};
      dst_ready_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_valid_sync_reg <= {dst_valid_sync_reg[SYNC_STAGES-2:0], dst_valid_reg};
      dst_ready_sync_reg <= {dst_ready_sync_reg[SYNC_STAGES-2:0], dst_ready_wire};
    end
  end

  // Source side
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
    end else begin
      if (src_clear_sync_reg[SYNC_STAGES-1]) begin
        src_data_reg <= {WIDTH{1'b0}};
        src_valid_reg <= 1'b0;
        src_clear_pending_reg <= 1'b0;
      end else if (src_valid_i && src_ready_wire) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_clear_pending_reg <= 1'b0;
      end else if (src_clear_i) begin
        src_data_reg <= {WIDTH{1'b0}};
        src_valid_reg <= 1'b0;
        src_clear_pending_reg <= 1'b1;
      end
    end
  end

  assign src_ready_wire = (dst_clear_sync_reg[SYNC_STAGES-1] || dst_ready_sync_reg[SYNC_STAGES-1]) ? 1'b1 : dst_ready_i;
  assign src_ready_o = src_ready_wire;
  assign src_clear_pending_o = src_clear_pending_reg;

  // Destination side
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
    end else begin
      if (dst_clear_sync_reg[SYNC_STAGES-1]) begin
        dst_data_reg <= {WIDTH{1'b0}};
        dst_valid_reg <= 1'b0;
        dst_clear_pending_reg <= 1'b0;
      end else if (src_valid_sync_reg[SYNC_STAGES-1] && src_ready_sync_reg[SYNC_STAGES-1]) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_clear_pending_reg <= 1'b0;
      end else if (dst_clear_i) begin
        dst_data_reg <= {WIDTH{1'b0}};
        dst_valid_reg <= 1'b0;
        dst_clear_pending_reg <= 1'b1;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;
  assign dst_ready_wire = (src_clear_sync_reg[SYNC_STAGES-1] || src_ready_sync_reg[SYNC_STAGES-1]) ? 1'b1 : src_ready_i;
  assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
                shift_reg <= {shift_reg[1:0], in[5]};
                state <= 3'b110;
            end
            3'b110: begin
                shift_reg <= {shift_reg[0], in[6]};
                state <= 3'b111;
            end
            3'b111: begin
                shift_reg <= {in[7], shift_reg[7:1]};
                state <= 3'b000;
            end
        endcase
        
        out <= shift_reg;
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] in,
    output reg [7:0] out
);

reg [7:0] shift_reg;
reg [2:0] state;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        state <= 3'b000;
        out <= 8'b0;
    end else begin
        case (state)
            3'b000: begin
                shift_reg <= {shift_reg[6:0], in[0]};
                state <= 3'b001;
            end
            3'b001: begin
                shift_reg <= {shift_reg[5:0], in[1]};
                state <= 3'b010;
            end
            3'b010: begin
                shift_reg <= {shift_reg[4:0], in[2]};
                state <= 3'b011;
            end
            3'b011: begin
                shift_reg <= {shift_reg[3:0], in[3]};
                state <= 3'b100;
            end
            3'b100: begin
                shift_reg <= {shift_reg[2:0], in[4]};
                state <= 3'b101;
            end
            3'b101: begin
