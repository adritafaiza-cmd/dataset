Sure, here is the complete code for the APB clock-domain bridge module:

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
    reg [ADDR_WIDTH-1:0] paddr_reg;
    reg [DATA_WIDTH-1:0] pwdata_reg;
    reg [DATA_WIDTH/8-1:0] pstrb_reg;
    reg [2:0] pprot_reg;
    reg psel_reg;
    reg penable_reg;
    reg pwrite_reg;
    reg [DATA_WIDTH-1:0] prdata_reg;
    reg pslverr_reg;
    reg pready_reg;
    reg [1:0] state_reg;

    // State machine states
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;

    // State machine transitions
    always @(posedge src_pclk_i) begin
        if (src_preset_ni == 1'b0) begin
            state_reg <= IDLE;
            psel_reg <= 1'b0;
            penable_reg <= 1'b0;
            pwrite_reg <= 1'b0;
            paddr_reg <= 0;
            pwdata_reg <= 0;
            pstrb_reg <= 0;
            pprot_reg <= 0;
            prdata_reg <= 0;
            pslverr_reg <= 1'b0;
            pready_reg <= 1'b0;
        end else begin
            case (state_reg)
                IDLE: begin
                    if (src_psel_i && src_penable_i) begin
                        state_reg <= SETUP;
                        psel_reg <= 1'b1;
                        penable_reg <= 1'b1;
                        pwrite_reg <= src_pwrite_i;
                        paddr_reg <= src_paddr_i;
                        pwdata_reg <= src_pwdata_i;
                        pstrb_reg <= src_pstrb_i;
                        pprot_reg <= src_pprot_i;
                    end
                end
                SETUP: begin
                    if (dst_pready_i) begin
                        state_reg <= ACCESS;
                        penable_reg <= 1'b0;
                        dst_psel_o <= psel_reg;
                        dst_penable_o <= penable_reg;
                        dst_pwrite_o <= pwrite_reg;
                        dst_paddr_o <= paddr_reg;
                        dst_pwdata_o <= pwdata_reg;
                        dst_pstrb_o <= pstrb_reg;
                        dst_pprot_o <= pprot_reg;
                    end
                end
                ACCESS: begin
                    if (dst_pready_i) begin
                        state_reg <= IDLE;
                        psel_reg <= 1'b0;
                        penable_reg <= 1'b0;
                        pwrite_reg <= 1'b0;
                        paddr_reg <= 0;
                        pwdata_reg <= 0;
                        pstrb_reg <= 0;
                        pprot_reg <= 0;
                        prdata_reg <= dst_prdata_i;
                        pslverr_reg <= dst_pslverr_i;
                        pready_reg <= 1'b1;
                    end
                end
            endcase
        end
    end

    // Output assignments
    assign src_pready_o = pready_reg;
    assign src_prdata_o = prdata_reg;
    assign src_pslverr_o = pslverr_reg;
    assign dst_psel_o = 1'b0;
    assign dst_penable_o = 1'b0;
    assign dst_pwrite_o = 1'b0;
    assign dst_paddr_o = 0;
    assign dst_pwdata_o = 0;
    assign dst_pstrb_o = 0;
    assign dst_pprot_o = 0;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b11001100;
        #10 in = 8'b00110011;
        #10 $finish;
    end

    always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input wire clk,
    input wire rst_n,
    input wire [7:0] in,
    output wire [7:0] out
);

    reg [7:0] reg_out;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            reg_out <= 8'b0;
        end else begin
            reg_out <= in;
        end
    end

    assign out = reg_out;

endmodule

module top_module_tb;

    reg clk;
    reg rst_n;
    reg [7:0] in;
    wire [7:0] out;

    top_module dut(
        .clk(clk),
        .rst_n(rst_n),
        .in(in),
        .out(out)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        in = 8'b0;
        #10 rst_n = 1;
        #10 in = 8'b10101010;
        #10 in = 8'b01010101;
        #10 in = 8'b1