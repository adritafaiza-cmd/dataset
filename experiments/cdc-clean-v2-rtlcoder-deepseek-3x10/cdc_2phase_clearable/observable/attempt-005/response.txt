The following is the complete SystemVerilog code for the module cdc_2phase_clearable:

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
  reg [SYNC_STAGES-1:0] dst_ready_sync_reg;
  reg [SYNC_STAGES-1:0] dst_valid_sync_reg;
  reg [SYNC_STAGES-1:0] src_ready_sync_reg;
  reg [SYNC_STAGES-1:0] src_clear_sync_next;
  reg [SYNC_STAGES-1:0] dst_clear_sync_next;
  reg [SYNC_STAGES-1:0] src_valid_sync_next;
  reg [SYNC_STAGES-1:0] dst_ready_sync_next;
  reg [SYNC_STAGES-1:0] dst_valid_sync_next;
  reg [SYNC_STAGES-1:0] src_ready_sync_next;

  // Assign outputs
  assign src_ready_o = src_ready_wire;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Source clock domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_clear_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      if (src_clear_i) begin
        src_clear_pending_reg <= 1'b1;
        src_clear_sync_reg <= {SYNC_STAGES{1'b0}};
      end else if (src_clear_pending_reg) begin
        src_clear_sync_reg <= {src_clear_sync_reg[SYNC_STAGES-2:0], 1'b1};
        if (&src_clear_sync_reg) begin
          src_clear_pending_reg <= 1'b0;
          src_clear_sync_reg <= {SYNC_STAGES{1'b0}};
        end
      end else begin
        src_data_reg <= src_data_i;
        src_valid_reg <= src_valid_i;
        src_valid_sync_reg <= {src_valid_sync_reg[SYNC_STAGES-2:0], src_valid_i};
        src_ready_sync_reg <= {src_ready_sync_reg[SYNC_STAGES-2:0], src_ready_wire};
        if (src_valid_i && src_ready_wire) begin
          src_valid_sync_next <= {src_valid_sync_reg[SYNC_STAGES-2:0], 1'b0};
          src_ready_sync_next <= {src_ready_sync_reg[SYNC_STAGES-2:0], 1'b1};
        end else begin
          src_valid_sync_next <= src_valid_sync_reg;
          src_ready_sync_next <= src_ready_sync_reg;
        end
      end
    end
  end

  // Destination clock domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_clear_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      if (dst_clear_i) begin
        dst_clear_pending_reg <= 1'b1;
        dst_clear_sync_reg <= {SYNC_STAGES{1'b0}};
      end else if (dst_clear_pending_reg) begin
        dst_clear_sync_reg <= {dst_clear_sync_reg[SYNC_STAGES-2:0], 1'b1};
        if (&dst_clear_sync_reg) begin
          dst_clear_pending_reg <= 1'b0;
          dst_clear_sync_reg <= {SYNC_STAGES{1'b0}};
        end
      end else begin
        dst_data_reg <= dst_data_reg;
        dst_valid_reg <= dst_valid_reg;
        dst_valid_sync_reg <= {dst_valid_sync_reg[SYNC_STAGES-2:0], dst_valid_reg};
        dst_ready_sync_reg <= {dst_ready_sync_reg[SYNC_STAGES-2:0], dst_ready_i};
        if (dst_valid_reg && dst_ready_i) begin
          dst_valid_sync_next <= {dst_valid_sync_reg[SYNC_STAGES-2:0], 1'b0};
          dst_ready_sync_next <= {dst_ready_sync_reg[SYNC_STAGES-2:0], 1'b1};
        end else begin
          dst_valid_sync_next <= dst_valid_sync_reg;
          dst_ready_sync_next <= dst_ready_sync_reg;
        end
      end
    end
  end

  // Source ready logic
  assign src_ready_wire = (src_clear_pending_reg || dst_clear_pending_reg) ? 1'b0 :
                          (src_valid_sync_next[SYNC_STAGES-1] && dst_ready_sync_next[SYNC_STAGES-1]) ? 1'b1 :
                          (src_valid_sync_reg[SYNC_STAGES-1] && dst_ready_sync_reg[SYNC_STAGES-1]) ? 1'b1 :
                          1'b0;

  // Destination valid logic
  assign dst_valid_reg = (src_clear_pending_reg || dst_clear_pending_reg) ? 1'b0 :
                         (src_valid_sync_reg[SYNC_STAGES-1] && dst_ready_sync_reg[SYNC_STAGES-1]) ? 1'b1 :
                         1'b0;

  // Clear pending logic
  assign src_clear_pending_o = src_clear_pending_reg;
  assign dst_clear_pending_o = dst_clear_pending_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
        shift_reg[1] <= 8'h00;
        shift_reg[2] <= 8'h00;
        shift_reg[3] <= 8'h00;
        shift_reg[4] <= 8'h00;
        shift_reg[5] <= 8'h00;
        shift_reg[6] <= 8'h00;
        shift_reg[7] <= 8'h00;
        out <= 8'h00;
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
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
        shift_reg[0] <= 8'h00;
       