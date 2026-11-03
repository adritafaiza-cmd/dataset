Sure, here is the complete Verilog-2001 code for the two-domain isolate-then-clear reset controller:

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
    reg [1:0] a_state;
    reg [1:0] b_state;
    reg [1:0] a_next_state;
    reg [1:0] b_next_state;
    reg a_clear_o_reg;
    reg b_clear_o_reg;
    reg a_isolate_o_reg;
    reg b_isolate_o_reg;
    reg a_clear_ack_reg;
    reg b_clear_ack_reg;
    reg a_isolate_ack_reg;
    reg b_isolate_ack_reg;
    reg a_clear_sync_reg [SYNC_STAGES-1:0];
    reg b_clear_sync_reg [SYNC_STAGES-1:0];
    reg a_isolate_sync_reg [SYNC_STAGES-1:0];
    reg b_isolate_sync_reg [SYNC_STAGES-1:0];
    reg a_clear_ack_sync_reg [SYNC_STAGES-1:0];
    reg b_clear_ack_sync_reg [SYNC_STAGES-1:0];
    reg a_isolate_ack_sync_reg [SYNC_STAGES-1:0];
    reg b_isolate_ack_sync_reg [SYNC_STAGES-1:0];

    // State machine
    always @(*) begin
        case (a_state)
            2'b00: begin // Idle
                a_next_state = 2'b01; // Active
                a_clear_o_reg = 1'b1;
                a_isolate_o_reg = 1'b1;
            end
            2'b01: begin // Active
                if (a_clear_i) begin
                    a_next_state = 2'b10; // Done
                    a_clear_o_reg = 1'b0;
                    a_isolate_o_reg = 1'b0;
                end else if (a_isolate_ack_i) begin
                    a_next_state = 2'b11; // Released
                    a_clear_o_reg = 1'b1;
                    a_isolate_o_reg = 1'b1;
                end else begin
                    a_next_state = 2'b01; // Active
                    a_clear_o_reg = 1'b1;
                    a_isolate_o_reg = 1'b1;
                end
            end
            2'b10: begin // Done
                if (a_clear_ack_i) begin
                    a_next_state = 2'b11; // Released
                    a_clear_o_reg = 1'b1;
                    a_isolate_o_reg = 1'b1;
                end else begin
                    a_next_state = 2'b10; // Done
                    a_clear_o_reg = 1'b0;
                    a_isolate_o_reg = 1'b0;
                end
            end
            2'b11: begin // Released
                a_next_state = 2'b00; // Idle
                a_clear_o_reg = 1'b1;
                a_isolate_o_reg = 1'b1;
            end
        endcase
    end

    always @(*) begin
        case (b_state)
            2'b00: begin // Idle
                b_next_state = 2'b01; // Active
                b_clear_o_reg = 1'b1;
                b_isolate_o_reg = 1'b1;
            end
            2'b01: begin // Active
                if (b_clear_i) begin
                    b_next_state = 2'b10; // Done
                    b_clear_o_reg = 1'b0;
                    b_isolate_o_reg = 1'b0;
                end else if (b_isolate_ack_i) begin
                    b_next_state = 2'b11; // Released
                    b_clear_o_reg = 1'b1;
                    b_isolate_o_reg = 1'b1;
                end else begin
                    b_next_state = 2'b01; // Active
                    b_clear_o_reg = 1'b1;
                    b_isolate_o_reg = 1'b1;
                end
            end
            2'b10: begin // Done
                if (b_clear_ack_i) begin
                    b_next_state = 2'b11; // Released
                    b_clear_o_reg = 1'b1;
                    b_isolate_o_reg = 1'b1;
                end else begin
                    b_next_state = 2'b10; // Done
                    b_clear_o_reg = 1'b0;
                    b_isolate_o_reg = 1'b0;
                end
            end
            2'b11: begin // Released
                b_next_state = 2'b00; // Idle
                b_clear_o_reg = 1'b1;
                b_isolate_o_reg = 1'b1;
            end
        endcase
    end

    // Synchronization
    always @(posedge a_clk_i) begin
        a_state <= a_next_state;
        a_clear_o_reg <= a_clear_o_reg;
        a_isolate_o_reg <= a_isolate_o_reg;
        a_clear_sync_reg[0] <= a_clear_i;
        a_isolate_sync_reg[0] <= a_isolate_i;
        a_clear_ack_sync_reg[0] <= a_clear_ack_i;
        a_isolate_ack_sync_reg[0] <= a_isolate_ack_i;
        for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
            a_clear_sync_reg[i] <= a_clear_sync_reg[i-1];
            a_isolate_sync_reg[i] <= a_isolate_sync_reg[i-1];
            a_clear_ack_sync_reg[i] <= a_clear_ack_sync_reg[i-1];
            a_isolate_ack_sync_reg[i] <= a_isolate_ack_sync_reg[i-1];
        end
    end

    always @(posedge b_clk_i) begin
        b_state <= b_next_state;
        b_clear_o_reg <= b_clear_o_reg;
        b_isolate_o_reg <= b_isolate_o_reg;
        b_clear_sync_reg[0] <= b_clear_i;
        b_isolate_sync_reg[0] <= b_isolate_i;
        b_clear_ack_sync_reg[0] <= b_clear_ack_i;
        b_isolate_ack_sync_reg[0] <= b_isolate_ack_i;
        for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
            b_clear_sync_reg[i] <= b_clear_sync_reg[i-1];
            b_isolate_sync_reg[i] <= b_isolate_sync_reg[i-1];
            b_clear_ack_sync_reg[i] <= b_clear_ack_sync_reg[i-1];
            b_isolate_ack_sync_reg[i] <= b_isolate_ack_sync_reg[i-1];
        end
    end

    // Output assignments
    assign a_clear_o = a_clear_o_reg;
    assign a_isolate_o = a_isolate_o_reg;
    assign b_clear_o = b_clear_o_reg;
    assign b_isolate_o = b_isolate_o_reg;
    assign a_clear_ack_reg = a_clear_ack_sync_reg[SYNC_STAGES-1];
    assign b_clear_ack_reg = b_clear_ack_sync_reg[SYNC_STAGES-1];
    assign a_isolate_ack_reg = a_isolate_ack_sync_reg[SYNC_STAGES-1];
    assign b_isolate_ack_reg = b_isolate_ack_sync_reg[SYNC_STAGES-1];
    assign a_clear_ack_i = a_clear_ack_reg;
    assign b_clear_ack_i = b_clear_ack_reg;
    assign a_isolate_ack_i = a_isolate_ack_reg;
    assign b_isolate_ack_i = b_isolate_ack_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [31:0] in;
wire [31:0] out;

top_module dut(
    .clk(clk),
    .rst_n(rst_n),
    .in(in),
    .out(out)
);

initial begin
    clk = 0;
    rst_n = 0;
    in = 0;
    #10 rst_n = 1;
    #10 in = 1;
    #10 in = 2;
    #10 in = 3;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [31:0] in,
    output wire [31:0] out
);

reg [31:0] reg_out;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        reg_out <= 0;
    end else begin
        reg_out <= in;
    end
end

assign out = reg_out;

endmodule

module top_module_tb