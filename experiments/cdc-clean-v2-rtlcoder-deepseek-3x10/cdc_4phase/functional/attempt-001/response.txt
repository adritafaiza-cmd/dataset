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
  wire src_ready_wire;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  wire dst_ready_wire;
  reg [1:0] src_phase_reg;
  reg [1:0] dst_phase_reg;
  reg [1:0] src_phase_next;
  reg [1:0] dst_phase_next;
  reg src_ready_reg;
  reg dst_valid_reg_next;
  reg dst_ready_reg;
  reg src_valid_reg_next;
  reg src_ready_reg_next;
  reg dst_valid_reg_next;
  reg dst_ready_reg_next;

  // Source phase logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase_reg <= 2'b00;
    end else begin
      src_phase_reg <= src_phase_next;
    end
  end

  always @* begin
    case (src_phase_reg)
      2'b00: begin
        src_ready_reg_next = 1'b0;
        src_valid_reg_next = 1'b0;
        if (src_valid_i && src_ready_wire) begin
          src_data_reg <= src_data_i;
          src_valid_reg_next = 1'b1;
          src_phase_next = 2'b01;
        end else begin
          src_phase_next = 2'b00;
        end
      end
      2'b01: begin
        src_ready_reg_next = 1'b1;
        src_valid_reg_next = 1'b1;
        src_phase_next = 2'b10;
      end
      2'b10: begin
        src_ready_reg_next = 1'b0;
        src_valid_reg_next = 1'b0;
        src_phase_next = 2'b00;
      end
      default: begin
        src_ready_reg_next = 1'b0;
        src_valid_reg_next = 1'b0;
        src_phase_next = 2'b00;
      end
    endcase
  end

  // Destination phase logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase_reg <= 2'b00;
    end else begin
      dst_phase_reg <= dst_phase_next;
    end
  end

  always @* begin
    case (dst_phase_reg)
      2'b00: begin
        dst_valid_reg_next = 1'b0;
        dst_ready_reg_next = 1'b0;
        if (dst_ready_wire) begin
          dst_data_reg <= src_data_reg;
          dst_valid_reg_next = 1'b1;
          dst_phase_next = 2'b01;
        end else begin
          dst_phase_next = 2'b00;
        end
      end
      2'b01: begin
        dst_valid_reg_next = 1'b1;
        dst_ready_reg_next = 1'b1;
        dst_phase_next = 2'b10;
      end
      2'b10: begin
        dst_valid_reg_next = 1'b0;
        dst_ready_reg_next = 1'b0;
        dst_phase_next = 2'b00;
      end
      default: begin
        dst_valid_reg_next = 1'b0;
        dst_ready_reg_next = 1'b0;
        dst_phase_next = 2'b00;
      end
    endcase
  end

  // Source ready logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  assign src_ready_wire = (src_phase_reg == 2'b00) ? src_ready_reg : 1'b0;

  // Destination valid and ready logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  assign dst_valid_wire = (dst_phase_reg == 2'b00) ? dst_valid_reg : 1'b0;
  assign dst_ready_wire = (dst_phase_reg == 2'b00) ? dst_ready_reg : 1'b0;

  // Output assignments
  assign src_ready_o = src_ready_wire;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_wire;

  // Reset logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_reg <= 1'b0;
    end else begin
      src_ready_reg <= src_ready_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
    end else begin
      dst_valid_reg <= dst_valid_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
    end else begin
      src_valid_reg <= src_valid_reg_next;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ready_reg <= 1'b0;
    end else begin
      dst_ready_reg <= dst_ready_reg_next;
    end
  end

  always @(posedge src_clk_i or negedge