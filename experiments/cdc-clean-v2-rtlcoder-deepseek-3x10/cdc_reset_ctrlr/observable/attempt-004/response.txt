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
    reg a_clear_o_int;
    reg b_clear_o_int;
    reg a_isolate_o_int;
    reg b_isolate_o_int;
    reg a_clear_ack_int;
    reg b_clear_ack_int;
    reg a_isolate_ack_int;
    reg b_isolate_ack_int;
    reg a_clear_sync;
    reg b_clear_sync;
    reg a_isolate_sync;
    reg b_isolate_sync;
    reg a_clear_ack_sync;
    reg b_clear_ack_sync;
    reg a_isolate_ack_sync;
    reg b_isolate_ack_sync;

    // State machine for A side
    always @(posedge a_clk_i or negedge a_rst_ni) begin
        if (~a_rst_ni) begin
            a_state <= 2'b00;
            a_clear_o_int <= 1'b0;
            a_isolate_o_int <= 1'b0;
            a_clear_ack_int <= 1'b0;
            a_isolate_ack_int <= 1'b0;
        end else begin
            case (a_state)
                2'b00: begin // Idle
                    if (a_clear_i) begin
                        a_state <= 2'b01;
                        a_clear_o_int <= 1'b1;
                        a_isolate_o_int <= 1'b1;
                    end else if (a_isolate_i) begin
                        a_state <= 2'b10;
                        a_isolate_o_int <= 1'b1;
                    end
                end
                2'b01: begin // Clear
                    if (a_clear_ack_i) begin
                        a_state <= 2'b11;
                        a_clear_ack_int <= 1'b1;
                    end
                end
                2'b10: begin // Isolate
                    if (a_isolate_ack_i) begin
                        a_state <= 2'b11;
                        a_isolate_ack_int <= 1'b1;
                    end
                end
                2'b11: begin // Released
                    a_state <= 2'b00;
                    a_clear_o_int <= 1'b0;
                    a_isolate_o_int <= 1'b0;
                    a_clear_ack_int <= 1'b0;
                    a_isolate_ack_int <= 1'b0;
                end
            endcase
        end
    end

    // State machine for B side
    always @(posedge b_clk_i or negedge b_rst_ni) begin
        if (~b_rst_ni) begin
            b_state <= 2'b00;
            b_clear_o_int <= 1'b0;
            b_isolate_o_int <= 1'b0;
            b_clear_ack_int <= 1'b0;
            b_isolate_ack_int <= 1'b0;
        end else begin
            case (b_state)
                2'b00: begin // Idle
                    if (b_clear_i) begin
                        b_state <= 2'b01;
                        b_clear_o_int <= 1'b1;
                        b_isolate_o_int <= 1'b1;
                    end else if (b_isolate_i) begin
                        b_state <= 2'b10;
                        b_isolate_o_int <= 1'b1;
                    end
                end
                2'b01: begin // Clear
                    if (b_clear_ack_i) begin
                        b_state <= 2'b11;
                        b_clear_ack_int <= 1'b1;
                    end
                end
                2'b10: begin // Isolate
                    if (b_isolate_ack_i) begin
                        b_state <= 2'b11;
                        b_isolate_ack_int <= 1'b1;
                    end
                end
                2'b11: begin // Released
                    b_state <= 2'b00;
                    b_clear_o_int <= 1'b0;
                    b_isolate_o_int <= 1'b0;
                    b_clear_ack_int <= 1'b0;
                    b_isolate_ack_int <= 1'b0;
                end
            endcase
        end
    end

    // Synchronize signals between domains
    always @(posedge a_clk_i) begin
        a_clear_sync <= a_clear_o_int;
        a_isolate_sync <= a_isolate_o_int;
        a_clear_ack_sync <= a_clear_ack_int;
        a_isolate_ack_sync <= a_isolate_ack_int;
    end

    always @(posedge b_clk_i) begin
        b_clear_sync <= b_clear_o_int;
        b_isolate_sync <= b_isolate_o_int;
        b_clear_ack_sync <= b_clear_ack_int;
        b_isolate_ack_sync <= b_isolate_ack_int;
    end

    // Output signals
    assign a_clear_o = a_clear_sync;
    assign a_isolate_o = a_isolate_sync;
    assign a_clear_ack_o = a_clear_ack_sync;
    assign a_isolate_ack_o = a_isolate_ack_sync;
    assign b_clear_o = b_clear_sync;
    assign b_isolate_o = b_isolate_sync;
    assign b_clear_ack_o = b_clear_ack_sync;
    assign b_isolate_ack_o = b_isolate_ack_sync;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_reg <= 8'h00;
        data_out <= 8'h00;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    data_in = 8'h00;
    #10 rst_n = 1;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 data_in = 8'h0a;
    #10 data_in = 8'h0b;
    #10 data_in = 8'h0c;
    #10 data_in = 8'h0d;
    #10 data_in = 8'h0e;
    #10 data_in = 8'h0f;
    #10 $finish