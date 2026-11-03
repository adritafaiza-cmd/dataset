Sure, here is the complete code for the cdc_2phase_clearable module:

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
  reg [SYNC_STAGES-1:0] src_sync_reg;
  reg [SYNC_STAGES-1:0] dst_sync_reg;
  reg src_clear_pending_reg;
  reg dst_clear_pending_reg;
  reg src_clear_reg;
  reg dst_clear_reg;

  // Source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_clear_pending_reg <= 1'b0;
      src_clear_reg <= 1'b0;
    end else begin
      if (src_clear_i) begin
        src_clear_reg <= 1'b1;
        src_clear_pending_reg <= 1'b1;
      end else if (src_valid_i && src_ready_wire) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_clear_pending_reg <= 1'b0;
        src_clear_reg <= 1'b0;
      end else begin
        src_clear_pending_reg <= 1'b0;
        src_clear_reg <= 1'b0;
      end
    end
  end

  // Destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_clear_pending_reg <= 1'b0;
      dst_clear_reg <= 1'b0;
    end else begin
      if (dst_clear_i) begin
        dst_clear_reg <= 1'b1;
        dst_clear_pending_reg <= 1'b1;
      end else if (dst_ready_wire && src_valid_reg && !src_clear_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_clear_pending_reg <= 1'b0;
        dst_clear_reg <= 1'b0;
      end else begin
        dst_clear_pending_reg <= 1'b0;
        dst_clear_reg <= 1'b0;
      end
    end
  end

  // Synchronization
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      src_sync_reg <= {src_sync_reg[SYNC_STAGES-2:0], src_valid_reg};
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_sync_reg <= {SYNC_STAGES{1'b0}};
    end else begin
      dst_sync_reg <= {dst_sync_reg[SYNC_STAGES-2:0], dst_valid_reg};
    end
  end

  // Ready/valid handshake
  assign src_ready_wire = dst_ready_wire && !dst_clear_reg;
  assign dst_ready_wire = src_ready_wire && !src_clear_reg;

  // Output assignments
  assign src_clear_pending_o = src_clear_pending_reg;
  assign src_ready_o = src_ready_wire;
  assign dst_clear_pending_o = dst_clear_pending_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output wire [31:0] data_out
);

    reg [31:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output wire [31:0] data_out
);

    reg [31:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output wire [31:0] data_out
);

    reg [31:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input wire clk,
    input wire rst_n,
    input wire [31:0] data_in,
    output wire [31:0] data_out
);

    reg [31:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_in;
        end
    end

    assign data_out = data_reg;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data_in = 0;
        #10 rst_n = 1;
        #10 data_in = 1;
        #10 data_in = 2;
        #10 data_in = 3;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [31:0] data_in;
    wire [31:0] data_out;

    top_module dut (
        .clk(clk),
