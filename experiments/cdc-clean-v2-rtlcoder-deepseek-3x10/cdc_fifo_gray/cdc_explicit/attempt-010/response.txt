Here is the complete Verilog code for the cdc_fifo_gray module:

```
module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Local parameters
    localparam DEPTH = 1 << LOG_DEPTH;
    localparam ADDR_WIDTH = LOG_DEPTH;
    localparam GRAY_WIDTH = LOG_DEPTH + 1;

    // Internal signals
    reg [ADDR_WIDTH-1:0] wr_ptr_d, wr_ptr_q;
    reg [ADDR_WIDTH-1:0] rd_ptr_d, rd_ptr_q;
    reg [GRAY_WIDTH-1:0] wr_gray_d, wr_gray_q;
    reg [GRAY_WIDTH-1:0] rd_gray_d, rd_gray_q;
    reg [WIDTH-1:0] data_d, data_q;
    reg valid_d, valid_q;
    reg ready_d, ready_q;
    wire [GRAY_WIDTH-1:0] wr_gray_next;
    wire [GRAY_WIDTH-1:0] rd_gray_next;
    wire [ADDR_WIDTH-1:0] wr_ptr_next;
    wire [ADDR_WIDTH-1:0] rd_ptr_next;
    wire [WIDTH-1:0] data_next;
    wire valid_next;
    wire ready_next;

    // Write pointer
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_ptr_q <= '0;
        end else begin
            wr_ptr_q <= wr_ptr_d;
        end
    end

    always @* begin
        wr_ptr_d = wr_ptr_q;
        if (src_valid_i && src_ready_o) begin
            wr_ptr_d = wr_ptr_q + 1;
        end
    end

    // Read pointer
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_ptr_q <= '0;
        end else begin
            rd_ptr_q <= rd_ptr_d;
        end
    end

    always @* begin
        rd_ptr_d = rd_ptr_q;
        if (dst_valid_o && dst_ready_i) begin
            rd_ptr_d = rd_ptr_q + 1;
        end
    end

    // Write gray code
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            wr_gray_q <= '0;
        end else begin
            wr_gray_q <= wr_gray_d;
        end
    end

    always @* begin
        wr_gray_d = wr_gray_q;
        if (src_valid_i && src_ready_o) begin
            wr_gray_d = wr_gray_q + 1;
        end
    end

    // Read gray code
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            rd_gray_q <= '0;
        end else begin
            rd_gray_q <= rd_gray_d;
        end
    end

    always @* begin
        rd_gray_d = rd_gray_q;
        if (dst_valid_o && dst_ready_i) begin
            rd_gray_d = rd_gray_q + 1;
        end
    end

    // Data
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            data_q <= '0;
        end else begin
            data_q <= data_d;
        end
    end

    always @* begin
        data_d = data_q;
        if (src_valid_i && src_ready_o) begin
            data_d = src_data_i;
        end
    end

    // Valid
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            valid_q <= 1'b0;
        end else begin
            valid_q <= valid_d;
        end
    end

    always @* begin
        valid_d = valid_q;
        if (src_valid_i && src_ready_o) begin
            valid_d = 1'b1;
        end else if (dst_valid_o && dst_ready_i) begin
            valid_d = 1'b0;
        end
    end

    // Ready
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            ready_q <= 1'b0;
        end else begin
            ready_q <= ready_d;
        end
    end

    always @* begin
        ready_d = ready_q;
        if (dst_valid_o && dst_ready_i) begin
            ready_d = 1'b0;
        end else if (src_valid_i && src_ready_o) begin
            ready_d = 1'b1;
        end
    end

    // Outputs
    assign src_ready_o = ready_q;
    assign dst_data_o = data_q;
    assign dst_valid_o = valid_q;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        shift_reg[4] <= 0;
        shift_reg[5] <= 0;
        shift_reg[6] <= 0;
        shift_reg[7] <= 0;
        data_out <= 0;
    end else begin
        shift_reg[0] <= data_in;
        shift_reg[1] <= shift_reg[0];
        shift_reg[2] <= shift_reg[1];
        shift_reg[3] <= shift_reg[2];
        shift_reg[4] <= shift_reg[3];
        shift_reg[5] <= shift_reg[4];
        shift_reg[6] <= shift_reg[5];
        shift_reg[7] <= shift_reg[6];
        
        if (shift_count == 7) begin
            data_out <= shift_reg[7];
            shift_count <= 0;
        end else begin
            shift_count <= shift_count + 1;
        end
    end
end

endmodule

module top_module_tb;

reg clk;
reg rst_n;
reg [7:0] data_in;
wire [7:0] data_out;

top_module dut(
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
    #10 data_in = 8'h01;
    #10 data_in = 8'h02;
    #10 data_in = 8'h03;
    #10 data_in = 8'h04;
    #10 data_in = 8'h05;
    #10 data_in = 8'h06;
    #10 data_in = 8'h07;
    #10 data_in = 8'h08;
    #10 $finish;
end

always #5 clk = ~clk;

endmodule<｜end▁of▁sentence｜><｜begin▁of▁sentence｜>module top_module(
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

reg [7:0] shift_reg [0:7];
reg [2:0] shift_count;

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        shift_count <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;