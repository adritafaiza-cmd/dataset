Sure, here is the complete code for the APB clock-domain bridge module in Verilog-2001:

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
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [2:0] src_pprot_reg;
    reg [2:0] dst_pprot_reg;
    reg src_psel_reg;
    reg dst_psel_reg;
    reg src_penable_reg;
    reg dst_penable_reg;
    reg src_pwrite_reg;
    reg dst_pwrite_reg;
    reg src_pready_reg;
    reg dst_pready_reg;
    reg src_pslverr_reg;
    reg dst_pslverr_reg;
    reg [DATA_WIDTH-1:0] src_prdata_reg;
    reg [DATA_WIDTH-1:0] dst_prdata_reg;
    reg [1:0] state;

    // State machine states
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;

    // State machine
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 1'b0) begin
            state <= IDLE;
            src_pready_reg <= 1'b0;
            src_pslverr_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (src_psel_i && src_penable_i) begin
                        state <= SETUP;
                        src_pready_reg <= 1'b0;
                        src_pslverr_reg <= 1'b0;
                        src_paddr_reg <= src_paddr_i;
                        src_pwdata_reg <= src_pwdata_i;
                        src_pstrb_reg <= src_pstrb_i;
                        src_pprot_reg <= src_pprot_i;
                        src_psel_reg <= src_psel_i;
                        src_penable_reg <= src_penable_i;
                        src_pwrite_reg <= src_pwrite_i;
                    end
                end
                SETUP: begin
                    if (dst_pready_i) begin
                        state <= ACCESS;
                        dst_psel_reg <= src_psel_reg;
                        dst_penable_reg <= src_penable_reg;
                        dst_pwrite_reg <= src_pwrite_reg;
                        dst_paddr_reg <= src_paddr_reg;
                        dst_pwdata_reg <= src_pwdata_reg;
                        dst_pstrb_reg <= src_pstrb_reg;
                        dst_pprot_reg <= src_pprot_reg;
                    end
                end
                ACCESS: begin
                    if (dst_pready_i) begin
                        state <= IDLE;
                        src_pready_reg <= 1'b1;
                        src_pslverr_reg <= dst_pslverr_i;
                        src_prdata_reg <= dst_prdata_i;
                    end
                end
            endcase
        end
    end

    // Output assignments
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

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110011;
    #10 $finish;
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module (
    input clk,
    input reset,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg;

always @(posedge clk) begin
    if (reset) begin
        shift_reg <= 8'b0;
        data_out <= 8'b0;
    end else begin
        shift_reg <= {shift_reg[6:0], data_in};
        data_out <= shift_reg[7];
    end
end

endmodule

module top_module_tb;

reg clk;
reg reset;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    clk = 0;
    reset = 1;
    data_in = 8'b0;
    #10 reset = 0;
end

always #5 clk = ~clk;

initial begin
    #10 data_in = 8'b10101010;
    #10 data_in = 8'b01010101;
    #10 data_in = 8'b11001100;
    #10 data_in = 8'b00110