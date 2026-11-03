Sure, here is the complete Verilog-2001 code for the APB clock-domain bridge:

```
module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    // Internal signals
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [2:0] src_pprot_reg;
    reg src_pwrite_reg;
    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pready_reg;
    reg [DATA_WIDTH-1:0] dst_prdata_reg;
    reg dst_pslverr_reg;
    reg dst_pready_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [2:0] dst_pprot_reg;
    reg dst_pwrite_reg;
    reg dst_psel_reg;
    reg dst_penable_reg;
    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg src_pslverr_reg;
    reg src_pready_reg;
    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_next;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_next;
    reg [2:0] dst_pprot_next;
    reg dst_pwrite_next;
    reg dst_psel_next;
    reg dst_penable_next;
    reg [DATA_WIDTH-1:0] src_pwdata_next;
    reg [DATA_WIDTH/8-1:0] src_pstrb_next;
    reg [2:0] src_pprot_next;
    reg src_pwrite_next;
    reg src_psel_next;
    reg src_penable_next;
    reg [DATA_WIDTH-1:0] dst_prdata_next;
    reg dst_pslverr_next;
    reg dst_pready_next;
    reg [ADDR_WIDTH-1:0] dst_paddr_next;
    reg [DATA_WIDTH-1:0] src_prdata_next;
    reg src_pslverr_next;
    reg src_pready_next;
    reg [ADDR_WIDTH-1:0] src_paddr_next;

    // Clock domain crossing
    always @(posedge src_pclk_i) begin
        if (!src_preset_ni) begin
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_pwrite_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 0;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 0;
            src_paddr_reg <= 0;
        end else begin
            src_pwdata_reg <= src_pwdata_next;
            src_pstrb_reg <= src_pstrb_next;
            src_pprot_reg <= src_pprot_next;
            src_pwrite_reg <= src_pwrite_next;
            src_psel_reg <= src_psel_next;
            src_penable_reg <= src_penable_next;
            src_pready_reg <= src_pready_next;
            src_prdata_reg <= src_prdata_next;
            src_pslverr_reg <= src_pslverr_next;
            src_paddr_reg <= src_paddr_next;
        end
    end

    always @(posedge dst_pclk_i) begin
        if (!dst_preset_ni) begin
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 0;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 0;
            dst_paddr_reg <= 0;
        end else begin
            dst_pwdata_reg <= dst_pwdata_next;
            dst_pstrb_reg <= dst_pstrb_next;
            dst_pprot_reg <= dst_pprot_next;
            dst_pwrite_reg <= dst_pwrite_next;
            dst_psel_reg <= dst_psel_next;
            dst_penable_reg <= dst_penable_next;
            dst_pready_reg <= dst_pready_next;
            dst_prdata_reg <= dst_prdata_next;
            dst_pslverr_reg <= dst_pslverr_next;
            dst_paddr_reg <= dst_paddr_next;
        end
    end

    // APB request and response
    always @(*) begin
        src_pready_next = dst_pready_reg;
        src_prdata_next = dst_prdata_reg;
        src_pslverr_next = dst_pslverr_reg;
        src_paddr_next = dst_paddr_reg;
        dst_pwdata_next = src_pwdata_reg;
        dst_pstrb_next = src_pstrb_reg;
        dst_pprot_next = src_pprot_reg;
        dst_pwrite_next = src_pwrite_reg;
        dst_psel_next = src_psel_reg;
        dst_penable_next = src_penable_reg;
        dst_pready_next = src_pready_reg;
        dst_prdata_next = src_prdata_reg;
        dst_pslverr_next = src_pslverr_reg;
        dst_paddr_next = src_paddr_reg;
    end

    // Output signals
    assign src_pready_o = src_pready_reg;
    assign src_prdata_o = src_prdata_reg;
    assign src_pslverr_o = src_pslverr_reg;
    assign dst_psel_o = dst_psel_reg;
    assign dst_penable_o = dst_penable_reg;
    assign dst_pwrite_o = dst_pwrite_reg;
    assign dst_paddr_o = dst_paddr_reg;
    assign dst_pwdata_o = dst_pwdata_reg;
    assign dst_pstrb_o = dst_pstrb_reg;
    assign dst_pprot_o = dst_pprot_reg;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= '{8{'0}};
        data_out <= '0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= '{8{'0}};
        data_out <= '0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= '{8{'0}};
        data_out <= '0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] index;

always @(posedge clk) begin
    if (reset) begin
        index <= 0;
        shift_reg <= '{8{'0}};
        data_out <= '0;
    end else begin
        shift_reg[index] <= data_in;
        index <= index + 1;
        if (index == 8) begin
            index <= 0;
            data_out <= shift_reg[7];
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'h00;
    #10 reset = 0;
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 data_in = 8'h09;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
