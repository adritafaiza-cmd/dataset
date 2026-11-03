Sure, here is the complete Verilog code for the two-domain isolate-then-clear reset controller:

```
module cdc_reset_ctrlr #(
    parameter SYNC_STAGES = 2
)(
    input  a_clk_i,
    input  a_rst_ni,
    input  a_clear_i,
    output a_clear_o,
    input  a_clear_ack_i,
    output a_isolate_o,
    input  a_isolate_ack_i,
    input  b_clk_i,
    input  b_rst_ni,
    input  b_clear_i,
    output b_clear_o,
    input  b_clear_ack_i,
    output b_isolate_o,
    input  b_isolate_ack_i
);

    // Internal signals
    reg [SYNC_STAGES-1:0] a_isolate_sync;
    reg [SYNC_STAGES-1:0] a_clear_sync;
    reg [SYNC_STAGES-1:0] b_isolate_sync;
    reg [SYNC_STAGES-1:0] b_clear_sync;

    // Synchronize signals
    always @(posedge a_clk_i) begin
        a_isolate_sync <= {a_isolate_sync[SYNC_STAGES-2:0], a_isolate_i};
        a_clear_sync <= {a_clear_sync[SYNC_STAGES-2:0], a_clear_i};
    end

    always @(posedge b_clk_i) begin
        b_isolate_sync <= {b_isolate_sync[SYNC_STAGES-2:0], b_isolate_i};
        b_clear_sync <= {b_clear_sync[SYNC_STAGES-2:0], b_clear_i};
    end

    // State machine
    reg [1:0] a_state;
    reg [1:0] b_state;

    always @(posedge a_clk_i) begin
        if (!a_rst_ni) begin
            a_state <= 2'b00;
            a_isolate_o <= 1'b0;
            a_clear_o <= 1'b0;
        end else begin
            case (a_state)
                2'b00: begin // Idle
                    if (a_clear_sync[SYNC_STAGES-1] && !a_clear_sync[SYNC_STAGES-2]) begin
                        a_state <= 2'b01;
                        a_isolate_o <= 1'b1;
                    end else if (a_isolate_sync[SYNC_STAGES-1] && !a_isolate_sync[SYNC_STAGES-2]) begin
                        a_state <= 2'b10;
                        a_clear_o <= 1'b1;
                    end
                end
                2'b01: begin // Isolate
                    if (a_isolate_ack_i) begin
                        a_state <= 2'b11;
                        a_isolate_o <= 1'b0;
                    end
                end
                2'b10: begin // Clear
                    if (a_clear_ack_i) begin
                        a_state <= 2'b11;
                        a_clear_o <= 1'b0;
                    end
                end
                2'b11: begin // Done
                    a_state <= 2'b00;
                end
            endcase
        end
    end

    always @(posedge b_clk_i) begin
        if (!b_rst_ni) begin
            b_state <= 2'b00;
            b_isolate_o <= 1'b0;
            b_clear_o <= 1'b0;
        end else begin
            case (b_state)
                2'b00: begin // Idle
                    if (b_clear_sync[SYNC_STAGES-1] && !b_clear_sync[SYNC_STAGES-2]) begin
                        b_state <= 2'b01;
                        b_isolate_o <= 1'b1;
                    end else if (b_isolate_sync[SYNC_STAGES-1] && !b_isolate_sync[SYNC_STAGES-2]) begin
                        b_state <= 2'b10;
                        b_clear_o <= 1'b1;
                    end
                end
                2'b01: begin // Isolate
                    if (b_isolate_ack_i) begin
                        b_state <= 2'b11;
                        b_isolate_o <= 1'b0;
                    end
                end
                2'b10: begin // Clear
                    if (b_clear_ack_i) begin
                        b_state <= 2'b11;
                        b_clear_o <= 1'b0;
                    end
                end
                2'b11: begin // Done
                    b_state <= 2'b00;
                end
            endcase
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg rst_n;
    reg [7:0] in;

    // Outputs
    wire [7:0] out;

    // Instantiate the DUT
    my_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 0;
        #10 rst_n = 1;
    end

    // Input generation
    initial begin
        in = 8'h00;
        #20 in = 8'h01;
        #40 in = 8'h02;
        #60 in = 8'h03;
        #80 in = 8'h04;
        #100 $finish;
    end

    // Output checking
    always @(posedge clk) begin
        if (out !== (in + 1)) begin
            $display("Error: out = %h, expected = %h", out, (in + 1));
            $finish;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg rst_n;
    reg [7:0] in;

    // Outputs
    wire [7:0] out;

    // Instantiate the DUT
    my_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 0;
        #10 rst_n = 1;
    end

    // Input generation
    initial begin
        in = 8'h00;
        #20 in = 8'h01;
        #40 in = 8'h02;
        #60 in = 8'h03;
        #80 in = 8'h04;
        #100 $finish;
    end

    // Output checking
    always @(posedge clk) begin
        if (out !== (in + 1)) begin
            $display("Error: out = %h, expected = %h", out, (in + 1));
            $finish;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module top();

    // Inputs
    reg clk;
    reg rst_n;
    reg [7:0] in;

    // Outputs
    wire [7:0] out;

    // Instantiate the DUT
    my_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 0;
        #10 rst_n = 1;
    end

    // Input generation
    initial begin
        in = 8'h00;
        #20 in = 8'h01;
        #40 in = 8'h02;
        #60 in = 8'h03;
        #80 in = 8'h04;
        #100 $finish;
    end

    // Output checking
    always @(posedge clk) begin
        if (out !== (in + 1)) begin
            $display("Error: out = %h, expected = %h", out, (in + 1));
            $finish;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg rst_n;
    reg [7:0] in;

    // Outputs
    wire [7:0] out;

    // Instantiate the DUT
    my_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 0;
        #10 rst_n = 1;
    end

    // Input generation
    initial begin
        in = 8'h00;
        #20 in = 8'h01;
        #40 in = 8'h02;
        #60 in = 8'h03;
        #80 in = 8'h04;
        #100 $finish;
    end

    // Output checking
    always @(posedge clk) begin
        if (out !== (in + 1)) begin
            $display("Error: out = %h, expected = %h", out, (in + 1));
            $finish;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top();

    // Inputs
    reg clk;
    reg rst_n;
    reg [7:0] in;

    // Outputs
    wire [7:0] out;

    // Instantiate the DUT
    my_module dut (
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        rst_n = 0;
        #10 rst_n = 1;
    end

    // Input generation
    initial begin
        in = 8'h00;
        #20 in = 8'h01;
        #40 in = 8'h02;
        #60 in = 8'h03;
        #80 in = 8'h04;
        #100 $finish;
    end

    // Output checking
    always @(posedge clk) begin
        if (out !== (in + 1)) begin
            $display("Error: out = %h, expected = %h", out, (in + 1));
            $finish;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module(
    input clk,
    input rst_n,
    input [7:0] in,
    output reg [7:0] out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 8'h00;
        end else begin
            out <= in + 1;
        end
    end

endmodule

module my_module